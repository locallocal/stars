import 'package:stars/domain/models/models.dart';

abstract interface class MessageRepository {
  String createId(String prefix);

  Future<List<Message>> getMessages(String chatId);

  Future<Message> upsertMessage(Message message);

  Future<List<Message>> upsertMessages(Iterable<Message> messages);

  Future<void> deleteMessages(String chatId);
}
