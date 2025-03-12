import 'package:bubble/services/message_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bubble/services/database_service.dart';
import 'package:bubble/model/model.dart';

class ChatService {
  static List<Chat> _chats = [];

  // 获取聊天列表
  static Future<List<Chat>> getChatList() async {
    if (_chats.isNotEmpty) {
      return _chats;
    }

    final db = await DatabaseService.database;
    final chats = await db.query(
      'chats',
      orderBy: 'last_message_timestamp DESC',
    );
    if (chats.isEmpty) {
      return [];
    }

    _chats =
        chats.map((chat) {
          return Chat.fromMap(chat);
        }).toList();
    return _chats;
  }

  // 添加或更新聊天
  static Future<void> addOrUpdateChat(Chat chat) async {
    final db = await DatabaseService.database;
    final index = _chats.indexWhere((c) => c.botId == chat.botId);

    if (index != -1) {
      _chats[index] = chat;
    } else {
      _chats.add(chat);
    }

    await db.insert(
      'chats',
      chat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 删除聊天
  static Future<void> deleteChat(String botId) async {
    await MessageService.deleteBotMessage(botId);

    final db = await DatabaseService.database;
    await db.delete('chats', where: 'bot_id = ?', whereArgs: [botId]);
    _chats.removeWhere((chat) => chat.botId == botId);
  }

  // 更新最后一条消息
  static Future<void> updateLastMessage(
    String botId,
    String lastMessage,
  ) async {
    final db = await DatabaseService.database;
    final chatList = await getChatList();
    final index = chatList.indexWhere((chat) => chat.botId == botId);
    final timestamp = DateTime.now();

    if (index != -1) {
      final chat = chatList[index];
      chatList[index] = Chat(
        botId: chat.botId,
        lastMessage: lastMessage,
        lastMessageTimestamp: timestamp,
        createTimestamp: chat.createTimestamp,
        modifyTimestamp: timestamp,
      );

      _chats = chatList;
      await db.update(
        'chats',
        {
          'last_message': lastMessage,
          'last_message_timestamp': timestamp.millisecondsSinceEpoch,
          'modify_timestamp': timestamp.millisecondsSinceEpoch,
        },
        where: 'bot_id = ?',
        whereArgs: [botId],
      );
    }
  }
}
