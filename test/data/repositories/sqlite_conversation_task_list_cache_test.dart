import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/repositories/sqlite_conversation_task_repository.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/conversation_task_list_item.dart';

import '../../support/conversation_task_repository_harness.dart';

void main() {
  late TaskRepositoryHarness h;
  setUp(() async {
    h = TaskRepositoryHarness();
    await h.open();
  });
  tearDown(() => h.close());

  Future<List<ConversationTaskListItem>> read({
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

  test('list reads one metadata query without decoding task details', () async {
    for (var i = 0; i < 25; i++) {
      committed(await h.accept(task: taskFixture(id: 'task-$i')));
    }
    // A partial projection with large detail payloads must be readable without
    // decoding TaskProgress or loading any per-task facts.
    await h.database.update('conversation_task_progress', {
      'progress_json': jsonEncode({
        'completedSteps': 1,
        'totalSteps': 2,
        'currentStepSummary': 'Write report',
        'latestTool': {'name': 'read_file', 'safeSummary': 'detail' * 10000},
        'pendingApprovalSummary': 'approval' * 9000,
        'tokenUsage': {'inputTokens': 12, 'outputTokens': 3, 'totalTokens': 15},
      }),
    });
    final database = delayReads()..recordListQueries = true;
    final items = await read();
    expect(items, hasLength(25));
    expect(items.first.completedSteps, 1);
    expect(items.first.totalSteps, 2);
    expect(items.first.currentStepSummary, 'Write report');
    expect(items.first.latestToolName, 'read_file');
    expect(items.first.tokenUsage!.effectiveTotalTokens, 15);
    expect(database.listQueries, hasLength(1));
    expect(database.listQueries.single, isNot(contains('SELECT *')));
    expect(database.listQueries.single, isNot(contains('acceptance_json')));
    expect(database.listQueries.single, isNot(contains('pendingApproval')));
    expect(
      database.listQueries.single,
      isNot(contains('terminal_summary_json')),
    );
    expect(await read(), same(items));
    expect(database.listQueries, hasLength(1));
  });

  test(
    'missing or stale projections keep metadata without replaying facts',
    () async {
      committed(await h.accept());
      committed(await h.accept(task: taskFixture(id: 'task-2')));
      await h.database.delete(
        'conversation_task_progress',
        where: 'task_id = ?',
        whereArgs: ['task-1'],
      );
      await h.database.update(
        'conversation_task_progress',
        {'summary_revision': 99, 'progress_json': '{"totalSteps":999}'},
        where: 'task_id = ?',
        whereArgs: ['task-2'],
      );
      final database = delayReads()..recordListQueries = true;
      final items = await read();
      expect(items, hasLength(2));
      expect(items.every((item) => item.totalSteps == null), isTrue);
      expect(
        items.every((item) => item.status == ConversationTaskStatus.queued),
        isTrue,
      );
      expect(database.listQueries, hasLength(1));
      // A later detail read still reconstructs the correct facts.
      database.recordListQueries = false;
      expect(
        (await h.repository.getExecutionSnapshot(
          'task-1',
        ))!.task.progress.totalSteps,
        2,
      );
    },
  );

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
  bool recordListQueries = false;
  final listQueries = <String>[];

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
    final result = await _database.transaction(
      (tx) => action(
        recordListQueries ? _ListReadTransaction(tx, listQueries) : tx,
      ),
      exclusive: exclusive,
    );
    if (gate != null) {
      gate.captured.complete();
      await gate.release.future;
    }
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A list read may use its metadata SELECT; any per-task query fails the test.
final class _ListReadTransaction implements Transaction {
  _ListReadTransaction(this.delegate, this.queries);
  final Transaction delegate;
  final List<String> queries;

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) {
    queries.add(sql);
    return delegate.rawQuery(sql, arguments);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
