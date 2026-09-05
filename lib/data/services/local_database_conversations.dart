part of 'local_database_service.dart';

extension LocalDatabaseConversations on LocalDatabaseService {
  Future<List<Map<String, Object?>>> loadChats() async {
    final database = await _databaseProvider();
    return database.query('chats', orderBy: 'last_message_timestamp DESC');
  }

  Future<List<Map<String, Object?>>> loadChat(String id) async {
    final database = await _databaseProvider();
    return database.query('chats', where: 'id = ?', whereArgs: [id], limit: 1);
  }

  Future<void> insertChat(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await _upsertByPrimaryKey(database, 'chats', values, 'id');
  }

  Future<void> deleteChat(String id) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await transaction.delete(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        'conversation_skill_pins',
        where: 'chat_id = ?',
        whereArgs: [id],
      );
      await _deleteConversationMemory(transaction, id);
      await transaction.delete('chats', where: 'id = ?', whereArgs: [id]);
    });
    _advanceMessageRevision(id);
  }

  Future<void> updateChatPreview(
    String id, {
    required String content,
    required DateTime timestamp,
  }) async {
    final database = await _databaseProvider();
    await database.update(
      'chats',
      {
        'last_message': content,
        'last_message_timestamp': timestamp.millisecondsSinceEpoch,
        'modify_timestamp': timestamp.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearChatHistory(String id, DateTime timestamp) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await transaction.delete(
        'agent_run_answer_checkpoints',
        where: 'chat_id = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        'tool_evidence_records',
        where: 'chat_id = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        'tool_invocation_events',
        where: 'chat_id = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        'tool_execution_records',
        where: 'chat_id = ?',
        whereArgs: [id],
      );
      await transaction.delete(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [id],
      );
      await _deleteConversationMemory(transaction, id);
      await transaction.update(
        'chats',
        {
          'last_message': '',
          'last_message_timestamp': timestamp.millisecondsSinceEpoch,
          'modify_timestamp': timestamp.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
    _advanceMessageRevision(id);
  }

  Future<List<Map<String, Object?>>> loadMessages(String chatId) async {
    final database = await _databaseProvider();
    return database.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC, message_id ASC',
    );
  }

  Future<List<Map<String, Object?>>> loadMessagePage(
    String chatId, {
    int? beforeTimestamp,
    String? beforeMessageId,
    required int limit,
  }) async {
    if (limit < 1 || limit > 200) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 200.');
    }
    final database = await _databaseProvider();
    final hasCursor = beforeTimestamp != null && beforeMessageId != null;
    return database.query(
      'messages',
      where:
          hasCursor
              ? 'chat_id = ? AND '
                  '(timestamp < ? OR (timestamp = ? AND message_id < ?))'
              : 'chat_id = ?',
      whereArgs:
          hasCursor
              ? [chatId, beforeTimestamp, beforeTimestamp, beforeMessageId]
              : [chatId],
      orderBy: 'timestamp DESC, message_id DESC',
      limit: limit + 1,
    );
  }

  Future<Set<String>> loadBotIdsForChat(String chatId) async {
    final database = await _databaseProvider();
    final records = await database.query(
      'messages',
      columns: const ['bot_id'],
      distinct: true,
      where: 'chat_id = ? AND bot_id != ?',
      whereArgs: [chatId, ''],
    );
    return {for (final record in records) record['bot_id']?.toString() ?? ''}
      ..remove('');
  }

  Future<List<Map<String, Object?>>> loadConversationMemoryState(
    String chatId,
  ) async {
    final database = await _databaseProvider();
    return database.query(
      'conversation_memory_state',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      limit: 1,
    );
  }

  Future<List<Map<String, Object?>>> loadActiveConversationSummary(
    String chatId,
  ) async {
    final database = await _databaseProvider();
    return database.rawQuery(
      '''
      SELECT segment.*
      FROM conversation_summary_segments AS segment
      INNER JOIN conversation_memory_state AS state
        ON state.chat_id = segment.chat_id
       AND state.active_summary_id = segment.id
      WHERE segment.chat_id = ? AND segment.status = 'active'
      LIMIT 1
      ''',
      [chatId],
    );
  }

  Future<List<Map<String, Object?>>> loadConversationMemoryItems(
    String chatId,
  ) async {
    final database = await _databaseProvider();
    return database.query(
      'conversation_memory_items',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: "CASE state WHEN 'pinned' THEN 0 ELSE 1 END, updated_at DESC",
    );
  }

  Future<void> invalidateConversationSummary(
    String chatId,
    String summaryId,
    String error,
  ) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await transaction.update(
        'conversation_summary_segments',
        {'status': 'invalid', 'updated_at': now},
        where: 'chat_id = ? AND id = ?',
        whereArgs: [chatId, summaryId],
      );
      await transaction.rawUpdate(
        '''
        UPDATE conversation_memory_state
        SET revision = revision + 1,
            active_summary_id = '',
            covered_through_message_id = '',
            compaction_status = 'failed',
            last_error = ?,
            updated_at = ?
        WHERE chat_id = ? AND active_summary_id = ?
        ''',
        [error, now, chatId, summaryId],
      );
    });
  }

  Future<bool> commitConversationCompaction({
    required String chatId,
    required int expectedRevision,
    required Map<String, Object?> summary,
    required Iterable<Map<String, Object?>> items,
  }) async {
    final database = await _databaseProvider();
    return database.transaction((transaction) async {
      final stateRows = await transaction.query(
        'conversation_memory_state',
        where: 'chat_id = ?',
        whereArgs: [chatId],
        limit: 1,
      );
      final currentRevision =
          stateRows.isEmpty ? 0 : _readCount(stateRows.first['revision']);
      if (currentRevision != expectedRevision) return false;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (stateRows.isNotEmpty) {
        final activeId = stateRows.first['active_summary_id']?.toString() ?? '';
        if (activeId.isNotEmpty) {
          await transaction.update(
            'conversation_summary_segments',
            {'status': 'superseded', 'updated_at': now},
            where: 'id = ? AND chat_id = ?',
            whereArgs: [activeId, chatId],
          );
        }
      }
      await transaction.insert(
        'conversation_summary_segments',
        {...summary, 'status': 'active', 'updated_at': now},
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      for (final item in items) {
        final memoryKey = item['memory_key']?.toString() ?? '';
        final existing = await transaction.query(
          'conversation_memory_items',
          columns: ['state', 'origin'],
          where: 'chat_id = ? AND memory_key = ?',
          whereArgs: [chatId, memoryKey],
          limit: 1,
        );
        final protected =
            existing.isNotEmpty &&
            (existing.first['origin'] == 'user' ||
                existing.first['state'] == 'pinned' ||
                existing.first['state'] == 'forgotten');
        if (!protected) {
          await transaction.insert(
            'conversation_memory_items',
            item,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      final state = <String, Object?>{
        'chat_id': chatId,
        'revision': currentRevision + 1,
        'active_summary_id': summary['id'],
        'covered_through_message_id': summary['source_end_message_id'],
        'auto_memory_enabled':
            stateRows.isEmpty
                ? 1
                : _readCount(stateRows.first['auto_memory_enabled']),
        'compaction_status': 'idle',
        'last_error': '',
        'last_compacted_at': now,
        'updated_at': now,
      };
      await transaction.insert(
        'conversation_memory_state',
        state,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    });
  }

  Future<void> upsertConversationMemoryItem(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.insert(
      'conversation_memory_items',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateConversationMemoryItemState(
    String chatId,
    String itemId,
    String state,
  ) async {
    final database = await _databaseProvider();
    await database.update(
      'conversation_memory_items',
      {'state': state, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'chat_id = ? AND id = ?',
      whereArgs: [chatId, itemId],
    );
  }

  Future<void> setConversationAutoMemoryEnabled(
    String chatId,
    bool enabled,
  ) async {
    final database = await _databaseProvider();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.rawInsert(
      '''
      INSERT INTO conversation_memory_state (
        chat_id, auto_memory_enabled, updated_at
      ) VALUES (?, ?, ?)
      ON CONFLICT(chat_id) DO UPDATE SET
        auto_memory_enabled = excluded.auto_memory_enabled,
        updated_at = excluded.updated_at
      ''',
      [chatId, enabled ? 1 : 0, now],
    );
  }

  Future<void> setConversationCompactionStatus(
    String chatId,
    String status,
    String lastError,
  ) async {
    final database = await _databaseProvider();
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.rawInsert(
      '''
      INSERT INTO conversation_memory_state (
        chat_id, compaction_status, last_error, updated_at
      ) VALUES (?, ?, ?, ?)
      ON CONFLICT(chat_id) DO UPDATE SET
        compaction_status = excluded.compaction_status,
        last_error = excluded.last_error,
        updated_at = excluded.updated_at
      ''',
      [chatId, status, lastError, now],
    );
  }

  Future<void> clearAutomaticConversationMemory(String chatId) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await transaction.delete(
        'conversation_summary_segments',
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );
      await transaction.delete(
        'conversation_memory_items',
        where: "chat_id = ? AND origin = 'auto' AND state != 'forgotten'",
        whereArgs: [chatId],
      );
      final updated = await transaction.update(
        'conversation_memory_state',
        {
          'revision': 0,
          'active_summary_id': '',
          'covered_through_message_id': '',
          'compaction_status': 'idle',
          'last_error': '',
          'last_compacted_at': null,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );
      if (updated == 0) {
        await transaction.insert('conversation_memory_state', {
          'chat_id': chatId,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  Future<void> deleteConversationMemory(String chatId) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await _deleteConversationMemory(transaction, chatId);
    });
  }

  static Future<void> _deleteConversationMemory(
    DatabaseExecutor database,
    String chatId,
  ) async {
    await database.delete(
      'conversation_summary_segments',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
    await database.delete(
      'conversation_memory_items',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
    await database.delete(
      'conversation_memory_state',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
  }
}
