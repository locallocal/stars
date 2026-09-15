import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';

import '../../support/task_runner_harness.dart';

void main() {
  late TaskRunnerHarness h;
  setUp(() {
    h = TaskRunnerHarness();
  });
  tearDown(() => h.close());

  for (final kind in ['toolQueued', 'toolStarted', 'approvalRequested']) {
    test('$kind transaction failure prevents external execution', () async {
      await h.open();
      h.models.tool();
      if (kind == 'approvalRequested') {
        h.policy.outcome = ToolPolicyOutcome.requireApproval;
      }
      await h.db.failWrite(
        'conversation_task_events',
        when: "NEW.kind = '$kind'",
      );
      await expectLater(h.run(), throwsA(isA<Exception>()));
      expect(h.tool.starts, 0);
      final snapshot = await h.snapshot;
      expect(snapshot.approvals, isEmpty);
      expect(snapshot.task.status, ConversationTaskStatus.running);
      expect(h.models.closed, 1);
    });
  }

  test(
    'committed queue and running record precede any tool side effect',
    () async {
      await h.open();
      h.models.tool();
      h.models.completeStep();
      h.models.candidate();
      h.tool.onStart = (call) async {
        final state = await h.snapshot;
        expect(state.attempts.single.status, ToolInvocationStatus.running);
        expect(state.checkpoint!.pendingAttemptIds, [
          state.attempts.single.attemptId,
        ]);
        final events = await h.db.database.query(
          'conversation_task_events',
          orderBy: 'sequence',
        );
        expect(
          events.map((e) => e['kind']),
          containsAllInOrder(['toolQueued', 'toolStarted']),
        );
        return ToolCompleted(
          ToolResult(
            callId: call.callId,
            name: call.name,
            content: 'Completed',
          ),
        );
      };
      expect(await h.run(), isA<TaskCompletionCandidate>());
    },
  );

  test(
    'failure after a side effect leaves running attempt for reconciliation',
    () async {
      await h.open();
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      await h.db.failWrite(
        'conversation_task_events',
        when: "NEW.kind = 'toolSucceeded'",
      );
      await expectLater(h.run(), throwsA(isA<Exception>()));
      expect(h.tool.starts, 1);
      expect(
        (await h.snapshot).attempts.single.status,
        ToolInvocationStatus.running,
      );
      await h.db.clearFailure();
      h.clock.advance(const Duration(days: 2));
      await h.db.reopen();
      h.tool.onReconcile =
          () async => ToolReconciled(
            ToolCompleted(
              ToolResult(
                callId: 'provider-call',
                name: 'read_file',
                content: 'Reconciled completion',
              ),
            ),
          );
      h.models.completeStep();
      h.models.candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      expect(h.tool.starts, 1);
      expect(h.tool.reconciles, 1);
      expect((await h.snapshot).attemptLinks.single.segmentId, 'segment-1');
    },
  );

  test(
    'fake clock provider timeout cancels its session and returns backoff',
    () async {
      await h.open();
      h.models.turns.add(() => StreamController<ModelEvent>().stream);
      h.clock.expireNext = true;
      final result = await h.run() as TaskBackoff;
      await Future<void>.delayed(Duration.zero);
      expect(result.snapshot.task.progress.modelTurns, 1);
      expect(h.models.closed, 1);
      expect(h.models.cancelled, 1);
      expect(h.clock.budgets, [const Duration(minutes: 15)]);
    },
  );

  test(
    'fake clock tool timeout cancels the individual operation token',
    () async {
      await h.open();
      h.models.tool();
      h.tool.onStart = (_) {
        h.clock.expireNext = true;
        return Completer<ToolStartResult>().future;
      };
      final result = await h.run() as TaskBackoff;
      expect(
        result.snapshot.attempts.single.status,
        ToolInvocationStatus.timedOut,
      );
      expect(h.tool.tokens.single.isCancelled, isTrue);
    },
  );

  test(
    'lease expiration during a tool prevents late completion persistence',
    () async {
      await h.open();
      h.models.tool();
      h.tool.onStart = (call) async {
        h.clock.advance(const Duration(minutes: 2));
        return ToolCompleted(
          ToolResult(
            callId: call.callId,
            name: call.name,
            content: 'late result',
          ),
        );
      };
      final result = await h.run(leaseDuration: const Duration(minutes: 1));
      expect(result, isA<TaskLeaseLost>());
      expect(
        result.snapshot.attempts.single.status,
        ToolInvocationStatus.running,
      );
      expect(result.snapshot.checkpoint!.execution!.candidate, isNull);
    },
  );

  test('repository lease conflict fences runner before side effects', () async {
    await h.open();
    h.models.tool();
    h.repositoryOverride = _FencedRepository(h.db.repository);
    expect(await h.run(), isA<TaskLeaseLost>());
    expect(h.tool.starts, 0);
    expect(h.models.requests, isEmpty);
  });

  test(
    'cancellation interrupts an active model without publishing its text',
    () async {
      await h.open();
      final events = StreamController<ModelEvent>();
      final started = Completer<void>();
      h.models.turns.add(() {
        started.complete();
        return events.stream;
      });
      final run = h.run();
      await started.future;
      events.add(const TextDelta('must not reach timeline'));
      final task = await h.db.task;
      committed(
        await h.db.repository.requestCancellation(
          taskId: task.taskId,
          expectedRevision: task.revision,
          source: TaskCancellationSource.user,
          requestedAt: h.clock.now(),
        ),
      );
      final result = await run as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.cancelled);
      expect(
        result.snapshot.task.cancellationSource,
        TaskCancellationSource.user,
      );
      expect(result.snapshot.task.lease, isNull);
      expect(h.models.closed, 1);
      expect(
        jsonEncode(await h.db.database.query('messages')),
        isNot(contains('must not reach timeline')),
      );
      await events.close();
    },
  );

  test(
    'cancelling a long job invokes cancel then retains an unknown effect warning',
    () async {
      await h.open();
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      h.tool.onStart =
          (_) async => ToolJobStarted(
            externalJobId: 'j',
            resumeHandle: 'handle:j',
            safeStatus: 'running',
            nextPollAt: h.clock.now().add(const Duration(hours: 1)),
          );
      await h.run();
      final task = await h.db.task;
      committed(
        await h.db.repository.requestCancellation(
          taskId: task.taskId,
          expectedRevision: task.revision,
          source: TaskCancellationSource.user,
          requestedAt: h.clock.now(),
        ),
      );
      h.tool.onCancel = () async => const ToolOutcomeUnknown();
      final result = await h.run() as TaskNeedsSafeFinalization;
      expect(result.reasonCode, TaskReasonCode.cancelled);
      expect(result.sideEffectsUnknown, isTrue);
      expect(h.tool.cancels, 1);
      expect(result.snapshot.checkpoint!.externalJobs, hasLength(1));
    },
  );

  test(
    'poll timeout keeps the original job and does not increase no-progress',
    () async {
      await h.open();
      h.models.tool();
      h.tool.onStart =
          (_) async => ToolJobStarted(
            externalJobId: 'j',
            resumeHandle: 'handle:j',
            safeStatus: 'running',
            nextPollAt: h.clock.now().add(const Duration(seconds: 30)),
          );
      await h.run();
      await h.advanceToDue();
      h.tool.onPoll = (_) async => throw TimeoutException('poll timeout');
      final result = await h.run() as TaskBackoff;
      expect(
        result.snapshot.checkpoint!.externalJobs.single.externalJobId,
        'j',
      );
      expect(
        result.snapshot.attempts.single.status,
        ToolInvocationStatus.running,
      );
      expect(result.snapshot.task.progress.noProgressSegments, 0);
      expect(h.tool.starts, 1);
    },
  );

  test(
    'reliable idempotency adapter may retry a timed-out write with the same key',
    () async {
      await h.open();
      h.tool = RunnerTool(
        risk: ToolRiskLevel.write,
        guaranteesIdempotency: true,
      );
      h.models.tool();
      h.tool.onStart = (_) async => throw TimeoutException('timeout');
      await h.run();
      await h.advanceToDue();
      h.tool.onStart = null;
      h.models.completeStep();
      h.models.candidate();
      expect(await h.run(), isA<TaskCompletionCandidate>());
      expect(h.tool.starts, 2);
      expect(h.tool.keys.toSet(), hasLength(1));
      expect(h.tool.reconciles, 0);
    },
  );

  for (final code in [
    'authentication_failed',
    'permission_denied',
    'invalid_arguments',
  ]) {
    test('$code does not retry a tool', () async {
      await h.open();
      h.models.tool();
      h.tool.onStart =
          (call) async => ToolCompleted(
            ToolResult(
              callId: call.callId,
              name: call.name,
              content: 'Unrecoverable failure',
              isError: true,
              errorCode: code,
            ),
          );
      expect(await h.run(), isA<TaskNeedsSafeFinalization>());
      expect(h.tool.starts, 1);
      expect((await h.snapshot).attempts, hasLength(1));
    });
  }

  test(
    'model-turn budget checkpoints the whole pending batch before starting tools',
    () async {
      await h.open(
        limits: TaskSegmentLimits(maxModelTurns: 1, maxToolCalls: 2),
      );
      h.models.events([
        for (var i = 0; i < 3; i++)
          ToolCallRequested(
            callId: 'call-$i',
            name: 'read_file',
            arguments: {'page': i},
          ),
        const ModelTurnCompleted(stopReason: 'tool_calls'),
      ]);
      expect(await h.run(), isA<TaskContinueSegment>());
      expect(h.tool.starts, 0);
      expect((await h.snapshot).checkpoint!.execution!.calls, hasLength(3));
      expect(await h.run(), isA<TaskContinueSegment>());
      expect(h.tool.starts, 2);
      expect((await h.snapshot).checkpoint!.execution!.calls, hasLength(1));
    },
  );
}

final class _FencedRepository implements ConversationTaskRepository {
  _FencedRepository(this.inner);
  final ConversationTaskRepository inner;
  @override
  Future<TaskExecutionSnapshot?> getExecutionSnapshot(String id) =>
      inner.getExecutionSnapshot(id);
  @override
  Stream<ConversationTaskProgressSummary> watchProgress(String id) =>
      inner.watchProgress(id);
  @override
  Future<TaskWriteResult<ConversationTask>> appendProgress(
    ConversationTaskProgressUpdate update,
  ) async => const TaskWriteConflict(TaskWriteConflictReason.leaseUnavailable);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
