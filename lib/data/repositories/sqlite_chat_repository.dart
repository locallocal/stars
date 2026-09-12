import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/data/services/conversation_summary_storage.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/conversation_memory_repository.dart';
import 'package:stars/domain/repositories/conversation_draft_repository.dart';
import 'package:stars/utils/utils.dart';

class SqliteChatRepository
    implements ChatRepository, BotChatDeletionParticipant {
  SqliteChatRepository({
    required LocalDatabaseService localDatabase,
    ConversationMemoryRepository? conversationMemoryRepository,
    ConversationSummaryStorage? conversationSummaryStorage,
    ConversationDraftRepository? conversationDraftRepository,
  }) : _localDatabase = localDatabase,
       _conversationMemoryRepository = conversationMemoryRepository,
       _conversationSummaryStorage = conversationSummaryStorage,
       _conversationDraftRepository = conversationDraftRepository;

  final LocalDatabaseService _localDatabase;
  final ConversationMemoryRepository? _conversationMemoryRepository;
  final ConversationSummaryStorage? _conversationSummaryStorage;
  final ConversationDraftRepository? _conversationDraftRepository;
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
    final storage = _conversationSummaryStorage;
    final staged = await storage?.stageForChatDeletion(id);
    try {
      if (storage == null) {
        await _conversationMemoryRepository?.deleteForChat(id);
      }
      await _localDatabase.deleteChat(id);
    } catch (_) {
      await staged?.rollback();
      rethrow;
    }
    await staged?.commit();
    await _conversationDraftRepository?.delete(id);
    _cache = _cache?.where((chat) => chat.id != id).toList();
    if (storage == null) {
      try {
        await deleteChatDirectory(id);
      } catch (error) {
        debugPrint('Failed to delete chat directory for $id: $error');
      }
    }
    _emit();
  }

  @override
  Future<void> deleteChatsForBot(String botId) async {
    final stage = await stageChatsForBotDeletion(botId);
    try {
      for (final id in stage.chatIds) {
        await _localDatabase.deleteChat(id);
      }
    } catch (_) {
      await stage.rollback();
      rethrow;
    }
    await stage.commit();
    await completeStagedBotDeletion(stage);
  }

  @override
  Future<BotChatDeletionStage> stageChatsForBotDeletion(String botId) async {
    final chats = await getChats(forceRefresh: true);
    final chatIds = <String>[
      for (final chat in chats)
        if (chat.botId == botId) chat.id,
    ];
    final staged = <StagedConversationDeletion>[];
    final storage = _conversationSummaryStorage;
    try {
      if (storage != null) {
        for (final chatId in chatIds) {
          final deletion = await storage.stageForChatDeletion(chatId);
          if (deletion != null) staged.add(deletion);
        }
      }
    } catch (_) {
      for (final deletion in staged.reversed) {
        await deletion.rollback();
      }
      rethrow;
    }
    return _SqliteBotChatDeletionStage(
      chatIds: List.unmodifiable(chatIds),
      deletions: staged,
      deleteUnstagedDirectories: storage == null,
    );
  }

  @override
  Future<void> completeStagedBotDeletion(BotChatDeletionStage stage) async {
    final deleted = stage.chatIds.toSet();
    for (final chatId in deleted) {
      await _conversationDraftRepository?.delete(chatId);
    }
    _cache = _cache?.where((chat) => !deleted.contains(chat.id)).toList();
    _emit();
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
            chat.copyWith(
              lastMessage: content,
              lastMessageTimestamp: timestamp,
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
  Future<void> updateChatName(String id, String name) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Chat name cannot be empty.');
    }
    if (normalizedName.length > Chat.maxNameLength) {
      throw ArgumentError.value(
        name,
        'name',
        'Chat name cannot exceed ${Chat.maxNameLength} characters.',
      );
    }

    final timestamp = DateTime.now();
    final updatedRows = await _localDatabase.updateChatName(
      id,
      name: normalizedName,
      timestamp: timestamp,
    );
    if (updatedRows != 1) {
      throw StateError('Chat $id does not exist.');
    }

    final cache = _cache;
    if (cache != null) {
      _cache = [
        for (final chat in cache)
          if (chat.id == id)
            chat.copyWith(name: normalizedName, modifyTimestamp: timestamp)
          else
            chat,
      ];
    }
    _emit();
  }

  @override
  Future<void> clearHistory(String id) async {
    final timestamp = DateTime.now();
    final storage = _conversationSummaryStorage;
    final staged = await storage?.stageForChatClear(id);
    try {
      if (storage == null) {
        await _conversationMemoryRepository?.clearForChat(id);
      }
      await _localDatabase.clearChatHistory(id, timestamp);
    } catch (_) {
      await staged?.rollback();
      rethrow;
    }
    await staged?.commit();
    final cache = _cache;
    if (cache != null) {
      _cache = [
        for (final chat in cache)
          if (chat.id == id)
            chat.copyWith(
              lastMessage: '',
              lastMessageTimestamp: timestamp,
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

final class _SqliteBotChatDeletionStage implements BotChatDeletionStage {
  _SqliteBotChatDeletionStage({
    required this.chatIds,
    required List<StagedConversationDeletion> deletions,
    required this.deleteUnstagedDirectories,
  }) : _deletions = deletions;

  @override
  final List<String> chatIds;
  final List<StagedConversationDeletion> _deletions;
  final bool deleteUnstagedDirectories;

  @override
  Future<void> rollback() async {
    for (final deletion in _deletions.reversed) {
      await deletion.rollback();
    }
  }

  @override
  Future<void> commit() async {
    for (final deletion in _deletions) {
      await deletion.commit();
    }
    if (deleteUnstagedDirectories) {
      for (final chatId in chatIds) {
        try {
          await deleteChatDirectory(chatId);
        } on Object catch (error) {
          debugPrint('Failed to delete chat directory for $chatId: $error');
        }
      }
    }
  }
}
