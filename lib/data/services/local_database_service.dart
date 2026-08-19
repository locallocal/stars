import 'package:sqflite/sqflite.dart';

part 'local_database_mcp_skills.dart';
part 'local_database_conversations.dart';
part 'local_database_usage.dart';

typedef DatabaseProvider = Future<Database> Function();

/// Boundary around sqflite. Repositories never open databases or assemble
/// cross-table transactions themselves.
class LocalDatabaseService {
  LocalDatabaseService({required DatabaseProvider databaseProvider})
    : _databaseProvider = databaseProvider;

  final DatabaseProvider _databaseProvider;
  final Map<String, int> _messageRevisions = <String, int>{};

  int messageRevision(String chatId) => _messageRevisions[chatId] ?? 0;

  void _advanceMessageRevision(String chatId) {
    _messageRevisions[chatId] = messageRevision(chatId) + 1;
  }

  Future<List<Map<String, Object?>>> loadBots() async {
    final database = await _databaseProvider();
    return database.query('bots', orderBy: 'create_timestamp ASC');
  }

  Future<List<Map<String, Object?>>> loadBot(String id) async {
    final database = await _databaseProvider();
    return database.query('bots', where: 'id = ?', whereArgs: [id], limit: 1);
  }

  Future<void> insertBot(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await _upsertByPrimaryKey(database, 'bots', values, 'id');
  }

  Future<void> insertBotWithSkillBindings(
    Map<String, Object?> bot,
    Iterable<Map<String, Object?>> bindings,
  ) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await _upsertByPrimaryKey(transaction, 'bots', bot, 'id');
      for (final binding in bindings) {
        await transaction.insert(
          'bot_skill_bindings',
          binding,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> updateBot(String id, Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.update('bots', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteBot(String id) async {
    final database = await _databaseProvider();
    final chatRows = await database.query(
      'chats',
      columns: const ['id'],
      where: 'bot_id = ?',
      whereArgs: [id],
    );
    await database.transaction((transaction) async {
      await transaction.delete(
        'skill_activations',
        where: 'chat_id IN (SELECT id FROM chats WHERE bot_id = ?)',
        whereArgs: [id],
      );
      await transaction.delete(
        'messages',
        where: 'chat_id IN (SELECT id FROM chats WHERE bot_id = ?)',
        whereArgs: [id],
      );
      await transaction.delete(
        'conversation_skill_pins',
        where: 'chat_id IN (SELECT id FROM chats WHERE bot_id = ?)',
        whereArgs: [id],
      );
      await transaction.delete(
        'conversation_summary_segments',
        where: 'chat_id IN (SELECT id FROM chats WHERE bot_id = ?)',
        whereArgs: [id],
      );
      await transaction.delete(
        'conversation_memory_items',
        where: 'chat_id IN (SELECT id FROM chats WHERE bot_id = ?)',
        whereArgs: [id],
      );
      await transaction.delete(
        'conversation_memory_state',
        where: 'chat_id IN (SELECT id FROM chats WHERE bot_id = ?)',
        whereArgs: [id],
      );
      await transaction.delete('chats', where: 'bot_id = ?', whereArgs: [id]);
      await transaction.delete(
        'bot_skill_bindings',
        where: 'bot_id = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        'token_usage_records',
        where: 'bot_id = ?',
        whereArgs: [id],
      );
      await transaction.delete('bots', where: 'id = ?', whereArgs: [id]);
    });
    for (final row in chatRows) {
      _advanceMessageRevision(row['id']?.toString() ?? '');
    }
  }

  Future<List<Map<String, Object?>>> loadSkills() async {
    final database = await _databaseProvider();
    return database.query('skills', orderBy: 'name ASC');
  }

  Future<List<Map<String, Object?>>> loadSkill(String id) async {
    final database = await _databaseProvider();
    return database.query('skills', where: 'id = ?', whereArgs: [id], limit: 1);
  }

  Future<List<Map<String, Object?>>> loadSkillByScopeAndName(
    String scope,
    String name,
  ) async {
    final database = await _databaseProvider();
    return database.query(
      'skills',
      where: 'scope = ? AND name = ?',
      whereArgs: [scope, name],
      limit: 1,
    );
  }

  Future<List<Map<String, Object?>>> queryInstalledSkillInventory({
    required String query,
    required int limit,
  }) async {
    final database = await _databaseProvider();
    return database.rawQuery(
      '''
      SELECT
        s.id,
        s.name,
        s.description,
        s.version,
        s.scope,
        s.trust_state,
        s.validation_status,
        s.signature_status,
        s.installed_at,
        s.updated_at,
        COUNT(DISTINCT b.bot_id) AS bound_bot_count,
        COUNT(DISTINCT CASE WHEN b.enabled = 1 THEN b.bot_id END)
          AS enabled_bot_count
      FROM skills AS s
      LEFT JOIN bot_skill_bindings AS b ON b.skill_id = s.id
      WHERE ? = ''
        OR instr(lower(s.id), ?) > 0
        OR instr(lower(s.name), ?) > 0
        OR instr(lower(s.description), ?) > 0
        OR instr(lower(s.source_uri), ?) > 0
      GROUP BY s.id
      ORDER BY lower(s.name) ASC, s.id ASC
      LIMIT ?
    ''',
      [query, query, query, query, query, limit],
    );
  }

  Future<List<Map<String, Object?>>> queryConversationSkillInventory(
    String chatId,
  ) async {
    final database = await _databaseProvider();
    return database.rawQuery(
      '''
      WITH current_chat AS (
        SELECT id AS chat_id, bot_id
        FROM chats
        WHERE id = ?
        LIMIT 1
      ),
      skill_ids AS (
        SELECT b.skill_id
        FROM bot_skill_bindings AS b
        JOIN current_chat AS c ON c.bot_id = b.bot_id
        UNION
        SELECT p.skill_id
        FROM conversation_skill_pins AS p
        JOIN current_chat AS c ON c.chat_id = p.chat_id
      )
      SELECT
        ids.skill_id AS id,
        COALESCE(
          s.name,
          CASE
            WHEN instr(ids.skill_id, ':') > 0
              THEN substr(ids.skill_id, instr(ids.skill_id, ':') + 1)
            ELSE ids.skill_id
          END
        ) AS name,
        COALESCE(s.version, '') AS version,
        COALESCE(
          s.scope,
          CASE WHEN ids.skill_id LIKE 'system:%' THEN 'bundled' ELSE '' END
        ) AS scope,
        CASE WHEN s.id IS NULL THEN 0 ELSE 1 END AS installed,
        CASE WHEN ids.skill_id LIKE 'system:%' THEN 1 ELSE 0 END AS bundled,
        CASE
          WHEN s.id IS NOT NULL OR ids.skill_id LIKE 'system:%' THEN 1
          ELSE 0
        END AS available,
        COALESCE(b.enabled, 0) AS configured_enabled,
        CASE WHEN p.skill_id IS NULL THEN 0 ELSE 1 END
          AS pinned_to_conversation,
        COALESCE(b.activation_mode, '') AS activation_mode,
        COALESCE(b.priority, 0) AS priority,
        COALESCE((
          SELECT a.status
          FROM skill_activations AS a
          WHERE a.chat_id = c.chat_id AND a.skill_id = ids.skill_id
          ORDER BY a.started_at DESC, a.id DESC
          LIMIT 1
        ), '') AS last_activation_status,
        (
          SELECT a.started_at
          FROM skill_activations AS a
          WHERE a.chat_id = c.chat_id AND a.skill_id = ids.skill_id
          ORDER BY a.started_at DESC, a.id DESC
          LIMIT 1
        ) AS last_activated_at
      FROM skill_ids AS ids
      CROSS JOIN current_chat AS c
      LEFT JOIN skills AS s ON s.id = ids.skill_id
      LEFT JOIN bot_skill_bindings AS b
        ON b.bot_id = c.bot_id AND b.skill_id = ids.skill_id
      LEFT JOIN conversation_skill_pins AS p
        ON p.chat_id = c.chat_id AND p.skill_id = ids.skill_id
      ORDER BY configured_enabled DESC, priority DESC, lower(name) ASC, id ASC
    ''',
      [chatId],
    );
  }

  Future<void> upsertSkill(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await _upsertByPrimaryKey(database, 'skills', values, 'id');
  }

  Future<void> deleteSkill(String id) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await transaction.delete(
        'bot_skill_bindings',
        where: 'skill_id = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        'conversation_skill_pins',
        where: 'skill_id = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        'skill_script_grants',
        where: 'skill_id = ?',
        whereArgs: [id],
      );
      await transaction.delete('skills', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Map<String, Object?>>> loadSkillPublishers() async {
    final database = await _databaseProvider();
    return database.query('skill_publishers', orderBy: 'name ASC');
  }

  Future<List<Map<String, Object?>>> loadSkillPublisher(String id) async {
    final database = await _databaseProvider();
    return database.query(
      'skill_publishers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
  }

  Future<void> upsertSkillPublisher(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.insert(
      'skill_publishers',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> loadSkillCatalogs() async {
    final database = await _databaseProvider();
    return database.query('skill_catalogs', orderBy: 'name ASC');
  }

  Future<void> upsertSkillCatalog(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.insert(
      'skill_catalogs',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setSkillUpdatePolicy(String skillId, String policy) async {
    final database = await _databaseProvider();
    await database.update(
      'skills',
      {
        'update_policy': policy,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [skillId],
    );
  }

  Future<List<Map<String, Object?>>> loadSkillOrganizationPolicy() async {
    final database = await _databaseProvider();
    return database.query(
      'skill_organization_policy',
      where: 'id = 1',
      limit: 1,
    );
  }

  Future<void> saveSkillOrganizationPolicy(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.insert('skill_organization_policy', {
      'id': 1,
      ...values,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> loadSkillScriptGrant(
    String skillId,
  ) async {
    final database = await _databaseProvider();
    return database.query(
      'skill_script_grants',
      where: 'skill_id = ?',
      whereArgs: [skillId],
      limit: 1,
    );
  }

  Future<void> upsertSkillScriptGrant(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.insert(
      'skill_script_grants',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSkillScriptGrant(String skillId) async {
    final database = await _databaseProvider();
    await database.delete(
      'skill_script_grants',
      where: 'skill_id = ?',
      whereArgs: [skillId],
    );
  }

  Future<void> insertSkillComplianceEvent(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await transaction.insert(
        'skill_compliance_events',
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await transaction.rawDelete('''
        DELETE FROM skill_compliance_events
        WHERE id IN (
          SELECT id
          FROM skill_compliance_events
          ORDER BY timestamp DESC
          LIMIT -1 OFFSET 10000
        )
      ''');
    });
  }

  Future<List<Map<String, Object?>>> loadSkillComplianceEvents({
    String? skillId,
    int limit = 100,
  }) async {
    final database = await _databaseProvider();
    return database.query(
      'skill_compliance_events',
      where: skillId == null ? null : 'skill_id = ?',
      whereArgs: skillId == null ? null : [skillId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }
}

Future<void> _upsertByPrimaryKey(
  DatabaseExecutor database,
  String table,
  Map<String, Object?> values,
  String key,
) async {
  final primaryKey = values[key];
  if (primaryKey == null) {
    throw ArgumentError.value(values, 'values', 'Missing primary key $key.');
  }
  final updates = Map<String, Object?>.from(values)..remove(key);
  final updated = await database.update(
    table,
    updates,
    where: '$key = ?',
    whereArgs: <Object?>[primaryKey],
    conflictAlgorithm: ConflictAlgorithm.abort,
  );
  if (updated == 0) {
    await database.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
}
