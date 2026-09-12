import 'package:stars/domain/models/models.dart';

abstract interface class ChatRepository {
  Stream<List<Chat>> get changes;

  Future<List<Chat>> getChats({bool forceRefresh = false});

  Future<Chat?> getChat(String id);

  Future<void> addChat(Chat chat);

  Future<void> deleteChat(String id);

  Future<void> deleteChatsForBot(String botId);

  Future<void> updateLastMessage(String id, String content);

  Future<void> updateChatName(String id, String name);

  Future<void> clearHistory(String id);

  void invalidate();
}

abstract interface class BotChatDeletionStage {
  List<String> get chatIds;

  Future<void> rollback();

  Future<void> commit();
}

/// Files are staged before the Bot aggregate transaction and committed only
/// after SQLite succeeds.
abstract interface class BotChatDeletionParticipant {
  Future<BotChatDeletionStage> stageChatsForBotDeletion(String botId);

  Future<void> completeStagedBotDeletion(BotChatDeletionStage stage);
}
