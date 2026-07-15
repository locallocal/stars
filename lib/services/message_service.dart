import 'package:sqflite/sqflite.dart';
import 'package:stars/model/model.dart';
import 'package:stars/services/database_service.dart';

class MessageService {
  static int _identitySequence = 0;

  static String createId(String prefix) {
    _identitySequence = (_identitySequence + 1) & 0x7fffffff;
    return '$prefix:${DateTime.now().microsecondsSinceEpoch}:'
        '$_identitySequence';
  }

  static Message ensureIdentity(Message message) {
    final messageId =
        message.messageId.isEmpty ? createId('message') : message.messageId;
    final turnId = message.turnId.isEmpty ? createId('turn') : message.turnId;
    return message.copyWith(messageId: messageId, turnId: turnId);
  }

  // 获取聊天列表
  static Future<List<Message>> getMessages(String chatId) async {
    final db = await DatabaseService.database;
    final messages = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    if (messages.isEmpty) {
      return [];
    }
    List<Message> chatMessages =
        messages.map((e) => Message.fromMap(e)).toList();
    return chatMessages;
  }

  // 添加消息
  static Future<Message> addMessage(Message message) => upsertMessage(message);

  static Future<Message> upsertMessage(Message message) async {
    final db = await DatabaseService.database;
    final identified = ensureIdentity(message);
    await db.insert(
      'messages',
      identified.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return identified;
  }

  static Future<List<Message>> upsertMessages(
    Iterable<Message> messages,
  ) async {
    final db = await DatabaseService.database;
    final identified = messages.map(ensureIdentity).toList(growable: false);
    await db.transaction((transaction) async {
      for (final message in identified) {
        await transaction.insert(
          'messages',
          message.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    return identified;
  }

  // 删除消息
  static Future<void> deleteChatMessage(String chatId) async {
    final db = await DatabaseService.database;
    // 删除智能体消息
    await db.delete('messages', where: 'chat_id = ?', whereArgs: [chatId]);
  }
}
