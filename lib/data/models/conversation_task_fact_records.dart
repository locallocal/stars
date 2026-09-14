part of 'conversation_task_record.dart';

final class ConversationTaskEventRecord {
  ConversationTaskEventRecord(Map<String, Object?> values)
    : values = Map.unmodifiable(values);
  factory ConversationTaskEventRecord.fromDomain(ConversationTaskEvent value) =>
      ConversationTaskEventRecord({
        'task_id': value.taskId,
        'sequence': value.sequence,
        'kind': value.kind.name,
        'occurred_at': value.occurredAt.microsecondsSinceEpoch,
        'safe_summary': value.safeSummary,
        'segment_id': value.segmentId,
        'step_id': value.stepId,
        'attempt_id': value.attemptId,
        'approval_id': value.approvalId,
        'evidence_id': value.evidenceId,
        'reason_code': value.reasonCode,
      });
  final Map<String, Object?> values;
  ConversationTaskEvent toDomain() {
    final row = _TaskRow(values);
    return ConversationTaskEvent(
      taskId: row.text('task_id'),
      sequence: row.integer('sequence'),
      kind: row.enumeration('kind', TaskEventKind.values),
      occurredAt: row.time('occurred_at'),
      safeSummary: row.text('safe_summary'),
      segmentId: row.optionalText('segment_id'),
      stepId: row.optionalText('step_id'),
      attemptId: row.optionalText('attempt_id'),
      approvalId: row.optionalText('approval_id'),
      evidenceId: row.optionalText('evidence_id'),
      reasonCode: row.optionalText('reason_code'),
    );
  }
}

final class TaskApprovalDbRecord {
  TaskApprovalDbRecord(Map<String, Object?> values)
    : values = Map.unmodifiable(values);
  factory TaskApprovalDbRecord.fromDomain(TaskApprovalRecord value) =>
      TaskApprovalDbRecord({
        'approval_id': value.approvalId,
        'task_id': value.taskId,
        'request_revision': value.requestRevision,
        'attempt_id': value.attemptId,
        'safe_action_summary': value.safeActionSummary,
        'requested_at': value.requestedAt.microsecondsSinceEpoch,
        'decision': value.decision?.name,
        'decided_by': value.decidedBy,
        'decided_at': value.decidedAt?.microsecondsSinceEpoch,
      });
  final Map<String, Object?> values;
  TaskApprovalRecord toDomain() {
    final row = _TaskRow(values);
    return TaskApprovalRecord(
      approvalId: row.text('approval_id'),
      taskId: row.text('task_id'),
      requestRevision: row.integer('request_revision'),
      attemptId: row.optionalText('attempt_id'),
      safeActionSummary: row.text('safe_action_summary'),
      requestedAt: row.time('requested_at'),
      decision: row.optionalEnum('decision', TaskApprovalDecision.values),
      decidedBy: row.optionalText('decided_by'),
      decidedAt: row.optionalTime('decided_at'),
    );
  }
}

final class TaskToolAttemptLinkRecord {
  TaskToolAttemptLinkRecord(Map<String, Object?> values)
    : values = Map.unmodifiable(values);
  factory TaskToolAttemptLinkRecord.fromDomain(TaskToolAttemptLink value) =>
      TaskToolAttemptLinkRecord({
        'task_id': value.taskId,
        'segment_id': value.segmentId,
        'attempt_id': value.attemptId,
        'idempotency_key': value.idempotencyKey,
        'attempt_number': value.attemptNumber,
      });
  final Map<String, Object?> values;
  TaskToolAttemptLink toDomain() {
    final row = _TaskRow(values);
    return TaskToolAttemptLink(
      taskId: row.text('task_id'),
      segmentId: row.text('segment_id'),
      attemptId: row.text('attempt_id'),
      idempotencyKey: row.text('idempotency_key'),
      attemptNumber: row.integer('attempt_number'),
    );
  }
}

final class TaskEvidenceLinkRecord {
  TaskEvidenceLinkRecord(Map<String, Object?> values)
    : values = Map.unmodifiable(values);
  factory TaskEvidenceLinkRecord.fromDomain(TaskEvidenceLink value) =>
      TaskEvidenceLinkRecord({
        'task_id': value.taskId,
        'segment_id': value.segmentId,
        'attempt_id': value.attemptId,
        'evidence_id': value.evidenceId,
      });
  final Map<String, Object?> values;
  TaskEvidenceLink toDomain() {
    final row = _TaskRow(values);
    return TaskEvidenceLink(
      taskId: row.text('task_id'),
      segmentId: row.text('segment_id'),
      attemptId: row.text('attempt_id'),
      evidenceId: row.text('evidence_id'),
    );
  }
}
