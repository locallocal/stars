import 'package:stars/domain/models/conversation_memory.dart';

abstract interface class ConversationMemoryRepository {
  Stream<String> get changes;

  Future<ConversationMemoryState> getState(String chatId);
  Future<ConversationSummaryDocument?> getActiveSummary(String chatId);
  Future<List<ConversationMemoryItem>> getItems(String chatId);

  Future<bool> commitCompaction({
    required String chatId,
    required int expectedRevision,
    required ConversationSummaryDocument summary,
    required List<ConversationMemoryItem> items,
  });

  Future<void> saveUserItem(ConversationMemoryItem item);
  Future<void> forgetItem(String chatId, String itemId);
  Future<void> restoreItem(String chatId, String itemId);
  Future<void> setAutoMemoryEnabled(String chatId, bool enabled);
  Future<void> setCompactionStatus(
    String chatId,
    ConversationCompactionStatus status, {
    String lastError = '',
  });
  Future<void> clearAutomaticMemory(String chatId);
  Future<void> clearForChat(String chatId);
  Future<void> deleteForChat(String chatId);
}
