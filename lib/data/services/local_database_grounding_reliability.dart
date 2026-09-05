part of 'local_database_service.dart';

extension LocalDatabaseGroundingReliability on LocalDatabaseService {
  Future<void> upsertAgentRunAnswerCheckpoint(
    Map<String, Object?> values,
  ) async {
    final database = await _databaseProvider();
    await database.insert(
      'agent_run_answer_checkpoints',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> loadAgentRunAnswerCheckpoints() async {
    final database = await _databaseProvider();
    return database.query(
      'agent_run_answer_checkpoints',
      orderBy: 'created_at ASC, run_id ASC',
    );
  }

  Future<void> deleteAgentRunAnswerCheckpoint(String runId) async {
    final database = await _databaseProvider();
    await database.delete(
      'agent_run_answer_checkpoints',
      where: 'run_id = ?',
      whereArgs: [runId],
    );
  }

  Future<List<Map<String, Object?>>>
  loadLatestNonTerminalToolInvocationEvents() async {
    final database = await _databaseProvider();
    return database.rawQuery('''
      SELECT event.*
      FROM tool_invocation_events AS event
      INNER JOIN (
        SELECT attempt_id, MAX(sequence) AS latest_sequence
        FROM tool_invocation_events
        GROUP BY attempt_id
      ) AS latest
        ON latest.attempt_id = event.attempt_id
       AND latest.latest_sequence = event.sequence
      WHERE event.status IN ('requested', 'awaitingApproval', 'running')
      ORDER BY event.occurred_at ASC, event.event_id ASC
    ''');
  }

  Future<void> appendInterruptedToolInvocation(
    Map<String, Object?> event,
  ) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await _insertImmutableLedgerRecord(
        transaction,
        table: 'tool_invocation_events',
        identityColumn: 'event_id',
        values: event,
      );
      await transaction.update(
        'tool_execution_records',
        <String, Object?>{
          'status': 'interrupted',
          'detail': 'agent_run_interrupted',
          'error_code': 'agent_run_interrupted',
          'completed_at': event['occurred_at'],
          'updated_at': event['occurred_at'],
        },
        where:
            "attempt_id = ? AND status IN "
            "('requested', 'awaitingApproval', 'running')",
        whereArgs: [event['attempt_id']],
      );
    });
  }

  Future<List<Map<String, Object?>>> loadEvidenceAwaitingAnswer() async {
    final database = await _databaseProvider();
    return database.rawQuery('''
      SELECT evidence.*
      FROM tool_evidence_records AS evidence
      LEFT JOIN messages AS message
        ON message.message_id = evidence.message_id
      WHERE evidence.message_id != ''
        AND (
          message.message_id IS NULL
          OR message.terminal_state = ''
          OR message.grounding_json LIKE '%evidence_commit_pending%'
        )
      ORDER BY evidence.observed_at ASC, evidence.evidence_id ASC
    ''');
  }

  Future<String?> loadRecoveryBotIdForChat(String chatId) async {
    final database = await _databaseProvider();
    final rows = await database.query(
      'chats',
      columns: const ['bot_id'],
      where: 'id = ?',
      whereArgs: [chatId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final botId = rows.single['bot_id'];
    return botId is String && botId.isNotEmpty ? botId : null;
  }

  Future<void> incrementGroundingMetrics(
    Iterable<Map<String, Object?>> deltas, {
    String observationId = '',
  }) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      if (observationId.isNotEmpty) {
        final existing = await transaction.query(
          'grounding_metric_observations',
          columns: const ['observation_id'],
          where: 'observation_id = ?',
          whereArgs: [observationId],
          limit: 1,
        );
        if (existing.isNotEmpty) return;
        await transaction
            .insert('grounding_metric_observations', <String, Object?>{
              'observation_id': observationId,
              'recorded_at': DateTime.now().toUtc().millisecondsSinceEpoch,
            });
      }
      for (final delta in deltas) {
        await transaction.rawInsert(
          '''
          INSERT INTO grounding_metric_counters (
            metric, category, count, updated_at
          ) VALUES (?, ?, ?, ?)
          ON CONFLICT(metric, category) DO UPDATE SET
            count = count + excluded.count,
            updated_at = excluded.updated_at
          ''',
          [
            delta['metric'],
            delta['category'],
            delta['count'],
            delta['updated_at'],
          ],
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> loadGroundingMetrics() async {
    final database = await _databaseProvider();
    return database.query(
      'grounding_metric_counters',
      orderBy: 'metric ASC, category ASC',
    );
  }
}
