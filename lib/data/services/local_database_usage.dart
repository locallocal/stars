part of 'local_database_service.dart';

extension LocalDatabaseUsage on LocalDatabaseService {
  Future<Map<String, Object?>> loadTokenUsageForBot(String botId) async {
    final database = await _databaseProvider();
    final rows = await database.rawQuery(
      '''
      SELECT
        COALESCE(SUM(input_token_count), 0) AS input_token_count,
        COALESCE(SUM(output_token_count), 0) AS output_token_count,
        COALESCE(SUM(
          CASE
            WHEN total_token_count > 0 THEN total_token_count
            ELSE input_token_count + output_token_count
          END
        ), 0) AS total_token_count
      FROM token_usage_records
      WHERE bot_id = ?
      ''',
      [botId],
    );
    return rows.single;
  }

  Future<List<Map<String, Object?>>> loadTokenUsageForBots(
    Iterable<String> botIds,
  ) async {
    final ids = botIds.toSet().toList(growable: false);
    if (ids.isEmpty) return const [];
    final database = await _databaseProvider();
    final placeholders = List.filled(ids.length, '?').join(',');
    return database.rawQuery('''
      SELECT
        bot_id,
        COALESCE(SUM(input_token_count), 0) AS input_token_count,
        COALESCE(SUM(output_token_count), 0) AS output_token_count,
        COALESCE(SUM(
          CASE
            WHEN total_token_count > 0 THEN total_token_count
            ELSE input_token_count + output_token_count
          END
        ), 0) AS total_token_count
      FROM token_usage_records
      WHERE bot_id IN ($placeholders)
      GROUP BY bot_id
      ''', ids);
  }

  Future<List<Map<String, Object?>>> loadTokenUsageByChatForBot(
    String botId,
  ) async {
    final database = await _databaseProvider();
    return database.rawQuery(
      '''
      SELECT
        chat_id,
        input_token_count,
        output_token_count,
        total_token_count
      FROM (
        SELECT
          chat_id,
          COALESCE(SUM(input_token_count), 0) AS input_token_count,
          COALESCE(SUM(output_token_count), 0) AS output_token_count,
          COALESCE(SUM(
            CASE
              WHEN total_token_count > 0 THEN total_token_count
              ELSE input_token_count + output_token_count
            END
          ), 0) AS total_token_count
        FROM token_usage_records
        WHERE bot_id = ?
        GROUP BY chat_id
      ) AS usage_by_chat
      WHERE total_token_count > 0
      ORDER BY total_token_count DESC, chat_id ASC
      ''',
      [botId],
    );
  }

  Future<List<Map<String, Object?>>> loadTokenUsageRecordsForChat(
    String chatId,
  ) async {
    final database = await _databaseProvider();
    return database.query(
      'token_usage_records',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC, message_id ASC',
    );
  }

  Future<List<Map<String, Object?>>> loadTokenUsageRecordsForBot(
    String botId,
  ) async {
    final database = await _databaseProvider();
    return database.query(
      'token_usage_records',
      where: 'bot_id = ?',
      whereArgs: [botId],
      orderBy: 'timestamp ASC, message_id ASC',
    );
  }

  Future<void> upsertMessage(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await _upsertMessageAndTokenUsage(transaction, values);
    });
    final chatId = values['chat_id']?.toString();
    if (chatId != null && chatId.isNotEmpty) _advanceMessageRevision(chatId);
  }

  Future<void> upsertMessages(Iterable<Map<String, Object?>> records) async {
    final rows = records.toList(growable: false);
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      for (final values in rows) {
        await _upsertMessageAndTokenUsage(transaction, values);
      }
    });
    final chatIds = <String>{
      for (final values in rows)
        if ((values['chat_id']?.toString() ?? '').isNotEmpty)
          values['chat_id']!.toString(),
    };
    for (final chatId in chatIds) {
      _advanceMessageRevision(chatId);
    }
  }

  Future<void> upsertModelUsage(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.insert(
      'token_usage_records',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMessages(String chatId) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await transaction.delete(
        'tool_evidence_records',
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );
      await transaction.delete(
        'tool_invocation_events',
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );
      await transaction.delete(
        'tool_execution_records',
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );
      await transaction.delete(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );
    });
    _advanceMessageRevision(chatId);
  }

  Future<List<Map<String, Object?>>> loadProfiles() async {
    final database = await _databaseProvider();
    return database.query('profile', limit: 1);
  }

  Future<void> insertProfile(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.insert('profile', values);
  }

  Future<void> updateProfile(Object id, Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.update('profile', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _upsertMessageAndTokenUsage(
    DatabaseExecutor database,
    Map<String, Object?> values,
  ) async {
    await _upsertByPrimaryKey(database, 'messages', values, 'message_id');

    final messageId = values['message_id']?.toString() ?? '';
    if (messageId.isEmpty) return;
    final inputTokens = _readCount(values['input_token_count']);
    final outputTokens = _readCount(values['output_token_count']);
    final totalTokens = _readCount(values['total_token_count']);
    final hasUsage = inputTokens > 0 || outputTokens > 0 || totalTokens > 0;
    if (!hasUsage) {
      await database.delete(
        'token_usage_records',
        where: 'message_id = ?',
        whereArgs: [messageId],
      );
      return;
    }

    await database.insert('token_usage_records', <String, Object?>{
      'message_id': messageId,
      'chat_id': values['chat_id']?.toString() ?? '',
      'bot_id': values['bot_id']?.toString() ?? '',
      'operation_kind': 'chat_reply',
      'token_model': values['token_model']?.toString() ?? '',
      'input_token_count': inputTokens,
      'output_token_count': outputTokens,
      'total_token_count': totalTokens,
      'timestamp': _readCount(values['timestamp']),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

int _readCount(Object? value) {
  return switch (value) {
    final int count => count,
    final num count => count.toInt(),
    _ => int.tryParse(value?.toString() ?? '') ?? 0,
  };
}
