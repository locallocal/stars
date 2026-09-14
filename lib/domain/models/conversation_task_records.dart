part of 'conversation_task.dart';

final class ConversationTaskEvent {
  ConversationTaskEvent({
    required this.taskId,
    required this.sequence,
    required this.kind,
    required this.occurredAt,
    required this.safeSummary,
    this.segmentId,
    this.stepId,
    this.attemptId,
    this.approvalId,
    this.evidenceId,
    this.reasonCode,
  }) {
    _taskText(taskId, 'taskId', maximum: 256);
    _taskCount(sequence, 'sequence', minimum: 1);
    _taskText(safeSummary, 'event summary', maximum: 2000);
    for (final value in [
      segmentId,
      stepId,
      attemptId,
      approvalId,
      evidenceId,
      reasonCode,
    ]) {
      if (value != null) _taskText(value, 'event reference', maximum: 256);
    }
  }

  final String taskId;
  final int sequence;
  final TaskEventKind kind;
  final DateTime occurredAt;
  final String safeSummary;
  final String? segmentId;
  final String? stepId;
  final String? attemptId;
  final String? approvalId;
  final String? evidenceId;
  final String? reasonCode;
}

final class TaskApprovalRecord {
  TaskApprovalRecord({
    required this.approvalId,
    required this.taskId,
    required this.requestRevision,
    required this.safeActionSummary,
    required this.requestedAt,
    this.attemptId,
    this.decision,
    this.decidedBy,
    this.decidedAt,
  }) {
    _taskText(approvalId, 'approvalId', maximum: 256);
    _taskText(taskId, 'taskId', maximum: 256);
    _taskText(safeActionSummary, 'approval summary', maximum: 2000);
    _taskCount(requestRevision, 'requestRevision');
    if (attemptId != null) _taskText(attemptId!, 'attemptId', maximum: 256);
    if ((decision != null) != (decidedBy != null) ||
        (decision != null) != (decidedAt != null)) {
      throw ArgumentError('Approval decisions require an actor and timestamp.');
    }
    if (decidedBy != null) _taskText(decidedBy!, 'decidedBy', maximum: 256);
    if (decidedAt != null && decidedAt!.isBefore(requestedAt)) {
      throw ArgumentError('Approval cannot precede its request.');
    }
  }

  final String approvalId;
  final String taskId;
  final int requestRevision;
  final String safeActionSummary;
  final DateTime requestedAt;
  final String? attemptId;
  final TaskApprovalDecision? decision;
  final String? decidedBy;
  final DateTime? decidedAt;
}

/// Immutable ownership of an existing execution record by one task/segment.
final class TaskToolAttemptLink {
  TaskToolAttemptLink({
    required this.taskId,
    required this.segmentId,
    required this.attemptId,
    required this.idempotencyKey,
    required this.attemptNumber,
  }) {
    for (final value in [taskId, segmentId, attemptId, idempotencyKey]) {
      _taskText(value, 'attempt identity', maximum: 256);
    }
    _taskCount(attemptNumber, 'attemptNumber', minimum: 1);
  }

  final String taskId;
  final String segmentId;
  final String attemptId;

  /// Stable across retries; the attempt number identifies each audit attempt.
  final String idempotencyKey;
  final int attemptNumber;
}

final class TaskEvidenceLink {
  TaskEvidenceLink({
    required this.taskId,
    required this.segmentId,
    required this.attemptId,
    required this.evidenceId,
  }) {
    for (final value in [taskId, segmentId, attemptId, evidenceId]) {
      _taskText(value, 'evidence identity', maximum: 256);
    }
    if (evidenceId != ToolEvidenceRecord.evidenceIdForAttempt(attemptId)) {
      throw ArgumentError('Evidence must belong to the linked attempt.');
    }
  }

  final String taskId;
  final String segmentId;
  final String attemptId;
  final String evidenceId;
}

/// An opaque, revocable local handle; never serialize an external credential.
final class TaskExternalJob {
  TaskExternalJob({
    required this.attemptId,
    required this.externalJobId,
    required this.resumeHandle,
    required this.safeStatus,
    required this.nextPollAt,
  }) {
    for (final value in [attemptId, externalJobId, safeStatus]) {
      _taskText(value, 'external job metadata', maximum: 256);
    }
    if (!RegExp(r'^handle:[a-zA-Z0-9_-]{1,128}$').hasMatch(resumeHandle)) {
      throw ArgumentError(
        'External jobs require an opaque local resume handle.',
      );
    }
  }

  final String attemptId;
  final String externalJobId;
  final String resumeHandle;
  final String safeStatus;
  final DateTime nextPollAt;
}
