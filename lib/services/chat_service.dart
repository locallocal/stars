import 'package:bubble/services/message_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bubble/services/database_service.dart';
import 'package:bubble/model/model.dart';

class ChatService {
  static List<Chat> _chats = [];

  // 获取聊天
  static Future<Chat?> getChat(String id) async {
    if (_chats.isEmpty) {
      await getChatList();
    }

    final index = _chats.indexWhere((chat) => chat.id == id);
    if (index != -1) {
      return _chats[index];
    }
    return null;
  }

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

  static Future<void> addOrUpdateChat(Chat chat) async {
    final db = await DatabaseService.database;
    _chats.add(chat);

    await db.insert(
      'chats',
      chat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteBotChats(String botId) async {
    final chatsToDelete = _chats.where((chat) => chat.botId == botId).toList();
    for (var chat in chatsToDelete) {
      await deleteChat(chat.id);
    }
  }

  static Future<void> deleteChat(String id) async {
    await MessageService.deleteChatMessage(id);

    final db = await DatabaseService.database;
    await db.delete('chats', where: 'id = ?', whereArgs: [id]);
    _chats.removeWhere((chat) => chat.id == id);
  }

  static Future<void> updateLastMessage(String id, String lastMessage) async {
    final db = await DatabaseService.database;
    final chatList = await getChatList();
    final index = chatList.indexWhere((chat) => chat.id == id);
    final timestamp = DateTime.now();

    if (index != -1) {
      final chat = chatList[index];
      chatList[index] = Chat(
        id: chat.id,
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
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
