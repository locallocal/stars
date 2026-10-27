part of 'local_database_service.dart';

extension LocalDatabaseMcpSkills on LocalDatabaseService {
  Future<List<Map<String, Object?>>> loadMcpServers() async {
    final database = await _databaseProvider();
    return database.query('mcp_servers', orderBy: 'name ASC');
  }

  Future<List<Map<String, Object?>>> queryInstalledMcpInventory({
    required String query,
    required int limit,
  }) async {
    final database = await _databaseProvider();
    return database.rawQuery(
      '''
      SELECT
        s.id,
        s.name,
        s.transport_type,
        s.remote_server_name,
        s.remote_server_version,
        s.connection_status,
        s.last_error_code,
        s.last_connected_at,
        s.created_at,
        s.updated_at,
        COUNT(t.remote_name) AS tool_count
      FROM mcp_servers AS s
      LEFT JOIN mcp_tools AS t ON t.server_id = s.id
      WHERE ? = '' OR instr(lower(s.name), ?) > 0
      GROUP BY s.id
      ORDER BY lower(s.name) ASC, s.id ASC
      LIMIT ?
    ''',
      [query, query, limit],
    );
  }

  Future<List<Map<String, Object?>>> queryConversationMcpIdentity(
    String chatId,
  ) async {
    final database = await _databaseProvider();
    return database.rawQuery(
      '''
      SELECT
        c.id AS chat_id,
        b.id AS bot_id,
        b.name AS bot_name,
        b.parameters AS bot_parameters
      FROM chats AS c
      JOIN bots AS b ON b.id = c.bot_id
      WHERE c.id = ?
      LIMIT 1
    ''',
      [chatId],
    );
  }

  Future<List<Map<String, Object?>>> loadAllMcpTools() async {
    final database = await _databaseProvider();
    return database.query(
      'mcp_tools',
      orderBy: 'server_id ASC, remote_name ASC',
    );
  }

  Future<List<Map<String, Object?>>> loadMcpServer(String id) async {
    final database = await _databaseProvider();
    return database.query(
      'mcp_servers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
  }

  Future<void> insertMcpServer(
    Map<String, Object?> values, {
    Future<void> Function()? beforeCommit,
  }) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await _checkMcpName(transaction, values);
      final existing = await transaction.query(
        'mcp_servers',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [values['id']],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        throw const McpException('mcp_server_id_conflict');
      }
      await transaction.insert(
        'mcp_servers',
        values,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await beforeCommit?.call();
    });
  }

  Future<void> upsertMcpServer(
    Map<String, Object?> values, {
    bool clearTools = false,
  }) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await _upsertMcpServer(transaction, values);
      if (clearTools) {
        await transaction.delete(
          'mcp_tools',
          where: 'server_id = ?',
          whereArgs: [values['id']],
        );
      }
    });
  }

  Future<void> deleteMcpServer(String id) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await transaction.delete(
        'mcp_tools',
        where: 'server_id = ?',
        whereArgs: [id],
      );
      await transaction.delete('mcp_servers', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Map<String, Object?>>> loadMcpTools(String serverId) async {
    final database = await _databaseProvider();
    return database.query(
      'mcp_tools',
      where: 'server_id = ?',
      whereArgs: [serverId],
      orderBy: 'remote_name ASC',
    );
  }

  Future<void> replaceMcpCatalog(
    Map<String, Object?> server,
    Iterable<Map<String, Object?>> tools,
  ) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await _upsertMcpServer(transaction, server);
      await transaction.delete(
        'mcp_tools',
        where: 'server_id = ?',
        whereArgs: [server['id']],
      );
      for (final values in tools) {
        await transaction.insert('mcp_tools', values);
      }
    });
  }

  Future<void> _upsertMcpServer(
    DatabaseExecutor database,
    Map<String, Object?> values,
  ) async {
    await _checkMcpName(database, values);
    final updated = await database.update(
      'mcp_servers',
      values,
      where: 'id = ?',
      whereArgs: [values['id']],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    if (updated == 0) {
      await database.insert(
        'mcp_servers',
        values,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  Future<void> _checkMcpName(
    DatabaseExecutor database,
    Map<String, Object?> values,
  ) async {
    final name = (values['name']! as String).trim().toLowerCase();
    final rows = await database.query('mcp_servers', columns: ['id', 'name']);
    // Existing duplicate names from older versions can still refresh their
    // catalogs. New inserts and renames must not introduce another duplicate.
    if (rows.any(
      (row) => row['id'] == values['id'] && row['name'] == values['name'],
    )) {
      return;
    }
    if (rows.any(
      (row) =>
          row['id'] != values['id'] &&
          (row['name']! as String).trim().toLowerCase() == name,
    )) {
      throw const McpException('mcp_server_already_exists');
    }
  }

  Future<List<Map<String, Object?>>> loadBotSkillBindings(String botId) async {
    final database = await _databaseProvider();
    return database.query(
      'bot_skill_bindings',
      where: 'bot_id = ?',
      whereArgs: [botId],
      orderBy: 'priority DESC, skill_id ASC',
    );
  }

  Future<List<Map<String, Object?>>> loadBotSkillBindingCounts(
    Iterable<String> botIds,
  ) async {
    final ids = botIds.toSet().toList(growable: false);
    if (ids.isEmpty) return const [];
    final database = await _databaseProvider();
    final placeholders = List.filled(ids.length, '?').join(',');
    return database.rawQuery('''
      SELECT bot_id, COUNT(*) AS binding_count
      FROM bot_skill_bindings
      WHERE bot_id IN ($placeholders)
      GROUP BY bot_id
      ''', ids);
  }

  Future<void> upsertBotSkillBinding(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.insert(
      'bot_skill_bindings',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBotSkillBinding(String botId, String skillId) async {
    final database = await _databaseProvider();
    await database.delete(
      'bot_skill_bindings',
      where: 'bot_id = ? AND skill_id = ?',
      whereArgs: [botId, skillId],
    );
  }

  Future<List<Map<String, Object?>>> loadConversationSkillPins(
    String chatId,
  ) async {
    final database = await _databaseProvider();
    return database.query(
      'conversation_skill_pins',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'created_at ASC, skill_id ASC',
    );
  }

  Future<void> upsertConversationSkillPin(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.insert(
      'conversation_skill_pins',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteConversationSkillPin(String chatId, String skillId) async {
    final database = await _databaseProvider();
    await database.delete(
      'conversation_skill_pins',
      where: 'chat_id = ? AND skill_id = ?',
      whereArgs: [chatId, skillId],
    );
  }

  Future<void> clearConversationSkillPins(String chatId) async {
    final database = await _databaseProvider();
    await database.delete(
      'conversation_skill_pins',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> upsertSkillActivations(
    Iterable<Map<String, Object?>> records,
  ) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      for (final values in records) {
        await transaction.insert(
          'skill_activations',
          values,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> loadSkillActivationsForRun(
    String runId,
  ) async {
    final database = await _databaseProvider();
    return database.query(
      'skill_activations',
      where: 'run_id = ?',
      whereArgs: [runId],
      orderBy: 'started_at ASC, id ASC',
    );
  }
}
