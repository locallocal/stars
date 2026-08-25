typedef ConversationArtifactsDirectoryProvider =
    Future<String> Function(String chatId);

abstract interface class AttachmentRepository {
  Future<String?> captureImage();

  Future<String?> selectImage();

  Future<String?> selectFile();
}

/// Persists picker results into a conversation-owned directory. The operation
/// is all-or-nothing: no returned path is visible until every source copied.
abstract interface class ConversationAssetRepository
    implements AttachmentRepository {
  Future<List<String>> persistAssets({
    required String chatId,
    required Iterable<String> sourcePaths,
  });

  /// Ensures and returns the conversation-owned directory shared by persisted
  /// attachments and agent-generated artifacts.
  Future<String> getOutputDirectory(String chatId);
}
