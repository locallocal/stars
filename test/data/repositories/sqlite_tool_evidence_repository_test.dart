import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/data/repositories/sqlite_tool_evidence_repository.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('commits and reloads an immutable run ledger after restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'stars_tool_evidence_restart_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final databasePath = path.join(directory.path, 'ledger.db');
    var database = await _openDatabase(databasePath);
    await _insertConversation(database);
    var repository = _repository(database);

    await repository.commitRun(
      runId: 'run-1',
      chatId: 'chat-1',
      invocationEvents: [
        _event(sequence: 1, status: ToolInvocationStatus.requested),
        _event(sequence: 2, status: ToolInvocationStatus.succeeded),
      ],
      evidenceRecords: [_evidence()],
    );
    expect(await database.query('messages'), isEmpty);
    await database.close();

    database = await _openDatabase(databasePath);
    addTearDown(database.close);
    repository = _repository(database);
    final restored = await repository.getById(_evidenceId);
    final events = await repository.getInvocationEventsForRun('run-1');

    expect(restored, isNotNull);
    expect(restored!.persisted, isTrue);
    expect(restored.chatId, 'chat-1');
    expect(restored.providerCallId, 'provider-call-1');
    expect(restored.capabilities, {ToolCapability.externalRead});
    expect(restored.scope, {'resource_id': 'item-1'});
    expect(restored.structuredFacts.single.name, 'resource.state');
    expect(restored.structuredFacts.single.value, {
      'status': 'ready',
      'revision': 2,
    });
    expect(restored.payloadRef, 'encrypted://tool-results/evidence-1');
    expect(restored.payloadExpiresAt, DateTime.utc(2026, 9, 5, 10));
    expect(restored.canSupportBusinessFacts, isTrue);
    expect(await repository.getForMessage('message-1'), hasLength(1));
    expect(events.map((event) => event.sequence), [1, 2]);
    expect(events.last.status, ToolInvocationStatus.succeeded);
    expect(await repository.verifyDigest(_evidenceId), isTrue);
  });

  test('round-trips Provider-native citation evidence', () async {
    final database = await _openDatabase(inMemoryDatabasePath);
    addTearDown(database.close);
    await _insertConversation(database);
    final repository = _repository(database);
    final citation = StructuredFact(
      name: 'web.citation.1',
      value: 'Current result.',
      attributes: const {
        'provider_reference_id': 'provider-message-1:url_citation:0',
        'source_resource_id': 'url:reference-1',
      },
    );

    await repository.commitRun(
      runId: 'run-1',
      chatId: 'chat-1',
      invocationEvents: [
        _event(
          status: ToolInvocationStatus.succeeded,
          source: ToolSource.providerNative,
          toolName: 'openai.responses.web_search',
        ),
      ],
      evidenceRecords: [
        _evidence(
          source: ToolSource.providerNative,
          toolName: 'openai.responses.web_search',
          structuredFacts: [citation],
        ),
      ],
    );

    final restored = await repository.getById(_evidenceId);
    expect(restored?.source, ToolSource.providerNative);
    expect(restored?.evidenceId, isNot(restored?.providerCallId));
    expect(
      restored?.structuredFacts.single.attributes['provider_reference_id'],
      'provider-message-1:url_citation:0',
    );
  });

  test(
    'recovers after evidence commits but the grounded answer rolls back',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars_grounded_answer_restart_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final databasePath = path.join(directory.path, 'grounded.db');
      var database = await _openDatabase(databasePath);
      addTearDown(() async {
        if (database.isOpen) await database.close();
      });
      await _insertConversation(database);
      var localDatabase = LocalDatabaseService(
        databaseProvider: () async => database,
      );
      var evidenceRepository = SqliteToolEvidenceRepository(
        localDatabase: localDatabase,
      );
      var messageRepository = SqliteMessageRepository(
        localDatabase: localDatabase,
      );
      await evidenceRepository.commitRun(
        runId: 'run-1',
        chatId: 'chat-1',
        invocationEvents: [
          _event(sequence: 1, status: ToolInvocationStatus.succeeded),
        ],
        evidenceRecords: [_evidence()],
      );
      final checkpoint = _answerCheckpoint();
      await messageRepository.upsertMessage(checkpoint);
      final invalidAnswer = _verifiedAnswer(
        checkpoint,
        evidenceIds: [_evidenceId, 'missing:evidence'],
      );

      await expectLater(
        messageRepository.upsertGroundedMessage(invalidAnswer),
        throwsA(isA<DatabaseException>()),
      );
      expect(await database.query('answer_claim_evidence'), isEmpty);
      var restored = (await messageRepository.getMessages('chat-1')).single;
      expect(restored.terminalOutcome, isNull);
      expect(restored.hasPartialContent, isTrue);
      expect(restored.grounding.trustLevel, AnswerTrustLevel.unverified);
      expect(await evidenceRepository.getById(_evidenceId), isNotNull);

      await database.close();
      database = await _openDatabase(databasePath);
      localDatabase = LocalDatabaseService(
        databaseProvider: () async => database,
      );
      evidenceRepository = SqliteToolEvidenceRepository(
        localDatabase: localDatabase,
      );
      messageRepository = SqliteMessageRepository(localDatabase: localDatabase);
      restored = (await messageRepository.getMessages('chat-1')).single;
      expect(restored.grounding.reasonCode, 'evidence_commit_pending');
      expect(await evidenceRepository.getById(_evidenceId), isNotNull);

      final recovered = _verifiedAnswer(restored, evidenceIds: [_evidenceId]);
      await messageRepository.upsertGroundedMessage(recovered);
      await messageRepository.upsertGroundedMessage(recovered);

      final messages = await messageRepository.getMessages('chat-1');
      expect(messages.single.terminalOutcome, MessageTerminalOutcome.completed);
      expect(messages.single.grounding.trustLevel, AnswerTrustLevel.verified);
      final claims = await database.query('answer_claim_evidence');
      expect(claims, hasLength(1));
      expect(claims.single['claim_id'], 'claim-answer');
      expect(claims.single['evidence_id'], _evidenceId);
    },
  );

  test('repeating content is idempotent and conflicts roll back', () async {
    final database = await _openDatabase(inMemoryDatabasePath);
    addTearDown(database.close);
    await _insertConversation(database);
    final repository = _repository(database);
    final event = _event(sequence: 1, status: ToolInvocationStatus.succeeded);
    final evidence = _evidence();

    for (var index = 0; index < 2; index += 1) {
      await repository.commitRun(
        runId: 'run-1',
        chatId: 'chat-1',
        invocationEvents: [event],
        evidenceRecords: [evidence],
      );
    }

    expect(await database.query('tool_invocation_events'), hasLength(1));
    expect(await database.query('tool_evidence_records'), hasLength(1));

    await expectLater(
      repository.commitRun(
        runId: 'run-1',
        chatId: 'chat-1',
        invocationEvents: [
          _event(sequence: 2, status: ToolInvocationStatus.succeeded),
        ],
        evidenceRecords: [_evidence(resultSummary: 'Conflicting summary.')],
      ),
      throwsStateError,
    );

    expect(await database.query('tool_invocation_events'), hasLength(1));
    final evidenceRows = await database.query('tool_evidence_records');
    expect(evidenceRows, hasLength(1));
    expect(evidenceRows.single['result_summary'], 'Resource observed.');

    await expectLater(
      repository.commitRun(
        runId: 'run-1',
        chatId: 'chat-1',
        invocationEvents: [
          _event(sequence: 1, status: ToolInvocationStatus.failed),
        ],
        evidenceRecords: const [],
      ),
      throwsStateError,
    );
    expect(await database.query('tool_invocation_events'), hasLength(1));
  });

  test(
    'detects stored content whose record digest no longer matches',
    () async {
      final database = await _openDatabase(inMemoryDatabasePath);
      addTearDown(database.close);
      await _insertConversation(database);
      final repository = _repository(database);
      await repository.commitRun(
        runId: 'run-1',
        chatId: 'chat-1',
        invocationEvents: [_event()],
        evidenceRecords: [_evidence()],
      );
      expect(await repository.verifyDigest(_evidenceId), isTrue);

      await database.execute(
        'DROP TRIGGER tool_evidence_records_prevent_update',
      );
      await database.update(
        'tool_evidence_records',
        {'result_summary': 'tampered'},
        where: 'evidence_id = ?',
        whereArgs: [_evidenceId],
      );

      expect(await repository.verifyDigest(_evidenceId), isFalse);
      await expectLater(repository.getById(_evidenceId), throwsFormatException);

      await database.execute(
        'DROP TRIGGER tool_invocation_events_prevent_update',
      );
      await database.update(
        'tool_invocation_events',
        {'tool_name': 'tampered.tool'},
        where: 'event_id = ?',
        whereArgs: ['$_attemptId:event:1'],
      );
      await expectLater(
        repository.getInvocationEventsForRun('run-1'),
        throwsFormatException,
      );
    },
  );

  test('ledger rows are append-only but still cascade with a chat', () async {
    final database = await _openDatabase(inMemoryDatabasePath);
    addTearDown(database.close);
    await _insertConversation(database);
    final localDatabase = LocalDatabaseService(
      databaseProvider: () async => database,
    );
    final repository = SqliteToolEvidenceRepository(
      localDatabase: localDatabase,
    );
    await repository.commitRun(
      runId: 'run-1',
      chatId: 'chat-1',
      invocationEvents: [
        _event(sequence: 1, status: ToolInvocationStatus.succeeded),
      ],
      evidenceRecords: [_evidence()],
    );

    await expectLater(
      database.update(
        'tool_invocation_events',
        {'error_code': 'mutated'},
        where: 'event_id = ?',
        whereArgs: ['$_attemptId:event:1'],
      ),
      throwsA(isA<DatabaseException>()),
    );
    await expectLater(
      database.update(
        'tool_evidence_records',
        {'result_summary': 'mutated'},
        where: 'evidence_id = ?',
        whereArgs: [_evidenceId],
      ),
      throwsA(isA<DatabaseException>()),
    );

    await database.insert('messages', _messageRow);
    await database.insert('answer_claim_evidence', <String, Object?>{
      'message_id': 'message-1',
      'claim_id': 'claim-1',
      'evidence_id': _evidenceId,
      'created_at': 1,
    });
    await localDatabase.deleteChat('chat-1');

    expect(await database.query('tool_invocation_events'), isEmpty);
    expect(await database.query('tool_evidence_records'), isEmpty);
    expect(await database.query('answer_claim_evidence'), isEmpty);
    expect(await database.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test('rejects records outside the requested run or chat', () async {
    final database = await _openDatabase(inMemoryDatabasePath);
    addTearDown(database.close);
    await _insertConversation(database);
    final repository = _repository(database);

    expect(
      () => repository.commitRun(
        runId: 'other-run',
        chatId: 'chat-1',
        invocationEvents: [_event()],
        evidenceRecords: const [],
      ),
      throwsArgumentError,
    );
    expect(
      () => repository.commitRun(
        runId: 'run-1',
        chatId: 'other-chat',
        invocationEvents: const [],
        evidenceRecords: [_evidence()],
      ),
      throwsArgumentError,
    );
  });
}

const _attemptId = 'run-1:invocation:1:attempt:1';
const _evidenceId = '$_attemptId:evidence';
const _argumentsDigest =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _resultDigest =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

ToolInvocationEvent _event({
  int sequence = 1,
  ToolInvocationStatus status = ToolInvocationStatus.requested,
  ToolSource source = ToolSource.mcp,
  String toolName = 'mcp.resources.read',
}) => ToolInvocationEvent(
  eventId: '$_attemptId:event:$sequence',
  runId: 'run-1',
  turnId: 'turn-1',
  chatId: 'chat-1',
  messageId: 'message-1',
  invocationId: 'run-1:invocation:1',
  attemptId: _attemptId,
  providerCallId: 'provider-call-1',
  toolName: toolName,
  toolVersion: '1.0.0',
  source: source,
  status: status,
  sequence: sequence,
  occurredAt: DateTime.utc(2026, 9, 4, 10, 0, sequence),
);

ToolEvidenceRecord _evidence({
  String resultSummary = 'Resource observed.',
  ToolSource source = ToolSource.mcp,
  String toolName = 'mcp.resources.read',
  List<StructuredFact>? structuredFacts,
}) => ToolEvidenceRecord(
  evidenceId: _evidenceId,
  runId: 'run-1',
  turnId: 'turn-1',
  chatId: 'chat-1',
  messageId: 'message-1',
  invocationId: 'run-1:invocation:1',
  attemptId: _attemptId,
  providerCallId: 'provider-call-1',
  toolName: toolName,
  toolVersion: '1.0.0',
  source: source,
  capabilities: const {ToolCapability.externalRead},
  terminalStatus: ToolInvocationStatus.succeeded,
  evidenceKind: EvidenceKind.observation,
  subject: 'resource:item-1',
  scope: const {'resource_id': 'item-1'},
  resultSummary: resultSummary,
  argumentsDigest: _argumentsDigest,
  resultDigest: _resultDigest,
  structuredFacts:
      structuredFacts ??
      [
        StructuredFact(
          name: 'resource.state',
          value: const {'status': 'ready', 'revision': 2},
        ),
      ],
  observedAt: DateTime.utc(2026, 9, 4, 10),
  validUntil: DateTime.utc(2026, 9, 4, 10, 5),
  payloadRef: 'encrypted://tool-results/evidence-1',
  payloadExpiresAt: DateTime.utc(2026, 9, 5, 10),
);

Message _answerCheckpoint() => Message(
  messageId: 'message-1',
  turnId: 'turn-1',
  runId: 'run-1',
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'bot-1',
  content: 'Answer',
  grounding: MessageGrounding(
    trustLevel: AnswerTrustLevel.unverified,
    reasonCode: 'evidence_commit_pending',
  ),
  hasPartialContent: true,
  timestamp: DateTime.utc(2026, 9, 4, 10, 1),
);

Message _verifiedAnswer(
  Message checkpoint, {
  required List<String> evidenceIds,
}) => checkpoint.copyWith(
  grounding: MessageGrounding(
    trustLevel: AnswerTrustLevel.verified,
    reasonCode: 'all_evidence_validated',
    claims: [
      MessageClaimGrounding(
        claim: AnswerClaim(
          claimId: 'claim-answer',
          text: 'The resource exists.',
          kind: ClaimKind.externalFact,
          evidenceIds: evidenceIds,
        ),
        trustLevel: ClaimTrustLevel.verified,
        acceptedEvidenceIds: evidenceIds,
      ),
    ],
  ),
  terminalOutcome: MessageTerminalOutcome.completed,
  hasPartialContent: false,
);

SqliteToolEvidenceRepository _repository(Database database) =>
    SqliteToolEvidenceRepository(
      localDatabase: LocalDatabaseService(
        databaseProvider: () async => database,
      ),
    );

Future<Database> _openDatabase(String databasePath) =>
    databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: DatabaseService.databaseVersion,
        onConfigure: DatabaseService.configure,
        onCreate: DatabaseService.createSchema,
      ),
    );

Future<void> _insertConversation(Database database) async {
  await database.insert('bots', _botRow);
  await database.insert('chats', _chatRow);
}

const _botRow = <String, Object?>{
  'id': 'bot-1',
  'name': 'Bot',
  'avatar': '',
  'provider': 'Provider',
  'base_url': 'https://example.test',
  'api_key': '',
  'api_type': 'openai',
  'model': 'model',
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

const _messageRow = <String, Object?>{
  'message_id': 'message-1',
  'turn_id': 'turn-1',
  'run_id': 'run-1',
  'chat_id': 'chat-1',
  'bot_id': 'bot-1',
  'sender_id': 'bot-1',
  'content': 'Answer',
  'reasoning': '',
  'process_info':
      '{"reasoning_status":"","duration_ms":null,'
      '"tool_calls":[],"command_executions":[],"file_edits":[],'
      '"skill_activations":[]}',
  'grounding_json': '',
  'images': '[]',
  'files': '[]',
  'audio': '',
  'music': '',
  'video': '',
  'token_model': '',
  'input_token_count': 0,
  'output_token_count': 0,
  'total_token_count': 0,
  'terminal_state': 'completed',
  'has_partial_content': 0,
  'timestamp': 1,
};
