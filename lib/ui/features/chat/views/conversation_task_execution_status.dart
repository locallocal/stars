import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/features/chat/view_models/task_execution_presentation.dart';
import 'package:stars/ui/features/chat/views/execution_status_card.dart';
import 'package:stars/ui/features/chat/views/message_list_process.dart';
import 'package:stars/ui/features/chat/views/task_execution_value.dart';
import 'package:stars/ui/features/chat/views/task_status_colors.dart';

final class ConversationTaskExecutionStatus extends StatelessWidget {
  const ConversationTaskExecutionStatus({
    super.key,
    required this.presentation,
  });
  final TaskExecutionPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final words = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final strings = S.of(context);
    final theme = ShadTheme.of(context);
    final muted = theme.textTheme.muted.copyWith(
      color: theme.colorScheme.mutedForeground,
      fontWeight: FontWeight.w400,
    );
    return ExecutionDetailsDisclosure(
      id: 'execution-status',
      maintainState: true,
      title: strings.executionStatus,
      header: TaskExecutionSectionHeading(
        title: strings.executionStatus,
        count: words.executionCalls(presentation.attempts.length),
      ),
      summary:
          presentation.attempts.isEmpty
              ? null
              : Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  for (final (tone, label, icon) in [
                    (
                      TaskAttemptTone.completed,
                      strings.statusCompleted,
                      LucideIcons.circleCheck,
                    ),
                    (
                      TaskAttemptTone.active,
                      strings.statusInProgress,
                      LucideIcons.loaderCircle,
                    ),
                    (
                      TaskAttemptTone.attention,
                      words.executionAttention,
                      LucideIcons.circleAlert,
                    ),
                    (
                      TaskAttemptTone.stopped,
                      words.executionStopped,
                      LucideIcons.circleMinus,
                    ),
                  ])
                    if (presentation.counts[tone]! > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 13,
                            color:
                                tone == TaskAttemptTone.attention
                                    ? theme.colorScheme.destructive
                                    : theme.colorScheme.mutedForeground,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${presentation.counts[tone]} $label',
                            style: muted,
                          ),
                        ],
                      ),
                ],
              ),
      child:
          presentation.attempts.isEmpty
              ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(words.executionEmpty, style: muted),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final attempt in presentation.attempts)
                    _TaskAttemptRow(
                      key: ValueKey('task-call-${attempt.id}'),
                      attempt: attempt,
                    ),
                ],
              ),
    );
  }
}

final class TaskExecutionSectionHeading extends StatelessWidget {
  const TaskExecutionSectionHeading({
    super.key,
    required this.title,
    required this.count,
  });
  final String title, count;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          title,
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          count,
          style: theme.textTheme.muted.copyWith(
            color: theme.colorScheme.mutedForeground,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

final class _TaskAttemptRow extends StatelessWidget {
  const _TaskAttemptRow({super.key, required this.attempt});
  final TaskAttemptPresentation attempt;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final strings = S.of(context);
    final muted = theme.textTheme.muted.copyWith(
      color: theme.colorScheme.mutedForeground,
      fontWeight: FontWeight.w400,
    );
    final words = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final call = attempt.call;
    final badgeColors = theme.toolStatusBadgeColors(call.status);
    final title = attempt.isCommand ? strings.commandExecutions : attempt.title;
    final metadata = [
      if (call.source.isNotEmpty) toolSourceLabel(strings, call.source),
      if (call.mcpServerName.isNotEmpty) call.mcpServerName,
      if (call.durationMs != null)
        formatProcessDuration(strings, call.durationMs!),
      if (attempt.attemptNumber > 1)
        words.executionAttempt(attempt.attemptNumber),
    ].join(' · ');
    return ExecutionDetailsDisclosure(
      id: attempt.id,
      title: title,
      initiallyExpanded: false,
      header: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              attempt.isCommand ? LucideIcons.terminal : LucideIcons.wrench,
              size: 16,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ExecutionStatusBadge(
                      status: call.status,
                      compact: true,
                      foregroundColor: badgeColors.foreground,
                      backgroundColor: badgeColors.background,
                    ),
                  ],
                ),
                if (attempt.preview.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    attempt.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ],
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(metadata, style: muted),
                ],
              ],
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, value) in [
            (words.executionCommand, attempt.command),
            (words.executionDirectory, attempt.workingDirectory),
            (words.executionArguments, attempt.arguments),
            (words.executionResult, call.resultSummary),
            (words.executionError, call.errorCode),
          ])
            if (value.isNotEmpty)
              TaskExecutionValue(
                key: ValueKey(label),
                label: label,
                value: value,
              ),
          if (call.resultSummary.isEmpty && call.errorCode.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                attempt.tone == TaskAttemptTone.active ||
                        call.status == 'awaitingApproval'
                    ? words.executionPendingOutput
                    : words.executionNoOutput,
                style: muted,
              ),
            ),
        ],
      ),
    );
  }
}
