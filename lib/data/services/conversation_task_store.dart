import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stars/data/models/conversation_task_record.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/models/tool_evidence_record.dart';
import 'package:stars/data/models/tool_execution_record.dart';
import 'package:stars/data/services/task_persistence_metrics.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/task_scheduling.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_safe_data.dart';
import 'package:stars/domain/services/task_execution_details.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';

part 'conversation_task_store_execution.dart';
part 'conversation_task_store_status.dart';
part 'conversation_task_store_writes.dart';
part 'conversation_task_store_commands.dart';
part 'conversation_task_store_scheduling.dart';
part 'conversation_task_store_facts.dart';
part 'conversation_task_store_planning.dart';
part 'conversation_task_store_projection.dart';
part 'conversation_task_store_usage.dart';
part 'conversation_task_store_validation.dart';

/// SQLite transaction boundary for task facts. No external work runs here.
final class ConversationTaskStore {
  ConversationTaskStore({
    required Future<Database> Function() databaseProvider,
    required void Function(String chatId) onMessageCommitted,
  }) : _databaseProvider = databaseProvider,
       _onMessageCommitted = onMessageCommitted;

  final Future<Database> Function() _databaseProvider;
  final void Function(String chatId) _onMessageCommitted;
  final metrics = TaskPersistenceMetrics();
  static final _buses =
      Expando<StreamController<ConversationTaskProgressSummary>>();

  StreamController<ConversationTaskProgressSummary> _bus(Database db) =>
      _buses[db] ??=
          StreamController<ConversationTaskProgressSummary>.broadcast();

  Future<T> _read<T>(Future<T> Function(Transaction) action) async =>
      (await _databaseProvider()).transaction(action);

  Future<TaskWriteResult<T>> _write<T>(
    String taskId,
    Future<TaskWriteCommitted<T>> Function(Transaction) action, {
    bool acceptance = false,
    bool message = false,
    bool progress = false,
  }) async {
    final timer = Stopwatch()..start();
    try {
      final db = await _databaseProvider();
      ConversationTaskProgressSummary? summary;
      final result = await db.transaction((tx) async {
        final result = await action(tx);
        if (!result.reused) {
          // sqflite does not roll back a failed deferred COMMIT itself. Check
          // deferred FKs while still in its callback, so errors trigger rollback.
          if ((await tx.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
            throw StateError('task_foreign_key_violation');
          }
          summary = await _summary(tx, taskId);
        }
        return result;
      });
      if (result.reused) {
        metrics.reusedWrites++;
      } else {
        metrics.committedWriteMicroseconds += timer.elapsedMicroseconds;
        if (acceptance) metrics.acceptances++;
        if (progress) metrics.progressUpdates++;
        if (summary != null) {
          if (message) _onMessageCommitted(summary!.chatId);
          _bus(db).add(summary!);
        }
      }
      return result;
    } on _TaskConflict catch (error) {
      metrics.recordConflict(error.reason);
      if (acceptance) metrics.acceptanceFailures++;
      return TaskWriteConflict(error.reason, actualRevision: error.revision);
    } on Object {
      metrics.writeFailures++;
      if (acceptance) metrics.acceptanceFailures++;
      rethrow;
    }
  }

  Future<ConversationTask?> getById(String taskId) =>
      _read((tx) => _task(tx, taskId));

  Future<ConversationTask?> getByOriginTurnId(String turnId) => _read((
    tx,
  ) async {
    final rows = await tx.query(
      'conversation_tasks',
      where: 'origin_turn_id = ?',
      whereArgs: [turnId],
    );
    return rows.isEmpty ? null : _task(tx, rows.single['task_id']! as String);
  });

  Future<List<ConversationTask>> listActiveForChat(String chatId) => _list(
    'chat_id = ? AND completed_at IS NULL',
    [chatId],
    'created_at, task_id',
  );

  Future<ConversationTask?> getLatestTerminalForChat(String chatId) async {
    final tasks = await _list(
      'chat_id = ? AND completed_at IS NOT NULL',
      [chatId],
      'completed_at DESC, task_id DESC',
      limit: 1,
    );
    return tasks.isEmpty ? null : tasks.single;
  }

  Future<List<ConversationTask>> listDue({
    required DateTime now,
    int limit = 100,
    String? afterTaskId,
  }) {
    _limit(limit);
    return _list(
      "status IN ('queued', 'paused', 'cancelRequested') AND phase != 'committing' "
          'AND (next_run_at IS NULL OR next_run_at <= ?) '
          'AND (lease_expires_at IS NULL OR lease_expires_at <= ?) '
          "AND (status = 'cancelRequested' OR NOT EXISTS (SELECT 1 FROM conversation_task_approvals a "
          'WHERE a.task_id = conversation_tasks.task_id AND a.decision IS NULL))'
          '${afterTaskId == null ? '' : ' AND task_id > ?'}',
      [
        now.microsecondsSinceEpoch,
        now.microsecondsSinceEpoch,
        if (afterTaskId != null) afterTaskId,
      ],
      'task_id',
      limit: limit,
    );
  }

  Future<List<ConversationTask>> listRecoverable({
    String? afterTaskId,
    int limit = 100,
  }) {
    _limit(limit);
    return _list(
      'completed_at IS NULL${afterTaskId == null ? '' : ' AND task_id > ?'}',
      [if (afterTaskId != null) afterTaskId],
      'task_id',
      limit: limit,
    );
  }

  Future<List<ConversationTask>> _list(
    String where,
    List<Object?> args,
    String order, {
    int? limit,
  }) => _read((tx) async {
    final rows = await tx.query(
      'conversation_tasks',
      columns: ['task_id'],
      where: where,
      whereArgs: args,
      orderBy: order,
      limit: limit,
    );
    return List.unmodifiable([
      for (final row in rows) (await _task(tx, row['task_id']! as String))!,
    ]);
  });

  Future<ConversationTaskCheckpoint?> getCheckpoint(
    String taskId,
    int planRevision,
  ) => _read((tx) async {
    final rows = await tx.query(
      'conversation_task_checkpoints',
      where: 'task_id = ? AND plan_revision = ?',
      whereArgs: [taskId, planRevision],
    );
    return rows.isEmpty
        ? null
        : ConversationTaskCheckpointRecord(rows.single).toDomain();
  });

  Future<ConversationTaskProgressSummary?> getProgressSummary(String taskId) =>
      _read((tx) => _summary(tx, taskId));

  Future<ConversationTaskProgressSummary?> rebuildProgress(String taskId) =>
      _read((tx) async {
        final rows = await tx.query(
          'conversation_tasks',
          where: 'task_id = ?',
          whereArgs: [taskId],
        );
        if (rows.isEmpty) return null;
        final progress = await _project(tx, rows.single);
        await _saveProjection(tx, rows.single, progress);
        return _summaryOf(
          ConversationTaskRecord(rows.single).toDomain(progress: progress),
        );
      });

  Stream<ConversationTaskProgressSummary> watchProgress(String taskId) {
    late StreamController<ConversationTaskProgressSummary> controller;
    StreamSubscription<ConversationTaskProgressSummary>? subscription;
    var cancelled = false;
    var ready = false;
    var revision = -1;
    final pending = <ConversationTaskProgressSummary>[];
    void emit(ConversationTaskProgressSummary value) {
      if (!cancelled && value.summaryRevision > revision) {
        revision = value.summaryRevision;
        controller.add(value);
      }
    }

    Future<void> start() async {
      try {
        final db = await _databaseProvider();
        if (cancelled) return;
        subscription = _bus(
          db,
        ).stream.where((value) => value.taskId == taskId).listen((value) {
          if (ready) {
            emit(value);
          } else {
            pending.add(value);
          }
        });
        final initial = await db.transaction((tx) => _summary(tx, taskId));
        if (initial != null) emit(initial);
        ready = true;
        pending.sort((a, b) => a.summaryRevision.compareTo(b.summaryRevision));
        for (final value in pending) {
          emit(value);
        }
        pending.clear();
      } on Object catch (error, stack) {
        if (!cancelled) controller.addError(error, stack);
        await subscription?.cancel();
        if (!cancelled) await controller.close();
      }
    }

    controller = StreamController(
      onListen: start,
      onCancel: () async {
        cancelled = true;
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }
}

void _limit(int limit) {
  if (limit < 1 || limit > 1000) throw ArgumentError.value(limit, 'limit');
}

final class _TaskConflict implements Exception {
  const _TaskConflict(this.reason, [this.revision]);
  final TaskWriteConflictReason reason;
  final int? revision;
}

Future<ConversationTask?> _task(DatabaseExecutor tx, String id) async {
  final rows = await tx.query(
    'conversation_tasks',
    where: 'task_id = ?',
    whereArgs: [id],
  );
  if (rows.isEmpty) return null;
  // Reading facts in this transaction also works when the projection is missing
  // or damaged. The runner and the UI never become an alternative fact source.
  return ConversationTaskRecord(
    rows.single,
  ).toDomain(progress: await _project(tx, rows.single));
}

Future<ConversationTask> _current(
  DatabaseExecutor tx,
  String id,
  int revision,
) async {
  final task = await _task(tx, id);
  if (task == null) throw const _TaskConflict(TaskWriteConflictReason.notFound);
  if (task.status.isTerminal) {
    throw _TaskConflict(TaskWriteConflictReason.alreadyTerminal, task.revision);
  }
  if (task.revision != revision) {
    throw _TaskConflict(
      TaskWriteConflictReason.revisionMismatch,
      task.revision,
    );
  }
  return task;
}

void _fence(ConversationTask task, TaskLease lease, DateTime now) {
  final current = task.lease;
  if (current == null ||
      current.taskId != lease.taskId ||
      current.ownerId != lease.ownerId ||
      current.token != lease.token ||
      current.acquiredAt != lease.acquiredAt) {
    throw _TaskConflict(
      TaskWriteConflictReason.leaseUnavailable,
      task.revision,
    );
  }
  if (!current.isValidAt(now)) {
    throw _TaskConflict(TaskWriteConflictReason.leaseExpired, task.revision);
  }
}

Future<ConversationTask> _saveTask(
  DatabaseExecutor tx,
  Map<String, Object?> values,
) async {
  final id = values['task_id'];
  final changed = await tx.update(
    'conversation_tasks',
    values,
    where: 'task_id = ? AND revision = ?',
    whereArgs: [id, (values['revision']! as int) - 1],
  );
  if (changed != 1) {
    throw const _TaskConflict(TaskWriteConflictReason.revisionMismatch);
  }
  final progress = await _project(tx, values);
  await _saveProjection(tx, values, progress);
  return ConversationTaskRecord(values).toDomain(progress: progress);
}

Future<void> _saveProjection(
  DatabaseExecutor tx,
  Map<String, Object?> task,
  TaskProgress progress,
) async {
  final values =
      TaskProgressRecord.fromDomain(
        task['task_id']! as String,
        task['revision']! as int,
        progress,
      ).values;
  final changed = await tx.update(
    'conversation_task_progress',
    values,
    where: 'task_id = ?',
    whereArgs: [task['task_id']],
  );
  if (changed == 0) await tx.insert('conversation_task_progress', values);
}

Future<int> _nextSequence(DatabaseExecutor tx, String id) async {
  final rows = await tx.rawQuery(
    'SELECT COALESCE(MAX(sequence), 0) + 1 AS next FROM conversation_task_events WHERE task_id = ?',
    [id],
  );
  return rows.single['next']! as int;
}

Future<void> _event(DatabaseExecutor tx, ConversationTaskEvent event) async {
  if (event.sequence != await _nextSequence(tx, event.taskId)) {
    throw const _TaskConflict(TaskWriteConflictReason.duplicateIdentity);
  }
  for (final (table, column, id) in [
    ('conversation_task_tool_attempts', 'attempt_id', event.attemptId),
    ('conversation_task_approvals', 'approval_id', event.approvalId),
    ('conversation_task_evidence_links', 'evidence_id', event.evidenceId),
  ]) {
    if (id != null &&
        (await tx.query(
          table,
          columns: [column],
          where: 'task_id = ? AND $column = ?',
          whereArgs: [event.taskId, id],
        )).isEmpty) {
      throw ArgumentError('Event references an unknown task fact.');
    }
  }
  await tx.insert('conversation_task_events', _eventValues(event));
}
