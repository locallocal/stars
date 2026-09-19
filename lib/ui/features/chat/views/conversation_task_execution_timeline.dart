import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/conversation_task_execution.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
import 'package:stars/ui/features/chat/view_models/task_execution_presentation.dart';
import 'package:stars/ui/features/chat/views/conversation_task_execution_status.dart';
import 'package:stars/ui/features/chat/views/execution_status_card.dart';
import 'package:stars/ui/features/chat/views/task_status_colors.dart';

final class ConversationTaskExecutionTimeline extends StatefulWidget {
  const ConversationTaskExecutionTimeline({
    super.key,
    required this.presentation,
  });
  final TaskExecutionPresentation presentation;

  @override
  State<ConversationTaskExecutionTimeline> createState() =>
      _ConversationTaskExecutionTimelineState();
}

final class _ConversationTaskExecutionTimelineState
    extends State<ConversationTaskExecutionTimeline> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.textTheme.muted.copyWith(
      color: theme.colorScheme.mutedForeground,
      fontWeight: FontWeight.w400,
    );
    final words = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final data = widget.presentation;
    final activities = _showAll ? data.activities : data.milestones;
    return ExecutionDetailsDisclosure(
      id: 'execution-timeline',
      title: words.executionTimeline,
      header: TaskExecutionSectionHeading(
        title: words.executionTimeline,
        count: words.executionEvents(data.activities.length),
      ),
      subtitle: words.executionNewestFirst,
      child: Column(
        key: const ValueKey('task-execution-timeline'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final (showAll, label) in [
                  (false, words.executionMilestones),
                  (true, words.executionAllEvents),
                ])
                  Semantics(
                    selected: _showAll == showAll,
                    child: ShadButton.raw(
                      key: ValueKey(
                        showAll ? 'task-events-all' : 'task-events-key',
                      ),
                      variant:
                          _showAll == showAll
                              ? ShadButtonVariant.secondary
                              : ShadButtonVariant.ghost,
                      size: ShadButtonSize.sm,
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      onPressed: () => setState(() => _showAll = showAll),
                      child: Text(label),
                    ),
                  ),
              ],
            ),
          ),
          if (activities.isEmpty)
            Text(words.executionNoMilestones, style: muted),
          for (var index = 0; index < activities.length; index++) ...[
            if (index == 0 ||
                !_sameDay(activities[index - 1], activities[index]))
              Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 8, bottom: 12),
                child: Text(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).toString(),
                  ).format(activities[index].event.occurredAt.toLocal()),
                  style: muted,
                ),
              ),
            _TaskActivityRow(
              key: ValueKey('task-event-${activities[index].event.sequence}'),
              activity: activities[index],
              connected:
                  index + 1 < activities.length &&
                  _sameDay(activities[index], activities[index + 1]),
            ),
          ],
        ],
      ),
    );
  }
}

bool _sameDay(TaskExecutionActivity a, TaskExecutionActivity b) {
  final first = a.event.occurredAt.toLocal(),
      second = b.event.occurredAt.toLocal();
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

final class _TaskActivityRow extends StatelessWidget {
  const _TaskActivityRow({
    super.key,
    required this.activity,
    required this.connected,
  });
  final TaskExecutionActivity activity;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.textTheme.muted.copyWith(
      color: theme.colorScheme.mutedForeground,
      fontWeight: FontWeight.w400,
    );
    final words = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final event = activity.event;
    final icon = switch (event.kind) {
      TaskEventKind.toolFailed ||
      TaskEventKind.evidenceRejected => LucideIcons.circleAlert,
      TaskEventKind.approvalDenied ||
      TaskEventKind.cancellationRequested => LucideIcons.circleX,
      TaskEventKind.toolSucceeded ||
      TaskEventKind.stepCompleted ||
      TaskEventKind.approvalApproved => LucideIcons.circleCheck,
      TaskEventKind.verificationCompleted => switch (event.verificationStatus) {
        TaskVerificationStatus.verified => LucideIcons.circleCheck,
        TaskVerificationStatus.failed ||
        TaskVerificationStatus.partial => LucideIcons.circleAlert,
        _ => LucideIcons.circle,
      },
      TaskEventKind.approvalRequested ||
      TaskEventKind.waitingForUser ||
      TaskEventKind.paused => LucideIcons.clock3,
      TaskEventKind.toolRetry ||
      TaskEventKind.retryScheduled ||
      TaskEventKind.processRecovered => LucideIcons.rotateCw,
      TaskEventKind.planCreated ||
      TaskEventKind.planRevised => LucideIcons.listTodo,
      TaskEventKind.terminal => LucideIcons.flag,
      _ => LucideIcons.circle,
    };
    return Stack(
      children: [
        if (connected)
          PositionedDirectional(
            start: 7,
            top: 20,
            bottom: 0,
            width: 1,
            child: ColoredBox(color: theme.colorScheme.border),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  icon,
                  size: 15,
                  color: _activityColor(theme, activity),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          words.event(event.kind),
                          style: theme.textTheme.small.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          DateFormat.Hms().format(event.occurredAt.toLocal()),
                          style: muted,
                        ),
                      ],
                    ),
                    if (activity.subject.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(activity.subject, style: muted),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _activityColor(ShadThemeData theme, TaskExecutionActivity activity) {
  final status = switch (activity.event.kind) {
    TaskEventKind.toolSucceeded ||
    TaskEventKind.stepCompleted ||
    TaskEventKind.approvalApproved ||
    TaskEventKind.evidenceAccepted ||
    TaskEventKind.modelTurnCompleted ||
    TaskEventKind.segmentCheckpoint => ConversationTaskStatus.succeeded,
    TaskEventKind.toolFailed ||
    TaskEventKind.approvalDenied ||
    TaskEventKind.evidenceRejected => ConversationTaskStatus.failed,
    TaskEventKind.approvalRequested ||
    TaskEventKind.waitingForUser ||
    TaskEventKind.toolRetry ||
    TaskEventKind.retryScheduled ||
    TaskEventKind.leaseExpired ||
    TaskEventKind.noProgress => ConversationTaskStatus.waitingForUser,
    TaskEventKind.paused => ConversationTaskStatus.paused,
    TaskEventKind.cancellationRequested =>
      ConversationTaskStatus.cancelRequested,
    TaskEventKind.queued ||
    TaskEventKind.toolQueued => ConversationTaskStatus.queued,
    TaskEventKind.started ||
    TaskEventKind.resumed ||
    TaskEventKind.planCreated ||
    TaskEventKind.planRevised ||
    TaskEventKind.stepStarted ||
    TaskEventKind.toolStarted ||
    TaskEventKind.externalJobUpdated ||
    TaskEventKind.verificationStarted ||
    TaskEventKind.resultCommitting ||
    TaskEventKind.processRecovered ||
    TaskEventKind.segmentProgress => ConversationTaskStatus.running,
    TaskEventKind.verificationCompleted => switch (activity
        .event
        .verificationStatus) {
      TaskVerificationStatus.verified => ConversationTaskStatus.succeeded,
      TaskVerificationStatus.partial => ConversationTaskStatus.waitingForUser,
      TaskVerificationStatus.failed => ConversationTaskStatus.failed,
      TaskVerificationStatus.verifying => ConversationTaskStatus.running,
      TaskVerificationStatus.notStarted || null => null,
    },
    TaskEventKind.terminal => activity.terminalStatus,
  };
  return status == null
      ? theme.colorScheme.mutedForeground
      : theme.taskStatusForeground(status);
}
