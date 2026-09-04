part of 'database_service.dart';

Future<void> _ensureCompatibleToolExecutionSchema(Database database) async {
  final rows = await database.rawQuery(
    "SELECT name, sql FROM sqlite_master WHERE type = 'table' AND name = ?",
    const ['tool_execution_records'],
  );
  if (rows.isEmpty) {
    await _createToolExecutionSchema(database);
    return;
  }

  final columns = await database.rawQuery(
    'PRAGMA table_info(tool_execution_records)',
  );
  final columnNames =
      columns.map((column) => column['name']).whereType<String>().toSet();
  final createSql = rows.single['sql']?.toString() ?? '';
  final hasSeparatedIdentities = const {
    'invocation_id',
    'attempt_id',
    'provider_call_id',
  }.every(columnNames.contains);
  final hasAttemptStatuses =
      createSql.contains("'duplicateReused'") &&
      createSql.contains("'duplicateConflict'");
  if (hasSeparatedIdentities && hasAttemptStatuses) return;

  await database.transaction((transaction) async {
    await transaction.execute('''
      ALTER TABLE tool_execution_records
      RENAME TO tool_execution_records_before_grd004
    ''');
    await transaction.execute(
      'DROP INDEX IF EXISTS tool_execution_records_run_id_index',
    );
    await transaction.execute(
      'DROP INDEX IF EXISTS tool_execution_records_chat_started_at_index',
    );
    await _createToolExecutionSchema(transaction);

    final invocationId =
        columnNames.contains('invocation_id')
            ? "CASE WHEN invocation_id = '' THEN execution_id "
                'ELSE invocation_id END'
            : 'execution_id';
    final attemptId =
        columnNames.contains('attempt_id')
            ? "CASE WHEN attempt_id = '' THEN execution_id "
                'ELSE attempt_id END'
            : 'execution_id';
    final providerCallId =
        columnNames.contains('provider_call_id')
            ? "CASE WHEN provider_call_id = '' THEN call_id "
                'ELSE provider_call_id END'
            : 'call_id';
    await transaction.execute('''
      INSERT INTO tool_execution_records (
        execution_id,
        invocation_id,
        attempt_id,
        provider_call_id,
        run_id,
        turn_id,
        message_id,
        chat_id,
        bot_id,
        call_id,
        tool_name,
        tool_title,
        mcp_server_name,
        source,
        risk_level,
        status,
        detail,
        arguments_summary,
        result_summary,
        approval_status,
        error_code,
        duration_ms,
        started_at,
        completed_at,
        updated_at
      )
      SELECT
        execution_id,
        $invocationId,
        $attemptId,
        $providerCallId,
        run_id,
        turn_id,
        message_id,
        chat_id,
        bot_id,
        call_id,
        tool_name,
        tool_title,
        mcp_server_name,
        source,
        risk_level,
        status,
        detail,
        arguments_summary,
        result_summary,
        approval_status,
        error_code,
        duration_ms,
        started_at,
        completed_at,
        updated_at
      FROM tool_execution_records_before_grd004
    ''');
    await transaction.execute(
      'DROP TABLE tool_execution_records_before_grd004',
    );
  });
}

Future<void> _createToolExecutionSchema(DatabaseExecutor database) async {
  await database.execute('''
    CREATE TABLE tool_execution_records (
      execution_id TEXT PRIMARY KEY,
      invocation_id TEXT NOT NULL CHECK (length(invocation_id) > 0),
      attempt_id TEXT NOT NULL UNIQUE
        CHECK (length(attempt_id) > 0 AND attempt_id = execution_id),
      provider_call_id TEXT NOT NULL
        CHECK (length(provider_call_id) > 0),
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
          'duplicateReused',
          'duplicateConflict',
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
