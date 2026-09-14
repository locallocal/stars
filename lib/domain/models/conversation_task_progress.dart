part of 'conversation_task.dart';

final class TaskToolProgress {
  TaskToolProgress({
    required this.attemptId,
    required this.name,
    required this.status,
    required this.safeSummary,
  }) {
    _taskText(attemptId, 'attemptId', maximum: 256);
    _taskText(name, 'tool name', maximum: 256);
    _taskText(safeSummary, 'tool summary', maximum: 2000);
  }

  final String attemptId;
  final String name;
  final ToolInvocationStatus status;
  final String safeSummary;
}

final class TaskProgress {
  TaskProgress({
    this.completedSteps = 0,
    required this.totalSteps,
    this.currentStepSummary = '',
    required this.lastMeaningfulProgressAt,
    this.modelTurns = 0,
    this.toolAttempts = 0,
    this.recoveries = 0,
    this.segments = 0,
    this.noProgressSegments = 0,
    this.summaryHash = '',
    this.latestTool,
    this.pendingApprovalId,
    this.pendingApprovalSummary,
    this.approvalRequestedAt,
    this.reasonCode = '',
    this.verificationStatus = TaskVerificationStatus.notStarted,
  }) {
    for (final entry
        in <String, int>{
          'completedSteps': completedSteps,
          'totalSteps': totalSteps,
          'modelTurns': modelTurns,
          'toolAttempts': toolAttempts,
          'recoveries': recoveries,
          'segments': segments,
          'noProgressSegments': noProgressSegments,
        }.entries) {
      _taskCount(entry.value, entry.key);
    }
    if (completedSteps > totalSteps || currentStepSummary.length > 2000) {
      throw ArgumentError('Invalid task step progress.');
    }
    if (summaryHash.isNotEmpty &&
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(summaryHash)) {
      throw ArgumentError('Progress hash must be a SHA-256 digest.');
    }
    final hasApproval = pendingApprovalId != null;
    if (hasApproval != (pendingApprovalSummary != null) ||
        hasApproval != (approvalRequestedAt != null)) {
      throw ArgumentError(
        'Approval progress must include identity, summary and time.',
      );
    }
    if (hasApproval) {
      _taskText(pendingApprovalId!, 'approvalId', maximum: 256);
      _taskText(pendingApprovalSummary!, 'approval summary', maximum: 2000);
    }
    if (reasonCode.isNotEmpty) {
      _taskText(reasonCode, 'reasonCode', maximum: 128);
    }
  }

  final int completedSteps;
  final int totalSteps;
  final String currentStepSummary;
  final DateTime lastMeaningfulProgressAt;
  final int modelTurns;
  final int toolAttempts;
  final int recoveries;
  final int segments;
  final int noProgressSegments;
  final String summaryHash;
  final TaskToolProgress? latestTool;
  final String? pendingApprovalId;
  final String? pendingApprovalSummary;
  final DateTime? approvalRequestedAt;
  final String reasonCode;
  final TaskVerificationStatus verificationStatus;
}

final class TaskTerminalSummary {
  TaskTerminalSummary({
    required this.status,
    required this.reasonCode,
    required this.safeReason,
    required this.completedWorkSummary,
    List<String> retainedArtifacts = const [],
    required this.sideEffectStatus,
    required this.canRetry,
    List<String> suggestedNextActions = const [],
    this.cancellationSource,
  }) : retainedArtifacts = _taskStrings(retainedArtifacts, 'retainedArtifacts'),
       suggestedNextActions = _taskStrings(
         suggestedNextActions,
         'nextActions',
       ) {
    if (status != ConversationTaskStatus.failed &&
        status != ConversationTaskStatus.cancelled) {
      throw ArgumentError(
        'Terminal summaries describe failure or cancellation.',
      );
    }
    _taskText(reasonCode, 'reasonCode', maximum: 128);
    _taskText(safeReason, 'safeReason', maximum: 2000);
    if (completedWorkSummary.length > 4000) {
      throw ArgumentError('Terminal summary is too large.');
    }
    if (status == ConversationTaskStatus.cancelled &&
        (cancellationSource == null ||
            sideEffectStatus == TaskSideEffectStatus.unknown)) {
      throw ArgumentError(
        'Cancellation requires a source and known side effects.',
      );
    }
  }

  final ConversationTaskStatus status;
  final String reasonCode;
  final String safeReason;
  final String completedWorkSummary;
  final List<String> retainedArtifacts;
  final TaskSideEffectStatus sideEffectStatus;
  final bool canRetry;
  final List<String> suggestedNextActions;
  final TaskCancellationSource? cancellationSource;
}

/// Safe, revision-bound query output; never includes the acceptance context.
final class ConversationTaskProgressSummary {
  ConversationTaskProgressSummary({
    required this.taskId,
    required this.chatId,
    required this.title,
    required this.status,
    required this.phase,
    required this.planRevision,
    required this.summaryRevision,
    required this.progress,
    required this.updatedAt,
    this.waitingReason,
    this.terminalSummary,
  }) {
    _taskText(taskId, 'taskId', maximum: 256);
    _taskText(chatId, 'chatId', maximum: 256);
    _taskText(title, 'title', maximum: 200);
    _taskCount(planRevision, 'planRevision', minimum: 1);
    _taskCount(summaryRevision, 'summaryRevision');
  }

  final String taskId;
  final String chatId;
  final String title;
  final ConversationTaskStatus status;
  final ConversationTaskPhase phase;
  final int planRevision;
  final int summaryRevision;
  final TaskProgress progress;
  final DateTime updatedAt;
  final TaskWaitingReason? waitingReason;
  final TaskTerminalSummary? terminalSummary;
}
