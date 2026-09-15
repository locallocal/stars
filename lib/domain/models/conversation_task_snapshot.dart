part of 'conversation_task.dart';

final class VerificationPolicySnapshot {
  VerificationPolicySnapshot({
    required this.reliabilityEnabled,
    required this.strictGroundingEnabled,
    required this.showVerificationStatus,
    this.policyVersion = 1,
  }) {
    _taskCount(policyVersion, 'policyVersion', minimum: 1);
  }

  final bool reliabilityEnabled;
  final bool strictGroundingEnabled;
  final bool showVerificationStatus;
  final int policyVersion;
}

/// Prepared, sanitized context only: no Provider configuration or reasoning.
final class TaskContextMessage {
  TaskContextMessage({
    required this.role,
    required this.content,
    List<String> assetReferences = const [],
  }) : assetReferences = _taskStrings(assetReferences, 'assetReferences') {
    if (content.length > 128000) {
      throw ArgumentError('Task context is too large.');
    }
  }

  final TaskContextRole role;
  final String content;
  final List<String> assetReferences;
}

final class TaskAcceptanceSnapshot {
  TaskAcceptanceSnapshot({
    required this.providerId,
    required this.modelId,
    required this.configurationDigest,
    required this.language,
    required List<TaskContextMessage> context,
    required Set<String> allowedToolNames,
    required this.verification,
    required this.segmentLimits,
  }) : context = List.unmodifiable(context),
       allowedToolNames = Set.unmodifiable(
         _taskStrings(allowedToolNames, 'tools'),
       ) {
    for (final value in [providerId, modelId, configurationDigest, language]) {
      _taskText(value, 'acceptance metadata', maximum: 256);
    }
    if (context.isEmpty || context.length > 1024) {
      throw ArgumentError('Task acceptance requires bounded prepared context.');
    }
  }

  final String providerId;
  final String modelId;
  final String configurationDigest;
  final String language;
  final List<TaskContextMessage> context;
  final Set<String> allowedToolNames;
  final VerificationPolicySnapshot verification;
  final TaskSegmentLimits segmentLimits;
}

final class TaskPlanStep {
  TaskPlanStep({
    required this.stepId,
    required this.summary,
    this.status = TaskPlanStepStatus.pending,
  }) {
    _taskText(stepId, 'stepId', maximum: 256);
    _taskText(summary, 'step summary', maximum: 2000);
  }

  final String stepId;
  final String summary;
  final TaskPlanStepStatus status;
}

final class ConversationTaskPlan {
  ConversationTaskPlan({
    required this.taskId,
    required this.revision,
    required this.objective,
    required List<TaskPlanStep> steps,
    required Set<String> allowedToolNames,
    required this.createdAt,
  }) : steps = List.unmodifiable(steps),
       allowedToolNames = Set.unmodifiable(
         _taskStrings(allowedToolNames, 'tools'),
       ) {
    _taskText(taskId, 'taskId', maximum: 256);
    _taskText(objective, 'objective');
    _taskCount(revision, 'planRevision', minimum: 1);
    if (steps.isEmpty ||
        steps.map((step) => step.stepId).toSet().length != steps.length) {
      throw ArgumentError('Plans require distinct steps.');
    }
  }

  final String taskId;
  final int revision;
  final String objective;
  final List<TaskPlanStep> steps;
  final Set<String> allowedToolNames;
  final DateTime createdAt;
}

final class ConversationTaskCheckpoint {
  ConversationTaskCheckpoint({
    required this.taskId,
    required this.segmentId,
    required this.planRevision,
    required this.sequence,
    required this.phase,
    required this.savedAt,
    this.nextStepId,
    this.evidenceCursor = 0,
    List<String> completedStepIds = const [],
    List<String> pendingAttemptIds = const [],
    List<TaskContextMessage> context = const [],
    List<TaskExternalJob> externalJobs = const [],
    this.execution,
  }) : completedStepIds = _taskStrings(completedStepIds, 'completedStepIds'),
       pendingAttemptIds = _taskStrings(pendingAttemptIds, 'pendingAttemptIds'),
       context = List.unmodifiable(context),
       externalJobs = List.unmodifiable(externalJobs) {
    _taskText(taskId, 'taskId', maximum: 256);
    _taskText(segmentId, 'segmentId', maximum: 256);
    if (nextStepId != null) _taskText(nextStepId!, 'nextStepId', maximum: 256);
    _taskCount(planRevision, 'planRevision', minimum: 1);
    _taskCount(sequence, 'sequence', minimum: 1);
    _taskCount(evidenceCursor, 'evidenceCursor');
  }

  final String taskId;
  final String segmentId;
  final int planRevision;
  final int sequence;
  final ConversationTaskPhase phase;
  final String? nextStepId;
  final int evidenceCursor;
  final List<String> completedStepIds;
  final List<String> pendingAttemptIds;
  final List<TaskContextMessage> context;
  final List<TaskExternalJob> externalJobs;
  final DateTime savedAt;
  final TaskExecutionState? execution;
}
