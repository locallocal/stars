import 'package:stars/domain/models/conversation_task.dart';

enum TaskCancellationOutcome {
  requested,
  alreadyRequested,
  alreadyFinished,
  notFound,
  changed,
}

/// Committed command outcomes and the task snapshots used to explain them.
final class TaskCancellationResult {
  TaskCancellationResult({
    required Map<String, TaskCancellationOutcome> outcomes,
    required List<ConversationTaskProgressSummary> summaries,
    this.needsSelection = false,
  }) : outcomes = Map.unmodifiable(outcomes),
       summaries = List.unmodifiable(summaries);

  final Map<String, TaskCancellationOutcome> outcomes;
  final List<ConversationTaskProgressSummary> summaries;
  final bool needsSelection;
}
