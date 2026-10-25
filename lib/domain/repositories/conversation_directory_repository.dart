import 'package:stars/domain/models/conversation_directory.dart';

abstract interface class ConversationDirectoryRepository {
  Future<ConversationDirectorySnapshot> read(
    String chatId, {
    String relativePath = '',
  });

  /// Renames an entry within its current directory, without replacing another.
  Future<void> rename(
    String chatId, {
    required String relativePath,
    required String newName,
  });

  /// Copies an entry into an existing directory without replacing another.
  Future<void> copy(
    String chatId, {
    required String relativePath,
    required String destinationDirectory,
  });

  /// Deletes an entry, including a directory's contents, after UI confirmation.
  Future<void> delete(String chatId, {required String relativePath});
}
