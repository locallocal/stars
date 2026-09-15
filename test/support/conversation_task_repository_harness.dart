import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/models/conversation_task_record.dart';
import 'package:stars/data/repositories/sqlite_conversation_task_repository.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';

import 'conversation_task_database.dart';
import 'conversation_task_fixtures.dart';

export 'conversation_task_database.dart';
export 'conversation_task_fixtures.dart';

final class TaskRepositoryHarness {
  late Database database;
  late Directory directory;
  late LocalDatabaseService local;
  late SqliteConversationTaskRepository repository;
  DateTime time = taskTime;
  DateTime get nextTime => time.add(const Duration(seconds: 1));

  Future<void> open() async {
    sqfliteFfiInit();
    directory = await Directory.systemTemp.createTemp('stars-task-repository-');
    database = await openTaskDatabase('${directory.path}/tasks.db');
    _repositories();
  }

  void _repositories() {
    local = LocalDatabaseService(databaseProvider: () async => database);
    repository = SqliteConversationTaskRepository(localDatabase: local);
  }

  Future<void> reopen() async {
    await database.close();
    database = await openTaskDatabase('${directory.path}/tasks.db');
    _repositories();
  }

  Future<void> close() async {
    await database.close();
    await directory.delete(recursive: true);
  }

  Future<ConversationTask> get task async =>
      (await repository.getById('task-1'))!;

  Future<TaskWriteResult<ConversationTask>> accept({
    ConversationTask? task,
    bool seed = true,
    ConversationTaskPlan? plan,
    Message? acknowledgement,
  }) async {
    final input = task ?? taskFixture();
    if (seed) await seedTaskOrigin(database, input);
    return repository.createWithAcknowledgement(
      task: input,
      plan: plan ?? taskPlan(input),
      initialEvent: ConversationTaskEvent(
        taskId: input.taskId,
        sequence: 1,
        kind: TaskEventKind.queued,
        occurredAt: input.createdAt,
        safeSummary: '已记录任务',
      ),
      acknowledgement: acknowledgement ?? taskMessage(input),
    );
  }

  Future<ConversationTask> start() async {
    committed(await accept());
    committed(
      await repository.tryAcquireLease(
        taskId: 'task-1',
        expectedRevision: 0,
        lease: taskLease(),
        now: time,
      ),
    );
    return committed(
      await advance(
        TaskEventKind.started,
        status: ConversationTaskStatus.running,
      ),
    );
  }

  Future<ConversationTaskProgressUpdate> update(
    TaskEventKind kind, {
    ConversationTask? current,
    ConversationTaskStatus? status,
    ConversationTaskPhase? phase,
    ConversationTaskPlan? plan,
    TaskWaitingReason? waitingReason,
    TaskApprovalRecord? approval,
    ConversationTaskCheckpoint? checkpoint,
    ToolExecutionRecord? tool,
    TaskToolAttemptLink? attemptLink,
    ToolEvidenceRecord? evidence,
    TaskEvidenceLink? evidenceLink,
    String? stepId,
    String? segmentId,
    String? attemptId,
    String? approvalId,
    String? evidenceId,
    String safeSummary = 'Task progress recorded.',
    String? reasonCode,
    int modelTurns = 0,
    TaskVerificationStatus? verificationStatus,
    int? sequence,
  }) async {
    final old = current ?? await task;
    time = nextTime;
    final next = changeTask(old, {
      'revision': old.revision + 1,
      'updated_at': time.microsecondsSinceEpoch,
      if (status != null) 'status': status.name,
      if (phase != null) 'phase': phase.name,
      if (status != null) 'waiting_reason': waitingReason?.name,
      if (plan != null) 'plan_revision': plan.revision,
    });
    final nextSequence =
        (await database.rawQuery(
              'SELECT MAX(sequence) + 1 AS next FROM conversation_task_events WHERE task_id = ?',
              [old.taskId],
            )).single['next']!
            as int;
    return ConversationTaskProgressUpdate(
      task: next,
      expectedRevision: old.revision,
      lease: old.lease!,
      now: time,
      event: ConversationTaskEvent(
        taskId: old.taskId,
        sequence: sequence ?? nextSequence,
        planRevision: next.planRevision,
        kind: kind,
        occurredAt: time,
        safeSummary: safeSummary,
        segmentId: segmentId,
        stepId: stepId,
        attemptId: attemptId ?? tool?.attemptId,
        approvalId: approvalId ?? approval?.approvalId,
        evidenceId: evidenceId ?? evidence?.evidenceId,
        modelTurns: modelTurns,
        verificationStatus: verificationStatus,
        reasonCode: reasonCode,
      ),
      plan: plan,
      checkpoint: checkpoint,
      approval: approval,
      toolExecution: tool,
      toolAttemptLink: attemptLink,
      evidence: evidence,
      evidenceLink: evidenceLink,
    );
  }

  Future<TaskWriteResult<ConversationTask>> advance(
    TaskEventKind kind, {
    ConversationTaskStatus? status,
    ConversationTaskPhase? phase,
    String? stepId,
    String? segmentId,
    int modelTurns = 0,
    TaskVerificationStatus? verificationStatus,
  }) async => repository.appendProgress(
    await update(
      kind,
      status: status,
      phase: phase,
      stepId: stepId,
      segmentId: segmentId,
      modelTurns: modelTurns,
      verificationStatus: verificationStatus,
    ),
  );

  Future<void> failWrite(
    String table, {
    String operation = 'INSERT',
    String? when,
  }) => database.execute(
    "CREATE TEMP TRIGGER injected_failure BEFORE $operation ON $table ${when == null ? '' : 'WHEN $when'} "
    "BEGIN SELECT RAISE(ABORT, 'injected storage failure'); END",
  );

  Future<void> clearFailure() =>
      database.execute('DROP TRIGGER injected_failure');

  Future<TaskTerminalWrite> terminal(ConversationTaskStatus status) async {
    final old = await task;
    time = nextTime;
    final next = old.transitionTo(
      status,
      at: time,
      phase: ConversationTaskPhase.committing,
      terminalSummary:
          status == ConversationTaskStatus.succeeded
              ? null
              : taskTerminal(status),
    );
    final sequence =
        (await database.rawQuery(
              'SELECT MAX(sequence) + 1 AS next FROM conversation_task_events WHERE task_id = ?',
              [old.taskId],
            )).single['next']!
            as int;
    return TaskTerminalWrite(
      task: next,
      event: ConversationTaskEvent(
        taskId: old.taskId,
        sequence: sequence,
        planRevision: old.planRevision,
        kind: TaskEventKind.terminal,
        occurredAt: time,
        safeSummary: 'Task finished.',
      ),
      lease: old.lease!,
      revision: old.revision,
    );
  }

  Future<Map<String, List<Map<String, Object?>>>> facts() async => {
    for (final table in [
      'conversation_tasks',
      'conversation_task_plans',
      'conversation_task_events',
      'conversation_task_progress',
      'conversation_task_approvals',
      'conversation_task_checkpoints',
      'conversation_task_tool_attempts',
      'conversation_task_evidence_links',
      'tool_execution_records',
      'tool_evidence_records',
      'messages',
      'token_usage_records',
      'chats',
    ])
      table: await database.query(table),
  };
}

final class TaskTerminalWrite {
  const TaskTerminalWrite({
    required this.task,
    required this.event,
    required this.lease,
    required this.revision,
  });
  final ConversationTask task;
  final ConversationTaskEvent event;
  final TaskLease lease;
  final int revision;

  Future<TaskWriteResult<ConversationTask>> commit(
    ConversationTaskRepository repository, {
    Message? message,
  }) => repository.commitTerminalMessage(
    terminalTask: task,
    event: event,
    message: message ?? taskMessage(task),
    expectedRevision: revision,
    lease: lease,
    now: task.updatedAt,
  );
}

T committed<T>(TaskWriteResult<T> result) {
  expect(result, isA<TaskWriteCommitted<T>>());
  return (result as TaskWriteCommitted<T>).value;
}

Matcher conflict(TaskWriteConflictReason reason) =>
    isA<TaskWriteConflict<Object?>>().having(
      (value) => value.reason,
      'reason',
      reason,
    );

ConversationTask changeTask(
  ConversationTask task,
  Map<String, Object?> changes,
) => ConversationTaskRecord({
  ...ConversationTaskRecord.fromDomain(task).values,
  ...changes,
}).toDomain(progress: task.progress);

Message taskMessage(ConversationTask task, {String? content}) => Message(
  messageId: task.status.isTerminal ? task.resultMessageId! : task.ackMessageId,
  turnId: task.originTurnId,
  chatId: task.chatId,
  botId: task.botId,
  taskId: task.taskId,
  taskMessageKind:
      task.status.isTerminal
          ? TaskMessageKind.result
          : TaskMessageKind.acknowledgement,
  senderId: 'assistant',
  content: content ?? (task.status.isTerminal ? 'Task finished.' : '已记录任务'),
  timestamp: task.updatedAt,
  terminalOutcome: switch (task.status) {
    ConversationTaskStatus.succeeded => MessageTerminalOutcome.completed,
    ConversationTaskStatus.failed => MessageTerminalOutcome.failed,
    ConversationTaskStatus.cancelled => MessageTerminalOutcome.cancelled,
    _ => null,
  },
);

ToolExecutionRecord taskTool({
  required DateTime at,
  DateTime? startedAt,
  String attemptId = 'attempt-1',
  ToolInvocationStatus status = ToolInvocationStatus.running,
  String summary = '',
  String arguments = '',
  String name = 'read_file',
}) => ToolExecutionRecord(
  executionId: attemptId,
  attemptId: attemptId,
  invocationId: 'invocation-1',
  providerCallId: 'call-1',
  runId: 'segment-1',
  turnId: 'task-1:turn',
  messageId: 'task-1:ack',
  chatId: 'chat-1',
  botId: 'bot-1',
  callId: 'call-1',
  name: name,
  source: ToolSource.builtIn,
  riskLevel: ToolRiskLevel.readOnly,
  status: status,
  startedAt: startedAt ?? at,
  updatedAt: at,
  argumentsSummary: arguments,
  resultSummary: summary,
  completedAt:
      {
            ToolInvocationStatus.requested,
            ToolInvocationStatus.awaitingApproval,
            ToolInvocationStatus.running,
          }.contains(status)
          ? null
          : at,
  durationMs:
      {
            ToolInvocationStatus.requested,
            ToolInvocationStatus.awaitingApproval,
            ToolInvocationStatus.running,
          }.contains(status)
          ? null
          : at.difference(startedAt ?? at).inMilliseconds,
);

TaskToolAttemptLink taskAttempt({
  String id = 'attempt-1',
  int number = 1,
  String key = 'read-report',
}) => TaskToolAttemptLink(
  taskId: 'task-1',
  segmentId: 'segment-1',
  attemptId: id,
  idempotencyKey: key,
  attemptNumber: number,
);
