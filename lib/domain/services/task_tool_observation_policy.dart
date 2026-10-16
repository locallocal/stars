import 'dart:convert';

import 'package:stars/domain/models/task_tool_observation.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_safe_data.dart';

TaskToolObservation prepareTaskToolObservation({
  required String attemptId,
  required ToolResult result,
}) {
  final safeContent = taskSafeText(
    result.content,
    maximum: result.content.length,
    structured: true,
    preserveWhitespace: true,
  );
  final safeStructured = taskSafeObject(
    result.structuredContent,
    preserveFormatting: true,
  );
  var structured = safeStructured;
  var truncated = result.truncated;
  // Omit oversized JSON as a whole; never present partial JSON as a complete
  // collection. The model must narrow the query instead of using missing items.
  if (jsonEncode(structured).length > TaskToolObservation.maxResultCharacters) {
    structured = null;
    truncated = true;
  }
  final remaining =
      TaskToolObservation.maxResultCharacters - jsonEncode(structured).length;
  final content =
      safeContent.length > remaining
          ? safeContent.substring(0, remaining)
          : safeContent;
  return TaskToolObservation(
    attemptId: attemptId,
    tool: result.name,
    content: content,
    structuredContent: structured,
    truncated: truncated || content != safeContent,
    redacted:
        safeContent != result.content ||
        jsonEncode(safeStructured) != jsonEncode(result.structuredContent),
  );
}
