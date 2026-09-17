import 'dart:convert';
import 'dart:math';

import 'package:stars/domain/models/task_file_read_observation.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_safe_data.dart';

bool retainsTaskFileRead(ToolDefinition definition) =>
    definition.name == 'read_local_file' &&
    definition.source == ToolSource.builtIn &&
    definition.riskLevel == ToolRiskLevel.readOnly;

Map<String, Object?> taskFileReadArguments(Map<String, Object?> arguments) => {
  'path': arguments['path'],
  'encoding': arguments['encoding'] ?? 'utf8',
  'offset_bytes': arguments['offset_bytes'] ?? 0,
  'max_bytes': arguments['max_bytes'] ?? 65536,
};

bool taskFileReadCovers(
  TaskFileReadObservation page,
  ToolCallRequest call,
  String? stepId,
) {
  final args = taskFileReadArguments(call.arguments);
  return page.stepId == stepId &&
      (page.requestedPath == args['path'] || page.path == args['path']) &&
      page.encoding == args['encoding'] &&
      page.offsetBytes == min(args['offset_bytes']! as int, page.sizeBytes) &&
      (!page.truncated ||
          page.maxBytes >=
              min(
                args['max_bytes']! as int,
                TaskFileReadObservation.maxPageBytes,
              ));
}

/// Prepares only the audited file fields. Offsets refer to source bytes, even
/// when credential redaction changes the length of the retained text.
TaskFileReadObservation prepareTaskFileRead({
  required ToolCallRequest call,
  required ToolResult result,
  required String attemptId,
  required String stepId,
}) {
  final data = result.structuredContent! as Map<String, Object?>;
  final encoding = data['encoding']! as String;
  final original = data['content']! as String;
  final limit = min(
    taskFileReadArguments(call.arguments)['max_bytes']! as int,
    TaskFileReadObservation.maxPageBytes,
  );
  final source =
      encoding == 'base64' ? base64Decode(original) : utf8.encode(original);
  // Dart's UTF-8 decoder consumes an initial BOM. It still occupies three
  // source bytes, which must count toward both the page limit and continuation.
  final prefixBytes =
      encoding == 'utf8' && data['bytes_returned'] == source.length + 3 ? 3 : 0;
  var count = min(source.length, limit - prefixBytes);
  String page;
  if (encoding == 'base64') {
    page = base64Encode(source.sublist(0, count));
  } else {
    while (count < source.length &&
        count > 0 &&
        (source[count] & 0xc0) == 0x80) {
      count--;
    }
    page = utf8.decode(source.sublist(0, count));
  }
  final safe = taskSafeText(
    page,
    maximum: page.length,
    structured: true,
    preserveWhitespace: true,
  );
  final offset = data['offset_bytes']! as int;
  return TaskFileReadObservation(
    attemptId: attemptId,
    stepId: stepId,
    requestedPath: call.arguments['path']! as String,
    path: data['path']! as String,
    encoding: encoding,
    content: safe,
    offsetBytes: offset,
    nextOffsetBytes: offset + prefixBytes + count,
    sizeBytes: data['size_bytes']! as int,
    maxBytes: limit,
    redacted: safe != page,
  );
}
