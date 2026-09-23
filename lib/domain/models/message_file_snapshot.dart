import 'package:stars/domain/models/message.dart';

/// Inputs that affect file discovery, independent of presentation metadata.
final class MessageFileRequest {
  MessageFileRequest({
    required this.content,
    required List<String> files,
    this.message,
  }) : files = List.unmodifiable(files);

  final String content;
  final List<String> files;
  final Message? message;

  (String?, String?) get identity => (message?.chatId, message?.messageId);

  bool sameScope(MessageFileRequest other) =>
      identity == other.identity &&
      message?.taskId == other.message?.taskId &&
      message?.timestamp == other.message?.timestamp;

  bool matches(MessageFileRequest other) =>
      sameScope(other) && sameContent(other);

  bool sameContent(MessageFileRequest other) =>
      content == other.content &&
      files.length == other.files.length &&
      other.files.indexed.every((entry) => files[entry.$1] == entry.$2);

  bool appendsTo(MessageFileRequest other) =>
      sameScope(other) &&
      content.startsWith(other.content) &&
      files.length >= other.files.length &&
      other.files.indexed.every((entry) => files[entry.$1] == entry.$2);
}

/// Text and its confirmed file cards must be presented as one immutable value.
final class MessageFileSnapshot {
  MessageFileSnapshot({required this.content, required Iterable<String> files})
    : files = List.unmodifiable(files);

  final String content;
  final List<String> files;
}
