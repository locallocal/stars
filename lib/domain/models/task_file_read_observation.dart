/// A bounded, sanitized file page retained for subsequent task model turns.
/// This is untrusted working data, separate from the immutable evidence ledger.
final class TaskFileReadObservation {
  TaskFileReadObservation({
    required this.attemptId,
    required this.stepId,
    required this.requestedPath,
    required this.path,
    required this.encoding,
    required this.content,
    required this.offsetBytes,
    required this.nextOffsetBytes,
    required this.sizeBytes,
    required this.maxBytes,
    required this.redacted,
  }) {
    for (final value in [attemptId, stepId, requestedPath, path]) {
      if (value.isEmpty || value.length > 4096) {
        throw ArgumentError('Invalid file observation identity.');
      }
    }
    if (!{'utf8', 'base64'}.contains(encoding) ||
        offsetBytes < 0 ||
        nextOffsetBytes < offsetBytes ||
        nextOffsetBytes > sizeBytes ||
        maxBytes < 1 ||
        maxBytes > maxPageBytes ||
        nextOffsetBytes - offsetBytes > maxBytes ||
        content.length > maxPageCharacters) {
      throw ArgumentError('Invalid or oversized file observation.');
    }
  }

  static const maxPageBytes = 65536;
  static const maxPageCharacters = 90000;
  static const maxRetainedCharacters = 262144;
  static const maxRetainedPages = 16;

  final String attemptId, stepId, requestedPath, path, encoding, content;
  final int offsetBytes, nextOffsetBytes, sizeBytes, maxBytes;
  final bool redacted;
  bool get truncated => nextOffsetBytes < sizeBytes;

  Map<String, Object?> toJson() => {
    'attemptId': attemptId,
    'stepId': stepId,
    'requestedPath': requestedPath,
    'path': path,
    'encoding': encoding,
    'content': content,
    'offsetBytes': offsetBytes,
    'nextOffsetBytes': nextOffsetBytes,
    'sizeBytes': sizeBytes,
    'maxBytes': maxBytes,
    'redacted': redacted,
  };

  factory TaskFileReadObservation.fromJson(Map<String, Object?> json) {
    const fields = {
      'attemptId',
      'stepId',
      'requestedPath',
      'path',
      'encoding',
      'content',
      'offsetBytes',
      'nextOffsetBytes',
      'sizeBytes',
      'maxBytes',
      'redacted',
    };
    if (json.length != fields.length || !fields.containsAll(json.keys)) {
      throw const FormatException('Invalid file observation fields.');
    }
    return TaskFileReadObservation(
      attemptId: json['attemptId']! as String,
      stepId: json['stepId']! as String,
      requestedPath: json['requestedPath']! as String,
      path: json['path']! as String,
      encoding: json['encoding']! as String,
      content: json['content']! as String,
      offsetBytes: json['offsetBytes']! as int,
      nextOffsetBytes: json['nextOffsetBytes']! as int,
      sizeBytes: json['sizeBytes']! as int,
      maxBytes: json['maxBytes']! as int,
      redacted: json['redacted']! as bool,
    );
  }

  Map<String, Object?> toModelJson() => {
    'attempt_id': attemptId,
    'tool': 'read_local_file',
    'step_id': stepId,
    'path': path,
    'encoding': encoding,
    'content': content,
    'offset_bytes': offsetBytes,
    'bytes_returned': nextOffsetBytes - offsetBytes,
    'next_offset_bytes': nextOffsetBytes,
    'size_bytes': sizeBytes,
    'truncated': truncated,
    'content_redacted': redacted,
  };

  static List<TaskFileReadObservation> retain(
    Iterable<TaskFileReadObservation> pages,
  ) {
    final kept = pages.toList();
    var characters = kept.fold(0, (sum, page) => sum + page.content.length);
    while (kept.length > maxRetainedPages ||
        characters > maxRetainedCharacters) {
      characters -= kept.removeAt(0).content.length;
    }
    return List.unmodifiable(kept);
  }
}
