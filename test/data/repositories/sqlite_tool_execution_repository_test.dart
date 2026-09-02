import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/repositories/sqlite_tool_execution_repository.dart';
import 'package:stars/data/services/database_service.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('upserts one durable MCP execution by stable execution id', () async {
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseService.databaseVersion,
        onConfigure: DatabaseService.configure,
        onCreate: DatabaseService.createSchema,
      ),
    );
    addTearDown(database.close);
    await database.insert('bots', _botRow);
    await database.insert('chats', _chatRow);
    final localDatabase = LocalDatabaseService(
      databaseProvider: () async => database,
    );
    final repository = SqliteToolExecutionRepository(
      localDatabase: localDatabase,
    );
    final startedAt = DateTime(2026, 9, 3, 10);

    await repository.upsert(
      _record(
        status: ToolInvocationStatus.running,
        startedAt: startedAt,
        updatedAt: startedAt,
      ),
    );
    await repository.upsert(
      _record(
        status: ToolInvocationStatus.succeeded,
        startedAt: startedAt,
        completedAt: startedAt.add(const Duration(milliseconds: 24)),
        updatedAt: startedAt.add(const Duration(milliseconds: 24)),
        durationMs: 24,
        resultSummary: 'saved',
      ),
    );

    final records = await repository.getForRun('run-1');
    expect(records, hasLength(1));
    final record = records.single;
    expect(record.executionId, 'run-1:tool:call-1');
    expect(record.callId, 'call-1');
    expect(record.chatId, 'chat-1');
    expect(record.source, ToolSource.mcp);
    expect(record.mcpServerName, 'Notes');
    expect(record.status, ToolInvocationStatus.succeeded);
    expect(record.resultSummary, 'saved');
    expect(record.durationMs, 24);
    expect(await repository.getForChat('chat-1'), hasLength(1));

    final rows = await database.query('tool_execution_records');
    expect(rows, hasLength(1));
    expect(rows.single['execution_id'], 'run-1:tool:call-1');
  });

  test('clearing a conversation removes its tool executions', () async {
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseService.databaseVersion,
        onConfigure: DatabaseService.configure,
        onCreate: DatabaseService.createSchema,
      ),
    );
    addTearDown(database.close);
    await database.insert('bots', _botRow);
    await database.insert('chats', _chatRow);
    final localDatabase = LocalDatabaseService(
      databaseProvider: () async => database,
    );
    final repository = SqliteToolExecutionRepository(
      localDatabase: localDatabase,
    );
    final now = DateTime(2026, 9, 3, 10);
    await repository.upsert(
      _record(
        status: ToolInvocationStatus.succeeded,
        startedAt: now,
        completedAt: now,
        updatedAt: now,
      ),
    );

    await localDatabase.clearChatHistory('chat-1', now);

    expect(await repository.getForChat('chat-1'), isEmpty);
  });
}

ToolExecutionRecord _record({
  required ToolInvocationStatus status,
  required DateTime startedAt,
  required DateTime updatedAt,
  DateTime? completedAt,
  int? durationMs,
  String resultSummary = '',
}) {
  return ToolExecutionRecord(
    executionId: 'run-1:tool:call-1',
    runId: 'run-1',
    turnId: 'turn-1',
    messageId: 'run-1:assistant',
    chatId: 'chat-1',
    botId: 'bot-1',
    callId: 'call-1',
    name: 'mcp.notes.save_note',
    title: 'Save note',
    mcpServerName: 'Notes',
    source: ToolSource.mcp,
    riskLevel: ToolRiskLevel.write,
    status: status,
    argumentsSummary: '{"title":"Release"}',
    resultSummary: resultSummary,
    approvalStatus: 'allowOnce',
    durationMs: durationMs,
    startedAt: startedAt,
    completedAt: completedAt,
    updatedAt: updatedAt,
  );
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
