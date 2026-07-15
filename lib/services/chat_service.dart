import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stars/services/database_service.dart';
import 'package:stars/model/model.dart';
import 'package:stars/utils/utils.dart';

class ChatService {
  static List<Chat> _chats = [];

  // 添加一个 Stream 控制器来发送通知
  static final _chatListChangedController = StreamController<void>.broadcast();
  // 获取通知流
  static Stream<void> get chatListChanged => _chatListChangedController.stream;

  // 发送通知
  static void notifyChatListChanged() {
    _chats = []; // 清空缓存，强制下次获取时重新加载
    _chatListChangedController.add(null);
  }

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

  static Future<void> addChat(Chat chat) async {
    final db = await DatabaseService.database;
    _chats.add(chat);

    await createChatDirectory(chat.id);

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
    final db = await DatabaseService.database;
    await db.transaction((transaction) async {
      await transaction.delete(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [id],
      );
      await transaction.delete('chats', where: 'id = ?', whereArgs: [id]);
    });
    _chats.removeWhere((chat) => chat.id == id);
    try {
      await deleteChatDirectory(id);
    } catch (error) {
      // The database is authoritative. A stale cache directory can be cleaned
      // on a later maintenance pass without resurrecting the deleted chat.
      debugPrint('Failed to delete chat directory for $id: $error');
    }
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

  /// Clears a conversation and its preview atomically.
  static Future<void> clearChatHistory(String id) async {
    final db = await DatabaseService.database;
    final timestamp = DateTime.now();
    await db.transaction((transaction) async {
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

    final index = _chats.indexWhere((chat) => chat.id == id);
    if (index != -1) {
      final chat = _chats[index];
      _chats[index] = Chat(
        id: chat.id,
        botId: chat.botId,
        lastMessage: '',
        lastMessageTimestamp: timestamp,
        createTimestamp: chat.createTimestamp,
        modifyTimestamp: timestamp,
      );
    }
  }

  // 在 dispose 方法中关闭控制器
  static void dispose() {
    _chatListChangedController.close();
  }
}
