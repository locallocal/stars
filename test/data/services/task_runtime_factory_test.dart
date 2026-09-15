import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/services/task_runtime_factory.dart';
import 'package:stars/data/services/task_tool_adapters.dart';
import 'package:stars/data/services/tools/built_in_tools.dart';
import 'package:stars/data/services/tools/shell_command_tool.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_scheduling.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/services/task_provider_configuration.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';
import 'package:stars/domain/use_cases/conversation_task_scheduler.dart';

import '../../support/foreground_turn_fixtures.dart';
import '../../support/task_scheduler_harness.dart';

void main() {
  late TaskRepositoryHarness h;
  late _Bots bots;
  setUp(() async {
    h = TaskRepositoryHarness();
    await h.open();
    bots = _Bots(foregroundBot(parameters: {}));
  });
  tearDown(() => h.close());
  ConversationTask task({
    Set<String> tools = const {'calculate'},
    TaskSegmentLimits? limits,
  }) => taskFixture(
    acceptance: TaskAcceptanceSnapshot(
      providerId: bots.bot!.apiType,
      modelId: bots.bot!.model,
      configurationDigest: taskProviderConfigurationDigest(bots.bot!),
      language: 'zh-CN',
      context: taskAcceptance().context,
      allowedToolNames: tools,
      verification: taskAcceptance().verification,
      segmentLimits: limits ?? TaskSegmentLimits(),
    ),
  );
  TaskRuntimeFactory runtime({
    Map<String, TaskToolAdapter> adapters = const {},
    List<Bot>? seen,
    RunnerModels? models,
    TaskRunnerClock clock = const SystemTaskRunnerClock(),
  }) => TaskRuntimeFactory(
    tasks: h.repository,
    bots: bots,
    providers: ForegroundProviders((bot) {
      seen?.add(bot);
      if (models != null) return _RuntimeProvider(bot, models);
      return ForegroundProvider(bot, events: () => const Stream.empty());
    }),
    registry: StaticToolRegistry([
      ...createBuiltInTools(now: clock.now),
      ShellCommandTool(platform: NativeShellPlatform.linux),
    ]),
    policy: RunnerPolicy(),
    adapters: adapters,
    clock: clock,
  );

  test(
    'each segment resolves fresh credentials without copying keys into durable acceptance',
    () async {
      final accepted = task();
      committed(await h.accept(task: accepted));
      final seen = <Bot>[];
      final factory = runtime(seen: seen);
      await factory.resolve(accepted);
      bots.bot = BotRecord.fromDomain(
        bots.bot!,
        storedApiKey: '',
      ).toDomain(apiKey: 'rotated-secret');
      await factory.resolve(accepted);
      expect(bots.refreshes, 2);
      expect(seen.map((bot) => bot.apiKey), [
        'test-credential-not-persisted',
        'rotated-secret',
      ]);
      final facts = jsonEncode(await h.facts());
      expect(facts, isNot(contains('rotated-secret')));
      expect(facts, isNot(contains('test-credential-not-persisted')));
    },
  );

  test(
    'missing bot, unavailable provider and missing key produce actionable safe reasons',
    () async {
      final accepted = task();
      final original = bots.bot!;
      bots.bot = null;
      await expectLater(
        runtime().resolve(accepted),
        throwsA(
          isA<TaskRuntimeUnavailable>().having(
            (e) => e.code,
            'code',
            TaskReasonCode.botUnavailable,
          ),
        ),
      );
      bots.bot = foregroundBot(model: 'different-model');
      await expectLater(
        runtime().resolve(accepted),
        throwsA(
          isA<TaskRuntimeUnavailable>().having(
            (e) => e.code,
            'code',
            TaskReasonCode.providerUnavailable,
          ),
        ),
      );
      bots.bot = BotRecord.fromDomain(
        original,
        storedApiKey: '',
      ).toDomain(apiKey: '');
      await expectLater(
        runtime().resolve(accepted),
        throwsA(
          isA<TaskRuntimeUnavailable>().having(
            (e) => e.reason,
            'reason',
            TaskWaitingReason.authentication,
          ),
        ),
      );
      bots.failure = StateError('Bearer private-credential');
      await expectLater(
        runtime().resolve(accepted),
        throwsA(
          isA<TaskRuntimeUnavailable>().having(
            (e) => e.code,
            'safe code',
            TaskReasonCode.missingCredentials,
          ),
        ),
      );
    },
  );

  test(
    'an unaudited dynamic tool cannot silently inherit durable argument permission',
    () async {
      final accepted = task(tools: {'dynamic_tool'});
      committed(await h.accept(task: accepted));
      await expectLater(
        runtime().resolve(accepted),
        throwsA(
          isA<TaskRuntimeUnavailable>().having(
            (e) => e.code,
            'code',
            TaskReasonCode.invalidPlan,
          ),
        ),
      );
    },
  );

  test(
    'unused shell and missing tools do not prevent persisted task recovery',
    () async {
      final accepted = task(
        tools: {'calculate', 'run_shell_command', 'missing_tool'},
      );
      final plan = ConversationTaskPlan(
        taskId: accepted.taskId,
        revision: 1,
        objective: accepted.objective,
        steps: taskPlan(accepted).steps,
        allowedToolNames: {'calculate'},
        createdAt: accepted.createdAt,
      );
      committed(await h.accept(task: accepted, plan: plan));
      final clock = RunnerClock();
      committed(
        await h.repository.waitForTaskInput(
          taskId: accepted.taskId,
          expectedRevision: 0,
          reason: TaskWaitingReason.requiredInput,
          reasonCode: TaskReasonCode.invalidPlan,
          now: clock.now(),
        ),
      );
      await h.reopen();
      final models =
          RunnerModels()
            ..tool(
              name: 'calculate',
              arguments: {'operation': 'add', 'left': 1, 'right': 2},
            )
            ..completeStep()
            ..completeStep()
            ..candidate();
      var identities = 0;
      final ready = <TaskSegmentResult>[];
      final scheduler = ConversationTaskScheduler(
        repository: h.repository,
        resolve: runtime(models: models, clock: clock).resolve,
        ownerId: 'recovered-worker',
        newId: () => 'recovered-${identities++}',
        clock: clock,
        onReady: (result) async => ready.add(result),
      );
      addTearDown(scheduler.stop);
      await scheduler.start(periodic: false);
      final commands = ConversationTaskCommands(
        repository: h.repository,
        clock: clock,
        wake: scheduler.enqueue,
      );
      committed(
        await commands.resume(
          taskId: accepted.taskId,
          expectedRevision: (await h.task).revision,
        ),
      );
      await until(
        () async =>
            scheduler.runningCount == 0 &&
            (ready.isNotEmpty ||
                (await h.task).status == ConversationTaskStatus.waitingForUser),
      );
      expect(ready, hasLength(1));
      expect(ready.single, isA<TaskCompletionCandidate>());
      final snapshot =
          (await h.repository.getExecutionSnapshot(accepted.taskId))!;
      expect(snapshot.task.progress.completedSteps, plan.steps.length);
      expect(snapshot.task.waitingReason, isNull);
      expect(snapshot.attempts.single.name, 'calculate');
      expect(snapshot.attempts.single.status, ToolInvocationStatus.succeeded);
      expect(
        snapshot.task.acceptance.allowedToolNames,
        accepted.acceptance.allowedToolNames,
      );
      expect(snapshot.plan.allowedToolNames, {'calculate'});
      expect(snapshot.evidence.single.structuredFacts.single.value, 3);
      expect(
        models.requests.first.tools.map((tool) => tool.name),
        unorderedEquals(['calculate', 'stars_revise_task_plan']),
      );
    },
  );

  test(
    'a shell tool required by the plan still needs an audited adapter',
    () async {
      final accepted = task(tools: {'run_shell_command'});
      committed(await h.accept(task: accepted));
      await expectLater(
        runtime().resolve(accepted),
        throwsA(
          isA<TaskRuntimeUnavailable>().having(
            (error) => error.code,
            'reason',
            TaskReasonCode.invalidPlan,
          ),
        ),
      );
    },
  );

  for (final entry
      in {
        'HTML': '\n  <!doctype html>\n<html>简历</html>\n',
        'JSON': '  {"title":"简历"}\n',
        'credentials': '\napi_key=sk-private-test-secret\n',
      }.entries) {
    final content = entry.value;
    test(
      entry.key == 'credentials'
          ? 'file payload credentials never enter the checkpoint or filesystem'
          : 'file payload formatting survives a checkpoint and database restart: ${entry.key}',
      () async {
        final accepted = task(
          tools: {'write_local_file'},
          limits: TaskSegmentLimits(maxModelTurns: 1),
        );
        committed(await h.accept(task: accepted));
        final file = File('${h.directory.path}/resume.txt');
        final models =
            RunnerModels()
              ..tool(
                name: 'write_local_file',
                arguments: {
                  'path': file.path,
                  'content': content,
                  'mode': 'create',
                },
              )
              ..completeStep();
        var segment = 0;
        Future<TaskSegmentResult> run() async {
          final current = await h.task;
          final now = DateTime.now().toUtc();
          final lease = TaskLease(
            taskId: accepted.taskId,
            ownerId: 'file-worker',
            token: 'file-${++segment}',
            acquiredAt: now,
            expiresAt: now.add(const Duration(minutes: 1)),
          );
          committed(
            await h.repository.tryAcquireLease(
              taskId: accepted.taskId,
              expectedRevision: current.revision,
              lease: lease,
              now: now,
            ),
          );
          final execute = await runtime(models: models).resolve(current);
          return execute(
            input: (await h.repository.getExecutionSnapshot(accepted.taskId))!,
            lease: lease,
            segmentId: 'file-segment-$segment',
          );
        }

        final first = await run();
        if (entry.key == 'credentials') {
          expect(first, isA<TaskNeedsSafeFinalization>());
          expect(first.snapshot.attempts, isEmpty);
          expect(
            jsonEncode(await h.facts()),
            isNot(contains('sk-private-test-secret')),
          );
          expect(await file.exists(), isFalse);
          return;
        }
        expect(first, isA<TaskContinueSegment>());
        expect(
          first
              .snapshot
              .checkpoint!
              .execution!
              .calls
              .single
              .call
              .arguments['content'],
          content,
        );
        expect(await file.exists(), isFalse);
        await h.reopen();
        final second = await run();
        expect(second, isA<TaskContinueSegment>());
        expect(await file.readAsBytes(), utf8.encode(content));
        expect(
          second.snapshot.attempts.single.status,
          ToolInvocationStatus.succeeded,
        );
      },
    );
  }

  test(
    'queued cancellation resolves without the bot, key or provider',
    () async {
      final accepted = task();
      committed(await h.accept(task: accepted));
      final cancelling = committed(
        await h.repository.requestCancellation(
          taskId: accepted.taskId,
          expectedRevision: 0,
          source: TaskCancellationSource.user,
          requestedAt: taskTime,
        ),
      );
      bots.bot = null;
      bots.failure = StateError('must not load missing configuration');
      await runtime().resolve(cancelling);
      expect(bots.refreshes, 0);
    },
  );

  test(
    'job adapter recovers a lost start response by lookup and polls the same job',
    () async {
      final runner = TaskRunnerHarness();
      await runner.open();
      addTearDown(runner.close);
      final client = _JobClient(runner.clock);
      final adapter = JobTaskToolAdapter(
        definition: RunnerTool(risk: ToolRiskLevel.write).definition,
        client: client,
        checkpointArgumentNames: {},
      );
      runner.models.tool();
      runner.models.completeStep();
      runner.models.candidate();
      final scheduler = createRunnerScheduler(
        runner,
        resolve:
            (_) async =>
                ConversationTaskRunner(
                  repository: runner.db.repository,
                  sessions: runner.models.open,
                  tools: [adapter],
                  policy: runner.policy,
                  clock: runner.clock,
                  jitter: () => 0.5,
                ).run,
      );
      addTearDown(scheduler.stop);
      await scheduler.start(periodic: false);
      await until(
        () async =>
            (await runner.db.task).nextRunAt != null &&
            scheduler.runningCount == 0,
      );
      await runner.advanceToDue();
      await scheduler.tick();
      await scheduler.tick();
      await until(
        () async =>
            (await runner.snapshot).checkpoint!.externalJobs.isNotEmpty &&
            scheduler.runningCount == 0,
      );
      await runner.advanceToDue();
      await scheduler.tick();
      await scheduler.tick();
      await until(
        () async =>
            (await runner.db.task).phase == ConversationTaskPhase.committing &&
            scheduler.runningCount == 0,
      );
      expect(client.starts, 1);
      expect(client.lookups, 1);
      expect(client.polls, 1);
      expect(client.keys.toSet(), hasLength(1));
      expect(adapter.guaranteesIdempotency, isFalse);
      final job = TaskExternalJob(
        attemptId: 'attempt',
        externalJobId: 'existing',
        resumeHandle: 'handle:existing',
        safeStatus: 'running',
        nextPollAt: runner.clock.now(),
      );
      expect(
        await adapter.cancel(job, AgentCancellationToken()),
        isA<ToolOutcomeUnknown>(),
      );
      expect(client.cancels, 1);
    },
  );
}

final class _RuntimeProvider extends AiProvider {
  _RuntimeProvider(super.bot, this.models);
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
      throw UnsupportedError('Use model sessions');
}

class _Bots implements BotRepository {
  _Bots(this.bot);
  Bot? bot;
  Object? failure;
  int refreshes = 0;
  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async {
    expect(forceRefresh, isTrue);
    refreshes++;
    if (failure case final error?) throw error;
    return [if (bot != null) bot!];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _JobClient implements TaskJobClient {
  _JobClient(this.clock);
  final RunnerClock clock;
  int starts = 0, lookups = 0, polls = 0, cancels = 0;
  final keys = <String>[];
  @override
  Future<ToolStartResult> start(
    ToolCallRequest call,
    String key,
    AgentCancellationToken token,
  ) async {
    starts++;
    keys.add(key);
    throw TimeoutException('job created; response lost');
  }

  @override
  Future<ToolReconciliation> lookup(
    ToolCallRequest call,
    String key,
    TaskExternalJob? job,
    AgentCancellationToken token,
  ) async {
    lookups++;
    keys.add(key);
    return ToolReconciled(
      ToolJobStarted(
        externalJobId: 'existing',
        resumeHandle: 'handle:existing',
        safeStatus: 'running',
        nextPollAt: clock.now().add(const Duration(minutes: 1)),
      ),
    );
  }

  @override
  Future<ToolStartResult> poll(
    TaskExternalJob job,
    AgentCancellationToken token,
  ) async {
    expect(job.externalJobId, 'existing');
    polls++;
    return ToolCompleted(
      ToolResult(callId: 'provider-call', name: 'read_file', content: 'Done'),
    );
  }

  @override
  Future<ToolReconciliation> cancel(
    TaskExternalJob job,
    AgentCancellationToken token,
  ) async {
    cancels++;
    return const ToolOutcomeUnknown();
  }
}
