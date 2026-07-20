import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

typedef ApplicationDocumentsDirectoryProvider = Future<Directory> Function();

class DatabaseService {
  DatabaseService({
    ApplicationDocumentsDirectoryProvider?
    applicationDocumentsDirectoryProvider,
  }) : _applicationDocumentsDirectoryProvider =
           applicationDocumentsDirectoryProvider ??
           getApplicationDocumentsDirectory;

  final ApplicationDocumentsDirectoryProvider
  _applicationDocumentsDirectoryProvider;
  Database? _database;
  Future<Database>? _openingDatabase;
  static const int databaseVersion = 3;

  // 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    return initDatabase();
  }

  // 初始化数据库
  Future<Database> initDatabase() async {
    if (_database != null) return _database!;
    final opening = _openingDatabase;
    if (opening != null) return opening;

    final future = _openDatabase();
    _openingDatabase = future;
    try {
      _database = await future;
      return _database!;
    } finally {
      _openingDatabase = null;
    }
  }

  Future<Database> _openDatabase() async {
    final Directory appDocDir = await _applicationDocumentsDirectoryProvider();
    final String appDocPath = appDocDir.path;
    final path = join(appDocPath, 'app.db');

    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: createSchema,
      onUpgrade: migrateSchema,
    );
  }

  static Future<void> createSchema(Database db, int version) async {
    // 创建聊天列表表
    await db.execute('''
          CREATE TABLE chats (
            id TEXT PRIMARY KEY,
            bot_id TEXT,
            last_message TEXT,
            last_message_timestamp INTEGER,
            create_timestamp INTERGER,
            modify_timestamp INTERGER
          );
        ''');

    // 创建聊天消息表
    await db.execute('''
          CREATE TABLE messages (
            message_id TEXT NOT NULL UNIQUE,
            turn_id TEXT NOT NULL,
            run_id TEXT NOT NULL DEFAULT '',
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
            terminal_state TEXT NOT NULL DEFAULT '',
            has_partial_content INTEGER NOT NULL DEFAULT 0,
            timestamp INTEGER
          );
        ''');
    await db.execute(
      'CREATE UNIQUE INDEX messages_message_id_unique '
      'ON messages(message_id)',
    );

    // 创建智能体表
    await db.execute('''
          CREATE TABLE bots (
            id TEXT PRIMARY KEY,
            name TEXT,
            avatar TEXT,
            provider TEXT,
            base_url TEXT,
            api_key TEXT,
            api_type TEXT,
            model TEXT,
            system_prompt TEXT,
            parameters TEXT,
            create_timestamp INTEGER,
            modify_timestamp INTEGER
          );
        ''');

    // 创建个人资料表
    await db.execute('''
          CREATE TABLE profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            avatar TEXT,
            font_size DOUBLE,
            theme_mode INTEGER,
            language TEXT,
            create_timestamp INTEGER,
            modify_timestamp INTEGER
          );
        ''');
  }

  static Future<void> migrateSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(db, 'messages', 'process_info', 'TEXT');
    }
    if (oldVersion < 3) {
      await _addColumnIfMissing(db, 'messages', 'message_id', 'TEXT');
      await _addColumnIfMissing(db, 'messages', 'turn_id', 'TEXT');
      await _addColumnIfMissing(
        db,
        'messages',
        'run_id',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _addColumnIfMissing(
        db,
        'messages',
        'terminal_state',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _addColumnIfMissing(
        db,
        'messages',
        'has_partial_content',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('''
        UPDATE messages
        SET message_id = 'legacy:' || chat_id || ':' || rowid
        WHERE message_id IS NULL OR message_id = ''
      ''');
      await db.execute('''
        UPDATE messages
        SET turn_id = 'legacy-turn:' || chat_id || ':' || rowid
        WHERE turn_id IS NULL OR turn_id = ''
      ''');
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS messages_message_id_unique '
        'ON messages(message_id)',
      );
    }
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String tableName,
    String columnName,
    String columnType,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final hasColumn = columns.any((column) => column['name'] == columnName);
    if (!hasColumn) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN $columnName $columnType',
      );
    }
  }
}
