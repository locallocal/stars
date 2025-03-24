import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  // 获取数据库实例
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  // 初始化数据库
  static Future<Database> initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
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
            type TEXT,
            chat_id TEXT,
            bot_id TEXT,
            sender_id TEXT,
            content TEXT,
            timestamp INTEGER
          );
        ''');

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
      },
    );
  }
}
