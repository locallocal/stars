part of 'database_service.dart';

const int _toolEvidenceInitialDatabaseVersion = 18;
const int _providerNativePreviousDatabaseVersion = 19;
const Set<int> _supportedPreviousDatabaseVersions = {
  _toolEvidenceInitialDatabaseVersion,
  _providerNativePreviousDatabaseVersion,
};

Future<void> _upgradeToolEvidenceSchema(
  Database database,
  int oldVersion,
  int newVersion,
) async {
  if (!_supportedPreviousDatabaseVersions.contains(oldVersion) ||
      newVersion != DatabaseService.databaseVersion) {
    throw StateError(
      'Unsupported database migration from $oldVersion to $newVersion.',
    );
  }
  if (oldVersion == _toolEvidenceInitialDatabaseVersion) {
    await _createToolEvidenceSchema(database);
    return;
  }
  await _rebuildToolEvidenceSchemaForProviderNative(database);
}

Future<void> _ensureCompatibleToolEvidenceSchema(Database database) =>
    _createToolEvidenceSchema(database);

Future<bool> _isSupportedPreviousDatabaseValid(
  String databasePath,
  int expectedVersion,
) async {
  if (!_supportedPreviousDatabaseVersions.contains(expectedVersion)) {
    return false;
  }
  try {
    final database = await openDatabase(
      databasePath,
      readOnly: true,
      singleInstance: false,
    );
    try {
      if (await database.getVersion() != expectedVersion) {
        return false;
      }
      await DatabaseService._verifyIntegrity(database);
      await _verifyCurrentDatabaseSchema(
        database,
        allowMissingToolExecutionSchema:
            expectedVersion == _providerNativePreviousDatabaseVersion,
        allowMissingToolEvidenceSchema:
            expectedVersion == _toolEvidenceInitialDatabaseVersion,
      );
      return true;
    } finally {
      await database.close();
    }
  } on Object {
    return false;
  }
}

Future<void> _verifySupportedDatabaseFile(String databasePath) async {
  final database = await openDatabase(
    databasePath,
    readOnly: true,
    singleInstance: false,
  );
  try {
    final version = await database.getVersion();
    if (version != DatabaseService.databaseVersion &&
        !_supportedPreviousDatabaseVersions.contains(version)) {
      throw const FormatException('Database schema version is unsupported.');
    }
    await DatabaseService._verifyIntegrity(database);
    await _verifyCurrentDatabaseSchema(
      database,
      allowMissingToolExecutionSchema:
          version == DatabaseService.databaseVersion ||
          version == _providerNativePreviousDatabaseVersion,
      allowMissingToolEvidenceSchema:
          version == _toolEvidenceInitialDatabaseVersion ||
          version == DatabaseService.databaseVersion,
    );
  } finally {
    await database.close();
  }
}

Future<void> _createToolEvidenceSchema(DatabaseExecutor database) async {
  await database.execute('''
    CREATE TABLE IF NOT EXISTS tool_invocation_events (
      event_id TEXT PRIMARY KEY,
      run_id TEXT NOT NULL CHECK (length(run_id) > 0),
      turn_id TEXT NOT NULL CHECK (length(turn_id) > 0),
      chat_id TEXT NOT NULL CHECK (length(chat_id) > 0),
      message_id TEXT NOT NULL DEFAULT '',
      invocation_id TEXT NOT NULL CHECK (length(invocation_id) > 0),
      attempt_id TEXT NOT NULL CHECK (length(attempt_id) > 0),
      provider_call_id TEXT NOT NULL DEFAULT '',
      tool_name TEXT NOT NULL CHECK (length(tool_name) > 0),
      tool_version TEXT NOT NULL DEFAULT '',
      source TEXT NOT NULL
        CHECK (source IN ('builtIn', 'mcp', 'skillScript', 'providerNative')),
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
      sequence INTEGER NOT NULL CHECK (sequence > 0),
      occurred_at INTEGER NOT NULL,
      error_code TEXT NOT NULL DEFAULT '',
      record_digest TEXT NOT NULL
        CHECK (
          length(record_digest) = 64
          AND record_digest NOT GLOB '*[^0-9a-f]*'
        ),
      CHECK (event_id = attempt_id || ':event:' || sequence),
      UNIQUE (attempt_id, sequence),
      FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE
    )
  ''');
  await database.execute(
    'CREATE INDEX IF NOT EXISTS tool_invocation_events_run_id_index '
    'ON tool_invocation_events(run_id, sequence)',
  );
  await database.execute(
    'CREATE INDEX IF NOT EXISTS tool_invocation_events_message_id_index '
    'ON tool_invocation_events(message_id)',
  );
  await database.execute(
    'CREATE INDEX IF NOT EXISTS tool_invocation_events_chat_time_index '
    'ON tool_invocation_events(chat_id, occurred_at)',
  );

  await database.execute('''
    CREATE TABLE IF NOT EXISTS tool_evidence_records (
      evidence_id TEXT PRIMARY KEY,
      run_id TEXT NOT NULL CHECK (length(run_id) > 0),
      turn_id TEXT NOT NULL CHECK (length(turn_id) > 0),
      chat_id TEXT NOT NULL CHECK (length(chat_id) > 0),
      message_id TEXT NOT NULL DEFAULT '',
      invocation_id TEXT NOT NULL CHECK (length(invocation_id) > 0),
      attempt_id TEXT NOT NULL UNIQUE CHECK (length(attempt_id) > 0),
      provider_call_id TEXT NOT NULL DEFAULT '',
      tool_name TEXT NOT NULL CHECK (length(tool_name) > 0),
      tool_version TEXT NOT NULL CHECK (length(tool_version) > 0),
      source TEXT NOT NULL
        CHECK (source IN ('builtIn', 'mcp', 'skillScript', 'providerNative')),
      capabilities_json TEXT NOT NULL DEFAULT '[]',
      terminal_status TEXT NOT NULL
        CHECK (terminal_status IN (
          'succeeded', 'failed', 'denied', 'cancelled', 'timedOut'
        )),
      evidence_kind TEXT NOT NULL
        CHECK (evidence_kind IN (
          'observation',
          'calculation',
          'actionReceipt',
          'executionFailure'
        )),
      subject TEXT NOT NULL DEFAULT '',
      scope_json TEXT NOT NULL DEFAULT '{}',
      result_summary TEXT NOT NULL CHECK (length(result_summary) > 0),
      arguments_digest TEXT NOT NULL
        CHECK (
          length(arguments_digest) = 64
          AND arguments_digest NOT GLOB '*[^0-9a-f]*'
        ),
      result_digest TEXT NOT NULL
        CHECK (
          length(result_digest) = 64
          AND result_digest NOT GLOB '*[^0-9a-f]*'
        ),
      structured_facts_json TEXT NOT NULL DEFAULT '[]',
      observed_at INTEGER NOT NULL,
      valid_until INTEGER,
      payload_ref TEXT NOT NULL DEFAULT '',
      payload_expires_at INTEGER,
      truncated INTEGER NOT NULL DEFAULT 0 CHECK (truncated IN (0, 1)),
      schema_valid INTEGER NOT NULL DEFAULT 1 CHECK (schema_valid IN (0, 1)),
      persisted INTEGER NOT NULL DEFAULT 1 CHECK (persisted = 1),
      error_code TEXT NOT NULL DEFAULT '',
      record_digest TEXT NOT NULL
        CHECK (
          length(record_digest) = 64
          AND record_digest NOT GLOB '*[^0-9a-f]*'
        ),
      CHECK (evidence_id = attempt_id || ':evidence'),
      CHECK (valid_until IS NULL OR valid_until > observed_at),
      CHECK (
        (payload_ref = '' AND payload_expires_at IS NULL)
        OR (
          payload_ref GLOB 'encrypted://*'
          AND payload_expires_at > observed_at
        )
      ),
      CHECK (
        (evidence_kind = 'executionFailure'
          AND terminal_status != 'succeeded'
          AND length(error_code) > 0)
        OR
        (evidence_kind != 'executionFailure'
          AND terminal_status = 'succeeded'
          AND error_code = '')
      ),
      CHECK (
        evidence_kind = 'executionFailure'
        OR (
          truncated = 0
          AND schema_valid = 1
          AND length(subject) > 0
          AND scope_json != '{}'
          AND structured_facts_json != '[]'
        )
      ),
      FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE
    )
  ''');
  await database.execute(
    'CREATE INDEX IF NOT EXISTS tool_evidence_records_run_id_index '
    'ON tool_evidence_records(run_id)',
  );
  await database.execute(
    'CREATE INDEX IF NOT EXISTS tool_evidence_records_message_id_index '
    'ON tool_evidence_records(message_id)',
  );
  await database.execute(
    'CREATE INDEX IF NOT EXISTS tool_evidence_records_observed_at_index '
    'ON tool_evidence_records(observed_at)',
  );
  await database.execute(
    'CREATE INDEX IF NOT EXISTS tool_evidence_records_chat_observed_index '
    'ON tool_evidence_records(chat_id, observed_at)',
  );

  await database.execute('''
    CREATE TABLE IF NOT EXISTS answer_claim_evidence (
      message_id TEXT NOT NULL,
      claim_id TEXT NOT NULL CHECK (length(claim_id) > 0),
      evidence_id TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      PRIMARY KEY (message_id, claim_id, evidence_id),
      FOREIGN KEY (message_id)
        REFERENCES messages(message_id) ON DELETE CASCADE,
      FOREIGN KEY (evidence_id)
        REFERENCES tool_evidence_records(evidence_id) ON DELETE CASCADE
    )
  ''');
  await database.execute(
    'CREATE INDEX IF NOT EXISTS answer_claim_evidence_evidence_id_index '
    'ON answer_claim_evidence(evidence_id)',
  );

  await database.execute('''
    CREATE TRIGGER IF NOT EXISTS tool_invocation_events_prevent_update
    BEFORE UPDATE ON tool_invocation_events
    BEGIN
      SELECT RAISE(ABORT, 'Tool invocation events are append-only');
    END
  ''');
  await database.execute('''
    CREATE TRIGGER IF NOT EXISTS tool_evidence_records_prevent_update
    BEFORE UPDATE ON tool_evidence_records
    BEGIN
      SELECT RAISE(ABORT, 'Tool evidence records are append-only');
    END
  ''');
  await database.execute('''
    CREATE TRIGGER IF NOT EXISTS answer_claim_evidence_prevent_update
    BEFORE UPDATE ON answer_claim_evidence
    BEGIN
      SELECT RAISE(ABORT, 'Claim evidence links are append-only');
    END
  ''');
}

Future<void> _rebuildToolEvidenceSchemaForProviderNative(
  DatabaseExecutor database,
) async {
  await database.execute('''
    CREATE TEMP TABLE grd012_invocation_events AS
    SELECT * FROM tool_invocation_events
  ''');
  await database.execute('''
    CREATE TEMP TABLE grd012_evidence_records AS
    SELECT * FROM tool_evidence_records
  ''');
  await database.execute('''
    CREATE TEMP TABLE grd012_claim_evidence AS
    SELECT * FROM answer_claim_evidence
  ''');
  await database.execute('DROP TABLE answer_claim_evidence');
  await database.execute('DROP TABLE tool_evidence_records');
  await database.execute('DROP TABLE tool_invocation_events');
  await _createToolEvidenceSchema(database);
  await database.execute('''
    INSERT INTO tool_invocation_events
    SELECT * FROM grd012_invocation_events
  ''');
  await database.execute('''
    INSERT INTO tool_evidence_records
    SELECT * FROM grd012_evidence_records
  ''');
  await database.execute('''
    INSERT INTO answer_claim_evidence
    SELECT * FROM grd012_claim_evidence
  ''');
  await database.execute('DROP TABLE grd012_claim_evidence');
  await database.execute('DROP TABLE grd012_evidence_records');
  await database.execute('DROP TABLE grd012_invocation_events');
}
