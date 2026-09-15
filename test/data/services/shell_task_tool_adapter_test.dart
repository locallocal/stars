import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/services/shell_task_tool_adapter.dart';
import 'package:stars/data/services/task_runtime_factory.dart';
import 'package:stars/data/services/tools/shell_command_tool.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/services/task_provider_configuration.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';

import '../../support/foreground_turn_fixtures.dart';
import '../../support/task_runner_harness.dart';

void main() {
  late TaskRepositoryHarness h;
  late RunnerModels models;
  late RunnerClock clock;
  late _ShellRunner process;
  var segments = 0;
  final bot = foregroundBot(parameters: {});

  TaskRuntimeFactory runtime() => TaskRuntimeFactory(
    tasks: h.repository,
    bots: _Bots(bot),
    providers: ForegroundProviders((bot) => _Provider(bot, models)),
    registry: StaticToolRegistry([
      ShellCommandTool(platform: NativeShellPlatform.linux, runner: process),
    ]),
    policy: const DefaultToolPolicy(
      allowDestructiveWithApproval: true,
      allowProcessExecution: true,
    ),
    clock: clock,
  );

  Future<TaskSegmentResult> run() async {
    final current = await h.task;
    final lease = TaskLease(
      taskId: current.taskId,
      ownerId: 'shell-worker',
      token: 'shell-lease-${++segments}',
      acquiredAt: clock.now(),
      expiresAt: clock.now().add(const Duration(minutes: 1)),
    );
    committed(
      await h.repository.tryAcquireLease(
        taskId: current.taskId,
        expectedRevision: current.revision,
        lease: lease,
        now: clock.now(),
      ),
    );
    final execute = await runtime().resolve(current);
    return execute(
      input: (await h.repository.getExecutionSnapshot(current.taskId))!,
      lease: lease,
      segmentId: 'shell-segment-$segments',
    );
  }

  Future<void> decide(
    TaskApprovalWait wait,
    TaskApprovalDecision decision,
  ) async {
    final current = await h.task;
    committed(
      await h.repository.decideApproval(
        taskId: current.taskId,
        expectedRevision: current.revision,
        approvalId: wait.approvalId,
        decision: decision,
        actorId: 'user',
        decidedAt: clock.now(),
      ),
    );
  }

  setUp(() async {
    h = TaskRepositoryHarness();
    await h.open();
    models = RunnerModels();
    clock = RunnerClock();
    process = _ShellRunner();
    segments = 0;
    committed(
      await h.accept(
        task: taskFixture(
          acceptance: TaskAcceptanceSnapshot(
            providerId: bot.apiType,
            modelId: bot.model,
            configurationDigest: taskProviderConfigurationDigest(bot),
            language: 'zh-CN',
            context: taskAcceptance().context,
            allowedToolNames: {'run_shell_command'},
            verification: taskAcceptance().verification,
            segmentLimits: TaskSegmentLimits(),
          ),
        ),
      ),
    );
  });
  tearDown(() => h.close());

  test(
    'approval preserves the complete command and execution resumes once after restart',
    () async {
      final command =
          "\n# ${List.filled(3000, 'x').join()}\nprintf '%s' '简历结束'\n";
      final arguments = <String, Object?>{
        'command': command,
        'working_directory': h.directory.path,
        'timeout_seconds': 7,
      };
      models.tool(name: 'run_shell_command', arguments: arguments);
      final wait = await run() as TaskApprovalWait;
      expect(process.requests, isEmpty);
      expect(
        wait.snapshot.task.progress.pendingApprovalSummary,
        contains(jsonEncode(arguments)),
      );
      await h.reopen();
      final snapshot = (await h.repository.getExecutionSnapshot('task-1'))!;
      expect(
        snapshot.task.progress.pendingApprovalSummary,
        contains(jsonEncode(arguments)),
      );
      expect(
        snapshot.checkpoint!.execution!.calls.single.call.arguments,
        arguments,
      );
      await decide(wait, TaskApprovalDecision.approved);
      models.completeStep();
      models.completeStep();
      models.candidate();
      final result = await run();
      expect(result, isA<TaskCompletionCandidate>());
      expect(process.requests.single.command, command);
      expect(process.requests.single.workingDirectory, h.directory.path);
      expect(process.requests.single.timeout, const Duration(seconds: 7));
      expect(
        result.snapshot.attempts.single.status,
        ToolInvocationStatus.succeeded,
      );
      await h.reopen();
      expect(await run(), isA<TaskCompletionCandidate>());
      expect(process.requests, hasLength(1));
    },
  );

  test('denying the persisted approval never starts a process', () async {
    models.tool(
      name: 'run_shell_command',
      arguments: {'command': 'echo denied'},
    );
    final wait = await run() as TaskApprovalWait;
    await h.reopen();
    await decide(wait, TaskApprovalDecision.denied);
    final result = await run() as TaskNeedsSafeFinalization;
    expect(result.reasonCode, TaskReasonCode.permissionDenied);
    expect(process.requests, isEmpty);
  });

  test(
    'cancellation before an approved command starts never invokes the shell',
    () async {
      models.tool(
        name: 'run_shell_command',
        arguments: {'command': 'echo cancelled'},
      );
      await run();
      final task = await h.task;
      committed(
        await h.repository.requestCancellation(
          taskId: task.taskId,
          expectedRevision: task.revision,
          source: TaskCancellationSource.user,
          requestedAt: clock.now(),
        ),
      );
      final result = await run() as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.cancelled);
      expect(process.requests, isEmpty);
    },
  );

  test(
    'interrupted shell attempt is not replayed after reopening the database',
    () async {
      models.tool(
        name: 'run_shell_command',
        arguments: {'command': 'echo started'},
      );
      final wait = await run() as TaskApprovalWait;
      await decide(wait, TaskApprovalDecision.approved);
      process.onRun = (_, _) async => throw const AgentRunCancelledException();
      expect(await run(), isA<TaskContinueSegment>());
      expect(process.requests, hasLength(1));
      await h.reopen();
      final result = await run() as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.reconciliationRequired);
      expect(
        result.snapshot.attempts.single.status,
        ToolInvocationStatus.running,
      );
      expect(process.requests, hasLength(1));
    },
  );

  test(
    'shell credentials are rejected before approval or checkpoint persistence',
    () async {
      const secret = 'sk-private-shell-test-secret';
      models.tool(
        name: 'run_shell_command',
        arguments: {'command': 'echo api_key=$secret'},
      );
      final result = await run() as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.invalidPlan);
      expect(result.snapshot.approvals, isEmpty);
      expect(process.requests, isEmpty);
      expect(jsonEncode(await h.facts()), isNot(contains(secret)));
    },
  );

  test(
    'native adapter writes the expected file using the supplied working directory',
    () async {
      final adapter = ShellTaskToolAdapter(
        ShellCommandTool(platform: NativeShellPlatform.linux),
      );
      final result =
          await adapter.start(
                ToolCallRequest(
                  callId: 'native',
                  name: 'run_shell_command',
                  arguments: {
                    'command': "printf '%s' 'shell task' > proof.txt",
                    'working_directory': h.directory.path,
                    'timeout_seconds': 3,
                  },
                ),
                'native-key',
                AgentCancellationToken(),
              )
              as ToolCompleted;
      expect(result.result.isError, isFalse);
      expect(
        await File('${h.directory.path}/proof.txt').readAsString(),
        'shell task',
      );
      expect(adapter.guaranteesIdempotency, isFalse);
    },
    skip: !Platform.isLinux,
  );
}

final class _ShellRunner implements ShellCommandRunner {
  final requests = <ShellCommandExecutionRequest>[];
  Future<ShellCommandExecutionResult> Function(
    ShellCommandExecutionRequest,
    AgentCancellationToken,
  )?
  onRun;

  @override
  Future<ShellCommandExecutionResult> run(
    ShellCommandExecutionRequest request,
    AgentCancellationToken token,
  ) async {
    requests.add(request);
    if (onRun != null) return onRun!(request, token);
    return ShellCommandExecutionResult(
      platform: NativeShellPlatform.linux,
      shell: 'POSIX sh',
      workingDirectory: request.workingDirectory,
      exitCode: 0,
      stdout: 'done',
      stderr: '',
      duration: const Duration(milliseconds: 1),
    );
  }
}

final class _Bots implements BotRepository {
  _Bots(this.bot);
  final Bot bot;
  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async => [bot];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Provider extends AiProvider {
  _Provider(super.bot, this.models);
  final RunnerModels models;
  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );
  @override
  AgentModelSession openModelSession(ModelRequest request) =>
      models.open(taskAcceptance(), request);
  @override
  Future<void> generateText(List<ChatMessage> messages) =>
      throw UnsupportedError('Use sessions');
}
