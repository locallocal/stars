import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/message_repository.dart';

class SqliteMessageRepository implements MessageRepository {
  SqliteMessageRepository({required LocalDatabaseService localDatabase})
    : _localDatabase = localDatabase;

  final LocalDatabaseService _localDatabase;
  int _identitySequence = 0;

  @override
  String createId(String prefix) {
    _identitySequence = (_identitySequence + 1) & 0x7fffffff;
    return '$prefix:${DateTime.now().microsecondsSinceEpoch}:'
        '$_identitySequence';
  }

  Message _ensureIdentity(Message message) {
    final messageId =
        message.messageId.isEmpty ? createId('message') : message.messageId;
    final turnId = message.turnId.isEmpty ? createId('turn') : message.turnId;
    return message.copyWith(messageId: messageId, turnId: turnId);
  }

  @override
  Future<List<Message>> getMessages(String chatId) async {
    final records = await _localDatabase.loadMessages(chatId);
    return List<Message>.unmodifiable(
      records.map((record) => MessageRecord(record).toDomain()),
    );
  }

  @override
  Future<Message> upsertMessage(Message message) async {
    final identified = _ensureIdentity(message);
    await _localDatabase.upsertMessage(
      MessageRecord.fromDomain(identified).values,
    );
    return identified;
  }

  @override
  Future<List<Message>> upsertMessages(Iterable<Message> messages) async {
    final identified = messages.map(_ensureIdentity).toList(growable: false);
    await _localDatabase.upsertMessages(
      identified.map((message) => MessageRecord.fromDomain(message).values),
    );
    return List<Message>.unmodifiable(identified);
  }

  @override
  Future<void> deleteMessages(String chatId) =>
      _localDatabase.deleteMessages(chatId);
}
