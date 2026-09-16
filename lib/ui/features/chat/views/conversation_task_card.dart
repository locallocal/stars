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
    this.onRefresh,
    this.busy = false,
    this.refreshing = false,
    this.historical = false,
    this.showStatusAction = true,
    this.expansionController,
  });
  final ConversationTaskProgressSummary summary;
  final ValueChanged<TaskCardAction>? onAction;
  final VoidCallback? onRefresh;
  final bool busy, historical;
  final bool refreshing;
  final bool showStatusAction;

  /// The task list owns expansion across pagination and live updates.
  final ShadAccordionController<String>? expansionController;

  @override
  Widget build(BuildContext context) {
    final w = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final s = summary, p = summary.progress;
    final theme = ShadTheme.maybeOf(context);
    final collapsible = expansionController != null && theme != null;
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
          if (!collapsible) ...[
            Text(
              '${taskSafeText(s.title, maximum: 200)} · ${taskShortId(s.taskId)}',
              style: textStyle.copyWith(fontWeight: FontWeight.w600),
            ),
            row(w.statusLabel, w.status(s.status)),
            row(w.steps, '${p.completedSteps}/${p.totalSteps}'),
          ],
          row(w.phaseLabel, w.phase(s.phase)),
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
              '${taskSafeText(p.pendingApprovalSummary!, maximum: TaskProgress.maximumApprovalSummaryLength)} · ${p.approvalRequestedAt!.toLocal()}',
            ),
          if (s.waitingReason != null)
            row(
              w.waiting,
              w.waitingDescription(s.waitingReason!, p.reasonCode),
            ),
          row(w.recoveries, '${p.recoveries}'),
          row(w.verification, w.verified(p.verificationStatus)),
          if (!historical && !collapsible)
            row(
              w.created,
              DateFormat.yMd().add_Hm().format(s.createdAt.toLocal()),
            ),
          row(
            w.updated,
            DateFormat.yMd().add_Hm().format(s.updatedAt.toLocal()),
          ),
          if (onAction != null ||
              (!historical && !s.status.isTerminal && onRefresh != null)) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (showStatusAction)
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
                if (!historical && !s.status.isTerminal && onRefresh != null)
                  Semantics(
                    label: '${w.refresh} · ${taskShortId(s.taskId)}',
                    button: true,
                    child: TaskActionButton(
                      key: ValueKey('task-refresh-${s.taskId}'),
                      label: w.refresh,
                      onPressed: busy || refreshing ? null : onRefresh,
                    ),
                  ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: collapsible ? 0 : 12,
                ),
                radius: StarsDesktopThemeSpec.statusRadius,
                child:
                    collapsible
                        ? ShadAccordion<String>.multiple(
                          controller: expansionController,
                          children: [
                            ShadAccordionItem<String>(
                              key: ValueKey('task-toggle-${s.taskId}'),
                              value: s.taskId,
                              separator: const SizedBox.shrink(),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              underlineTitleOnHover: false,
                              duration:
                                  MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 180),
                              title: ListenableBuilder(
                                listenable: expansionController!,
                                builder:
                                    (context, child) => Semantics(
                                      key: ValueKey('task-heading-${s.taskId}'),
                                      button: true,
                                      expanded: expansionController!.value
                                          .contains(s.taskId),
                                      onTap:
                                          () => expansionController!.toggle(
                                            s.taskId,
                                          ),
                                      child: child,
                                    ),
                                child: _TaskSummaryHeader(summary: s, words: w),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: content,
                              ),
                            ),
                          ],
                        )
                        : content,
              ),
    );
  }
}

final class _TaskSummaryHeader extends StatelessWidget {
  const _TaskSummaryHeader({required this.summary, required this.words});

  final ConversationTaskProgressSummary summary;
  final TaskProgressStrings words;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${taskSafeText(summary.title, maximum: 200)} · ${taskShortId(summary.taskId)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _TaskStatusBadge(
                status: summary.status,
                label: words.status(summary.status),
              ),
              Text(
                '${words.steps}: ${summary.progress.completedSteps}/${summary.progress.totalSteps}',
                style: theme.textTheme.muted,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${words.created}: ${DateFormat.yMd().add_Hm().format(summary.createdAt.toLocal())}',
            style: theme.textTheme.muted,
          ),
        ],
      ),
    );
  }
}

final class _TaskStatusBadge extends StatelessWidget {
  const _TaskStatusBadge({required this.status, required this.label});

  final ConversationTaskStatus status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // Semantic shades stay readable on tinted surfaces in both theme modes.
    final (lightForeground, darkForeground) = switch (status) {
      ConversationTaskStatus.queued => (
        const Color(0xFF334155),
        const Color(0xFFCBD5E1),
      ),
      ConversationTaskStatus.running => (
        const Color(0xFF1D4ED8),
        const Color(0xFF93C5FD),
      ),
      ConversationTaskStatus.waitingForUser => (
        const Color(0xFF92400E),
        const Color(0xFFFCD34D),
      ),
      ConversationTaskStatus.paused => (
        const Color(0xFF6D28D9),
        const Color(0xFFC4B5FD),
      ),
      ConversationTaskStatus.cancelRequested => (
        const Color(0xFF9A3412),
        const Color(0xFFFDBA74),
      ),
      ConversationTaskStatus.succeeded => (
        const Color(0xFF166534),
        const Color(0xFF86EFAC),
      ),
      ConversationTaskStatus.failed => (
        const Color(0xFFB91C1C),
        const Color(0xFFFCA5A5),
      ),
      ConversationTaskStatus.cancelled => (
        colors.secondaryForeground,
        colors.secondaryForeground,
      ),
    };
    final foreground = isDark ? darkForeground : lightForeground;
    final background =
        status == ConversationTaskStatus.cancelled
            ? colors.secondary
            : Color.alphaBlend(
              foreground.withValues(alpha: isDark ? 0.16 : 0.10),
              colors.card,
            );
    return ShadBadge.secondary(
      key: ValueKey('task-status-${status.name}'),
      backgroundColor: background,
      hoverBackgroundColor: background,
      foregroundColor: foreground,
      child: Text(label),
    );
  }
}
