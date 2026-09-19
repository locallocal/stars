final class ModelLogSettings {
  const ModelLogSettings({
    required this.enabled,
    required this.directoryPath,
    this.writeFailed = false,
  });

  final bool enabled;
  final String directoryPath;
  final bool writeFailed;
}

/// Local diagnostic preferences and storage status, independent of the UI.
abstract interface class ModelLogRepository {
  Stream<ModelLogSettings> get changes;
  Future<ModelLogSettings> load();
  Future<void> setEnabled(bool enabled);
  Future<void> ensureDirectory();
}

/// Resolves independent diagnostic preferences and files for each conversation.
abstract interface class ConversationModelLogRepository {
  ModelLogRepository forConversation(String chatId);
}
