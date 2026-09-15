import 'package:stars/domain/models/app_failure.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';

final class ConversationTaskRetryDraft {
  const ConversationTaskRetryDraft({required this.taskId, required this.input});
  final String taskId;
  final String input;
}

final class PrepareConversationTaskRetry {
  const PrepareConversationTaskRetry({
    required this.tasks,
    required this.messages,
  });
  final ConversationTaskRepository tasks;
  final MessageRepository messages;
  Future<ConversationTaskRetryDraft> call({
    required String chatId,
    required String botId,
    required String taskId,
  }) async {
    final task = await tasks.getById(taskId);
    if (task == null ||
        task.chatId != chatId ||
        task.botId != botId ||
        !task.status.isTerminal ||
        task.terminalSummary?.canRetry != true ||
        task.terminalSummary!.sideEffectStatus != TaskSideEffectStatus.none) {
      throw const AppFailure.validation('task_retry_unavailable');
    }
    final original =
        (await messages.getMessages(
          chatId,
        )).where((m) => m.messageId == task.originUserMessageId).firstOrNull;
    if (original == null) {
      throw const AppFailure.validation('task_retry_unavailable');
    }
    // Attachments require a fresh selection, never replay old file references.
    return ConversationTaskRetryDraft(taskId: taskId, input: original.content);
  }
}
