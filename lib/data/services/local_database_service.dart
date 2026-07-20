import 'package:sqflite/sqflite.dart';

typedef DatabaseProvider = Future<Database> Function();

/// Stateless boundary around sqflite. Repositories never open databases or
/// assemble cross-table transactions themselves.
class LocalDatabaseService {
  const LocalDatabaseService({required DatabaseProvider databaseProvider})
    : _databaseProvider = databaseProvider;

  final DatabaseProvider _databaseProvider;

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
    await database.insert(
      'bots',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBot(String id, Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.update('bots', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteBot(String id) async {
    final database = await _databaseProvider();
    await database.delete('bots', where: 'id = ?', whereArgs: [id]);
  }

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
    await database.insert(
      'chats',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteChat(String id) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      await transaction.delete(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [id],
      );
      await transaction.delete('chats', where: 'id = ?', whereArgs: [id]);
    });
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
        'messages',
        where: 'chat_id = ?',
        whereArgs: [id],
      );
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
  }

  Future<List<Map<String, Object?>>> loadMessages(String chatId) async {
    final database = await _databaseProvider();
    return database.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> upsertMessage(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.insert(
      'messages',
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertMessages(Iterable<Map<String, Object?>> records) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      for (final values in records) {
        await transaction.insert(
          'messages',
          values,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> deleteMessages(String chatId) async {
    final database = await _databaseProvider();
    await database.delete(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
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
}
