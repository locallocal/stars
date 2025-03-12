import 'package:sqflite/sqflite.dart';
import 'package:bubble/model/model.dart';
import 'package:bubble/services/database_service.dart';

class MessageService {
  // 获取聊天列表
  static Future<List<Message>> getMessages(String botId) async {
    final db = await DatabaseService.database;
    final messages = await db.query(
      'messages',
      where: 'bot_id = ?',
      whereArgs: [botId],
      orderBy: 'timestamp ASC',
    );
    if (messages.isEmpty) {
      return [];
    }
    List<Message> botMessages =
        messages.map((e) => Message.fromMap(e)).toList();
    return botMessages;
  }

  // 添加消息
  static Future<void> addMessage(Message message) async {
    final db = await DatabaseService.database;
    await db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 删除消息
  static Future<void> deleteBotMessage(String botId) async {
    final db = await DatabaseService.database;
    // 删除智能体消息
    await db.delete('messages', where: 'bot_id = ?', whereArgs: [botId]);
  }
}
