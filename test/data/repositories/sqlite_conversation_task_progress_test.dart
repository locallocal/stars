import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/models/conversation_task_record.dart';
import 'package:stars/data/repositories/sqlite_tool_evidence_repository.dart';
import 'package:stars/data/repositories/sqlite_tool_execution_repository.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_execution_state.dart';
import 'package:stars/domain/models/task_file_read_observation.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';

import '../../support/conversation_task_repository_harness.dart';

void main() {
  late TaskRepositoryHarness h;
  setUp(() async {
    h = TaskRepositoryHarness();
    await h.open();
  });
  tearDown(() => h.close());

  Future<DateTime> beginTool({String id = 'attempt-1', int number = 1}) async {
    final started = h.nextTime;
    committed(
      await h.repository.appendProgress(
        await h.update(
          number == 1 ? TaskEventKind.toolStarted : TaskEventKind.toolRetry,
          tool: taskTool(at: started, attemptId: id),
          attemptLink: taskAttempt(id: id, number: number),
          segmentId: 'segment-1',
        ),
      ),
    );
    return started;
  }

  Future<void> finishTool(
    DateTime started, {
    String id = 'attempt-1',
    ToolInvocationStatus status = ToolInvocationStatus.succeeded,
  }) async {
    committed(
      await h.repository.appendProgress(
        await h.update(
          status == ToolInvocationStatus.succeeded
              ? TaskEventKind.toolSucceeded
              : TaskEventKind.toolFailed,
          tool: taskTool(
            at: h.nextTime,
            startedAt: started,
            attemptId: id,
            status: status,
            summary: 'Result recorded.',
          ),
          segmentId: 'segment-1',
        ),
      ),
    );
  }

  ToolEvidenceRecord evidence({
    String id = 'attempt-1',
    String chatId = 'chat-1',
  }) => ToolEvidenceRecord(
    evidenceId: '$id:evidence',
    runId: 'segment-1',
    turnId: 'task-1:turn',
    chatId: chatId,
    invocationId: 'invocation-1',
    attemptId: id,
    providerCallId: 'call-1',
    toolName: 'read_file',
    toolVersion: '1',
    source: ToolSource.builtIn,
    terminalStatus: ToolInvocationStatus.succeeded,
    evidenceKind: EvidenceKind.observation,
    capabilities: {ToolCapability.localRead},
    subject: 'report',
    scope: {'document': 'report'},
    structuredFacts: [StructuredFact(name: 'read', value: true)],
    resultSummary: 'Report read.',
    argumentsDigest: 'a' * 64,
    resultDigest: 'b' * 64,
    observedAt: h.nextTime,
  );

  test(
    'tool begin, failure and retry preserve separate attempts across database reopen',
    () async {
      await h.start();
      final started = await beginTool();
      var task = await h.task;
      expect(task.progress.toolAttempts, 1);
      expect(task.progress.latestTool!.status, ToolInvocationStatus.running);
      await h.reopen();
      expect((await h.task).progress.latestTool!.attemptId, 'attempt-1');
      await finishTool(started, status: ToolInvocationStatus.timedOut);
      final failedRows = await h.database.query('tool_execution_records');
      expect(failedRows.single['status'], 'timedOut');
      final retried = await beginTool(id: 'attempt-2', number: 2);
      await finishTool(retried, id: 'attempt-2');
      await h.reopen();
      task = await h.task;
      expect(task.progress.toolAttempts, 2);
      expect(task.progress.latestTool!.status, ToolInvocationStatus.succeeded);
      final rows = await h.database.query(
        'tool_execution_records',
        orderBy: 'attempt_id',
      );
      expect(rows.first, failedRows.single);
      expect(rows.last['duration_ms'], 1000);
      final links = await h.database.query(
        'conversation_task_tool_attempts',
        orderBy: 'attempt_number',
      );
      expect(links.map((row) => row['idempotency_key']).toSet(), {
        'read-report',
      });
      expect(links.map((row) => row['attempt_number']), [1, 2]);
      final before = await h.facts();
      final replay = await h.update(
        TaskEventKind.toolStarted,
        tool: taskTool(at: h.nextTime, startedAt: started),
        segmentId: 'segment-1',
      );
      expect(
        await h.repository.appendProgress(replay),
        conflict(TaskWriteConflictReason.duplicateIdentity),
      );
      expect(await h.facts(), before);
    },
  );

  test(
    'tool lifecycle cannot finish without a start or overwrite its terminal state',
    () async {
      await h.start();
      final missing = await h.update(
        TaskEventKind.toolSucceeded,
        tool: taskTool(at: h.nextTime, status: ToolInvocationStatus.succeeded),
        segmentId: 'segment-1',
      );
      await expectLater(
        h.repository.appendProgress(missing),
        throwsArgumentError,
      );
      final started = await beginTool();
      await finishTool(started);
      final generic = SqliteToolExecutionRepository(localDatabase: h.local);
      await expectLater(
        generic.upsert(
          taskTool(
            at: h.nextTime,
            startedAt: started,
            status: ToolInvocationStatus.failed,
          ),
        ),
        throwsStateError,
      );
      expect(
        (await h.database.query('tool_execution_records')).single['status'],
        'succeeded',
      );
      final retry = await h.update(
        TaskEventKind.toolRetry,
        tool: taskTool(at: h.nextTime, attemptId: 'attempt-2'),
        attemptLink: taskAttempt(id: 'attempt-2', number: 2),
        segmentId: 'segment-1',
      );
      expect(
        await h.repository.appendProgress(retry),
        conflict(TaskWriteConflictReason.duplicateIdentity),
      );
    },
  );

  for (final table in [
    'tool_execution_records',
    'conversation_task_tool_attempts',
    'conversation_task_events',
    'conversation_task_progress',
  ]) {
    test('tool start and progress roll back when $table fails', () async {
      await h.start();
      final before = await h.facts();
      await h.failWrite(
        table,
        operation: table == 'conversation_task_progress' ? 'UPDATE' : 'INSERT',
      );
      await expectLater(beginTool(), throwsA(isA<DatabaseException>()));
      expect(await h.facts(), before);
    });
  }

  test('tool scope and idempotency cannot be rebound', () async {
    await h.start();
    await beginTool();
    final before = await h.facts();
    final update = await h.update(
      TaskEventKind.toolStarted,
      tool: taskTool(at: h.nextTime, attemptId: 'attempt-2'),
      attemptLink: taskAttempt(id: 'attempt-2'),
      segmentId: 'segment-1',
    );
    expect(
      await h.repository.appendProgress(update),
      conflict(TaskWriteConflictReason.duplicateIdentity),
    );
    final outsideTools = await h.update(
      TaskEventKind.toolStarted,
      tool: taskTool(
        at: h.nextTime,
        attemptId: 'attempt-2',
        name: 'delete_file',
      ),
      attemptLink: taskAttempt(id: 'attempt-2', key: 'delete-report'),
      segmentId: 'segment-1',
    );
    await expectLater(
      h.repository.appendProgress(outsideTools),
      throwsArgumentError,
    );
    expect(await h.facts(), before);
  });

  test(
    'evidence links and terminal tool facts commit with progress in one transaction',
    () async {
      await h.start();
      final started = await beginTool();
      final item = evidence();
      final update = await h.update(
        TaskEventKind.toolSucceeded,
        tool: taskTool(
          at: h.nextTime,
          startedAt: started,
          status: ToolInvocationStatus.succeeded,
        ),
        segmentId: 'segment-1',
        evidence: item,
        evidenceLink: TaskEvidenceLink(
          taskId: 'task-1',
          segmentId: 'segment-1',
          attemptId: 'attempt-1',
          evidenceId: item.evidenceId,
        ),
      );
      committed(await h.repository.appendProgress(update));
      await h.reopen();
      final repository = SqliteToolEvidenceRepository(localDatabase: h.local);
      expect(await repository.verifyDigest(item.evidenceId), isTrue);
      expect((await repository.getById(item.evidenceId))!.persisted, isTrue);
      expect(
        (await h.task).progress.latestTool!.status,
        ToolInvocationStatus.succeeded,
      );
      committed(
        await h.repository.appendProgress(
          await h.update(
            TaskEventKind.evidenceAccepted,
            evidenceId: item.evidenceId,
            segmentId: 'segment-2',
          ),
        ),
      );
      expect((await h.task).progress.segments, 2);
    },
  );

  for (final table in [
    'tool_evidence_records',
    'conversation_task_evidence_links',
    'conversation_task_events',
    'conversation_task_progress',
  ]) {
    test('evidence and tool completion roll back when $table fails', () async {
      await h.start();
      final started = await beginTool();
      final before = await h.facts();
      final item = evidence();
      final update = await h.update(
        TaskEventKind.toolSucceeded,
        tool: taskTool(
          at: h.nextTime,
          startedAt: started,
          status: ToolInvocationStatus.succeeded,
        ),
        segmentId: 'segment-1',
        evidence: item,
        evidenceLink: TaskEvidenceLink(
          taskId: 'task-1',
          segmentId: 'segment-1',
          attemptId: 'attempt-1',
          evidenceId: item.evidenceId,
        ),
      );
      await h.failWrite(
        table,
        operation: table == 'conversation_task_progress' ? 'UPDATE' : 'INSERT',
      );
      await expectLater(
        h.repository.appendProgress(update),
        throwsA(isA<DatabaseException>()),
      );
      expect(await h.facts(), before);
    });
  }

  test(
    'unknown evidence and checkpoint attempts are rejected without writes',
    () async {
      await h.start();
      final before = await h.facts();
      final badEvidence = await h.update(
        TaskEventKind.evidenceAccepted,
        evidenceId: 'foreign:evidence',
      );
      await expectLater(
        h.repository.appendProgress(badEvidence),
        throwsArgumentError,
      );
      final checkpoint = ConversationTaskCheckpoint(
        taskId: 'task-1',
        segmentId: 'segment-1',
        planRevision: 1,
        sequence: 3,
        phase: ConversationTaskPhase.planning,
        savedAt: h.nextTime,
        pendingAttemptIds: ['foreign-attempt'],
      );
      final badCheckpoint = await h.update(
        TaskEventKind.paused,
        status: ConversationTaskStatus.paused,
        checkpoint: checkpoint,
        segmentId: 'segment-1',
      );
      await expectLater(
        h.repository.appendProgress(badCheckpoint),
        throwsArgumentError,
      );
      expect(await h.facts(), before);
    },
  );

  test(
    'checkpoints and external job handles survive reopening and roll back with their event',
    () async {
      await h.start();
      await beginTool();
      final checkpoint = ConversationTaskCheckpoint(
        taskId: 'task-1',
        segmentId: 'segment-1',
        planRevision: 1,
        sequence: 4,
        phase: ConversationTaskPhase.observing,
        savedAt: h.nextTime,
        nextStepId: 'write',
        completedStepIds: ['read'],
        pendingAttemptIds: ['attempt-1'],
        evidenceCursor: 0,
        externalJobs: [
          TaskExternalJob(
            attemptId: 'attempt-1',
            externalJobId: 'job-1',
            resumeHandle: 'handle:job-1',
            safeStatus: 'pending',
            nextPollAt: h.nextTime.add(const Duration(minutes: 1)),
          ),
        ],
      );
      final update = await h.update(
        TaskEventKind.externalJobUpdated,
        status: ConversationTaskStatus.paused,
        phase: ConversationTaskPhase.observing,
        segmentId: 'segment-1',
        attemptId: 'attempt-1',
        checkpoint: checkpoint,
      );
      final before = await h.facts();
      await h.failWrite('conversation_task_events');
      await expectLater(
        h.repository.appendProgress(update),
        throwsA(isA<DatabaseException>()),
      );
      expect(await h.facts(), before);
      await h.clearFailure();
      committed(await h.repository.appendProgress(update));
      await h.reopen();
      final saved = (await h.repository.getCheckpoint('task-1', 1))!;
      expect(
        ConversationTaskCheckpointRecord.fromDomain(saved).values,
        ConversationTaskCheckpointRecord.fromDomain(checkpoint).values,
      );
      expect((await h.task).progress.completedSteps, 1);
      expect((await h.task).progress.currentStepSummary, '整理报告');
    },
  );

  test(
    'projection rebuild matches all normal writes after plan revision, retry, approval and verification',
    () async {
      await h.start();
      committed(
        await h.advance(
          TaskEventKind.stepCompleted,
          stepId: 'read',
          segmentId: 'segment-1',
          modelTurns: 2,
        ),
      );
      final first = await beginTool();
      await finishTool(first, status: ToolInvocationStatus.failed);
      final second = await beginTool(id: 'attempt-2', number: 2);
      await finishTool(second, id: 'attempt-2');
      var task = await h.task;
      final plan = ConversationTaskPlan(
        taskId: task.taskId,
        revision: 2,
        objective: task.objective,
        steps: [
          TaskPlanStep(
            stepId: 'read',
            summary: '读取资料',
            status: TaskPlanStepStatus.completed,
          ),
          TaskPlanStep(stepId: 'write', summary: '整理报告'),
          TaskPlanStep(stepId: 'check', summary: '检查报告'),
        ],
        allowedToolNames: {'read_file'},
        createdAt: h.nextTime,
      );
      committed(
        await h.repository.appendProgress(
          await h.update(TaskEventKind.planRevised, plan: plan),
        ),
      );
      task = await h.task;
      committed(
        await h.repository.appendProgress(
          await h.update(
            TaskEventKind.approvalRequested,
            status: ConversationTaskStatus.waitingForUser,
            waitingReason: TaskWaitingReason.approval,
            approval: TaskApprovalRecord(
              approvalId: 'approval-1',
              taskId: task.taskId,
              requestRevision: task.revision + 1,
              safeActionSummary: '继续整理报告',
              requestedAt: h.nextTime,
            ),
          ),
        ),
      );
      task = await h.task;
      committed(
        await h.repository.decideApproval(
          taskId: task.taskId,
          approvalId: 'approval-1',
          expectedRevision: task.revision,
          decision: TaskApprovalDecision.approved,
          actorId: 'user',
          decidedAt: h.nextTime,
        ),
      );
      h.time = h.nextTime;
      task = await h.task;
      final lease = TaskLease(
        taskId: task.taskId,
        ownerId: 'runner-2',
        token: 'lease-2',
        acquiredAt: h.time,
        expiresAt: h.time.add(const Duration(minutes: 1)),
      );
      committed(
        await h.repository.tryAcquireLease(
          taskId: task.taskId,
          expectedRevision: task.revision,
          lease: lease,
          now: h.time,
        ),
      );
      committed(
        await h.advance(
          TaskEventKind.resumed,
          status: ConversationTaskStatus.running,
          segmentId: 'segment-2',
        ),
      );
      committed(
        await h.advance(TaskEventKind.processRecovered, segmentId: 'segment-2'),
      );
      committed(
        await h.advance(
          TaskEventKind.stepStarted,
          stepId: 'write',
          modelTurns: 1,
        ),
      );
      committed(
        await h.advance(
          TaskEventKind.verificationStarted,
          phase: ConversationTaskPhase.verifying,
        ),
      );
      committed(
        await h.advance(
          TaskEventKind.verificationCompleted,
          verificationStatus: TaskVerificationStatus.partial,
        ),
      );
      final beforeNoProgress = (await h.task).progress;
      committed(
        await h.advance(TaskEventKind.noProgress, segmentId: 'segment-2'),
      );
      final summary = (await h.repository.getProgressSummary('task-1'))!;
      expect(summary.planRevision, 2);
      expect(summary.progress.totalSteps, 3);
      expect(summary.progress.completedSteps, 1);
      expect(summary.progress.modelTurns, 3);
      expect(summary.progress.toolAttempts, 2);
      expect(summary.progress.recoveries, 1);
      expect(summary.progress.segments, 2);
      expect(summary.progress.noProgressSegments, 1);
      expect(summary.progress.pendingApprovalId, isNull);
      expect(
        summary.progress.verificationStatus,
        TaskVerificationStatus.partial,
      );
      expect(
        summary.progress.lastMeaningfulProgressAt,
        beforeNoProgress.lastMeaningfulProgressAt,
      );
      expect(summary.progress.summaryHash, beforeNoProgress.summaryHash);
      final projection =
          (await h.database.query('conversation_task_progress')).single;
      await h.database.update('conversation_task_progress', {
        'summary_revision': 999,
        'progress_json': '{}',
      });
      await h.reopen();
      final rebuilt = (await h.repository.rebuildProgress('task-1'))!;
      expect(rebuilt.summaryRevision, summary.summaryRevision);
      expect(
        (await h.database.query('conversation_task_progress')).single,
        projection,
      );
      await h.database.delete('conversation_task_progress');
      expect(
        (await h.repository.getProgressSummary('task-1'))!.progress.modelTurns,
        3,
      );
      await h.repository.rebuildProgress('task-1');
      expect(
        (await h.database.query('conversation_task_progress')).single,
        projection,
      );
      expect(await h.repository.rebuildProgress('missing-task'), isNull);
    },
  );

  test(
    'summary counters ignore caller projection and stay consistent while writes race reads',
    () async {
      await h.start();
      final first = await h.update(
        TaskEventKind.stepCompleted,
        stepId: 'read',
        modelTurns: 1,
      );
      final reads = List.generate(
        15,
        (_) => h.repository.getProgressSummary('task-1'),
      );
      final write = h.repository.appendProgress(first);
      final moreReads = List.generate(
        15,
        (_) => h.repository.getProgressSummary('task-1'),
      );
      committed(await write);
      final summaries = await Future.wait([...reads, ...moreReads]);
      for (final summary in summaries) {
        expect(summary!.summaryRevision, anyOf(2, 3));
        expect(
          summary.progress.completedSteps,
          summary.summaryRevision == 2 ? 0 : 1,
        );
        expect(
          summary.progress.modelTurns,
          summary.summaryRevision == 2 ? 0 : 1,
        );
      }
    },
  );

  test(
    'caller-supplied counters cannot invent completed steps or model calls',
    () async {
      await h.start();
      final update = await h.update(TaskEventKind.stepStarted, stepId: 'read');
      final invented = ConversationTaskRecord.fromDomain(update.task).toDomain(
        progress: TaskProgress(
          totalSteps: 2,
          completedSteps: 2,
          modelTurns: 999,
          toolAttempts: 999,
          lastMeaningfulProgressAt: update.now,
        ),
      );
      final saved = committed(
        await h.repository.appendProgress(
          ConversationTaskProgressUpdate(
            task: invented,
            event: update.event,
            expectedRevision: update.expectedRevision,
            lease: update.lease,
            now: update.now,
          ),
        ),
      );
      expect(saved.progress.completedSteps, 0);
      expect(saved.progress.modelTurns, 0);
      expect(saved.progress.toolAttempts, 0);
    },
  );

  test(
    'later segments finish the original tool attempt without rebinding its ownership',
    () async {
      await h.start();
      final started = await beginTool();
      committed(
        await h.repository.appendProgress(
          await h.update(
            TaskEventKind.toolSucceeded,
            tool: taskTool(
              at: h.nextTime,
              startedAt: started,
              status: ToolInvocationStatus.succeeded,
            ),
            segmentId: 'segment-2',
          ),
        ),
      );
      expect(
        (await h.database.query(
          'conversation_task_tool_attempts',
        )).single['segment_id'],
        'segment-1',
      );
      expect((await h.task).progress.toolAttempts, 1);
      expect((await h.task).progress.segments, 2);
    },
  );

  test(
    'a checkpoint cannot erase earlier checkpoint completion facts',
    () async {
      await h.start();
      committed(
        await h.repository.appendProgress(
          await h.update(
            TaskEventKind.stepStarted,
            stepId: 'write',
            segmentId: 'segment-1',
            checkpoint: ConversationTaskCheckpoint(
              taskId: 'task-1',
              segmentId: 'segment-1',
              planRevision: 1,
              sequence: 3,
              phase: ConversationTaskPhase.planning,
              savedAt: h.nextTime,
              completedStepIds: ['read'],
              nextStepId: 'write',
            ),
          ),
        ),
      );
      final before = await h.facts();
      final forgetting = await h.update(
        TaskEventKind.noProgress,
        segmentId: 'segment-1',
        checkpoint: ConversationTaskCheckpoint(
          taskId: 'task-1',
          segmentId: 'segment-1',
          planRevision: 1,
          sequence: 4,
          phase: ConversationTaskPhase.planning,
          savedAt: h.nextTime,
        ),
      );
      await expectLater(
        h.repository.appendProgress(forgetting),
        throwsArgumentError,
      );
      expect(await h.facts(), before);
      expect(
        (await h.repository.rebuildProgress('task-1'))!.progress.completedSteps,
        1,
      );
    },
  );

  test(
    'tool waiting for approval cannot run or report success before the decision is saved',
    () async {
      await h.start();
      final started = h.nextTime;
      committed(
        await h.repository.appendProgress(
          await h.update(
            TaskEventKind.toolQueued,
            tool: taskTool(
              at: started,
              status: ToolInvocationStatus.awaitingApproval,
            ),
            attemptLink: taskAttempt(),
            segmentId: 'segment-1',
          ),
        ),
      );
      final task = await h.task;
      committed(
        await h.repository.appendProgress(
          await h.update(
            TaskEventKind.approvalRequested,
            status: ConversationTaskStatus.waitingForUser,
            waitingReason: TaskWaitingReason.approval,
            approval: TaskApprovalRecord(
              approvalId: 'approval-1',
              taskId: task.taskId,
              attemptId: 'attempt-1',
              requestRevision: task.revision + 1,
              safeActionSummary: 'Read the report.',
              requestedAt: h.nextTime,
            ),
          ),
        ),
      );
      final before = await h.facts();
      for (final status in [
        ToolInvocationStatus.running,
        ToolInvocationStatus.succeeded,
      ]) {
        final update = await h.update(
          status == ToolInvocationStatus.running
              ? TaskEventKind.toolStarted
              : TaskEventKind.toolSucceeded,
          tool: taskTool(at: h.nextTime, startedAt: started, status: status),
          segmentId: 'segment-2',
        );
        await expectLater(
          h.repository.appendProgress(update),
          throwsArgumentError,
        );
        expect(await h.facts(), before);
      }
    },
  );

  test(
    'execution arguments survive restart while progress excludes credentials and stack traces',
    () async {
      await h.start();
      final started = h.nextTime;
      committed(
        await h.repository.appendProgress(
          await h.update(
            TaskEventKind.toolStarted,
            tool: taskTool(
              at: started,
              arguments: '{"path":"private.txt","api_key":"private-key"}',
            ),
            attemptLink: taskAttempt(),
            segmentId: 'segment-1',
            safeSummary:
                'Read report. password=private-password\n#0 privateStack (file.dart:1)',
          ),
        ),
      );
      committed(
        await h.repository.appendProgress(
          await h.update(
            TaskEventKind.toolSucceeded,
            tool: taskTool(
              at: h.nextTime,
              startedAt: started,
              status: ToolInvocationStatus.succeeded,
              summary:
                  'Report read. Authorization: Bearer private-token\n#1 secretStack (file.dart:2)',
            ),
            segmentId: 'segment-1',
          ),
        ),
      );
      await h.reopen();
      final summary = (await h.repository.getProgressSummary('task-1'))!;
      final rows = jsonEncode(await h.facts());
      for (final secret in [
        'private-key',
        'private-password',
        'private-token',
        'privateStack',
        'secretStack',
      ]) {
        expect(rows, isNot(contains(secret)));
        expect(
          summary.progress.latestTool!.safeSummary,
          isNot(contains(secret)),
        );
      }
      expect(
        (await h.database.query(
          'tool_execution_records',
        )).single['arguments_summary'],
        '{"path":"private.txt","api_key":"[redacted]"}',
      );
      final projection =
          (await h.database.query('conversation_task_progress')).single;
      await h.repository.rebuildProgress('task-1');
      expect(
        (await h.database.query('conversation_task_progress')).single,
        projection,
      );
    },
  );

  for (final attempt in ['missing-attempt', 'attempt-1']) {
    test('file pages cannot borrow an unqualified attempt: $attempt', () async {
      await h.start();
      final started = await beginTool();
      // This succeeds under read_file, not the audited read_local_file tool.
      await finishTool(started);
      final before = await h.facts();
      final update = await h.update(
        TaskEventKind.segmentCheckpoint,
        segmentId: 'segment-1',
        checkpoint: ConversationTaskCheckpoint(
          taskId: 'task-1',
          segmentId: 'segment-1',
          planRevision: 1,
          sequence: 5,
          phase: ConversationTaskPhase.planning,
          savedAt: h.nextTime,
          execution: TaskExecutionState(
            fileReads: [
              TaskFileReadObservation(
                attemptId: attempt,
                stepId: 'read',
                requestedPath: '/report.md',
                path: '/report.md',
                encoding: 'utf8',
                content: 'Forged content',
                offsetBytes: 0,
                nextOffsetBytes: 14,
                sizeBytes: 14,
                maxBytes: 65536,
                redacted: false,
              ),
            ],
          ),
        ),
      );
      await expectLater(
        h.repository.appendProgress(update),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'reason',
            'File observations require a successful task read.',
          ),
        ),
      );
      expect(await h.facts(), before);
    });
  }
}
