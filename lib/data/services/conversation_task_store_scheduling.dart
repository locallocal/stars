part of 'conversation_task_store.dart';

extension ConversationTaskStoreScheduling on ConversationTaskStore {
  Future<TaskWriteResult<ConversationTask>> recoverTask({
    required String taskId,
    required int expectedRevision,
    required DateTime now,
  }) => _write(taskId, (tx) async {
    final old = await _current(tx, taskId, expectedRevision);
    if (old.lease == null) {
      return TaskWriteCommitted(old, revision: old.revision, reused: true);
    }
    if (old.lease!.isValidAt(now)) {
      throw _TaskConflict(
        TaskWriteConflictReason.leaseUnavailable,
        old.revision,
      );
    }
    await _scheduleEvent(tx, old, now, TaskEventKind.leaseExpired);
    await _scheduleEvent(tx, old, now, TaskEventKind.processRecovered);
    final saved = await _saveTask(tx, {
      ...ConversationTaskRecord.fromDomain(old).values,
      ..._releasedLease,
      'status':
          old.status == ConversationTaskStatus.running
              ? ConversationTaskStatus.paused.name
              : old.status.name,
      'revision': old.revision + 1,
      'updated_at': now.microsecondsSinceEpoch,
    });
    return TaskWriteCommitted(saved, revision: saved.revision);
  }, progress: true);

  Future<TaskWriteResult<ConversationTask>> waitForTaskInput({
    required String taskId,
    required int expectedRevision,
    required TaskWaitingReason reason,
    required String reasonCode,
    required DateTime now,
    TaskLease? lease,
  }) => _write(taskId, (tx) async {
    final old = await _current(tx, taskId, expectedRevision);
    if (reason == TaskWaitingReason.approval ||
        !{
              TaskReasonCode.missingCredentials,
              TaskReasonCode.providerUnavailable,
              TaskReasonCode.botUnavailable,
              TaskReasonCode.reconciliationRequired,
              TaskReasonCode.invalidPlan,
            }.contains(reasonCode) &&
            !TaskReasonCode.isToolUnavailable(reasonCode)) {
      throw ArgumentError(
        'Use a safe runtime obstacle or reconciliation reason.',
      );
    }
    if (old.lease != null) {
      if (lease == null) {
        throw _TaskConflict(
          TaskWriteConflictReason.leaseUnavailable,
          old.revision,
        );
      }
      _fence(old, lease, now);
    }
    await _scheduleEvent(
      tx,
      old,
      now,
      TaskEventKind.waitingForUser,
      reasonCode,
    );
    final saved = await _saveTask(tx, {
      ...ConversationTaskRecord.fromDomain(old).values,
      ..._releasedLease,
      'status': ConversationTaskStatus.waitingForUser.name,
      'waiting_reason': reason.name,
      'next_run_at': null,
      'revision': old.revision + 1,
      'updated_at': now.microsecondsSinceEpoch,
    });
    return TaskWriteCommitted(saved, revision: saved.revision);
  }, progress: true);

  Future<TaskWriteResult<ConversationTask>> resumeTask({
    required String taskId,
    required int expectedRevision,
    required DateTime now,
  }) => _write(taskId, (tx) async {
    final old = await _current(tx, taskId, expectedRevision);
    final approvals = await tx.query(
      'conversation_task_approvals',
      where: 'task_id = ? AND decision IS NULL',
      whereArgs: [taskId],
    );
    if (old.status != ConversationTaskStatus.waitingForUser ||
        old.waitingReason == TaskWaitingReason.approval ||
        (approvals.isNotEmpty && old.cancelRequestedAt == null) ||
        old.lease != null) {
      throw _TaskConflict(
        TaskWriteConflictReason.leaseUnavailable,
        old.revision,
      );
    }
    // The checkpoint keeps its pending calls and job handles. The runner retries
    // reconciliation before any new I/O when resuming an uncertain outcome.
    await _scheduleEvent(tx, old, now, TaskEventKind.resumed);
    final saved = await _saveTask(tx, {
      ...ConversationTaskRecord.fromDomain(old).values,
      'status':
          old.cancelRequestedAt == null
              ? ConversationTaskStatus.queued.name
              : ConversationTaskStatus.cancelRequested.name,
      'phase': ConversationTaskPhase.observing.name,
      'waiting_reason': null,
      'next_run_at': now.microsecondsSinceEpoch,
      'revision': old.revision + 1,
      'updated_at': now.microsecondsSinceEpoch,
    });
    return TaskWriteCommitted(saved, revision: saved.revision);
  }, progress: true);
}

const _releasedLease = <String, Object?>{
  'lease_owner_id': null,
  'lease_token': null,
  'lease_acquired_at': null,
  'lease_expires_at': null,
};

Future<void> _scheduleEvent(
  DatabaseExecutor tx,
  ConversationTask old,
  DateTime now,
  TaskEventKind kind, [
  String? reason,
]) async {
  if (now.isBefore(old.updatedAt)) {
    throw ArgumentError('Stale scheduling time.');
  }
  await _event(
    tx,
    ConversationTaskEvent(
      taskId: old.taskId,
      sequence: await _nextSequence(tx, old.taskId),
      kind: kind,
      planRevision: old.planRevision,
      occurredAt: now,
      safeSummary: 'Task scheduling: ${kind.name}.',
      reasonCode: reason,
    ),
  );
}
