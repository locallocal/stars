import 'dart:async';
import 'dart:collection';

import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';

import 'conversation_task_repository_harness.dart';

export 'conversation_task_repository_harness.dart';

final class RunnerClock implements TaskRunnerClock {
  DateTime time = taskTime;
  final budgets = <Duration>[];
  bool expireNext = false;
  Duration tick = Duration.zero;
  @override
  DateTime now() {
    final value = time;
    time = time.add(tick);
    return value;
  }

  @override
  Future<T> timeout<T>(Future<T> work, Duration limit) async {
    budgets.add(limit);
    if (expireNext) {
      expireNext = false;
      unawaited(work.then<void>((_) {}, onError: (Object _) {}));
      throw TimeoutException('fake attempt timeout');
    }
    return work;
  }

  void advance(Duration duration) {
    time = time.add(duration);
  }
}

final class RunnerModels {
  final turns = Queue<Stream<ModelEvent> Function()>();
  final requests = <ModelRequest>[];
  final acceptances = <TaskAcceptanceSnapshot>[];
  final synthesisRequests = <GroundedAnswerSynthesisRequest>[];
  int closed = 0, cancelled = 0;
  AgentModelSession open(
    TaskAcceptanceSnapshot acceptance,
    ModelRequest request,
  ) {
    acceptances.add(acceptance);
    requests.add(request);
    return _Session(this);
  }

  void events(List<ModelEvent> events) =>
      turns.add(() => Stream.fromIterable(events));
  void tool({
    String id = 'provider-call',
    Map<String, Object?> arguments = const {},
    String name = 'read_file',
  }) => events([
    ToolCallRequested(callId: id, name: name, arguments: arguments),
    const ModelTurnCompleted(stopReason: 'tool_calls'),
  ]);
  void completeStep() => events([
    const TextDelta('private intermediate draft'),
    const ModelTurnCompleted(stopReason: 'stop'),
  ]);
  void candidate([GroundedAnswerCandidate? candidate]) => events([
    GroundedAnswerProduced(
      candidate ?? GroundedAnswerCandidate(nonFactualText: '已整理'),
    ),
    const ModelTurnCompleted(stopReason: 'stop'),
  ]);
}

final class _Session implements AgentModelSession {
  _Session(this.owner);
  final RunnerModels owner;
  @override
  Stream<ModelEvent> start() => owner.turns.removeFirst()();
  @override
  Stream<ModelEvent> synthesizeGroundedAnswer(
    GroundedAnswerSynthesisRequest request, {
    List<ToolResult> pendingToolResults = const [],
  }) {
    owner.synthesisRequests.add(request);
    return start();
  }

  @override
  Stream<ModelEvent> continueWith(List<ToolResult> results) =>
      throw StateError('Sessions must be rebuilt from facts.');
  @override
  Stream<ModelEvent> continueWithReliabilityFeedback(String feedback) =>
      throw StateError('Unexpected in-memory continuation.');
  @override
  Future<void> cancel() async {
    owner.cancelled++;
  }

  @override
  void close() {
    owner.closed++;
  }
}

final class RunnerTool implements TaskToolAdapter {
  RunnerTool({
    ToolRiskLevel risk = ToolRiskLevel.readOnly,
    this.guaranteesIdempotency = false,
    ToolDefinition? definition,
    this.checkpointArgumentNames = const {'path', 'page', 'scope'},
  }) : definition =
           definition ??
           ToolDefinition(
             name: 'read_file',
             description: 'Read report',
             source: ToolSource.builtIn,
             riskLevel: risk,
             inputSchema: {'type': 'object'},
           );
  @override
  final ToolDefinition definition;
  @override
  final bool guaranteesIdempotency;
  @override
  final Set<String> checkpointArgumentNames;
  int starts = 0, polls = 0, cancels = 0, reconciles = 0;
  final keys = <String>[];
  final tokens = <AgentCancellationToken>[];
  Future<ToolStartResult> Function(ToolCallRequest)? onStart;
  Future<ToolStartResult> Function(TaskExternalJob)? onPoll;
  Future<ToolReconciliation> Function()? onReconcile;
  Future<ToolReconciliation> Function()? onCancel;
  @override
  Future<ToolStartResult> start(
    ToolCallRequest call,
    String idempotencyKey,
    AgentCancellationToken token,
  ) {
    starts++;
    keys.add(idempotencyKey);
    tokens.add(token);
    return onStart?.call(call) ??
        Future.value(
          ToolCompleted(
            ToolResult(
              callId: call.callId,
              name: call.name,
              content: 'Read completed.',
            ),
          ),
        );
  }

  @override
  Future<ToolStartResult> poll(
    TaskExternalJob job,
    AgentCancellationToken token,
  ) {
    polls++;
    tokens.add(token);
    return onPoll!(job);
  }

  @override
  Future<ToolReconciliation> cancel(
    TaskExternalJob job,
    AgentCancellationToken token,
  ) async {
    cancels++;
    return onCancel?.call() ?? const ToolNotStarted();
  }

  @override
  Future<ToolReconciliation> reconcile(
    ToolCallRequest call,
    String idempotencyKey,
    TaskExternalJob? job,
    AgentCancellationToken token,
  ) async {
    reconciles++;
    return onReconcile?.call() ?? const ToolOutcomeUnknown();
  }
}

final class RunnerPolicy implements ToolPolicy {
  ToolPolicyOutcome outcome = ToolPolicyOutcome.allow;
  @override
  ToolPolicyDecision evaluate(
    ToolDefinition definition,
    ToolCallRequest call,
    ToolPolicyContext context,
  ) => ToolPolicyDecision(outcome: outcome);
}

final class TaskRunnerHarness {
  final db = TaskRepositoryHarness();
  final clock = RunnerClock();
  final models = RunnerModels();
  final policy = RunnerPolicy();
  ToolPolicy? policyOverride;
  RunnerTool tool = RunnerTool();
  List<TaskToolAdapter>? toolOverrides;
  int segment = 0;
  ConversationTaskRepository? repositoryOverride;
  TaskExecutionPreparer? prepare;
  Future<void> open({
    TaskSegmentLimits? limits,
    int steps = 1,
    TaskAcceptanceSnapshot? acceptance,
  }) async {
    await db.open();
    final task = taskFixture(
      acceptance: acceptance ?? taskAcceptance(limits: limits),
    );
    committed(
      await db.accept(
        task: task,
        plan: ConversationTaskPlan(
          taskId: task.taskId,
          revision: 1,
          objective: task.objective,
          isPending: task.acceptance.deferredPreparation,
          steps:
              task.acceptance.deferredPreparation
                  ? []
                  : [
                    for (var i = 0; i < steps; i++)
                      TaskPlanStep(stepId: 'step-$i', summary: 'Step $i'),
                  ],
          allowedToolNames: task.acceptance.allowedToolNames,
          createdAt: task.createdAt,
        ),
      ),
    );
  }

  Future<TaskSegmentResult> run({
    Duration leaseDuration = const Duration(days: 1),
    AgentCancellationToken? interruption,
  }) async {
    final task = await db.task;
    segment++;
    final at = clock.now();
    final lease = TaskLease(
      taskId: task.taskId,
      ownerId: 'test-worker',
      token: 'lease-$segment',
      acquiredAt: at,
      expiresAt: at.add(leaseDuration),
    );
    committed(
      await db.repository.tryAcquireLease(
        taskId: task.taskId,
        expectedRevision: task.revision,
        lease: lease,
        now: at,
      ),
    );
    final input = (await db.repository.getExecutionSnapshot(task.taskId))!;
    return runner.run(
      input: input,
      lease: lease,
      segmentId: 'segment-$segment',
      interruption: interruption,
    );
  }

  ConversationTaskRunner get runner => ConversationTaskRunner(
    repository: repositoryOverride ?? db.repository,
    sessions: models.open,
    tools: toolOverrides ?? [tool],
    policy: policyOverride ?? policy,
    prepare: prepare,
    clock: clock,
    jitter: () => 0.5,
  );
  Future<TaskExecutionSnapshot> get snapshot async =>
      (await db.repository.getExecutionSnapshot('task-1'))!;
  Future<void> close() => db.close();
  Future<void> advanceToDue() async {
    final scheduled = (await db.task).nextRunAt;
    if (scheduled != null && scheduled.isAfter(clock.time)) {
      clock.time = scheduled;
    }
  }
}
