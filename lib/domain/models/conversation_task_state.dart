part of 'conversation_task.dart';

enum ConversationTaskStatus {
  queued,
  running,
  waitingForUser,
  paused,
  cancelRequested,
  succeeded,
  failed,
  cancelled;

  bool get isTerminal =>
      this == succeeded || this == failed || this == cancelled;

  bool canTransitionTo(ConversationTaskStatus next) {
    if (isTerminal || next == this) return false;
    if (next == cancelRequested || next == failed) return true;
    return switch (this) {
      queued => {running, paused, waitingForUser}.contains(next),
      running => {queued, waitingForUser, paused, succeeded}.contains(next),
      waitingForUser => {queued, running, paused}.contains(next),
      paused => {queued, running, waitingForUser}.contains(next),
      cancelRequested => {paused, waitingForUser, cancelled}.contains(next),
      succeeded || failed || cancelled => false,
    };
  }
}

enum ConversationTaskPhase {
  planning,
  executing,
  observing,
  verifying,
  synthesizing,
  committing,
}

enum TaskWaitingReason {
  approval,
  authentication,
  requiredInput,
  reconciliation,
}

enum TaskCancellationSource { user, conversationDeletion, botDeletion }

enum TaskSideEffectStatus { none, unknown, reconciled, irreversible }

enum TaskVerificationStatus { notStarted, verifying, verified, partial, failed }

enum TaskPlanStepStatus { pending, running, completed, skipped }

enum TaskApprovalDecision { approved, denied }

enum TaskContextRole { system, user, assistant, tool }

enum TaskEventKind {
  queued,
  started,
  paused,
  resumed,
  cancellationRequested,
  terminal,
  planCreated,
  planRevised,
  stepStarted,
  stepCompleted,
  toolQueued,
  toolStarted,
  toolSucceeded,
  toolFailed,
  toolRetry,
  externalJobUpdated,
  approvalRequested,
  waitingForUser,
  approvalApproved,
  approvalDenied,
  verificationStarted,
  evidenceAccepted,
  evidenceRejected,
  verificationCompleted,
  resultCommitting,
  leaseExpired,
  processRecovered,
  retryScheduled,
  noProgress,
  modelTurnCompleted,
  segmentCheckpoint,
  segmentProgress,
}

abstract final class TaskReasonCode {
  static const noProgress = 'task_no_progress';
  static const invalidPlan = 'task_invalid_plan';
  static const permissionDenied = 'task_permission_denied';
  static const missingCredentials = 'task_missing_credentials';
  static const providerUnavailable = 'task_provider_unavailable';
  static const botUnavailable = 'task_bot_unavailable';
  static const reconciliationRequired = 'task_reconciliation_required';
  static const verificationFailed = 'task_verification_failed';
  static const cancelled = 'task_cancelled';
}

final class TaskLease {
  TaskLease({
    required this.taskId,
    required this.ownerId,
    required this.token,
    required this.acquiredAt,
    required this.expiresAt,
  }) {
    for (final value in [taskId, ownerId, token]) {
      _taskText(value, 'lease identity', maximum: 256);
    }
    if (!expiresAt.isAfter(acquiredAt)) {
      throw ArgumentError('Lease expiration must follow acquisition.');
    }
  }

  final String taskId;
  final String ownerId;

  /// A fencing token generated for each acquisition, never a credential.
  final String token;
  final DateTime acquiredAt;
  final DateTime expiresAt;

  bool isValidAt(DateTime now) =>
      !now.isBefore(acquiredAt) && now.isBefore(expiresAt);
}
