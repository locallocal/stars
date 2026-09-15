import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';

/// Resolves an explicit task reference within its conversation.
final class GetConversationTaskProgress {
  const GetConversationTaskProgress({
    required ConversationTaskRepository repository,
  }) : _repository = repository;

  final ConversationTaskRepository _repository;

  Future<ConversationTaskProgressSummary?> call({
    required String chatId,
    required String taskId,
  }) async {
    if (chatId.trim().isEmpty || taskId.trim().isEmpty) {
      throw ArgumentError('Conversation and task identifiers are required.');
    }
    final summary = await _repository.getProgressSummary(taskId);
    return summary?.chatId == chatId ? summary : null;
  }
}
