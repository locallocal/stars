part of 'conversation_task_store.dart';

extension ConversationTaskStoreExecution on ConversationTaskStore {
  Future<TaskExecutionSnapshot?> getExecutionSnapshot(String taskId) => _read((
    tx,
  ) async {
    final task = await _task(tx, taskId);
    if (task == null) return null;
    final plans = await tx.query(
      'conversation_task_plans',
      where: 'task_id = ? AND plan_revision = ?',
      whereArgs: [taskId, task.planRevision],
    );
    final checkpoints = await tx.query(
      'conversation_task_checkpoints',
      where: 'task_id = ? AND plan_revision = ?',
      whereArgs: [taskId, task.planRevision],
    );
    final links = await tx.query(
      'conversation_task_tool_attempts',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
    final attempts = await tx.rawQuery(
      'SELECT execution.* FROM conversation_task_tool_attempts link '
      'JOIN tool_execution_records execution ON execution.attempt_id = link.attempt_id '
      'WHERE link.task_id = ? ORDER BY execution.started_at, execution.attempt_id',
      [taskId],
    );
    final approvals = await tx.query(
      'conversation_task_approvals',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'requested_at, approval_id',
    );
    final evidence = await tx.rawQuery(
      'SELECT evidence.* FROM conversation_task_evidence_links link '
      'JOIN tool_evidence_records evidence ON evidence.evidence_id = link.evidence_id '
      'WHERE link.task_id = ? ORDER BY evidence.observed_at, evidence.evidence_id',
      [taskId],
    );
    return TaskExecutionSnapshot(
      task: task,
      plan: ConversationTaskPlanRecord(plans.single).toDomain(),
      checkpoint:
          checkpoints.isEmpty
              ? null
              : ConversationTaskCheckpointRecord(checkpoints.single).toDomain(),
      lastSequence: await _nextSequence(tx, taskId) - 1,
      events:
          (await tx.query(
            'conversation_task_events',
            where: 'task_id = ?',
            whereArgs: [taskId],
            orderBy: 'sequence',
          )).map((row) => ConversationTaskEventRecord(row).toDomain()).toList(),
      attempts:
          attempts.map((row) => ToolExecutionDbRecord(row).toDomain()).toList(),
      attemptLinks:
          links
              .map((row) => TaskToolAttemptLinkRecord(row).toDomain())
              .toList(),
      approvals:
          approvals.map((row) => TaskApprovalDbRecord(row).toDomain()).toList(),
      evidence:
          evidence
              .map(_readTaskEvidence)
              .whereType<ToolEvidenceRecord>()
              .toList(),
    );
  });
}

ToolEvidenceRecord? _readTaskEvidence(Map<String, Object?> row) {
  try {
    return ToolEvidenceDbRecord(row).toDomain();
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}
