import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';
import 'package:stars/domain/use_cases/conversation_task_scheduler.dart';

import '../../support/task_scheduler_harness.dart';

void main() {
  late TaskRunnerHarness h;
  final schedulers = <ConversationTaskScheduler>[];
  setUp(() async {
    h = TaskRunnerHarness();
    await h.open();
  });
  tearDown(() async {
    for (final scheduler in schedulers) {
      await scheduler.stop();
    }
    schedulers.clear();
    await h.close();
  });

  ConversationTaskScheduler scheduler({
    List<TaskSegmentResult>? ready,
    String owner = 'new-worker',
  }) {
    final value = createRunnerScheduler(
      h,
      owner: owner,
      onReady: (result) async {
        ready?.add(result);
      },
    );
    schedulers.add(value);
    return value;
  }

  ConversationTaskCommands commands(ConversationTaskScheduler value) =>
      ConversationTaskCommands(
        repository: h.db.repository,
        wake: value.enqueue,
        clock: h.clock,
      );
  Future<void> parked(ConversationTaskScheduler value) => until(
    () async =>
        (await h.db.task).phase == ConversationTaskPhase.committing &&
        value.runningCount == 0,
  );
  ToolCompleted completed() => ToolCompleted(
    ToolResult(
      callId: 'provider-call',
      name: 'read_file',
      content: 'Confirmed completion',
    ),
  );

  test(
    'approval survives months and restart; committed decision wakes the exact task',
    () async {
      h.policy.outcome = ToolPolicyOutcome.requireApproval;
      h.models.tool(arguments: {'path': 'approved.txt'});
      final wait = await h.run() as TaskApprovalWait;
      await h.db.reopen();
      h.clock.advance(const Duration(days: 90));
      final ready = <TaskSegmentResult>[];
      final value = scheduler(ready: ready);
      await value.start(periodic: false);
      expect((await h.db.task).status, ConversationTaskStatus.waitingForUser);
      expect(h.tool.starts, 0);
      final revision = (await h.db.task).revision;
      h.models.completeStep();
      h.models.candidate();
      committed(
        await commands(value).decide(
          taskId: 'task-1',
          expectedRevision: revision,
          approvalId: wait.approvalId,
          decision: TaskApprovalDecision.approved,
          actorId: 'user',
        ),
      );
      await parked(value);
      expect(h.tool.starts, 1);
      expect(ready.single, isA<TaskCompletionCandidate>());
      expect(
        await commands(value).decide(
          taskId: 'task-1',
          expectedRevision: revision,
          approvalId: wait.approvalId,
          decision: TaskApprovalDecision.denied,
          actorId: 'user',
        ),
        isA<TaskWriteConflict<TaskApprovalRecord>>(),
      );
      expect(
        (await h.snapshot).approvals.single.decision,
        TaskApprovalDecision.approved,
      );
    },
  );

  test(
    'a cancellation accepted before restart stops a queued task without model calls',
    () async {
      committed(
        await h.db.repository.requestCancellation(
          taskId: 'task-1',
          expectedRevision: 0,
          source: TaskCancellationSource.user,
          requestedAt: h.clock.now(),
        ),
      );
      await h.db.reopen();
      final ready = <TaskSegmentResult>[];
      final active = scheduler(ready: ready, owner: 'cancel-worker');
      await active.start(periodic: false);
      await parked(active);
      expect(
        (ready.single as TaskNeedsSafeFinalization).reasonCode,
        TaskReasonCode.cancelled,
      );
      expect((await h.db.task).status, ConversationTaskStatus.cancelRequested);
      expect(h.models.requests, isEmpty);
      expect(h.tool.starts, 0);
      expect((await h.db.task).completedAt, isNull);
    },
  );

  test(
    'crash before toolStarted commits never issues a write before recovery',
    () async {
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      await h.db.failWrite(
        'conversation_task_events',
        when: "NEW.kind = 'toolStarted'",
      );
      await expectLater(
        h.run(leaseDuration: const Duration(seconds: 10)),
        throwsA(isA<Exception>()),
      );
      expect(h.tool.starts, 0);
      await h.db.clearFailure();
      await h.db.reopen();
      h.clock.advance(const Duration(seconds: 11));
      h.models.completeStep();
      h.models.candidate();
      final value = scheduler();
      await value.start(periodic: false);
      await parked(value);
      expect(h.tool.starts, 1);
      expect(h.tool.reconciles, 0);
      expect(value.metrics.recoveries, 1);
      expect((await h.db.task).progress.recoveries, 1);
    },
  );

  test(
    'lost job-creation response is reconciled by key, then only the existing job is polled',
    () async {
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      final due = h.clock.now().add(const Duration(minutes: 5));
      ToolJobStarted job() => ToolJobStarted(
        externalJobId: 'external-1',
        resumeHandle: 'handle:external_1',
        safeStatus: 'queued',
        nextPollAt: due,
      );
      h.tool.onStart = (_) async => job();
      await h.db.failWrite(
        'conversation_task_events',
        when: "NEW.kind = 'externalJobUpdated'",
      );
      await expectLater(
        h.run(leaseDuration: const Duration(seconds: 10)),
        throwsA(isA<Exception>()),
      );
      final key = h.tool.keys.single;
      expect((await h.snapshot).checkpoint!.externalJobs, isEmpty);
      await h.db.clearFailure();
      await h.db.reopen();
      h.clock.advance(const Duration(seconds: 11));
      h.tool.onReconcile = () async => ToolReconciled(job());
      final first = scheduler();
      await first.start(periodic: false);
      await until(
        () async =>
            (await h.db.task).nextRunAt == due && first.runningCount == 0,
      );
      expect(
        (await h.snapshot).checkpoint!.externalJobs.single.externalJobId,
        'external-1',
      );
      expect(h.tool.starts, 1);
      expect(h.tool.reconciles, 1);
      await first.stop();
      await h.db.reopen();
      final second = scheduler(owner: 'poll-worker');
      await second.start(periodic: false);
      expect(h.tool.polls, 0);
      h.clock.time = due;
      h.tool.onPoll = (_) async => completed();
      h.models.completeStep();
      h.models.candidate();
      await second.tick();
      await second.tick();
      await parked(second);
      expect(h.tool.starts, 1);
      expect(h.tool.polls, 1);
      expect((await h.snapshot).attemptLinks.single.idempotencyKey, key);
      expect(second.metrics.waitingTime, greaterThan(Duration.zero));
    },
  );

  test(
    'uncertain cancellation remains a reconciliation wait across restart and explicit retry',
    () async {
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      h.tool.onStart = (_) async => throw TimeoutException('issued write');
      expect(await h.run(), isA<TaskBackoff>());
      committed(
        await h.db.repository.requestCancellation(
          taskId: 'task-1',
          expectedRevision: (await h.db.task).revision,
          source: TaskCancellationSource.user,
          requestedAt: h.clock.now(),
        ),
      );
      final first = scheduler();
      await first.start(periodic: false);
      await until(
        () async =>
            (await h.db.task).status == ConversationTaskStatus.waitingForUser &&
            first.runningCount == 0,
      );
      expect((await h.db.task).waitingReason, TaskWaitingReason.reconciliation);
      expect((await h.db.task).cancelRequestedAt, isNotNull);
      expect(
        (await h.snapshot).attempts.single.status,
        ToolInvocationStatus.running,
      );
      await first.stop();
      await h.db.reopen();
      final ready = <TaskSegmentResult>[];
      final second = scheduler(ready: ready, owner: 'retry-worker');
      await second.start(periodic: false);
      expect(ready, isEmpty);
      h.tool.onReconcile = () async => ToolReconciled(completed());
      committed(
        await commands(second).resume(
          taskId: 'task-1',
          expectedRevision: (await h.db.task).revision,
        ),
      );
      await parked(second);
      final result = ready.single as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.cancelled);
      expect(result.sideEffectsUnknown, isFalse);
      expect(h.tool.starts, 1);
      expect(
        (await h.snapshot).attempts.single.status,
        ToolInvocationStatus.succeeded,
      );
      expect((await h.db.task).status, ConversationTaskStatus.cancelRequested);
    },
  );

  test(
    'unknown write without cancellation waits and reconciles again after explicit resume',
    () async {
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      h.tool.onStart = (_) async => throw TimeoutException('issued');
      await h.run();
      await h.advanceToDue();
      final value = scheduler();
      await value.start(periodic: false);
      await until(
        () async =>
            (await h.db.task).status == ConversationTaskStatus.waitingForUser &&
            value.runningCount == 0,
      );
      h.tool.onReconcile = () async => ToolReconciled(completed());
      h.models.completeStep();
      h.models.candidate();
      committed(
        await commands(value).resume(
          taskId: 'task-1',
          expectedRevision: (await h.db.task).revision,
        ),
      );
      await parked(value);
      expect(
        (await h.snapshot).checkpoint!.execution!.sideEffectsUnknown,
        isFalse,
      );
      expect(h.tool.starts, 1);
      expect(h.tool.reconciles, 2);
    },
  );

  test(
    'expired worker cannot commit its late success after another worker takes ownership',
    () async {
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      final issued = Completer<void>(),
          lateResult = Completer<ToolStartResult>();
      h.tool.onStart = (_) {
        issued.complete();
        return lateResult.future;
      };
      final oldRun = h.run(leaseDuration: const Duration(seconds: 10));
      await issued.future;
      h.clock.advance(const Duration(seconds: 11));
      h.tool.onReconcile = () async => ToolReconciled(completed());
      h.models.completeStep();
      h.models.candidate();
      final value = scheduler();
      await value.start(periodic: false);
      await parked(value);
      final facts = await h.db.facts();
      lateResult.complete(completed());
      expect(await oldRun, isA<TaskLeaseLost>());
      expect(await h.db.facts(), facts);
      expect(h.tool.starts, 1);
      expect(value.metrics.leaseExpirations, 1);
    },
  );

  test(
    'application suspension preserves an in-flight read and retries with its original key',
    () async {
      h.models.tool();
      final issued = Completer<void>();
      h.tool.onStart = (_) {
        issued.complete();
        return Completer<ToolStartResult>().future;
      };
      final first = scheduler();
      await first.start(periodic: false);
      await issued.future;
      final key = h.tool.keys.single;
      await first.stop();
      expect(h.tool.tokens.single.isCancelled, isTrue);
      expect((await h.db.task).cancelRequestedAt, isNull);
      expect((await h.db.task).lease, isNull);
      h.tool.onStart = (_) async => completed();
      h.models.completeStep();
      h.models.candidate();
      final second = scheduler(owner: 'resumed-worker');
      await second.start(periodic: false);
      await until(
        () async =>
            (await h.db.task).nextRunAt != null && second.runningCount == 0,
      );
      await h.advanceToDue();
      await second.tick();
      await second.tick();
      await parked(second);
      expect(h.tool.keys, [key, key]);
      expect(
        (await h.snapshot).attemptLinks.map((link) => link.attemptNumber),
        [1, 2],
      );
      expect(second.metrics.retries, 1);
    },
  );

  test(
    'a failed write cancellation retains its running intent until a later reconciliation',
    () async {
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      h.tool.onStart =
          (_) async => ToolJobStarted(
            externalJobId: 'job',
            resumeHandle: 'handle:job',
            safeStatus: 'running',
            nextPollAt: h.clock.now().add(const Duration(minutes: 1)),
          );
      await h.run();
      final ready = <TaskSegmentResult>[];
      final value = scheduler(ready: ready);
      h.tool.onCancel =
          () async => ToolReconciled(
            ToolCompleted(
              ToolResult(
                callId: 'provider-call',
                name: 'read_file',
                content: 'Partial write failed',
                isError: true,
                errorCode: 'partial_write',
              ),
            ),
          );
      committed(
        await commands(value).cancel(
          taskId: 'task-1',
          expectedRevision: (await h.db.task).revision,
        ),
      );
      await value.start(periodic: false);
      await until(
        () async =>
            (await h.db.task).status == ConversationTaskStatus.waitingForUser &&
            value.runningCount == 0,
      );
      expect(
        (await h.snapshot).attempts.single.status,
        ToolInvocationStatus.running,
      );
      expect((await h.snapshot).checkpoint!.pendingAttemptIds, hasLength(1));
      expect(ready, isEmpty);
      committed(
        await commands(value).resume(
          taskId: 'task-1',
          expectedRevision: (await h.db.task).revision,
        ),
      );
      await until(
        () async =>
            (await h.db.task).status == ConversationTaskStatus.waitingForUser &&
            value.runningCount == 0,
      );
      expect(
        (await h.snapshot).attempts.single.status,
        ToolInvocationStatus.running,
      );
      h.tool.onCancel = () async => ToolReconciled(completed());
      committed(
        await commands(value).resume(
          taskId: 'task-1',
          expectedRevision: (await h.db.task).revision,
        ),
      );
      await parked(value);
      expect(
        (ready.single as TaskNeedsSafeFinalization).sideEffectsUnknown,
        isFalse,
      );
      expect(h.tool.starts, 1);
      expect(h.tool.cancels, 3);
    },
  );

  test(
    'reconciliation timeout persists backoff across restart without replaying the write',
    () async {
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      h.tool.onStart = (_) async => throw TimeoutException('issued');
      await h.run();
      await h.advanceToDue();
      h.tool.onReconcile =
          () async => throw TimeoutException('lookup unavailable');
      final first = scheduler();
      await first.start(periodic: false);
      await until(
        () async =>
            (await h.db.task).nextRunAt?.isAfter(h.clock.now()) == true &&
            first.runningCount == 0,
      );
      final due = (await h.db.task).nextRunAt;
      await first.stop();
      await h.db.reopen();
      final second = scheduler(owner: 'timeout-recovery');
      await second.start(periodic: false);
      expect(h.tool.starts, 1);
      expect(h.tool.reconciles, 1);
      expect((await h.db.task).nextRunAt, due);
      h.tool.onReconcile = () async => ToolReconciled(completed());
      h.models.completeStep();
      h.models.candidate();
      await h.advanceToDue();
      await second.tick();
      await second.tick();
      await parked(second);
      expect(h.tool.starts, 1);
      expect(h.tool.reconciles, 2);
    },
  );

  test(
    'recovery retries uncommitted delivery without rerunning tools or synthesis',
    () async {
      h.models.completeStep();
      h.models.candidate();
      await h.run();
      final before = h.models.requests.length;
      await h.db.reopen();
      final ready = <TaskSegmentResult>[];
      final value = scheduler(ready: ready);
      await value.start(periodic: false);
      await value.tick();
      await value.tick();
      expect(ready, hasLength(3));
      expect(ready, everyElement(isA<TaskCompletionCandidate>()));
      expect(h.models.requests.length, before);
      expect(value.runningCount, 0);
      expect((await h.db.repository.listDue(now: h.clock.now())), isEmpty);
    },
  );

  test(
    'a crash after resuming reconciliation does not strand the task in committing',
    () async {
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      h.tool.onStart = (_) async => throw TimeoutException('issued');
      await h.run();
      await h.advanceToDue();
      await h.run();
      committed(
        await h.db.repository.waitForTaskInput(
          taskId: 'task-1',
          expectedRevision: (await h.db.task).revision,
          reason: TaskWaitingReason.reconciliation,
          reasonCode: TaskReasonCode.reconciliationRequired,
          now: h.clock.now(),
        ),
      );
      committed(
        await h.db.repository.resumeTask(
          taskId: 'task-1',
          expectedRevision: (await h.db.task).revision,
          now: h.clock.now(),
        ),
      );
      h.tool.onReconcile = () async => ToolReconciled(completed());
      await h.db.failWrite(
        'conversation_task_events',
        when: "NEW.kind = 'toolSucceeded'",
      );
      await expectLater(
        h.run(leaseDuration: const Duration(seconds: 10)),
        throwsA(isA<Exception>()),
      );
      expect((await h.db.task).phase, isNot(ConversationTaskPhase.committing));
      await h.db.clearFailure();
      await h.db.reopen();
      h.clock.advance(const Duration(seconds: 11));
      h.models.completeStep();
      h.models.candidate();
      final value = scheduler();
      await value.start(periodic: false);
      await parked(value);
      expect(h.tool.starts, 1);
      expect((await h.db.task).progress.completedSteps, 1);
    },
  );
}
