import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/repositories/sqlite_agent_run_recovery_repository.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/data/repositories/sqlite_grounding_metrics_repository.dart';
import 'package:stars/data/repositories/sqlite_tool_evidence_repository.dart';
import 'package:stars/data/repositories/sqlite_tool_execution_repository.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/grounding_metrics_service.dart';
import 'package:stars/domain/use_cases/recover_agent_runs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database database;
  late LocalDatabaseService localDatabase;
  late SqliteMessageRepository messages;
  late SqliteToolEvidenceRepository evidence;
  late SqliteToolExecutionRepository executions;
  late SqliteAgentRunRecoveryRepository recovery;

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseService.databaseVersion,
        onConfigure: DatabaseService.configure,
        onCreate: DatabaseService.createSchema,
      ),
    );
    await database.insert('bots', _botRow);
    await database.insert('chats', _chatRow);
    localDatabase = LocalDatabaseService(
      databaseProvider: () async => database,
    );
    messages = SqliteMessageRepository(localDatabase: localDatabase);
    evidence = SqliteToolEvidenceRepository(localDatabase: localDatabase);
    executions = SqliteToolExecutionRepository(localDatabase: localDatabase);
    recovery = SqliteAgentRunRecoveryRepository(localDatabase: localDatabase);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'restart reconciles every active Loop phase without replay or duplicate writes',
    () async {
      // planning has no durable tool or answer state and intentionally needs no
      // recovery mutation.
      await messages.upsertMessage(_userMessage('planning'));

      await _persistNonTerminalRun(
        recovery: recovery,
        evidence: evidence,
        executions: executions,
        runId: 'awaiting',
        status: ToolInvocationStatus.awaitingApproval,
      );
      await _persistNonTerminalRun(
        recovery: recovery,
        evidence: evidence,
        executions: executions,
        runId: 'executing',
        status: ToolInvocationStatus.running,
      );

      for (final runId in const ['observing', 'verifying', 'synthesizing']) {
        await messages.upsertMessage(_pendingAssistant(runId));
        await evidence.commitRun(
          runId: runId,
          chatId: 'chat-1',
          invocationEvents: const [],
          evidenceRecords: [_evidence(runId)],
        );
      }

      const committingRun = 'committing';
      await messages.upsertMessage(_pendingAssistant(committingRun));
      await evidence.commitRun(
        runId: committingRun,
        chatId: 'chat-1',
        invocationEvents: const [],
        evidenceRecords: [_evidence(committingRun)],
      );
      final target = _verifiedAssistant(committingRun);
      await recovery.stageAnswer(target);

      final recover = RecoverAgentRuns(
        recoveryRepository: recovery,
        messageRepository: messages,
        groundedMessageRepository: messages,
        evidenceRepository: evidence,
        executionRepository: executions,
      );
      final first = await recover(recoveredAt: DateTime.utc(2026, 8, 1));

      expect(first.interruptedInvocations, 2);
      expect(first.recoveredAnswers, 1);
      expect(first.failedAnswers, 3);
      for (final runId in const ['awaiting', 'executing']) {
        final events = await evidence.getInvocationEventsForRun(runId);
        expect(events.map((item) => item.status), [
          runId == 'awaiting'
              ? ToolInvocationStatus.awaitingApproval
              : ToolInvocationStatus.running,
          ToolInvocationStatus.interrupted,
        ]);
        expect(
          (await executions.getForRun(runId)).single.status,
          ToolInvocationStatus.interrupted,
        );
      }
      final persisted = await messages.getMessages('chat-1');
      for (final runId in const ['observing', 'verifying', 'synthesizing']) {
        final failed = persisted.singleWhere(
          (message) => message.runId == runId && message.senderId == 'bot-1',
        );
        expect(failed.terminalOutcome, MessageTerminalOutcome.failed);
        expect(failed.content, isEmpty);
        expect(
          failed.grounding.reasonCode,
          'recovery_answer_checkpoint_missing',
        );
      }
      final committed = persisted.singleWhere(
        (message) => message.runId == committingRun,
      );
      expect(committed.content, 'Verified answer');
      expect(committed.grounding.trustLevel, AnswerTrustLevel.verified);
      expect(await recovery.loadPendingAnswers(), isEmpty);

      final ledgerRowsBefore = await database.query('tool_invocation_events');
      final messageRowsBefore = await database.query('messages');
      final evidenceRowsBefore = await database.query('tool_evidence_records');
      final second = await recover(recoveredAt: DateTime.utc(2026, 8, 2));

      expect(second.interruptedInvocations, 0);
      expect(second.recoveredAnswers, 0);
      expect(second.failedAnswers, 0);
      expect(await database.query('tool_invocation_events'), ledgerRowsBefore);
      expect(await database.query('messages'), messageRowsBefore);
      expect(await database.query('tool_evidence_records'), evidenceRowsBefore);
    },
  );

  test('corrupt answer checkpoint becomes a stable safe failure', () async {
    await database.insert('agent_run_answer_checkpoints', <String, Object?>{
      'run_id': 'corrupt-run',
      'chat_id': 'chat-1',
      'message_id': 'corrupt-run-assistant',
      'terminal_message_json': '{contains-user-or-tool-data',
      'created_at': 1,
    });
    final recover = RecoverAgentRuns(
      recoveryRepository: recovery,
      messageRepository: messages,
      groundedMessageRepository: messages,
      evidenceRepository: evidence,
      executionRepository: executions,
    );

    final first = await recover(recoveredAt: DateTime.utc(2026, 8, 1));
    final second = await recover(recoveredAt: DateTime.utc(2026, 8, 2));
    final persisted = (await messages.getMessages('chat-1')).single;

    expect(first.failedAnswers, 1);
    expect(second.failedAnswers, 0);
    expect(persisted.content, isEmpty);
    expect(persisted.terminalOutcome, MessageTerminalOutcome.failed);
    expect(persisted.grounding.trustLevel, AnswerTrustLevel.failed);
    expect(await recovery.loadPendingAnswers(), isEmpty);
  });

  test('committed answer recovery fills metrics exactly once', () async {
    const runId = 'metrics-run';
    await evidence.commitRun(
      runId: runId,
      chatId: 'chat-1',
      invocationEvents: const [],
      evidenceRecords: [_evidence(runId)],
    );
    final target = _verifiedAssistant(runId);
    await recovery.stageAnswer(target);
    await messages.upsertGroundedMessage(target);
    final metricsRepository = SqliteGroundingMetricsRepository(
      localDatabase: localDatabase,
    );
    final metrics = GroundingMetricsService(
      repository: metricsRepository,
      evidenceRepository: evidence,
    );
    // Simulate a crash after metrics commit but before checkpoint cleanup.
    await metrics.recordTerminalMessage(target);
    final recover = RecoverAgentRuns(
      recoveryRepository: recovery,
      messageRepository: messages,
      groundedMessageRepository: messages,
      evidenceRepository: evidence,
      executionRepository: executions,
      onRecoveredMessage: metrics.recordTerminalMessage,
    );

    await recover(recoveredAt: DateTime.utc(2026, 8, 1));
    final snapshot = await metricsRepository.snapshot();

    expect(snapshot.total(GroundingMetricName.verifiedEvidenceRequired), 1);
    expect(snapshot.total(GroundingMetricName.verifiedEvidencePersisted), 1);
    expect(await recovery.loadPendingAnswers(), isEmpty);
  });

  test('clearing chat history also removes pending answer recovery', () async {
    await recovery.stageAnswer(_verifiedAssistant('clear-run'));

    await localDatabase.clearChatHistory('chat-1', DateTime.utc(2026, 8, 1));

    expect(await recovery.loadPendingAnswers(), isEmpty);
  });
}

Future<void> _persistNonTerminalRun({
  required SqliteAgentRunRecoveryRepository recovery,
  required SqliteToolEvidenceRepository evidence,
  required SqliteToolExecutionRepository executions,
  required String runId,
  required ToolInvocationStatus status,
}) async {
  final attemptId = '$runId-attempt';
  final instant = DateTime.utc(2026, 7, 31);
  await evidence.commitRun(
    runId: runId,
    chatId: 'chat-1',
    invocationEvents: [
      ToolInvocationEvent(
        eventId: ToolInvocationEvent.eventIdForAttempt(attemptId, 1),
        runId: runId,
        turnId: '$runId-turn',
        chatId: 'chat-1',
        messageId: '$runId-assistant',
        invocationId: '$runId-invocation',
        attemptId: attemptId,
        providerCallId: '$runId-provider-call',
        toolName: 'notes.write',
        toolVersion: '1',
        source: ToolSource.mcp,
        status: status,
        sequence: 1,
        occurredAt: instant,
      ),
    ],
    evidenceRecords: const [],
  );
  await executions.upsert(
    ToolExecutionRecord(
      executionId: attemptId,
      invocationId: '$runId-invocation',
      attemptId: attemptId,
      providerCallId: '$runId-provider-call',
      runId: runId,
      turnId: '$runId-turn',
      messageId: '$runId-assistant',
      chatId: 'chat-1',
      botId: 'bot-1',
      callId: '$runId-provider-call',
      name: 'notes.write',
      source: ToolSource.mcp,
      riskLevel: ToolRiskLevel.write,
      status: status,
      argumentsSummary: '{}',
      startedAt: instant,
      updatedAt: instant,
    ),
  );
  // The repository is deliberately present here to document that recovery,
  // rather than a tool executor, owns the next state mutation.
  expect(recovery, isNotNull);
}

Message _userMessage(String runId) => Message(
  messageId: '$runId-user',
  turnId: '$runId-turn',
  runId: runId,
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'user-1',
  content: 'Start',
  timestamp: DateTime.utc(2026, 7, 31),
);

Message _pendingAssistant(String runId) => Message(
  messageId: '$runId-assistant',
  turnId: '$runId-turn',
  runId: runId,
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'bot-1',
  content: 'Uncommitted answer',
  grounding: MessageGrounding(
    trustLevel: AnswerTrustLevel.unverified,
    reasonCode: 'evidence_commit_pending',
  ),
  hasPartialContent: true,
  timestamp: DateTime.utc(2026, 7, 31),
);

Message _verifiedAssistant(String runId) {
  final evidenceId = '$runId-attempt:evidence';
  final claim = AnswerClaim(
    claimId: 'claim_1',
    text: 'Verified answer',
    kind: ClaimKind.currentFact,
    evidenceIds: [evidenceId],
  );
  return _pendingAssistant(runId).copyWith(
    content: 'Verified answer',
    grounding: MessageGrounding(
      trustLevel: AnswerTrustLevel.verified,
      reasonCode: 'all_evidence_validated',
      evidenceIds: [evidenceId],
      claims: [
        MessageClaimGrounding(
          claim: claim,
          trustLevel: ClaimTrustLevel.verified,
          acceptedEvidenceIds: [evidenceId],
          reasonCode: 'evidence_accepted',
        ),
      ],
    ),
    terminalOutcome: MessageTerminalOutcome.completed,
    hasPartialContent: false,
  );
}

ToolEvidenceRecord _evidence(String runId) {
  final attemptId = '$runId-attempt';
  return ToolEvidenceRecord(
    evidenceId: ToolEvidenceRecord.evidenceIdForAttempt(attemptId),
    runId: runId,
    turnId: '$runId-turn',
    chatId: 'chat-1',
    messageId: '$runId-assistant',
    invocationId: '$runId-invocation',
    attemptId: attemptId,
    providerCallId: '$runId-provider-call',
    toolName: 'clock.read',
    toolVersion: '1',
    source: ToolSource.builtIn,
    capabilities: const {ToolCapability.localRead},
    terminalStatus: ToolInvocationStatus.succeeded,
    evidenceKind: EvidenceKind.observation,
    subject: 'clock',
    scope: const {'timezone': 'UTC'},
    resultSummary: 'Clock produced one structured fact.',
    argumentsDigest: 'a' * 64,
    resultDigest: 'b' * 64,
    structuredFacts: [StructuredFact(name: 'clock.hour', value: 12)],
    observedAt: DateTime.utc(2026, 7, 31),
    validUntil: DateTime.utc(2026, 8, 3),
    persisted: true,
  );
}

const _botRow = <String, Object?>{
  'id': 'bot-1',
  'name': 'Bot',
  'avatar': '',
  'provider': 'test',
  'base_url': '',
  'api_key': '',
  'api_type': 'openai',
  'model': 'test',
  'system_prompt': '',
  'parameters': '{}',
  'create_timestamp': 1,
  'modify_timestamp': 1,
};

const _chatRow = <String, Object?>{
  'id': 'chat-1',
  'bot_id': 'bot-1',
  'last_message': '',
  'last_message_timestamp': 1,
  'create_timestamp': 1,
  'modify_timestamp': 1,
};
