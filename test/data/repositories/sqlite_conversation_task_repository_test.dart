import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/models/conversation_task_record.dart';
import 'package:stars/data/repositories/sqlite_conversation_task_repository.dart';
import 'package:stars/data/services/local_database_service.dart';
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

  test('approval grant order does not change acceptance identity', () async {
    TaskAcceptanceSnapshot acceptance(Set<String> grants) => taskAcceptance(
      allowedToolNames: {'read_file', 'write_file'},
      approvalExemptToolNames: grants,
    );
    committed(
      await h.accept(
        task: taskFixture(acceptance: acceptance({'read_file', 'write_file'})),
      ),
    );
    await h.reopen();
    final reused =
        await h.accept(
              seed: false,
              task: taskFixture(
                acceptance: acceptance({'write_file', 'read_file'}),
              ),
            )
            as TaskWriteCommitted<ConversationTask>;
    expect(reused.reused, isTrue);
    expect(reused.value.acceptance.approvalExemptToolNames, {
      'read_file',
      'write_file',
    });
  });

  test(
    'legacy acceptance can resume without inventing approval grants',
    () async {
      committed(await h.accept());
      final row = (await h.database.query('conversation_tasks')).single;
      expect(
        row['acceptance_json'],
        isNot(contains('approvalExemptToolNames')),
      );
      await h.reopen();
      expect((await h.task).acceptance.approvalExemptToolNames, isEmpty);
      committed(
        await h.repository.tryAcquireLease(
          taskId: 'task-1',
          expectedRevision: 0,
          lease: taskLease(),
          now: taskTime,
        ),
      );
      committed(
        await h.advance(
          TaskEventKind.started,
          status: ConversationTaskStatus.running,
        ),
      );
      expect((await h.task).status, ConversationTaskStatus.running);
      expect((await h.task).acceptance.approvalExemptToolNames, isEmpty);
    },
  );

  test(
    'accepts a saved user message and atomically persists acknowledgement and snapshots',
    () async {
      final saved = committed(await h.accept());
      expect(saved.ackMessageId, 'task-1:ack');
      expect(saved.progress.totalSteps, 2);
      expect(saved.progress.summaryHash, matches(r'^[a-f0-9]{64}$'));
      expect(h.local.messageRevision('chat-1'), 1);
      expect(h.repository.metrics.acceptances, 1);
      final facts = await h.facts();
      expect(facts['messages'], hasLength(2));
      expect(facts['conversation_task_plans'], hasLength(1));
      expect(facts['conversation_task_events'], hasLength(1));
      expect(facts['conversation_task_progress'], hasLength(1));
      expect(facts['token_usage_records'], hasLength(1));
      expect(facts['chats']!.single['last_message'], '已记录任务');
      await h.reopen();
      final reopened = await h.task;
      expect(
        TaskAcceptanceRecord.encode(reopened.acceptance),
        TaskAcceptanceRecord.encode(saved.acceptance),
      );
      expect(reopened.createdAt, taskTime);
      expect(
        (await h.repository.getByOriginTurnId(saved.originTurnId))!.taskId,
        saved.taskId,
      );
    },
  );

  for (final (table, operation) in [
    ('conversation_tasks', 'INSERT'),
    ('conversation_task_plans', 'INSERT'),
    ('conversation_task_events', 'INSERT'),
    ('conversation_task_progress', 'INSERT'),
    ('messages', 'INSERT'),
    ('token_usage_records', 'INSERT'),
    ('chats', 'UPDATE'),
  ]) {
    test('acceptance rolls back every write when $table fails', () async {
      await seedTaskOrigin(h.database, taskFixture());
      final before = await h.facts();
      await h.failWrite(table, operation: operation);
      await expectLater(
        h.accept(seed: false),
        throwsA(isA<DatabaseException>()),
      );
      expect(await h.facts(), before);
      expect(h.local.messageRevision('chat-1'), 0);
      expect(h.repository.metrics.acceptanceFailures, 1);
      expect(h.repository.metrics.orphanAcknowledgements, 0);
      await h.clearFailure();
      committed(await h.accept(seed: false));
      final retry = await h.accept(seed: false);
      expect((retry as TaskWriteCommitted<ConversationTask>).reused, isTrue);
      expect((await h.facts())['messages'], hasLength(2));
    });
  }

  test(
    'deferred foreign-key failure rolls back before sqflite COMMIT and permits retry',
    () async {
      await seedTaskOrigin(h.database, taskFixture());
      final before = await h.facts();
      await h.database.execute(
        "CREATE TEMP TRIGGER corrupt_ack AFTER INSERT ON messages WHEN NEW.task_message_kind = 'taskAcknowledgement' "
        "BEGIN UPDATE messages SET message_id = 'wrong:ack', task_id = NULL, task_message_kind = NULL WHERE message_id = NEW.message_id; END",
      );
      await expectLater(h.accept(seed: false), throwsStateError);
      expect(await h.facts(), before);
      await h.database.execute('DROP TRIGGER corrupt_ack');
      committed(await h.accept(seed: false));
      expect(await h.database.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    },
  );

  test('cannot create a task without a saved matching user message', () async {
    await expectLater(h.accept(seed: false), throwsArgumentError);
    expect(await h.database.query('conversation_tasks'), isEmpty);
    expect(await h.database.query('messages'), isEmpty);
  });

  test(
    'same origin with a newly generated task ID returns original acceptance after restart',
    () async {
      committed(await h.accept());
      await h.reopen();
      final changedId = changeTask(taskFixture(), {
        'task_id': 'new-id',
        'ack_message_id': 'new-id:ack',
      });
      final result = await h.accept(task: changedId, seed: false);
      expect(result, isA<TaskWriteCommitted<ConversationTask>>());
      expect((result as TaskWriteCommitted<ConversationTask>).reused, isTrue);
      expect(result.value.taskId, 'task-1');
      expect(await h.database.query('messages'), hasLength(2));
      expect(h.local.messageRevision('chat-1'), 0);
    },
  );

  test(
    'concurrent identical acceptance has one commit and one idempotent reuse',
    () async {
      await seedTaskOrigin(h.database, taskFixture());
      final other = SqliteConversationTaskRepository(
        localDatabase: LocalDatabaseService(
          databaseProvider: () async => h.database,
        ),
      );
      final task = taskFixture();
      final results = await Future.wait([
        h.accept(seed: false),
        other.createWithAcknowledgement(
          task: task,
          plan: taskPlan(task),
          initialEvent: ConversationTaskEvent(
            taskId: task.taskId,
            sequence: 1,
            kind: TaskEventKind.queued,
            occurredAt: taskTime,
            safeSummary: '已记录任务',
          ),
          acknowledgement: taskMessage(task),
        ),
      ]);
      expect(
        results.whereType<TaskWriteCommitted<ConversationTask>>().where(
          (result) => result.reused,
        ),
        hasLength(1),
      );
      expect(await h.database.query('conversation_tasks'), hasLength(1));
      expect(await h.database.query('messages'), hasLength(2));
    },
  );

  test(
    'changed objective, snapshot, initial plan or acknowledgement conflict',
    () async {
      committed(await h.accept());
      final original = taskFixture();
      expect(
        await h.accept(
          task: changeTask(original, {'objective': 'different objective'}),
          seed: false,
        ),
        conflict(TaskWriteConflictReason.duplicateIdentity),
      );
      final changed = taskFixture(
        acceptance: taskAcceptance(limits: TaskSegmentLimits(maxModelTurns: 4)),
      );
      expect(
        await h.accept(task: changed, seed: false),
        conflict(TaskWriteConflictReason.duplicateIdentity),
      );
      final plan = ConversationTaskPlan(
        taskId: original.taskId,
        revision: 1,
        objective: original.objective,
        steps: [TaskPlanStep(stepId: 'other', summary: 'Other step')],
        allowedToolNames: {'read_file'},
        createdAt: taskTime,
      );
      expect(
        await h.accept(seed: false, plan: plan),
        conflict(TaskWriteConflictReason.duplicateIdentity),
      );
      expect(
        await h.accept(
          seed: false,
          acknowledgement: taskMessage(
            original,
            content: 'Other acknowledgement',
          ),
        ),
        conflict(TaskWriteConflictReason.duplicateIdentity),
      );
      expect(
        h.repository.metrics.conflicts[TaskWriteConflictReason
            .duplicateIdentity],
        4,
      );
      expect(await h.database.query('messages'), hasLength(2));
    },
  );

  test('widening initial allowed tools is rejected', () async {
    final task = taskFixture();
    final plan = ConversationTaskPlan(
      taskId: task.taskId,
      revision: 1,
      objective: task.objective,
      steps: taskPlan(task).steps,
      allowedToolNames: {'delete_file'},
      createdAt: taskTime,
    );
    await expectLater(h.accept(plan: plan), throwsArgumentError);
    expect(await h.database.query('conversation_tasks'), isEmpty);
  });

  test(
    'duplicate and skipped event sequences cannot partially advance a revision',
    () async {
      await h.start();
      final before = await h.facts();
      for (final sequence in [1, 99]) {
        final update = await h.update(
          TaskEventKind.stepStarted,
          stepId: 'read',
          sequence: sequence,
        );
        expect(
          await h.repository.appendProgress(update),
          conflict(TaskWriteConflictReason.duplicateIdentity),
        );
        expect(await h.facts(), before);
      }
    },
  );

  test(
    'stale and racing progress updates are fenced by task revision',
    () async {
      final old = await h.start();
      final first = await h.update(
        TaskEventKind.stepStarted,
        current: old,
        stepId: 'read',
      );
      final second = await h.update(
        TaskEventKind.stepCompleted,
        current: old,
        stepId: 'read',
      );
      final results = await Future.wait([
        h.repository.appendProgress(first),
        h.repository.appendProgress(second),
      ]);
      expect(
        results.whereType<TaskWriteCommitted<ConversationTask>>(),
        hasLength(1),
      );
      expect(
        results.whereType<TaskWriteConflict<ConversationTask>>().single.reason,
        TaskWriteConflictReason.revisionMismatch,
      );
      expect(
        await h.repository.appendProgress(first),
        conflict(TaskWriteConflictReason.revisionMismatch),
      );
      expect((await h.task).revision, old.revision + 1);
    },
  );

  for (final table in [
    'conversation_task_events',
    'conversation_task_progress',
    'conversation_tasks',
  ]) {
    test('progress event and projection roll back on $table failure', () async {
      await h.start();
      final before = await h.facts();
      final update = await h.update(TaskEventKind.stepStarted, stepId: 'read');
      await h.failWrite(
        table,
        operation: table == 'conversation_task_events' ? 'INSERT' : 'UPDATE',
      );
      await expectLater(
        h.repository.appendProgress(update),
        throwsA(isA<DatabaseException>()),
      );
      expect(await h.facts(), before);
      await h.clearFailure();
      committed(await h.repository.appendProgress(update));
    });
  }

  test(
    'watch emits initial committed snapshot and only successful changes across repositories',
    () async {
      committed(await h.accept());
      final values = <ConversationTaskProgressSummary>[];
      final initial = Completer<void>();
      final sub = h.repository.watchProgress('task-1').listen((value) {
        values.add(value);
        if (!initial.isCompleted) initial.complete();
      });
      addTearDown(sub.cancel);
      await initial.future;
      final other = SqliteConversationTaskRepository(
        localDatabase: LocalDatabaseService(
          databaseProvider: () async => h.database,
        ),
      );
      final old = await h.task;
      await h.failWrite('conversation_task_events');
      await expectLater(
        other.requestCancellation(
          taskId: old.taskId,
          expectedRevision: old.revision,
          source: TaskCancellationSource.user,
          requestedAt: h.nextTime,
        ),
        throwsA(isA<DatabaseException>()),
      );
      await h.clearFailure();
      committed(
        await other.requestCancellation(
          taskId: old.taskId,
          expectedRevision: old.revision,
          source: TaskCancellationSource.user,
          requestedAt: h.nextTime,
        ),
      );
      await h.repository.getProgressSummary(old.taskId);
      await Future<void>.delayed(Duration.zero);
      expect(values.map((value) => value.summaryRevision), [0, 1]);
      expect(values.last.status, ConversationTaskStatus.cancelRequested);
    },
  );

  test(
    'watch subscription racing acceptance has no lost or duplicate snapshot',
    () async {
      final values = <ConversationTaskProgressSummary>[];
      final accepted = Completer<void>();
      final sub = h.repository.watchProgress('task-1').listen((value) {
        values.add(value);
        if (!accepted.isCompleted) accepted.complete();
      });
      addTearDown(sub.cancel);
      committed(await h.accept());
      await accepted.future;
      committed(await h.accept(seed: false));
      await h.repository.getProgressSummary('task-1');
      await Future<void>.delayed(Duration.zero);
      expect(values, hasLength(1));
      expect(values.single.summaryRevision, 0);
    },
  );
}
