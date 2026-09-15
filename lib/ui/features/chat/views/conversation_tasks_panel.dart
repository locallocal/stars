import 'package:flutter/material.dart';
import 'package:stars/ui/features/chat/views/task_action_button.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/services/task_progress_strings.dart';
import 'package:stars/ui/features/chat/view_models/conversation_tasks_view_model.dart';
import 'package:stars/ui/features/chat/views/conversation_task_card.dart';

final class ConversationTasksPanel extends StatefulWidget {
  const ConversationTasksPanel({
    super.key,
    required this.state,
    required this.onQuery,
    required this.onRefresh,
    required this.onAction,
  });
  final ConversationTasksState state;
  final VoidCallback onQuery, onRefresh;
  final void Function(ConversationTaskProgressSummary, TaskCardAction) onAction;
  @override
  State<ConversationTasksPanel> createState() => _ConversationTasksPanelState();
}

final class _ConversationTasksPanelState extends State<ConversationTasksPanel> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final w = TaskProgressStrings(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final active =
        widget.state.summaries.where((s) => !s.status.isTerminal).length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            TaskActionButton(
              ghost: true,
              label: '${w.tasks} · $active',
              onPressed: () => setState(() => expanded = !expanded),
            ),
            TaskActionButton(
              ghost: true,
              label: w.viewStatus,
              onPressed: widget.onQuery,
            ),
          ],
        ),
        if (widget.state.error) ...[
          Text(w.commandFailed, style: Theme.of(context).textTheme.bodySmall),
          TaskActionButton(label: w.refresh, onPressed: widget.onRefresh),
        ],
        if (expanded)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .28,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.state.summaries.isEmpty && !widget.state.loading)
                    Text(w.noTasks),
                  for (final summary in widget.state.summaries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ConversationTaskCard(
                        key: ValueKey('live-${summary.taskId}'),
                        summary: summary,
                        busy: widget.state.pendingCommands.contains(
                          summary.taskId,
                        ),
                        onAction: (action) => widget.onAction(summary, action),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
