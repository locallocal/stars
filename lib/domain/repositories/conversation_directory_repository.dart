import 'package:stars/domain/models/conversation_directory.dart';

abstract interface class ConversationDirectoryRepository {
  Future<ConversationDirectorySnapshot> read(
    String chatId, {
    String relativePath = '',
  });
}
