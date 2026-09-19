import 'dart:convert';

import 'package:stars/domain/services/task_safe_data.dart';

/// Display-only audit data, separate from compact evidence/model summaries.
/// Sanitization precedes truncation so a boundary cannot expose a partial secret.
String taskExecutionText(String value, {int maximum = 32000}) {
  final normalized = value.replaceAll(RegExp(r'[\x00-\x08\x0b-\x1f\x7f]'), '');
  final safe = taskSafeText(
    normalized,
    // Redaction can expand short values (for example password=x).
    maximum: normalized.length + maximum,
    structured: true,
    preserveWhitespace: true,
  );
  const marker = '\n… [truncated]';
  return safe.length <= maximum
      ? safe
      : '${safe.substring(0, maximum - marker.length)}$marker';
}

/// Keeps arguments as valid JSON, including commands and working directories.
String taskExecutionArguments(String value) {
  if (value.isEmpty) return '';
  try {
    final safe = taskSafeObject(jsonDecode(value), preserveFormatting: true);
    final encoded = jsonEncode(safe);
    if (encoded.length <= 64000) return encoded;
    return jsonEncode({'preview': taskExecutionText(encoded)});
  } on FormatException {
    return taskExecutionText(value);
  }
}

/// Retains structured results and multiline stdout/stderr for human inspection.
String taskExecutionOutput(String value) {
  try {
    final safe = taskSafeObject(jsonDecode(value), preserveFormatting: true);
    if (safe is Map<String, Object?> &&
        (safe.containsKey('stdout') || safe.containsKey('stderr'))) {
      return taskExecutionText(
        safe.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n'),
      );
    }
    return taskExecutionText(const JsonEncoder.withIndent('  ').convert(safe));
  } on FormatException {
    return taskExecutionText(value);
  }
}
