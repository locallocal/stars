import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/get_conversation_task_progress.dart';

import '../../support/conversation_task_fixtures.dart';

void main() {
  test(
    'returns a single revision-bound snapshot only for its conversation',
    () async {
      final summary = ConversationTaskProgressSummary(
        taskId: 'task-1',
        chatId: 'chat-1',
        title: 'Task',
        status: ConversationTaskStatus.running,
        phase: ConversationTaskPhase.executing,
        planRevision: 2,
        summaryRevision: 7,
        progress: TaskProgress(
          totalSteps: 3,
          completedSteps: 1,
          lastMeaningfulProgressAt: taskTime,
        ),
        updatedAt: taskTime,
      );
      final repository = _Tasks(summary);
      final get = GetConversationTaskProgress(repository: repository);
      expect(await get(chatId: 'chat-1', taskId: 'task-1'), same(summary));
      expect(await get(chatId: 'foreign-chat', taskId: 'task-1'), isNull);
      expect(await get(chatId: 'chat-1', taskId: 'missing'), isNull);
      expect(repository.reads, ['task-1', 'task-1', 'missing']);
      await expectLater(get(chatId: '', taskId: 'task-1'), throwsArgumentError);
      await expectLater(
        get(chatId: 'chat-1', taskId: ' '),
        throwsArgumentError,
      );
    },
  );
}

class _Tasks implements ConversationTaskRepository {
  _Tasks(this.summary);
  final ConversationTaskProgressSummary summary;
  final reads = <String>[];
  @override
  Future<ConversationTaskProgressSummary?> getProgressSummary(
    String taskId,
  ) async {
    reads.add(taskId);
    return taskId == summary.taskId ? summary : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
