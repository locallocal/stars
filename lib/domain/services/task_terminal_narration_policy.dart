import 'package:stars/domain/models/conversation_task.dart';

part 'task_terminal_strings.dart';

final class TaskTerminalNarration {
  const TaskTerminalNarration(this.text, {required this.usedFallback});
  final String text;
  final bool usedFallback;
}

/// The whole draft must fit an application-authored grammar. Free text cannot
/// add completion, rollback, artifacts or advice by evading a word blacklist.
final class TaskTerminalNarrationPolicy {
  const TaskTerminalNarrationPolicy();

  List<String> alternatives(TaskTerminalSummary summary, String language) {
    final words = TaskTerminalStrings(language);
    final blocks = <String>[
      summary.status == ConversationTaskStatus.cancelled
          ? words.cancelled
          : words.failed,
      summary.safeReason,
      summary.completedWorkSummary.isEmpty
          ? words.noResults
          : summary.completedWorkSummary,
      if (summary.retainedArtifacts.isEmpty) words.noArtifacts,
      if (summary.retainedArtifacts.isNotEmpty)
        '${words.artifacts} ${summary.retainedArtifacts.join(', ')}',
      switch (summary.sideEffectStatus) {
        TaskSideEffectStatus.none => words.noEffects,
        TaskSideEffectStatus.irreversible => words.irreversible,
        TaskSideEffectStatus.reconciled => words.reconciled,
        TaskSideEffectStatus.unknown => words.unknown,
      },
      ...summary.suggestedNextActions,
    ];
    return [blocks.join('\n\n'), blocks.join('\n')];
  }

  TaskTerminalNarration evaluate({
    required TaskTerminalSummary summary,
    required String language,
    String draft = '',
  }) {
    final allowed = alternatives(summary, language);
    final accepted = allowed.contains(draft.trim());
    return TaskTerminalNarration(
      accepted ? draft.trim() : allowed.first,
      usedFallback: !accepted,
    );
  }
}
