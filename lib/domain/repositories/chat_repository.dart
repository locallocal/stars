import 'package:stars/domain/models/models.dart';

abstract interface class ChatRepository {
  Stream<List<Chat>> get changes;

  Future<List<Chat>> getChats({bool forceRefresh = false});

  Future<Chat?> getChat(String id);

  Future<void> addChat(Chat chat);

  Future<void> deleteChat(String id);

  Future<void> deleteChatsForBot(String botId);

  Future<void> updateLastMessage(String id, String content);

  Future<void> clearHistory(String id);

  void invalidate();
}
