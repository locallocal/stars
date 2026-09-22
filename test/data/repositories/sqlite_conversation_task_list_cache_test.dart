import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/repositories/sqlite_conversation_task_repository.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/conversation_task.dart';

import '../../support/conversation_task_repository_harness.dart';

void main() {
  late TaskRepositoryHarness h;
  setUp(() async {
    h = TaskRepositoryHarness();
    await h.open();
  });
  tearDown(() => h.close());

  Future<List<ConversationTaskProgressSummary>> read({
    String chatId = 'chat-1',
    bool refresh = false,
  }) => h.repository
      .watchForChat(chatId, refresh: refresh)
      .first
      .timeout(const Duration(seconds: 5));

  _DelayedDatabase delayReads() {
    final database = _DelayedDatabase(h.database);
    h.local = LocalDatabaseService(databaseProvider: () async => database);
    h.repository = SqliteConversationTaskRepository(localDatabase: h.local);
    return database;
  }

  test(
    'reentry shares an immutable snapshot across repository instances',
    () async {
      committed(await h.accept());
      final initial = await read();
      expect((await read()), same(initial));
      final other = SqliteConversationTaskRepository(
        localDatabase: LocalDatabaseService(
          databaseProvider: () async => h.database,
        ),
      );
      expect(await other.watchForChat('chat-1').first, same(initial));
      expect(h.repository.metrics.taskListSnapshotReads, 1);
      expect(other.metrics.taskListSnapshotReads, 0);
      expect(() => initial.clear(), throwsUnsupportedError);

      final empty = await read(chatId: 'other-chat');
      expect(empty, isEmpty);
      expect(await read(chatId: 'other-chat'), same(empty));
      expect(h.repository.metrics.taskListSnapshotReads, 2);
      expect(await read(), same(initial));
    },
  );

  test(
    'concurrent readers share one load and merge writes during it',
    () async {
      committed(await h.accept());
      final database = delayReads();
      final gate = database.holdNextTransaction();
      final first = read();
      final second = read();
      await gate.captured.future;
      committed(
        await h.repository.requestCancellation(
          taskId: 'task-1',
          expectedRevision: 0,
          source: TaskCancellationSource.user,
          requestedAt: taskTime,
        ),
      );
      gate.release.complete();
      final snapshots = await Future.wait([first, second]);
      expect(
        snapshots.first.single.status,
        ConversationTaskStatus.cancelRequested,
      );
      expect(snapshots.last, same(snapshots.first));
      expect(h.repository.metrics.taskListSnapshotReads, 1);
    },
  );

  test(
    'committed updates and new tasks reach caches while the page is closed',
    () async {
      committed(await h.accept());
      final initial = await read();
      final writer = SqliteConversationTaskRepository(
        localDatabase: LocalDatabaseService(
          databaseProvider: () async => h.database,
        ),
      );
      committed(
        await writer.requestCancellation(
          taskId: 'task-1',
          expectedRevision: 0,
          source: TaskCancellationSource.user,
          requestedAt: taskTime,
        ),
      );
      committed(await h.accept(task: taskFixture(id: 'task-2')));
      committed(
        await h.accept(
          task: changeTask(taskFixture(id: 'other'), {'chat_id': 'other-chat'}),
        ),
      );
      final cached = await read();
      expect(cached.map((s) => s.taskId), ['task-1', 'task-2']);
      expect(cached.first.status, ConversationTaskStatus.cancelRequested);
      expect(initial.single.status, ConversationTaskStatus.queued);
      expect(h.repository.metrics.taskListSnapshotReads, 1);
    },
  );

  test(
    'explicit refresh reloads once and broadcasts to existing readers',
    () async {
      committed(await h.accept());
      final database = delayReads();
      final initial = await read();
      final updates = StreamIterator(h.repository.watchForChat('chat-1'));
      addTearDown(updates.cancel);
      expect(await updates.moveNext(), isTrue);
      expect(updates.current, same(initial));
      // Seed a durable change outside the store's commit notifications.
      await seedTask(h.database, taskFixture(id: 'task-2'));
      expect(await read(), same(initial));
      final gate = database.holdNextTransaction();
      final first = read(refresh: true);
      final second = read(refresh: true);
      await gate.captured.future;
      gate.release.complete();
      final refreshed = await Future.wait([first, second]);
      expect(refreshed.first.map((s) => s.taskId), ['task-1', 'task-2']);
      expect(refreshed.last, same(refreshed.first));
      expect(await updates.moveNext(), isTrue);
      expect(updates.current, same(refreshed.first));
      expect(h.repository.metrics.taskListSnapshotReads, 2);
    },
  );

  test(
    'failed loads can retry and failed refresh preserves a good snapshot',
    () async {
      committed(await h.accept());
      final database = delayReads();
      database.failNextTransaction = true;
      await expectLater(read(), throwsStateError);
      final initial = await read();
      database.failNextTransaction = true;
      await expectLater(read(refresh: true), throwsStateError);
      expect(await read(), same(initial));
      expect(h.repository.metrics.taskListSnapshotReads, 3);
      expect((await read(refresh: true)).single.taskId, 'task-1');
      expect(h.repository.metrics.taskListSnapshotReads, 4);
    },
  );

  for (final operation in ['clear', 'deleteChat', 'deleteBot']) {
    test(
      '$operation clears cached tasks and notifies open pages after commit',
      () async {
        await h.start();
        committed(
          await (await h.terminal(
            ConversationTaskStatus.failed,
          )).commit(h.repository),
        );
        final initial = await read();
        final updates = StreamIterator(h.repository.watchForChat('chat-1'));
        addTearDown(updates.cancel);
        expect(await updates.moveNext(), isTrue);
        expect(updates.current, same(initial));
        switch (operation) {
          case 'clear':
            await h.local.clearChatHistory('chat-1', taskTime);
          case 'deleteChat':
            await h.local.deleteChat('chat-1');
          case 'deleteBot':
            await h.local.deleteBot('bot-1');
        }
        expect(await updates.moveNext(), isTrue);
        expect(updates.current, isEmpty);
        expect(await read(), isEmpty);
        expect(h.repository.metrics.taskListSnapshotReads, 1);
      },
    );
  }

  test('clearing history during a read cannot restore deleted tasks', () async {
    await h.start();
    committed(
      await (await h.terminal(
        ConversationTaskStatus.failed,
      )).commit(h.repository),
    );
    final database = delayReads();
    final gate = database.holdNextTransaction();
    final loading = read();
    await gate.captured.future;
    await h.local.clearChatHistory('chat-1', taskTime);
    gate.release.complete();
    expect(await loading, isEmpty);
    expect(await read(), isEmpty);
    expect(h.repository.metrics.taskListSnapshotReads, 1);
  });

  test('rolled-back deletion leaves the cache intact', () async {
    await h.start();
    committed(
      await (await h.terminal(
        ConversationTaskStatus.failed,
      )).commit(h.repository),
    );
    final initial = await read();
    await h.failWrite('messages', operation: 'DELETE');
    await expectLater(
      h.local.clearChatHistory('chat-1', taskTime),
      throwsException,
    );
    expect(await read(), same(initial));
    expect(await h.repository.getById('task-1'), isNotNull);
  });

  test(
    'evicts least recently opened inactive chats but keeps live readers',
    () async {
      committed(await h.accept());
      final updates = StreamIterator(h.repository.watchForChat('chat-1'));
      addTearDown(updates.cancel);
      expect(await updates.moveNext(), isTrue);
      final active = updates.current;
      for (var i = 0; i < 40; i++) {
        expect(await read(chatId: 'empty-$i'), isEmpty);
      }
      expect(h.repository.metrics.taskListSnapshotReads, 41);
      expect(await read(), same(active));
      await read(chatId: 'empty-39');
      expect(h.repository.metrics.taskListSnapshotReads, 41);
      await read(chatId: 'empty-0');
      expect(h.repository.metrics.taskListSnapshotReads, 42);
    },
  );

  test('reopening the database loads a fresh snapshot', () async {
    committed(await h.accept());
    await read();
    await h.reopen();
    expect((await read()).single.taskId, 'task-1');
    expect(h.repository.metrics.taskListSnapshotReads, 1);
  });
}

final class _ReadGate {
  final captured = Completer<void>();
  final release = Completer<void>();
}

/// Lets a real SQLite transaction finish before delaying delivery of its result.
final class _DelayedDatabase implements Database {
  _DelayedDatabase(this._database);
  final Database _database;
  _ReadGate? _next;
  bool failNextTransaction = false;

  _ReadGate holdNextTransaction() => _next = _ReadGate();

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction) action, {
    bool? exclusive,
  }) async {
    if (failNextTransaction) {
      failNextTransaction = false;
      throw StateError('storage unavailable');
    }
    final gate = _next;
    _next = null;
    final result = await _database.transaction(action, exclusive: exclusive);
    if (gate != null) {
      gate.captured.complete();
      await gate.release.future;
    }
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
