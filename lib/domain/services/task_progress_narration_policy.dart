import 'dart:convert';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/services/task_safe_data.dart';

final class TaskProgressNarrationPolicy {
  const TaskProgressNarrationPolicy();

  /// No context, raw outputs, arguments, credentials or private reasoning.
  Map<String, Object?> facts(ConversationTaskProgressSummary summary) => {
    'taskId': summary.taskId,
    'summaryRevision': summary.summaryRevision,
    'title': taskSafeText(summary.title, maximum: 200),
    'status': summary.status.name,
    'phase': summary.phase.name,
    'completedSteps': summary.progress.completedSteps,
    'totalSteps': summary.progress.totalSteps,
    'currentStep': taskSafeText(summary.progress.currentStepSummary),
    'latestTool':
        summary.progress.latestTool == null
            ? null
            : {
              'name': taskSafeText(summary.progress.latestTool!.name),
              'status': summary.progress.latestTool!.status.name,
              'summary': taskSafeText(summary.progress.latestTool!.safeSummary),
            },
    'approval':
        summary.progress.pendingApprovalId == null
            ? null
            : {
              'id': summary.progress.pendingApprovalId,
              'summary': taskSafeText(summary.progress.pendingApprovalSummary!),
              'requestedAt':
                  summary.progress.approvalRequestedAt!
                      .toUtc()
                      .toIso8601String(),
            },
    'updatedAt': summary.updatedAt.toUtc().toIso8601String(),
    'waitingReason': summary.waitingReason?.name,
    'reasonCode': taskSafeText(summary.progress.reasonCode),
    'lastMeaningfulProgressAt':
        summary.progress.lastMeaningfulProgressAt.toUtc().toIso8601String(),
    'recoveries': summary.progress.recoveries,
    'verification': summary.progress.verificationStatus.name,
    if (summary.terminalSummary case final terminal?)
      'terminal': {
        'reason': taskSafeText(terminal.safeReason),
        'completedWork': taskSafeText(terminal.completedWorkSummary),
        'sideEffects': terminal.sideEffectStatus.name,
        'canRetry': terminal.canRetry,
        'retainedArtifacts':
            terminal.retainedArtifacts.map(taskSafeText).toList(),
      },
  };

  /// Checks response shape, not a prose template or a claim of factual proof.
  /// Task identity and revisions remain bound to the request in the use case.
  String? validate(String draft) {
    final text = draft.trim();
    if (text.isEmpty || text.length > 12000 || text.startsWith('```')) {
      return null;
    }
    try {
      jsonDecode(text);
      return null;
    } on FormatException {
      return taskSafeText(text, maximum: 12000, structured: true);
    }
  }
}
