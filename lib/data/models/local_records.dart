import 'package:stars/domain/models/models.dart';

/// Raw database record adapters. Mapping stays in the data layer even while
/// the legacy domain classes retain compatibility `fromMap`/`toMap` methods.
final class BotRecord {
  const BotRecord(this.values);

  factory BotRecord.fromDomain(Bot bot) => BotRecord(bot.toMap());

  final Map<String, Object?> values;

  Bot toDomain() => Bot.fromMap(values);
}

final class ChatRecord {
  const ChatRecord(this.values);

  factory ChatRecord.fromDomain(Chat chat) => ChatRecord(chat.toMap());

  final Map<String, Object?> values;

  Chat toDomain() => Chat.fromMap(values);
}

final class MessageRecord {
  const MessageRecord(this.values);

  factory MessageRecord.fromDomain(Message message) =>
      MessageRecord(message.toMap());

  final Map<String, Object?> values;

  Message toDomain() => Message.fromMap(values);
}

final class ProfileRecord {
  const ProfileRecord(this.values);

  factory ProfileRecord.fromDomain(Profile profile) =>
      ProfileRecord(profile.toMap());

  final Map<String, Object?> values;

  Profile toDomain() => Profile.fromMap(values);
}
