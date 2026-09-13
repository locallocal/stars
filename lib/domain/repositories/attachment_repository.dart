typedef ConversationArtifactsDirectoryProvider =
    Future<String> Function(String chatId);

abstract interface class AttachmentRepository {
  Future<String?> captureImage();

  Future<String?> selectImage();

  Future<String?> selectFile();
}

/// Persists picker results into a dedicated user-attachment directory owned by
/// the conversation. The operation is all-or-nothing: no returned path is
/// visible until every source copied.
abstract interface class ConversationAssetRepository
    implements AttachmentRepository {
  Future<List<String>> persistAssets({
    required String chatId,
    required Iterable<String> sourcePaths,
  });

  /// Ensures and returns the conversation root used by agent-generated
  /// artifacts. User attachments are stored in a dedicated child directory.
  Future<String> getOutputDirectory(String chatId);
}
