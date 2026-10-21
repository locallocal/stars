import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_cancellation_result.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/models/turn_disposition.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';
import 'package:stars/domain/use_cases/get_conversation_task_progress.dart';

/// Resolves only the foreground turn's frozen candidates, then commits intent
/// through the same revision-fenced command used by the task controls.
final class CancelConversationTasks {
  const CancelConversationTasks({required this.commands});
  final ConversationTaskCommands commands;

  Future<TaskCancellationResult> call({
    required String chatId,
    required TaskCancellationRequest request,
    required List<String> activeTaskIds,
    required DateTime requestedAt,
    AgentCancellationToken? cancellation,
  }) async {
    final needsSelection =
        request.taskId == null && !request.all && activeTaskIds.length > 1;
    final ids = [if (request.taskId case final id?) id else ...activeTaskIds];
    final outcomes = <String, TaskCancellationOutcome>{};
    if (!needsSelection) {
      for (final id in ids) {
        cancellation?.throwIfCancelled();
        outcomes[id] = await _cancel(chatId, id, requestedAt, cancellation);
      }
    }
    final query = GetConversationTaskProgress(repository: commands.repository);
    final summaries = <ConversationTaskProgressSummary>[];
    for (final id in ids) {
      if (outcomes[id] == TaskCancellationOutcome.notFound) continue;
      final summary = await query(chatId: chatId, taskId: id);
      if (summary != null) summaries.add(summary);
    }
    return TaskCancellationResult(
      outcomes: outcomes,
      summaries: summaries,
      needsSelection: needsSelection,
    );
  }

  Future<TaskCancellationOutcome> _cancel(
    String chatId,
    String taskId,
    DateTime requestedAt,
    AgentCancellationToken? cancellation,
  ) async {
    // A running task may advance while the command reads its revision. Re-read
    // that same identity, never substitute a different task on a conflict.
    for (var attempt = 0; attempt < 3; attempt++) {
      cancellation?.throwIfCancelled();
      final task = await commands.repository.getById(taskId);
      if (task == null ||
          task.chatId != chatId ||
          task.createdAt.isAfter(requestedAt)) {
        return TaskCancellationOutcome.notFound;
      }
      if (task.status.isTerminal) {
        return TaskCancellationOutcome.alreadyFinished;
      }
      cancellation?.throwIfCancelled();
      final result = await commands.cancel(
        taskId: taskId,
        expectedRevision: task.revision,
      );
      if (result is TaskWriteCommitted<ConversationTask>) {
        return result.reused
            ? TaskCancellationOutcome.alreadyRequested
            : TaskCancellationOutcome.requested;
      }
    }
    return TaskCancellationOutcome.changed;
  }
}
