import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:stars/data/services/database_service.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'schema migration backfills stable identities and creates a unique index',
    () async {
      final database = await _openMigratedV2Database();
      addTearDown(database.close);

      final rows = await database.query('messages', orderBy: 'rowid ASC');
      expect(rows, hasLength(2));
      expect(
        rows.map((row) => row['message_id']),
        orderedEquals(<String>['legacy:chat-1:1', 'legacy:chat-1:2']),
      );
      expect(
        rows.map((row) => row['turn_id']),
        orderedEquals(<String>['legacy-turn:chat-1:1', 'legacy-turn:chat-1:2']),
      );
      expect(rows.map((row) => row['run_id']), everyElement(''));
      expect(rows.map((row) => row['terminal_state']), everyElement(''));
      expect(rows.map((row) => row['has_partial_content']), everyElement(0));
      final profiles = await database.query('profile');
      expect(profiles.single['show_execution_status'], 1);

      final indexes = await database.rawQuery('PRAGMA index_list(messages)');
      final identityIndex = indexes.singleWhere(
        (index) => index['name'] == 'messages_message_id_unique',
      );
      expect(identityIndex['unique'], 1);
    },
  );

  test('replacing a duplicate message id leaves exactly one row', () async {
    final database = await _openMigratedV2Database();
    addTearDown(database.close);

    const messageId = 'assistant:stable-id';
    await database.insert('messages', <String, Object?>{
      'message_id': messageId,
      'turn_id': 'turn-1',
      'chat_id': 'chat-1',
      'content': 'first response',
    });
    await database.insert('messages', <String, Object?>{
      'message_id': messageId,
      'turn_id': 'turn-1',
      'chat_id': 'chat-1',
      'content': 'updated response',
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final rows = await database.query(
      'messages',
      where: 'message_id = ?',
      whereArgs: <Object?>[messageId],
    );
    expect(rows, hasLength(1));
    expect(rows.single['content'], 'updated response');
  });
}

Future<Database> _openMigratedV2Database() async {
  final database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
  await database.execute('''
    CREATE TABLE messages (
      chat_id TEXT,
      bot_id TEXT,
      sender_id TEXT,
      content TEXT,
      reasoning TEXT,
      process_info TEXT,
      images TEXT,
      files TEXT,
      audio TEXT,
      music TEXT,
      video TEXT,
      timestamp INTEGER
    )
  ''');
  await database.execute('''
    CREATE TABLE profile (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      avatar TEXT,
      font_size DOUBLE,
      theme_mode INTEGER,
      language TEXT,
      create_timestamp INTEGER,
      modify_timestamp INTEGER
    )
  ''');
  await database.insert('profile', <String, Object?>{
    'name': 'Legacy User',
    'font_size': 16,
    'theme_mode': 0,
    'language': 'zh_CN',
    'create_timestamp': 0,
    'modify_timestamp': 0,
  });
  await database.insert('messages', <String, Object?>{
    'chat_id': 'chat-1',
    'content': 'legacy user message',
  });
  await database.insert('messages', <String, Object?>{
    'chat_id': 'chat-1',
    'content': 'legacy assistant message',
  });

  await DatabaseService.migrateSchema(
    database,
    2,
    DatabaseService.databaseVersion,
  );
  return database;
}
