/// Immutable snapshot of the files stored for one conversation.
final class ConversationDirectorySnapshot {
  ConversationDirectorySnapshot({
    required this.path,
    required this.relativePath,
    required Iterable<ConversationDirectoryEntry> entries,
  }) : entries = List<ConversationDirectoryEntry>.unmodifiable(entries);

  /// Absolute path of the directory represented by this snapshot.
  final String path;

  /// Path of this directory relative to the conversation directory root.
  ///
  /// An empty value represents the root directory.
  final String relativePath;
  final List<ConversationDirectoryEntry> entries;
}

/// A file-system entry represented without exposing platform APIs to the UI.
final class ConversationDirectoryEntry {
  const ConversationDirectoryEntry({
    required this.name,
    required this.relativePath,
    required this.isDirectory,
    required this.modifiedAt,
    this.sizeBytes,
  });

  final String name;
  final String relativePath;
  final bool isDirectory;
  final DateTime modifiedAt;
  final int? sizeBytes;
}

/// Accepts a single portable filename, never a path or a reserved device name.
bool isValidConversationEntryName(String name) {
  if (name.isEmpty || name != name.trim() || name.endsWith('.')) return false;
  if (RegExp(r'[<>:"/\\|?*\x00-\x1f]').hasMatch(name)) return false;
  return !RegExp(
    r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)',
    caseSensitive: false,
  ).hasMatch(name);
}
