import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';

import '../../support/conversation_task_repository_harness.dart';

void main() {
  late TaskRepositoryHarness h;
  setUp(() async {
    h = TaskRepositoryHarness();
    await h.open();
  });
  tearDown(() => h.close());

  test(
    'receipt, attempts and result survive rebuild without double counting',
    () async {
      final task = taskFixture();
      final accepted = committed(
        await h.accept(
          task: task,
          acknowledgement: taskMessage(task).copyWith(
            tokenUsage: const ModelTokenUsage(inputTokens: 10, outputTokens: 2),
          ),
        ),
      );
      expect(accepted.progress.tokenUsage!.inputTokens, 10);
      committed(
        await h.repository.tryAcquireLease(
          taskId: task.taskId,
          expectedRevision: accepted.revision,
          lease: taskLease(),
          now: h.time,
        ),
      );
      committed(
        await h.advance(
          TaskEventKind.started,
          status: ConversationTaskStatus.running,
        ),
      );
      final update = await h.update(
        TaskEventKind.modelTurnCompleted,
        modelTurns: 1,
        modelUsage: const ModelTokenUsage(inputTokens: 100, outputTokens: 20),
      );
      committed(await h.repository.appendProgress(update));
      expect(
        await h.repository.appendProgress(update),
        conflict(TaskWriteConflictReason.revisionMismatch),
      );
      final terminal = await h.terminal(ConversationTaskStatus.failed);
      committed(
        await terminal.commit(
          h.repository,
          message: taskMessage(terminal.task).copyWith(
            tokenUsage: const ModelTokenUsage(inputTokens: 30, outputTokens: 4),
          ),
        ),
      );
      await h.reopen();
      await h.repository.rebuildProgress(task.taskId);
      await h.repository.rebuildProgress(task.taskId);
      final usage = (await h.task).progress.tokenUsage!;
      expect(usage.inputTokens, 140);
      expect(usage.outputTokens, 26);
      expect(usage.effectiveTotalTokens, 166);
      final messages = SqliteMessageRepository(localDatabase: h.local);
      addTearDown(messages.dispose);
      final botUsage = await messages.getTokenUsageForBot(task.botId);
      expect(botUsage.inputTokens, usage.inputTokens);
      expect(botUsage.outputTokens, usage.outputTokens);
      expect(
        await messages.getTokenUsageRecordsForChat(task.chatId),
        hasLength(3),
      );
    },
  );

  test(
    'usage and progress roll back together, then publish once on retry',
    () async {
      await h.start();
      final update = await h.update(
        TaskEventKind.modelTurnCompleted,
        modelTurns: 1,
        modelUsage: const ModelTokenUsage(inputTokens: 50, outputTokens: 7),
      );
      final before = await h.facts();
      await h.failWrite('conversation_task_progress', operation: 'UPDATE');
      await expectLater(
        h.repository.appendProgress(update),
        throwsA(isA<Exception>()),
      );
      expect(await h.facts(), before);
      await h.clearFailure();
      final summary = h.repository
          .watchProgress('task-1')
          .firstWhere((s) => s.progress.tokenUsage != null);
      committed(await h.repository.appendProgress(update));
      expect((await summary).progress.tokenUsage!.inputTokens, 50);
      expect((await h.task).progress.tokenUsage!.outputTokens, 7);
    },
  );

  test('an explicit zero report differs from unavailable usage', () async {
    await h.start();
    expect((await h.task).progress.tokenUsage, isNull);
    committed(
      await h.repository.appendProgress(
        await h.update(
          TaskEventKind.modelTurnCompleted,
          modelTurns: 1,
          modelUsage: ModelTokenUsage.empty,
        ),
      ),
    );
    await h.reopen();
    expect((await h.task).progress.tokenUsage, isNotNull);
    expect((await h.task).progress.tokenUsage!.effectiveTotalTokens, 0);
  });

  test('reports for similar task identities are kept separate', () async {
    await h.start();
    final sibling = taskFixture(id: 'task-1:2');
    committed(await h.accept(task: sibling));
    committed(
      await h.repository.appendProgress(
        await h.update(
          TaskEventKind.modelTurnCompleted,
          modelTurns: 1,
          modelUsage: const ModelTokenUsage(inputTokens: 50),
        ),
      ),
    );
    expect(
      (await h.repository.getById(sibling.taskId))!.progress.tokenUsage,
      isNull,
    );
  });
}
