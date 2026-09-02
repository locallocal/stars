part of 'database_service.dart';

Future<void> _ensureCompatibleToolExecutionSchema(Database database) async {
  final rows = await database.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
    const ['tool_execution_records'],
  );
  if (rows.isNotEmpty) return;
  await _createToolExecutionSchema(database);
}

Future<void> _createToolExecutionSchema(DatabaseExecutor database) async {
  await database.execute('''
    CREATE TABLE tool_execution_records (
      execution_id TEXT PRIMARY KEY,
      run_id TEXT NOT NULL,
      turn_id TEXT NOT NULL,
      message_id TEXT NOT NULL,
      chat_id TEXT NOT NULL,
      bot_id TEXT NOT NULL,
      call_id TEXT NOT NULL,
      tool_name TEXT NOT NULL,
      tool_title TEXT NOT NULL DEFAULT '',
      mcp_server_name TEXT NOT NULL DEFAULT '',
      source TEXT NOT NULL
        CHECK (source IN ('builtIn', 'mcp', 'skillScript')),
      risk_level TEXT NOT NULL
        CHECK (risk_level IN ('readOnly', 'write', 'destructive')),
      status TEXT NOT NULL
        CHECK (status IN (
          'requested',
          'awaitingApproval',
          'running',
          'succeeded',
          'failed',
          'denied',
          'cancelled',
          'timedOut',
          'duplicate'
        )),
      detail TEXT NOT NULL DEFAULT '',
      arguments_summary TEXT NOT NULL DEFAULT '',
      result_summary TEXT NOT NULL DEFAULT '',
      approval_status TEXT NOT NULL DEFAULT '',
      error_code TEXT NOT NULL DEFAULT '',
      duration_ms INTEGER,
      started_at INTEGER NOT NULL,
      completed_at INTEGER,
      updated_at INTEGER NOT NULL,
      FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE,
      FOREIGN KEY (bot_id) REFERENCES bots(id) ON DELETE CASCADE
    )
  ''');
  await database.execute(
    'CREATE INDEX tool_execution_records_run_id_index '
    'ON tool_execution_records(run_id)',
  );
  await database.execute(
    'CREATE INDEX tool_execution_records_chat_started_at_index '
    'ON tool_execution_records(chat_id, started_at DESC)',
  );
}
