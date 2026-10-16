import 'dart:convert';

import 'package:stars/domain/models/skill_installer.dart';

/// Bounded working data, not evidence for verified claims. Results survive model
/// turns and restarts independently of the short audit summary.
final class TaskToolObservation {
  TaskToolObservation({
    required this.attemptId,
    required this.tool,
    required this.content,
    Object? structuredContent,
    required this.truncated,
    required this.redacted,
  }) : _structuredJson = jsonEncode(structuredContent) {
    if (attemptId.isEmpty ||
        attemptId.length > 256 ||
        tool.isEmpty ||
        tool.length > 256 ||
        characters > maxResultCharacters) {
      throw ArgumentError('Invalid task tool observation.');
    }
  }

  static const maxResultCharacters = 131072;
  static const maxRetainedCharacters = 524288;
  static const maxRetainedResults = 64;
  final String attemptId, tool, content;
  final String _structuredJson;
  final bool truncated, redacted;
  Object? get structuredContent => jsonDecode(_structuredJson);
  int get characters => content.length + _structuredJson.length;

  Map<String, Object?> toJson() => {
    'attemptId': attemptId,
    'tool': tool,
    'content': content,
    'structuredContent': structuredContent,
    'truncated': truncated,
    'redacted': redacted,
  };

  factory TaskToolObservation.fromJson(Map<String, Object?> json) {
    const fields = {
      'attemptId',
      'tool',
      'content',
      'structuredContent',
      'truncated',
      'redacted',
    };
    if (json.length != fields.length || !fields.containsAll(json.keys)) {
      throw const FormatException('Invalid tool observation fields.');
    }
    return TaskToolObservation(
      attemptId: json['attemptId']! as String,
      tool: json['tool']! as String,
      content: json['content']! as String,
      structuredContent: json['structuredContent'],
      truncated: json['truncated']! as bool,
      redacted: json['redacted']! as bool,
    );
  }

  Map<String, Object?> toModelJson() => {
    'attempt_id': attemptId,
    'tool': tool,
    'content': content,
    'structured_content': structuredContent,
    'truncated': truncated,
    'redacted': redacted,
  };

  static List<TaskToolObservation> retain(Iterable<TaskToolObservation> items) {
    final kept = items.toList();
    var size = kept.fold(0, (sum, item) => sum + item.characters);
    while (kept.length > maxRetainedResults || size > maxRetainedCharacters) {
      // Source manifests drive the remaining installations. Prefer evicting
      // individual receipts, which can be recovered from the installed state.
      final expendable = kept.indexWhere(
        (item) => item.tool != resolveSkillSourceToolName,
      );
      size -= kept.removeAt(expendable < 0 ? 0 : expendable).characters;
    }
    return List.unmodifiable(kept);
  }
}
