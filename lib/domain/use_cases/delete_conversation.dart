import 'package:stars/domain/models/app_failure.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';

/// Retains the conversation and its evidence until all tasks have a terminal
/// outcome. The database repeats the guard atomically with physical deletion.
final class DeleteConversation {
  const DeleteConversation({
    required this.chats,
    required this.tasks,
    required this.commands,
  });
  final ChatRepository chats;
  final ConversationTaskRepository tasks;
  final ConversationTaskCommands commands;

  Future<bool> hasActiveTasks(String chatId) async =>
      (await tasks.listActiveForChat(chatId)).isNotEmpty;

  Future<void> call(String chatId) async {
    for (final task in await tasks.listActiveForChat(chatId)) {
      var current = task;
      for (var attempt = 0; attempt < 8; attempt++) {
        if (current.cancelRequestedAt != null || current.status.isTerminal) {
          break;
        }
        final result = await commands.cancel(
          taskId: current.taskId,
          expectedRevision: current.revision,
          source: TaskCancellationSource.conversationDeletion,
        );
        if (result is TaskWriteCommitted<ConversationTask>) break;
        final latest = await tasks.getById(current.taskId);
        if (latest == null) break;
        current = latest;
      }
    }
    if ((await tasks.listActiveForChat(chatId)).isNotEmpty) {
      throw const AppFailure.validation('conversation_tasks_stopping');
    }
    await chats.deleteChat(chatId);
  }
}
