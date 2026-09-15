import 'dart:convert';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
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
    'recoveries': summary.progress.recoveries,
    'verification': summary.progress.verificationStatus.name,
  };

  List<String> alternatives(
    ConversationTaskProgressSummary s,
    String language,
  ) {
    final w = TaskProgressStrings(language);
    final p = s.progress;
    final blocks = [
      '${taskSafeText(s.title, maximum: 200)} · ${taskShortId(s.taskId)}',
      '${w.statusLabel}: ${w.status(s.status)}',
      '${w.phaseLabel}: ${w.phase(s.phase)}',
      '${w.steps}: ${p.completedSteps}/${p.totalSteps}',
      if (p.currentStepSummary.isNotEmpty)
        '${w.currentStep}: ${taskSafeText(p.currentStepSummary)}',
      if (p.latestTool != null)
        '${w.latestTool}: ${taskSafeText(p.latestTool!.name)} · ${w.toolStatus(p.latestTool!.status.name)} · ${taskSafeText(p.latestTool!.safeSummary)}',
      if (p.pendingApprovalId != null)
        '${w.approval}: ${taskSafeText(p.pendingApprovalSummary!)} · ${p.approvalRequestedAt!.toUtc().toIso8601String()}',
      if (s.waitingReason != null) '${w.waiting}: ${w.wait(s.waitingReason!)}',
      '${w.recoveries}: ${p.recoveries}',
      '${w.verification}: ${w.verified(p.verificationStatus)}',
      '${w.updated}: ${s.updatedAt.toUtc().toIso8601String()}',
    ];
    return [blocks.join('\n'), blocks.join('\n\n')];
  }

  String? validate(
    String draft,
    ConversationTaskProgressSummary summary,
    String language,
  ) {
    try {
      final value = jsonDecode(draft);
      if (value is! Map<String, Object?> ||
          value.length != 3 ||
          value['taskId'] != summary.taskId ||
          value['summaryRevision'] != summary.summaryRevision ||
          value['content'] is! String) {
        return null;
      }
      final text = (value['content']! as String).trim();
      // Whole-text grammar validation protects numerical, tool, approval and
      // terminal facts; a keyword blacklist cannot provide this guarantee.
      return alternatives(summary, language).contains(text) ? text : null;
    } on Object {
      return null;
    }
  }
}
