import 'package:stars/domain/models/models.dart';

abstract interface class MessageRepository {
  Stream<void> get changes;

  String createId(String prefix);

  Future<List<Message>> getMessages(String chatId);

  Future<List<ModelTokenUsageRecord>> getTokenUsageRecordsForChat(
    String chatId,
  );

  Future<List<ModelTokenUsageRecord>> getTokenUsageRecordsForBot(String botId);

  Future<ModelTokenUsage> getTokenUsageForBot(String botId);

  Future<Map<String, ModelTokenUsage>> getTokenUsageByChatForBot(String botId);

  Future<Message> upsertMessage(Message message);

  Future<List<Message>> upsertMessages(Iterable<Message> messages);

  Future<void> deleteMessages(String chatId);
}

/// Optional synchronous access to an already-loaded conversation.
///
/// UI code can use this capability to restore a recently opened chat without
/// showing a loading frame or decoding the same database rows again.
abstract interface class CachedMessageRepository implements MessageRepository {
  List<Message>? peekMessages(String chatId);
}

abstract interface class PaginatedMessageRepository
    implements MessageRepository {
  Future<MessagePage> getMessagePage(
    String chatId, {
    MessageCursor? before,
    int limit = 50,
  });

  MessagePage? peekMessagePage(String chatId);
}

abstract interface class BotScopedMessageMetricsRepository
    implements MessageRepository {
  Stream<Set<String>> get botMetricChanges;

  Future<Map<String, ModelTokenUsage>> getTokenUsageForBots(
    Iterable<String> botIds,
  );
}

/// Commits a final message and all of its evidence links atomically.
abstract interface class GroundedMessageRepository {
  Future<Message> upsertGroundedMessage(Message message);
}
