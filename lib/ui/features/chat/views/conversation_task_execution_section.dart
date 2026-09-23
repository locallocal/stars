import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/features/chat/view_models/conversation_tasks_view_model.dart';
import 'package:stars/ui/features/chat/views/conversation_task_execution_status.dart';
import 'package:stars/ui/features/chat/views/conversation_task_execution_timeline.dart';

final class ConversationTaskExecutionSection extends StatelessWidget {
  const ConversationTaskExecutionSection({
    super.key,
    required this.state,
    required this.onRetry,
  });

  final ConversationTaskExecutionState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final words = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.loading) const ShadProgress(),
        if (state.error)
          ShadAlert.destructive(
            title: Text(words.executionLoadFailed),
            description: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: onRetry,
                child: Text(S.of(context).retry),
              ),
            ),
          ),
        if (state.presentation case final presentation?) ...[
          ConversationTaskExecutionStatus(
            key: const ValueKey('task-execution-status'),
            presentation: presentation,
          ),
          if (presentation.activities.isNotEmpty) ...[
            const SizedBox(height: 16),
            ConversationTaskExecutionTimeline(
              key: const ValueKey('task-execution-flow'),
              presentation: presentation,
            ),
          ],
        ],
      ],
    );
  }
}
