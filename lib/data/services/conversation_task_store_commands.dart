part of 'conversation_task_store.dart';

extension ConversationTaskStoreCommands on ConversationTaskStore {
  Future<TaskWriteResult<TaskLease>> tryAcquireLease({
    required String taskId,
    required int expectedRevision,
    required TaskLease lease,
    required DateTime now,
  }) => _write(taskId, (tx) async {
    final old = await _current(tx, taskId, expectedRevision);
    if (lease.taskId != taskId ||
        lease.acquiredAt != now ||
        !lease.isValidAt(now) ||
        now.isBefore(old.updatedAt)) {
      throw ArgumentError('Lease must start now and belong to this task.');
    }
    if ((old.lease != null &&
            (old.lease!.expiresAt.isAfter(now) ||
                old.lease!.token == lease.token)) ||
        (old.nextRunAt != null && old.nextRunAt!.isAfter(now)) ||
        (old.status == ConversationTaskStatus.waitingForUser &&
            old.cancelRequestedAt == null)) {
      throw _TaskConflict(
        TaskWriteConflictReason.leaseUnavailable,
        old.revision,
      );
    }
    final values = {
      ...ConversationTaskRecord.fromDomain(old).values,
      'lease_owner_id': lease.ownerId,
      'lease_token': lease.token,
      'lease_acquired_at': lease.acquiredAt.microsecondsSinceEpoch,
      'lease_expires_at': lease.expiresAt.microsecondsSinceEpoch,
      'revision': old.revision + 1,
      'updated_at': now.microsecondsSinceEpoch,
    };
    await _saveTask(tx, values);
    return TaskWriteCommitted(lease, revision: old.revision + 1);
  });

  Future<TaskWriteResult<TaskLease>> renewLease({
    required TaskLease lease,
    required DateTime expiresAt,
    required int expectedRevision,
    required DateTime now,
  }) => _write(lease.taskId, (tx) async {
    final old = await _current(tx, lease.taskId, expectedRevision);
    _fence(old, lease, now);
    if (now.isBefore(old.updatedAt) ||
        !expiresAt.isAfter(old.lease!.expiresAt)) {
      throw ArgumentError('Renewal must extend the current lease.');
    }
    final renewed = TaskLease(
      taskId: lease.taskId,
      ownerId: lease.ownerId,
      token: lease.token,
      acquiredAt: old.lease!.acquiredAt,
      expiresAt: expiresAt,
    );
    await _saveTask(tx, {
      ...ConversationTaskRecord.fromDomain(old).values,
      'lease_expires_at': expiresAt.microsecondsSinceEpoch,
      'revision': old.revision + 1,
      'updated_at': now.microsecondsSinceEpoch,
    });
    return TaskWriteCommitted(renewed, revision: old.revision + 1);
  });

  Future<TaskWriteResult<ConversationTask>> releaseLease({
    required TaskLease lease,
    required int expectedRevision,
    required DateTime now,
    DateTime? nextRunAt,
  }) => _write(lease.taskId, (tx) async {
    final old = await _current(tx, lease.taskId, expectedRevision);
    _fence(old, lease, now);
    if (now.isBefore(old.updatedAt) ||
        (nextRunAt != null && nextRunAt.isBefore(now))) {
      throw ArgumentError('Release cannot schedule in the past.');
    }
    final status =
        old.status == ConversationTaskStatus.running
            ? ConversationTaskStatus.paused
            : old.status;
    if (status != old.status) {
      await _event(
        tx,
        ConversationTaskEvent(
          taskId: old.taskId,
          sequence: await _nextSequence(tx, old.taskId),
          kind: TaskEventKind.paused,
          planRevision: old.planRevision,
          occurredAt: now,
          safeSummary: 'Execution segment released.',
        ),
      );
    }
    final saved = await _saveTask(tx, {
      ...ConversationTaskRecord.fromDomain(old).values,
      'status': status.name,
      'lease_owner_id': null,
      'lease_token': null,
      'lease_acquired_at': null,
      'lease_expires_at': null,
      'next_run_at': nextRunAt?.microsecondsSinceEpoch,
      'revision': old.revision + 1,
      'updated_at': now.microsecondsSinceEpoch,
    });
    return TaskWriteCommitted(saved, revision: saved.revision);
  });

  Future<TaskWriteResult<TaskApprovalRecord>> decideApproval({
    required String taskId,
    required String approvalId,
    required int expectedRevision,
    required TaskApprovalDecision decision,
    required String actorId,
    required DateTime decidedAt,
  }) => _write(taskId, (tx) async {
    final old = await _current(tx, taskId, expectedRevision);
    final rows = await tx.query(
      'conversation_task_approvals',
      where: 'task_id = ? AND approval_id = ?',
      whereArgs: [taskId, approvalId],
    );
    if (rows.isEmpty) {
      throw _TaskConflict(TaskWriteConflictReason.notFound, old.revision);
    }
    final approval = TaskApprovalDbRecord(rows.single).toDomain();
    if (approval.decision != null) {
      throw _TaskConflict(
        TaskWriteConflictReason.approvalAlreadyDecided,
        old.revision,
      );
    }
    if (decidedAt.isBefore(old.updatedAt)) {
      throw ArgumentError('Approval decision is stale.');
    }
    final decided = TaskApprovalRecord(
      approvalId: approvalId,
      taskId: taskId,
      requestRevision: approval.requestRevision,
      safeActionSummary: approval.safeActionSummary,
      requestedAt: approval.requestedAt,
      attemptId: approval.attemptId,
      decision: decision,
      decidedBy: actorId,
      decidedAt: decidedAt,
    );
    await tx.update(
      'conversation_task_approvals',
      TaskApprovalDbRecord.fromDomain(decided).values,
      where: 'approval_id = ? AND decision IS NULL',
      whereArgs: [approvalId],
    );
    await _event(
      tx,
      ConversationTaskEvent(
        taskId: taskId,
        sequence: await _nextSequence(tx, taskId),
        planRevision: old.planRevision,
        kind:
            decision == TaskApprovalDecision.approved
                ? TaskEventKind.approvalApproved
                : TaskEventKind.approvalDenied,
        approvalId: approvalId,
        occurredAt: decidedAt,
        reasonCode:
            decision == TaskApprovalDecision.denied
                ? TaskReasonCode.permissionDenied
                : null,
        safeSummary:
            decision == TaskApprovalDecision.approved
                ? 'Action approved.'
                : 'Action denied.',
      ),
    );
    // A decision permits the scheduler to reconsider the task. A denied action
    // remains denied in the ledger; only the runner decides its next safe step.
    final status =
        old.cancelRequestedAt != null
            ? ConversationTaskStatus.cancelRequested
            : ConversationTaskStatus.queued;
    await _saveTask(tx, {
      ...ConversationTaskRecord.fromDomain(old).values,
      'status': status.name,
      'waiting_reason': null,
      'lease_owner_id': null,
      'lease_token': null,
      'lease_acquired_at': null,
      'lease_expires_at': null,
      'next_run_at': decidedAt.microsecondsSinceEpoch,
      'revision': old.revision + 1,
      'updated_at': decidedAt.microsecondsSinceEpoch,
    });
    return TaskWriteCommitted(decided, revision: old.revision + 1);
  }, progress: true);

  Future<TaskWriteResult<ConversationTask>> requestCancellation({
    required String taskId,
    required int expectedRevision,
    required TaskCancellationSource source,
    required DateTime requestedAt,
  }) => _write(taskId, (tx) async {
    final old = await _current(tx, taskId, expectedRevision);
    if (old.cancelRequestedAt != null) {
      return TaskWriteCommitted(old, revision: old.revision, reused: true);
    }
    if (requestedAt.isBefore(old.updatedAt)) {
      throw ArgumentError('Cancellation request is stale.');
    }
    await _event(
      tx,
      ConversationTaskEvent(
        taskId: taskId,
        sequence: await _nextSequence(tx, taskId),
        planRevision: old.planRevision,
        kind: TaskEventKind.cancellationRequested,
        occurredAt: requestedAt,
        safeSummary: 'Cancellation requested.',
        reasonCode: TaskReasonCode.cancelled,
      ),
    );
    final saved = await _saveTask(tx, {
      ...ConversationTaskRecord.fromDomain(old).values,
      'status': ConversationTaskStatus.cancelRequested.name,
      'waiting_reason': null,
      'cancellation_source': source.name,
      'cancel_requested_at': requestedAt.microsecondsSinceEpoch,
      'next_run_at': requestedAt.microsecondsSinceEpoch,
      'revision': old.revision + 1,
      'updated_at': requestedAt.microsecondsSinceEpoch,
    });
    return TaskWriteCommitted(saved, revision: saved.revision);
  }, progress: true);
}
