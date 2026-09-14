import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/models/conversation_task_record.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/models/tool_evidence_record.dart';
import 'package:stars/data/models/tool_execution_record.dart';
import 'package:stars/data/services/application_data_directory.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/domain/models/models.dart';

import '../../support/conversation_task_database.dart';
import '../../support/conversation_task_fixtures.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'creates a complete new schema and restores a task after reopening',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars_task_schema_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final databasePath = path.join(directory.path, 'tasks.db');
      var database = await openTaskDatabase(databasePath);
      final task = taskFixture(lease: taskLease());
      await seedTask(database, task);
      final checkpoint = ConversationTaskCheckpoint(
        taskId: task.taskId,
        segmentId: 'segment-1',
        planRevision: 1,
        sequence: 1,
        phase: ConversationTaskPhase.planning,
        savedAt: taskTime,
        nextStepId: 'read',
        context: task.acceptance.context,
      );
      await database.insert(
        'conversation_task_checkpoints',
        ConversationTaskCheckpointRecord.fromDomain(checkpoint).values,
      );
      await DatabaseService.verifySchema(database);
      await database.close();
      database = await openTaskDatabase(databasePath);
      addTearDown(database.close);
      await DatabaseService.verifySchema(database);
      final progress =
          TaskProgressRecord(
            (await database.query('conversation_task_progress')).single,
          ).toDomain();
      final restored = ConversationTaskRecord(
        (await database.query('conversation_tasks')).single,
      ).toDomain(progress: progress);
      expect(
        ConversationTaskRecord.fromDomain(restored).values,
        ConversationTaskRecord.fromDomain(task).values,
      );
      expect(
        ConversationTaskCheckpointRecord(
          (await database.query('conversation_task_checkpoints')).single,
        ).toDomain().nextStepId,
        'read',
      );
      expect(await database.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    },
  );

  test(
    'requires task, current plan and acknowledgement within one commit',
    () async {
      final database = await openTaskDatabase();
      addTearDown(database.close);
      final task = taskFixture();
      await seedTask(database, task);
      final origin =
          (await database.query(
            'messages',
            where: 'message_id = ?',
            whereArgs: [task.originUserMessageId],
          )).single;
      await expectLater(
        database.transaction((tx) async {
          await tx.insert('messages', {
            ...origin,
            'message_id': 'incomplete:user',
            'turn_id': 'incomplete:turn',
          });
          await tx.insert('conversation_tasks', {
            ...ConversationTaskRecord.fromDomain(task).values,
            'task_id': 'incomplete',
            'origin_turn_id': 'incomplete:turn',
            'origin_user_message_id': 'incomplete:user',
            'ack_message_id': 'incomplete:ack',
          });
          // Force the deferred-constraint failure inside the callback so sqflite
          // rolls back the still-open SQLite transaction on this fault path.
          await tx.execute('COMMIT');
        }),
        throwsA(isA<DatabaseException>()),
      );
      expect(await database.query('conversation_tasks'), hasLength(1));
    },
  );

  test(
    'task origin identity cannot create a second task or acknowledgement',
    () async {
      final database = await openTaskDatabase();
      addTearDown(database.close);
      final task = taskFixture();
      await seedTask(database, task);
      await expectLater(
        database.insert('conversation_tasks', {
          ...ConversationTaskRecord.fromDomain(task).values,
          'task_id': 'task-2',
          'ack_message_id': 'task-2:ack',
          'origin_user_message_id': 'other:user',
        }),
        throwsA(isA<DatabaseException>()),
      );
      final ack =
          (await database.query(
            'messages',
            where: 'task_message_kind = ?',
            whereArgs: ['taskAcknowledgement'],
          )).single;
      await expectLater(
        database.insert('messages', ack),
        throwsA(isA<DatabaseException>()),
      );
      expect(await database.query('conversation_tasks'), hasLength(1));
    },
  );

  test(
    'rejects illegal lifecycle, incomplete waits, leases and premature terminal states',
    () async {
      final database = await openTaskDatabase();
      addTearDown(database.close);
      await seedTask(database, taskFixture());
      for (final changes in <Map<String, Object?>>[
        {'status': 'timedOut'},
        {'status': 'waitingForUser'},
        {'revision': -1},
        {'status': 'succeeded'},
        {'status': 'cancelRequested'},
        {'status': 'running'},
        {'lease_token': 'token'},
        {'lease_owner_id': 'runner'},
        {
          'lease_token': 'token',
          'lease_owner_id': 'runner',
          'lease_acquired_at': 2,
          'lease_expires_at': 1,
        },
        {'acceptance_json': 'invalid json'},
      ]) {
        await expectLater(
          database.update('conversation_tasks', changes),
          throwsA(isA<DatabaseException>()),
          reason: '$changes',
        );
      }
    },
  );

  test(
    'accepted input, policies and cancellation intent cannot be overwritten',
    () async {
      final database = await openTaskDatabase();
      addTearDown(database.close);
      final task = taskFixture();
      await seedTask(database, task);
      for (final change in <Map<String, Object?>>[
        {'objective': 'different request'},
        {'origin_turn_id': 'other'},
        {'acceptance_json': '{}'},
        {'created_at': 0},
      ]) {
        await expectLater(
          database.update('conversation_tasks', change),
          throwsA(isA<DatabaseException>()),
        );
      }
      final cancelling = task.transitionTo(
        ConversationTaskStatus.cancelRequested,
        at: taskTime,
        cancellationSource: TaskCancellationSource.user,
      );
      await database.update(
        'conversation_tasks',
        ConversationTaskRecord.fromDomain(cancelling).values,
      );
      await expectLater(
        database.update('conversation_tasks', {
          'status': 'queued',
          'cancellation_source': null,
          'cancel_requested_at': null,
        }),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test(
    'a terminal result cannot be replaced by another lifecycle or outcome',
    () async {
      final database = await openTaskDatabase();
      addTearDown(database.close);
      final task = taskFixture();
      await seedTask(database, task);
      final running = task.transitionTo(
        ConversationTaskStatus.running,
        at: taskTime,
        lease: taskLease(),
      );
      await database.update(
        'conversation_tasks',
        ConversationTaskRecord.fromDomain(running).values,
      );
      final terminal = running.transitionTo(
        ConversationTaskStatus.succeeded,
        at: taskTime.add(const Duration(microseconds: 1)),
        phase: ConversationTaskPhase.committing,
      );
      await database.transaction((tx) async {
        await tx.insert(
          'messages',
          MessageRecord.fromDomain(
            Message(
              messageId: terminal.resultMessageId!,
              turnId: task.originTurnId,
              chatId: task.chatId,
              botId: task.botId,
              senderId: 'assistant',
              taskId: task.taskId,
              taskMessageKind: TaskMessageKind.result,
              terminalOutcome: MessageTerminalOutcome.completed,
              content: '报告完成',
              timestamp: taskTime,
            ),
          ).values,
        );
        await tx.update(
          'conversation_tasks',
          ConversationTaskRecord.fromDomain(terminal).values,
        );
      });
      await expectLater(
        database.update(
          'conversation_tasks',
          ConversationTaskRecord.fromDomain(task).values,
        ),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        database.insert(
          'conversation_tasks',
          ConversationTaskRecord.fromDomain(task).values,
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        (await database.query('conversation_tasks')).single['status'],
        'succeeded',
      );
      expect(
        await database.query(
          'messages',
          where: 'task_message_kind = ?',
          whereArgs: ['taskResult'],
        ),
        hasLength(1),
      );
    },
  );

  test(
    'task events and versioned plans cannot be updated or replaced',
    () async {
      final database = await openTaskDatabase();
      addTearDown(database.close);
      await seedTask(database, taskFixture());
      for (final table in [
        'conversation_task_events',
        'conversation_task_plans',
      ]) {
        final row = (await database.query(table)).single;
        await expectLater(
          database.update(table, row),
          throwsA(isA<DatabaseException>()),
        );
        await expectLater(
          database.delete(table),
          throwsA(isA<DatabaseException>()),
        );
        await expectLater(
          database.insert(
            table,
            row,
            conflictAlgorithm: ConflictAlgorithm.replace,
          ),
          throwsA(isA<DatabaseException>()),
        );
      }
    },
  );

  test(
    'long-lived approval decisions require a complete actor and time',
    () async {
      final database = await openTaskDatabase();
      addTearDown(database.close);
      final task = taskFixture();
      await seedTask(database, task);
      final request = TaskApprovalDbRecord.fromDomain(
        TaskApprovalRecord(
          approvalId: 'approval-1',
          taskId: task.taskId,
          requestRevision: 0,
          safeActionSummary: '保存报告',
          requestedAt: taskTime,
        ),
      );
      await database.insert('conversation_task_approvals', request.values);
      await expectLater(
        database.update('conversation_task_approvals', {
          'decision': 'approved',
        }),
        throwsA(isA<DatabaseException>()),
      );
      await database.update('conversation_task_approvals', {
        'decision': 'approved',
        'decided_by': 'user-1',
        'decided_at':
            taskTime.add(const Duration(days: 2)).microsecondsSinceEpoch,
      });
      final restored =
          TaskApprovalDbRecord(
            (await database.query('conversation_task_approvals')).single,
          ).toDomain();
      expect(restored.decision, TaskApprovalDecision.approved);
      expect(
        restored.decidedAt!.difference(restored.requestedAt),
        const Duration(days: 2),
      );
    },
  );

  test(
    'attempt keys support audited retries and immutable task/segment ownership',
    () async {
      final database = await openTaskDatabase();
      addTearDown(database.close);
      final task = taskFixture();
      await seedTask(database, task);
      final other = taskFixture(id: 'task-2');
      await seedTask(database, other);
      await _insertAttempt(database, task, 'attempt-1');
      await _insertAttempt(database, task, 'attempt-2');
      final link =
          TaskToolAttemptLinkRecord.fromDomain(
            TaskToolAttemptLink(
              taskId: task.taskId,
              segmentId: 'segment-1',
              attemptId: 'attempt-1',
              idempotencyKey: 'operation-1',
              attemptNumber: 1,
            ),
          ).values;
      await database.insert('conversation_task_tool_attempts', link);
      await expectLater(
        database.insert('conversation_task_tool_attempts', {
          ...link,
          'attempt_id': 'attempt-2',
        }),
        throwsA(isA<DatabaseException>()),
      );
      await database.insert('conversation_task_tool_attempts', {
        ...link,
        'attempt_id': 'attempt-2',
        'attempt_number': 2,
        'segment_id': 'segment-2',
      });
      await expectLater(
        database.update('conversation_task_tool_attempts', {
          'task_id': other.taskId,
        }),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        database.insert(
          'conversation_task_tool_attempts',
          link,
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
        throwsA(isA<DatabaseException>()),
      );
      await _insertAttempt(database, task, 'attempt-3');
      await expectLater(
        database.insert('conversation_task_tool_attempts', {
          ...link,
          'task_id': other.taskId,
          'attempt_id': 'attempt-3',
        }),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        await database.query('conversation_task_tool_attempts'),
        hasLength(2),
      );
    },
  );

  test(
    'evidence links reject cross-task or cross-segment attribution',
    () async {
      final database = await openTaskDatabase();
      addTearDown(database.close);
      final task = taskFixture();
      await seedTask(database, task);
      final other = taskFixture(id: 'task-2');
      await seedTask(database, other);
      await _insertAttempt(database, task, 'attempt-1');
      await database.insert(
        'conversation_task_tool_attempts',
        TaskToolAttemptLinkRecord.fromDomain(
          TaskToolAttemptLink(
            taskId: task.taskId,
            segmentId: 'segment-1',
            attemptId: 'attempt-1',
            idempotencyKey: 'operation-1',
            attemptNumber: 1,
          ),
        ).values,
      );
      final evidence = ToolEvidenceRecord(
        evidenceId: 'attempt-1:evidence',
        runId: 'segment-1',
        turnId: task.originTurnId,
        chatId: task.chatId,
        invocationId: 'invocation-1',
        attemptId: 'attempt-1',
        toolName: 'read_file',
        toolVersion: '1',
        source: ToolSource.builtIn,
        capabilities: {ToolCapability.externalRead},
        terminalStatus: ToolInvocationStatus.succeeded,
        evidenceKind: EvidenceKind.observation,
        subject: 'source',
        scope: {'resource_id': 'source'},
        resultSummary: '读取完成',
        argumentsDigest: 'a' * 64,
        resultDigest: 'b' * 64,
        structuredFacts: [StructuredFact(name: 'file.exists', value: true)],
        observedAt: taskTime,
        validUntil: taskTime.add(const Duration(minutes: 5)),
      );
      await database.insert(
        'tool_evidence_records',
        ToolEvidenceDbRecord.fromDomain(evidence).values,
      );
      final link =
          TaskEvidenceLinkRecord.fromDomain(
            TaskEvidenceLink(
              taskId: task.taskId,
              segmentId: 'segment-1',
              attemptId: 'attempt-1',
              evidenceId: evidence.evidenceId,
            ),
          ).values;
      await expectLater(
        database.insert('conversation_task_evidence_links', {
          ...link,
          'task_id': other.taskId,
        }),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        database.insert('conversation_task_evidence_links', {
          ...link,
          'segment_id': 'segment-2',
        }),
        throwsA(isA<DatabaseException>()),
      );
      await database.insert('conversation_task_evidence_links', link);
      await expectLater(
        database.update('conversation_task_evidence_links', {
          'task_id': other.taskId,
        }),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        database.insert(
          'conversation_task_evidence_links',
          link,
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test(
    'schema verifier refuses a current database with missing task fields',
    () async {
      final database = await openTaskDatabase();
      addTearDown(database.close);
      await database.execute(
        'ALTER TABLE conversation_task_checkpoints DROP COLUMN checkpoint_json',
      );
      await expectLater(
        DatabaseService.verifySchema(database),
        throwsFormatException,
      );
    },
  );

  test(
    'old database version is rejected without changing data or chat assets',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars_task_old_version_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final root = path.join(directory.path, starsApplicationDataDirectoryName);
      final asset = File(path.join(root, 'chats', 'saved', 'artifact.txt'));
      await asset.parent.create(recursive: true);
      await asset.writeAsString('preserve');
      final databasePath = path.join(root, 'app.db');
      // A version sentinel, not a legacy migration fixture or upgraded database.
      final old = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: DatabaseService.databaseVersion - 1,
          onCreate:
              (db, _) => db.execute('CREATE TABLE preserved (value TEXT)'),
        ),
      );
      await old.insert('preserved', {'value': 'original'});
      await old.close();
      final service = DatabaseService(
        applicationDocumentsDirectoryProvider: () async => directory,
      );
      await expectLater(
        service.initDatabase(),
        throwsA(
          isA<AppFailure>().having(
            (error) => error.code,
            'code',
            'database_rebuild_required',
          ),
        ),
      );
      final unchanged = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      addTearDown(unchanged.close);
      expect(await unchanged.getVersion(), DatabaseService.databaseVersion - 1);
      expect((await unchanged.query('preserved')).single['value'], 'original');
      expect(await asset.readAsString(), 'preserve');
    },
  );
}

Future<void> _insertAttempt(
  Database database,
  ConversationTask task,
  String id,
) => database.insert(
  'tool_execution_records',
  ToolExecutionDbRecord.fromDomain(
    ToolExecutionRecord(
      executionId: id,
      attemptId: id,
      invocationId: 'invocation-1',
      providerCallId: 'provider-call',
      runId: 'segment-1',
      turnId: task.originTurnId,
      messageId: task.ackMessageId,
      chatId: task.chatId,
      botId: task.botId,
      callId: 'provider-call',
      name: 'read_file',
      source: ToolSource.builtIn,
      riskLevel: ToolRiskLevel.readOnly,
      status: ToolInvocationStatus.requested,
      startedAt: taskTime,
      updatedAt: taskTime,
    ),
  ).values,
);
