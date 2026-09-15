import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_runner_contracts.dart';

/// Resolves an explicit task reference within its conversation.
final class GetConversationTaskProgress {
  const GetConversationTaskProgress({
    required ConversationTaskRepository repository,
    this.clock = const SystemTaskRunnerClock(),
  }) : _repository = repository;

  final ConversationTaskRepository _repository;
  final TaskRunnerClock clock;

  Future<ConversationTaskProgressSummary?> call({
    required String chatId,
    required String taskId,
  }) async {
    if (chatId.trim().isEmpty || taskId.trim().isEmpty) {
      throw ArgumentError('Conversation and task identifiers are required.');
    }
    final summary = await _repository.getProgressSummary(taskId);
    return summary?.chatId == chatId ? summary!.observedAt(clock.now()) : null;
  }
}
