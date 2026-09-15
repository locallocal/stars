import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';

import '../../support/conversation_task_repository_harness.dart';

void main() {
  late TaskRepositoryHarness h;
  setUp(() async {
    h = TaskRepositoryHarness();
    await h.open();
  });
  tearDown(() => h.close());

  Future<ConversationTask> waitForApproval() async {
    final task = await h.task;
    return committed(
      await h.repository.appendProgress(
        await h.update(
          TaskEventKind.approvalRequested,
          status: ConversationTaskStatus.waitingForUser,
          waitingReason: TaskWaitingReason.approval,
          approval: TaskApprovalRecord(
            approvalId: 'approval-1',
            taskId: task.taskId,
            requestRevision: task.revision + 1,
            safeActionSummary: '允许读取资料',
            requestedAt: h.nextTime,
          ),
        ),
      ),
    );
  }

  test(
    'competing lease acquisitions return a single owner with a newer revision',
    () async {
      committed(await h.accept());
      final other = TaskLease(
        taskId: 'task-1',
        ownerId: 'runner-2',
        token: 'lease-2',
        acquiredAt: taskTime,
        expiresAt: taskTime.add(const Duration(minutes: 1)),
      );
      final results = await Future.wait([
        h.repository.tryAcquireLease(
          taskId: 'task-1',
          expectedRevision: 0,
          lease: taskLease(),
          now: taskTime,
        ),
        h.repository.tryAcquireLease(
          taskId: 'task-1',
          expectedRevision: 0,
          lease: other,
          now: taskTime,
        ),
      ]);
      expect(results.whereType<TaskWriteCommitted<TaskLease>>(), hasLength(1));
      expect(
        results.whereType<TaskWriteConflict<TaskLease>>().single.reason,
        TaskWriteConflictReason.revisionMismatch,
      );
      expect(
        await h.repository.tryAcquireLease(
          taskId: 'task-1',
          expectedRevision: 1,
          lease: other,
          now: taskTime,
        ),
        conflict(TaskWriteConflictReason.leaseUnavailable),
      );
    },
  );

  test(
    'expired owner is rejected even with the current task revision',
    () async {
      final old = await h.start();
      h.time = taskTime.add(const Duration(minutes: 1));
      final stale = await h.update(
        TaskEventKind.stepStarted,
        current: old,
        stepId: 'read',
      );
      expect(
        await h.repository.appendProgress(stale),
        conflict(TaskWriteConflictReason.leaseExpired),
      );
      final replacement = TaskLease(
        taskId: old.taskId,
        ownerId: 'runner-2',
        token: 'lease-2',
        acquiredAt: h.time,
        expiresAt: h.time.add(const Duration(minutes: 1)),
      );
      committed(
        await h.repository.tryAcquireLease(
          taskId: old.taskId,
          expectedRevision: old.revision,
          lease: replacement,
          now: h.time,
        ),
      );
      final current = await h.task;
      final valid = await h.update(
        TaskEventKind.processRecovered,
        current: current,
        segmentId: 'recovery-1',
      );
      final forged = ConversationTaskProgressUpdate(
        task: valid.task,
        event: valid.event,
        expectedRevision: current.revision,
        lease: old.lease!,
        now: valid.now,
      );
      expect(
        await h.repository.appendProgress(forged),
        conflict(TaskWriteConflictReason.leaseUnavailable),
      );
      committed(await h.repository.appendProgress(valid));
      expect((await h.task).progress.recoveries, 1);
    },
  );

  test(
    'lease renewal and release persist their revisions and scheduling time',
    () async {
      final old = await h.start();
      final renewed = committed(
        await h.repository.renewLease(
          lease: old.lease!,
          expiresAt: taskTime.add(const Duration(minutes: 3)),
          expectedRevision: old.revision,
          now: h.nextTime,
        ),
      );
      final current = await h.task;
      expect(current.revision, old.revision + 1);
      expect(current.lease!.expiresAt, renewed.expiresAt);
      final due = taskTime.add(const Duration(minutes: 5));
      final released = committed(
        await h.repository.releaseLease(
          lease: renewed,
          expectedRevision: current.revision,
          now: h.nextTime,
          nextRunAt: due,
        ),
      );
      expect(released.status, ConversationTaskStatus.paused);
      expect(released.lease, isNull);
      expect(released.nextRunAt, due);
      await h.reopen();
      expect((await h.task).nextRunAt, due);
      expect(
        await h.repository.listDue(
          now: due.subtract(const Duration(microseconds: 1)),
        ),
        isEmpty,
      );
      expect((await h.repository.listDue(now: due)).single.taskId, old.taskId);
      expect(
        await h.repository.releaseLease(
          lease: renewed,
          expectedRevision: released.revision,
          now: due,
        ),
        conflict(TaskWriteConflictReason.leaseUnavailable),
      );
    },
  );

  test('expired lease cannot be renewed or released', () async {
    final old = await h.start();
    final now = old.lease!.expiresAt;
    expect(
      await h.repository.renewLease(
        lease: old.lease!,
        expiresAt: now.add(const Duration(minutes: 1)),
        expectedRevision: old.revision,
        now: now,
      ),
      conflict(TaskWriteConflictReason.leaseExpired),
    );
    expect(
      await h.repository.releaseLease(
        lease: old.lease!,
        expectedRevision: old.revision,
        now: now,
      ),
      conflict(TaskWriteConflictReason.leaseExpired),
    );
  });

  test(
    'lease acquisition and renewal roll back if projection update fails',
    () async {
      committed(await h.accept());
      final before = await h.facts();
      await h.failWrite('conversation_task_progress', operation: 'UPDATE');
      await expectLater(
        h.repository.tryAcquireLease(
          taskId: 'task-1',
          expectedRevision: 0,
          lease: taskLease(),
          now: h.time,
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(await h.facts(), before);
      await h.clearFailure();
      committed(
        await h.repository.tryAcquireLease(
          taskId: 'task-1',
          expectedRevision: 0,
          lease: taskLease(),
          now: h.time,
        ),
      );
      final acquired = await h.facts();
      await h.failWrite('conversation_task_progress', operation: 'UPDATE');
      await expectLater(
        h.repository.renewLease(
          lease: taskLease(),
          expiresAt: taskTime.add(const Duration(minutes: 2)),
          expectedRevision: 1,
          now: h.nextTime,
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(await h.facts(), acquired);
    },
  );

  for (final decision in TaskApprovalDecision.values) {
    test(
      '$decision is saved before scheduling and cannot be overwritten',
      () async {
        await h.start();
        final waiting = await waitForApproval();
        expect(waiting.status, ConversationTaskStatus.waitingForUser);
        expect(waiting.progress.pendingApprovalId, 'approval-1');
        expect(await h.repository.listDue(now: h.time), isEmpty);
        await h.reopen();
        expect((await h.task).progress.pendingApprovalSummary, '允许读取资料');
        final before = await h.facts();
        final premature = await h.update(
          TaskEventKind.resumed,
          status: ConversationTaskStatus.running,
        );
        await expectLater(
          h.repository.appendProgress(premature),
          throwsArgumentError,
        );
        expect(await h.facts(), before);
        final result = await h.repository.decideApproval(
          taskId: waiting.taskId,
          approvalId: 'approval-1',
          expectedRevision: waiting.revision,
          decision: decision,
          actorId: 'local-user',
          decidedAt: h.nextTime,
        );
        final approval = committed(result);
        expect(approval.decidedBy, 'local-user');
        expect(approval.decidedAt, h.nextTime);
        final saved = await h.task;
        expect(saved.status, ConversationTaskStatus.queued);
        expect(saved.lease, isNull);
        expect(saved.progress.pendingApprovalId, isNull);
        expect(
          saved.progress.reasonCode,
          decision == TaskApprovalDecision.denied
              ? TaskReasonCode.permissionDenied
              : '',
        );
        expect(
          await h.repository.decideApproval(
            taskId: saved.taskId,
            approvalId: 'approval-1',
            expectedRevision: saved.revision,
            decision: decision,
            actorId: 'local-user',
            decidedAt: h.nextTime,
          ),
          conflict(TaskWriteConflictReason.approvalAlreadyDecided),
        );
        await h.reopen();
        expect(
          (await h.database.query(
            'conversation_task_approvals',
          )).single['decision'],
          decision.name,
        );
        expect(
          (await h.repository.listDue(now: h.nextTime)).single.taskId,
          saved.taskId,
        );
      },
    );
  }

  for (final table in [
    'conversation_task_approvals',
    'conversation_task_events',
    'conversation_tasks',
    'conversation_task_progress',
  ]) {
    test(
      'approval request rolls back waiting and facts when $table fails',
      () async {
        await h.start();
        final before = await h.facts();
        await h.failWrite(
          table,
          operation:
              {
                    'conversation_tasks',
                    'conversation_task_progress',
                  }.contains(table)
                  ? 'UPDATE'
                  : 'INSERT',
        );
        await expectLater(waitForApproval(), throwsA(isA<DatabaseException>()));
        expect(await h.facts(), before);
      },
    );
    test('approval decision rolls back completely when $table fails', () async {
      await h.start();
      final waiting = await waitForApproval();
      final before = await h.facts();
      await h.failWrite(
        table,
        operation: table == 'conversation_task_events' ? 'INSERT' : 'UPDATE',
      );
      await expectLater(
        h.repository.decideApproval(
          taskId: waiting.taskId,
          approvalId: 'approval-1',
          expectedRevision: waiting.revision,
          decision: TaskApprovalDecision.approved,
          actorId: 'local-user',
          decidedAt: h.nextTime,
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(await h.facts(), before);
    });
  }

  test(
    'cancellation intent survives approval and prevents ordinary work from resuming',
    () async {
      await h.start();
      final waiting = await waitForApproval();
      final cancelling = committed(
        await h.repository.requestCancellation(
          taskId: waiting.taskId,
          expectedRevision: waiting.revision,
          source: TaskCancellationSource.user,
          requestedAt: h.nextTime,
        ),
      );
      final requestedAt = cancelling.cancelRequestedAt;
      expect(cancelling.status, ConversationTaskStatus.cancelRequested);
      expect(
        await h.repository.requestCancellation(
          taskId: waiting.taskId,
          expectedRevision: waiting.revision,
          source: TaskCancellationSource.user,
          requestedAt: h.nextTime,
        ),
        conflict(TaskWriteConflictReason.revisionMismatch),
      );
      final repeated = await h.repository.requestCancellation(
        taskId: waiting.taskId,
        expectedRevision: cancelling.revision,
        source: TaskCancellationSource.botDeletion,
        requestedAt: h.nextTime,
      );
      expect((repeated as TaskWriteCommitted<ConversationTask>).reused, isTrue);
      committed(
        await h.repository.decideApproval(
          taskId: waiting.taskId,
          approvalId: 'approval-1',
          expectedRevision: cancelling.revision,
          decision: TaskApprovalDecision.approved,
          actorId: 'local-user',
          decidedAt: h.nextTime,
        ),
      );
      await h.reopen();
      final saved = await h.task;
      expect(saved.status, ConversationTaskStatus.cancelRequested);
      expect(saved.cancelRequestedAt, requestedAt);
      expect(saved.cancellationSource, TaskCancellationSource.user);
      expect(await h.repository.listDue(now: h.nextTime), isEmpty);
      expect(
        (await h.repository.listRecoverable()).single.taskId,
        saved.taskId,
      );
    },
  );

  test(
    'cancellation atomically rolls back intent if its event cannot be written',
    () async {
      final old = await h.start();
      final before = await h.facts();
      await h.failWrite('conversation_task_events');
      await expectLater(
        h.repository.requestCancellation(
          taskId: old.taskId,
          expectedRevision: old.revision,
          source: TaskCancellationSource.user,
          requestedAt: h.nextTime,
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(await h.facts(), before);
    },
  );

  test(
    'active, terminal, due and paginated recovery queries select only persisted facts',
    () async {
      await h.start();
      committed(
        await (await h.terminal(
          ConversationTaskStatus.succeeded,
        )).commit(h.repository),
      );
      committed(await h.accept(task: taskFixture(id: 'task-2')));
      committed(await h.accept(task: taskFixture(id: 'task-3')));
      expect(
        (await h.repository.listActiveForChat(
          'chat-1',
        )).map((task) => task.taskId),
        ['task-2', 'task-3'],
      );
      expect(
        (await h.repository.getLatestTerminalForChat('chat-1'))!.taskId,
        'task-1',
      );
      expect(
        (await h.repository.listRecoverable(limit: 1)).single.taskId,
        'task-2',
      );
      expect(
        (await h.repository.listRecoverable(
          afterTaskId: 'task-2',
        )).single.taskId,
        'task-3',
      );
      expect(await h.repository.listActiveForChat('other-chat'), isEmpty);
      expect(await h.repository.getLatestTerminalForChat('other-chat'), isNull);
      expect(
        () => h.repository.listDue(now: h.time, limit: 0),
        throwsArgumentError,
      );
      expect(
        () => h.repository.listRecoverable(limit: 1001),
        throwsArgumentError,
      );
    },
  );
}
