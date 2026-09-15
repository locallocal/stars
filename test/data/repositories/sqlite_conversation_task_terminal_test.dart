import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';

import '../../support/conversation_task_repository_harness.dart';

void main() {
  late TaskRepositoryHarness h;
  setUp(() async {
    h = TaskRepositoryHarness();
    await h.open();
  });
  tearDown(() => h.close());

  for (final status in [
    ConversationTaskStatus.succeeded,
    ConversationTaskStatus.failed,
    ConversationTaskStatus.cancelled,
  ]) {
    test(
      '$status commits one result and is idempotent after database restart',
      () async {
        var old = await h.start();
        if (status == ConversationTaskStatus.cancelled) {
          old = committed(
            await h.repository.requestCancellation(
              taskId: old.taskId,
              expectedRevision: old.revision,
              source: TaskCancellationSource.user,
              requestedAt: h.nextTime,
            ),
          );
          h.time = h.nextTime;
        }
        final write = await h.terminal(status);
        final saved = committed(await write.commit(h.repository));
        expect(saved.status, status);
        expect(saved.resultMessageId, 'task-1:result');
        expect(saved.lease, isNull);
        expect(
          saved.terminalSummary != null,
          status != ConversationTaskStatus.succeeded,
        );
        final before = await h.facts();
        expect(before['messages'], hasLength(3));
        expect(h.local.messageRevision(old.chatId), 2);
        await h.reopen();
        final repeated = await write.commit(h.repository);
        expect(
          (repeated as TaskWriteCommitted<ConversationTask>).reused,
          isTrue,
        );
        expect(await h.facts(), before);
        expect(
          await write.commit(
            h.repository,
            message: taskMessage(write.task, content: 'Changed result'),
          ),
          conflict(TaskWriteConflictReason.alreadyTerminal),
        );
        expect(
          await h.repository.requestCancellation(
            taskId: old.taskId,
            expectedRevision: saved.revision,
            source: TaskCancellationSource.user,
            requestedAt: h.nextTime,
          ),
          conflict(TaskWriteConflictReason.alreadyTerminal),
        );
      },
    );
  }

  for (final (table, operation) in [
    ('conversation_task_events', 'INSERT'),
    ('conversation_tasks', 'UPDATE'),
    ('conversation_task_progress', 'UPDATE'),
    ('messages', 'INSERT'),
    ('token_usage_records', 'INSERT'),
    ('chats', 'UPDATE'),
  ]) {
    test(
      'terminal transaction rolls back on $table failure and succeeds on retry',
      () async {
        await h.start();
        final before = await h.facts();
        final write = await h.terminal(ConversationTaskStatus.failed);
        final values = <ConversationTaskProgressSummary>[];
        final initial = Completer<void>();
        final sub = h.repository.watchProgress('task-1').listen((value) {
          values.add(value);
          if (!initial.isCompleted) initial.complete();
        });
        addTearDown(sub.cancel);
        await initial.future;
        await h.failWrite(table, operation: operation);
        await expectLater(
          write.commit(h.repository),
          throwsA(isA<DatabaseException>()),
        );
        expect(await h.facts(), before);
        expect(h.local.messageRevision('chat-1'), 1);
        await h.clearFailure();
        committed(await write.commit(h.repository));
        await h.repository.getProgressSummary('task-1');
        await Future<void>.delayed(Duration.zero);
        expect(values.map((value) => value.status), [
          ConversationTaskStatus.running,
          ConversationTaskStatus.failed,
        ]);
      },
    );
  }

  test(
    'terminal deferred result reference failure rolls back before commit',
    () async {
      await h.start();
      final before = await h.facts();
      await h.database.execute(
        "CREATE TEMP TRIGGER corrupt_result AFTER INSERT ON messages WHEN NEW.task_message_kind = 'taskResult' "
        "BEGIN UPDATE messages SET message_id = 'wrong:result', task_id = NULL, task_message_kind = NULL WHERE message_id = NEW.message_id; END",
      );
      final write = await h.terminal(ConversationTaskStatus.failed);
      await expectLater(write.commit(h.repository), throwsStateError);
      expect(await h.facts(), before);
      await h.database.execute('DROP TRIGGER corrupt_result');
      committed(await write.commit(h.repository));
    },
  );

  test('concurrent terminal commits publish a single outcome', () async {
    await h.start();
    final write = await h.terminal(ConversationTaskStatus.failed);
    final results = await Future.wait([
      write.commit(h.repository),
      write.commit(h.repository),
    ]);
    expect(
      results.whereType<TaskWriteCommitted<ConversationTask>>().where(
        (result) => result.reused,
      ),
      hasLength(1),
    );
    expect(
      await h.database.query(
        'messages',
        where: 'task_message_kind = ?',
        whereArgs: ['taskResult'],
      ),
      hasLength(1),
    );
  });

  test(
    'a successful result built before cancellation cannot overwrite the command',
    () async {
      final old = await h.start();
      final write = await h.terminal(ConversationTaskStatus.succeeded);
      committed(
        await h.repository.requestCancellation(
          taskId: old.taskId,
          expectedRevision: old.revision,
          source: TaskCancellationSource.user,
          requestedAt: h.time,
        ),
      );
      expect(
        await write.commit(h.repository),
        conflict(TaskWriteConflictReason.revisionMismatch),
      );
      expect((await h.task).status, ConversationTaskStatus.cancelRequested);
      expect(
        await h.database.query(
          'messages',
          where: 'task_message_kind = ?',
          whereArgs: ['taskResult'],
        ),
        isEmpty,
      );
    },
  );

  test(
    'terminal requires a valid lease and correctly scoped message',
    () async {
      await h.start();
      final write = await h.terminal(ConversationTaskStatus.failed);
      await expectLater(
        write.commit(
          h.repository,
          message: taskMessage(write.task).copyWith(chatId: 'other-chat'),
        ),
        throwsArgumentError,
      );
      expect(
        await h.repository.commitTerminalMessage(
          terminalTask: write.task,
          event: write.event,
          message: taskMessage(write.task),
          expectedRevision: write.revision,
          lease: write.lease,
          now: write.lease.expiresAt,
        ),
        conflict(TaskWriteConflictReason.leaseExpired),
      );
      expect((await h.task).status, ConversationTaskStatus.running);
    },
  );
}
