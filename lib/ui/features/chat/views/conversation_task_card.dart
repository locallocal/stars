import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
import 'package:stars/domain/services/task_safe_data.dart';
import 'package:stars/utils/theme.dart';
import 'package:stars/ui/features/chat/views/task_action_button.dart';

enum TaskCardAction { status, approve, deny, cancel, resume, retry }

final class ConversationTaskCard extends StatelessWidget {
  const ConversationTaskCard({
    super.key,
    required this.summary,
    this.onAction,
    this.busy = false,
    this.historical = false,
  });
  final ConversationTaskProgressSummary summary;
  final ValueChanged<TaskCardAction>? onAction;
  final bool busy, historical;

  @override
  Widget build(BuildContext context) {
    final w = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final s = summary, p = summary.progress;
    final theme = ShadTheme.maybeOf(context);
    final textStyle =
        theme?.textTheme.small ?? Theme.of(context).textTheme.bodySmall!;
    Widget row(String label, String text) => Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        '$label: $text',
        style: textStyle.copyWith(
          color:
              theme?.colorScheme.mutedForeground ??
              Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
    Widget action(TaskCardAction action, String title) => Semantics(
      label: '$title · ${taskShortId(s.taskId)}',
      button: true,
      child: TaskActionButton(
        label: title,
        onPressed: busy || onAction == null ? null : () => onAction!(action),
      ),
    );
    final content = FocusTraversalGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${taskSafeText(s.title, maximum: 200)} · ${taskShortId(s.taskId)}',
            style: textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          row(w.statusLabel, w.status(s.status)),
          row(w.phaseLabel, w.phase(s.phase)),
          row(w.steps, '${p.completedSteps}/${p.totalSteps}'),
          if (p.currentStepSummary.isNotEmpty)
            row(w.currentStep, taskSafeText(p.currentStepSummary)),
          if (p.latestTool != null)
            row(
              w.latestTool,
              '${taskSafeText(p.latestTool!.name)} · ${w.toolStatus(p.latestTool!.status.name)} · ${taskSafeText(p.latestTool!.safeSummary)}',
            ),
          if (p.pendingApprovalId != null)
            row(
              w.approval,
              '${taskSafeText(p.pendingApprovalSummary!)} · ${p.approvalRequestedAt!.toLocal()}',
            ),
          if (s.waitingReason != null) row(w.waiting, w.wait(s.waitingReason!)),
          if (!historical &&
              {
                TaskWaitingReason.authentication,
                TaskWaitingReason.requiredInput,
              }.contains(s.waitingReason))
            row(w.waiting, w.configurationInput),
          row(w.recoveries, '${p.recoveries}'),
          row(w.verification, w.verified(p.verificationStatus)),
          row(w.updated, '${s.updatedAt.toLocal()}'),
          if (onAction != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                action(TaskCardAction.status, w.viewStatus),
                if (!historical && !s.status.isTerminal) ...[
                  if (s.status != ConversationTaskStatus.cancelRequested)
                    action(TaskCardAction.cancel, w.cancel),
                  if (s.waitingReason == TaskWaitingReason.approval &&
                      p.pendingApprovalId != null) ...[
                    action(TaskCardAction.approve, w.approve),
                    action(TaskCardAction.deny, w.deny),
                  ],
                  if (s.status == ConversationTaskStatus.waitingForUser &&
                      s.waitingReason != TaskWaitingReason.approval)
                    action(TaskCardAction.resume, w.resume),
                ],
                if (!historical &&
                    s.status.isTerminal &&
                    s.terminalSummary?.canRetry == true &&
                    s.terminalSummary?.sideEffectStatus ==
                        TaskSideEffectStatus.none)
                  action(TaskCardAction.retry, w.retry),
              ],
            ),
          ],
        ],
      ),
    );
    return Semantics(
      container: true,
      liveRegion: !historical,
      label:
          '${w.tasks}: ${taskSafeText(s.title)} · ${taskShortId(s.taskId)} · ${w.status(s.status)}',
      child:
          theme == null
              ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: content,
              )
              : ShadCard(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                radius: StarsDesktopThemeSpec.statusRadius,
                child: content,
              ),
    );
  }
}
