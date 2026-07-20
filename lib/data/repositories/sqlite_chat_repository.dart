import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/utils/utils.dart';

class SqliteChatRepository implements ChatRepository {
  SqliteChatRepository({required LocalDatabaseService localDatabase})
    : _localDatabase = localDatabase;

  final LocalDatabaseService _localDatabase;
  final StreamController<List<Chat>> _changes =
      StreamController<List<Chat>>.broadcast();
  List<Chat>? _cache;

  @override
  Stream<List<Chat>> get changes => _changes.stream;

  @override
  Future<List<Chat>> getChats({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _snapshot;

    final records = await _localDatabase.loadChats();
    _cache = records.map((record) => ChatRecord(record).toDomain()).toList();
    return _snapshot;
  }

  @override
  Future<Chat?> getChat(String id) async {
    final cached = _cache?.where((chat) => chat.id == id).firstOrNull;
    if (cached != null) return cached;

    final records = await _localDatabase.loadChat(id);
    if (records.isEmpty) return null;
    final chat = ChatRecord(records.first).toDomain();
    final cache = _cache;
    if (cache != null) {
      _cache = [...cache, chat];
    }
    return chat;
  }

  @override
  Future<void> addChat(Chat chat) async {
    await createChatDirectory(chat.id);
    try {
      await _localDatabase.insertChat(ChatRecord.fromDomain(chat).values);
    } catch (_) {
      try {
        await deleteChatDirectory(chat.id);
      } catch (_) {
        // Database insertion is the operation whose error should be surfaced.
      }
      rethrow;
    }

    final cache = _cache;
    if (cache != null) {
      _cache = [...cache.where((item) => item.id != chat.id), chat]..sort(
        (left, right) =>
            right.lastMessageTimestamp.compareTo(left.lastMessageTimestamp),
      );
    }
    _emit();
  }

  @override
  Future<void> deleteChat(String id) async {
    await _localDatabase.deleteChat(id);
    _cache = _cache?.where((chat) => chat.id != id).toList();
    try {
      await deleteChatDirectory(id);
    } catch (error) {
      debugPrint('Failed to delete chat directory for $id: $error');
    }
    _emit();
  }

  @override
  Future<void> deleteChatsForBot(String botId) async {
    final chats = await getChats(forceRefresh: true);
    final matchingIds = [
      for (final chat in chats)
        if (chat.botId == botId) chat.id,
    ];
    for (final id in matchingIds) {
      await deleteChat(id);
    }
  }

  @override
  Future<void> updateLastMessage(String id, String content) async {
    final timestamp = DateTime.now();
    await _localDatabase.updateChatPreview(
      id,
      content: content,
      timestamp: timestamp,
    );

    final cache = _cache;
    if (cache != null) {
      _cache = [
        for (final chat in cache)
          if (chat.id == id)
            Chat(
              id: chat.id,
              botId: chat.botId,
              lastMessage: content,
              lastMessageTimestamp: timestamp,
              createTimestamp: chat.createTimestamp,
              modifyTimestamp: timestamp,
            )
          else
            chat,
      ]..sort(
        (left, right) =>
            right.lastMessageTimestamp.compareTo(left.lastMessageTimestamp),
      );
    }
    _emit();
  }

  @override
  Future<void> clearHistory(String id) async {
    final timestamp = DateTime.now();
    await _localDatabase.clearChatHistory(id, timestamp);
    final cache = _cache;
    if (cache != null) {
      _cache = [
        for (final chat in cache)
          if (chat.id == id)
            Chat(
              id: chat.id,
              botId: chat.botId,
              lastMessage: '',
              lastMessageTimestamp: timestamp,
              createTimestamp: chat.createTimestamp,
              modifyTimestamp: timestamp,
            )
          else
            chat,
      ];
    }
    _emit();
  }

  @override
  void invalidate() {
    _cache = null;
    _emit();
  }

  List<Chat> get _snapshot => List<Chat>.unmodifiable(_cache ?? const []);

  void _emit() {
    if (!_changes.isClosed) _changes.add(_snapshot);
  }

  @visibleForTesting
  Future<void> dispose() => _changes.close();
}
