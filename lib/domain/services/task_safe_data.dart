/// Sanitizes prepared task data; never accepts raw reasoning or credentials.
String taskSafeText(
  String text, {
  int maximum = 2000,
  bool structured = false,
}) {
  var value = text
      .replaceAll(
        RegExp(
          r'-----BEGIN [^-]*PRIVATE KEY-----[\s\S]*?-----END [^-]*PRIVATE KEY-----',
        ),
        '[redacted]',
      )
      .replaceAll(
        RegExp(r'\bBearer\s+[^\s,;"\x27]+', caseSensitive: false),
        'Bearer [redacted]',
      )
      .replaceAll(RegExp(r'\bsk-[A-Za-z0-9_-]{8,}\b'), '[redacted]')
      .replaceAllMapped(
        RegExp(
          r'''["']?\b(api[_-]?key|access[_-]?token|refresh[_-]?token|password|secret|authorization|cookie)["']?\s*[:=]\s*(?:"[^"\n]*"|'[^'\n]*'|[^\s,;]+)''',
          caseSensitive: false,
        ),
        (match) => '${match.group(1)}=[redacted]',
      )
      .replaceAll(
        RegExp(r'https?://[^\s/@]+:[^\s/@]+@', caseSensitive: false),
        'https://[redacted]@',
      );
  value =
      value
          .split('\n')
          .where(
            (line) =>
                !RegExp(
                  r'^\s*(#\d+\s|at\s+\S+\s*\(|Traceback\b|File ".*", line \d+)',
                  caseSensitive: false,
                ).hasMatch(line),
          )
          .join('\n')
          .trim();
  if (!structured &&
      (value.startsWith('{') ||
          value.startsWith('[') && !value.startsWith('[redacted]'))) {
    value = '[details omitted]';
  }
  if (value.length > maximum) value = value.substring(0, maximum).trimRight();
  return value.isEmpty && text.isNotEmpty ? '[details omitted]' : value;
}

Object? taskSafeObject(Object? value, {String key = ''}) {
  if (RegExp(
    r'^(api[_-]?key|access[_-]?token|refresh[_-]?token|password|secret|authorization|cookie|reasoning|rawArguments|rawOutput|stackTrace)$',
    caseSensitive: false,
  ).hasMatch(key)) {
    return '[redacted]';
  }
  if (value is Map<String, Object?>) {
    return {
      for (final entry in value.entries)
        entry.key: taskSafeObject(entry.value, key: entry.key),
    };
  }
  if (value is List<Object?>) {
    return value.map((item) => taskSafeObject(item)).toList();
  }
  if (value is String) {
    return taskSafeText(
      value,
      maximum:
          key == 'content'
              ? 128000
              : key == 'objective'
              ? 16000
              : 2000,
      structured: key == 'content' || key == 'objective',
    );
  }
  return value;
}
