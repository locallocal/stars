part of 'skill_tool_sessions.dart';

final class _ProviderToolNameCodec {
  _ProviderToolNameCodec(List<ToolDefinition> definitions) {
    for (final definition in definitions) {
      final canonical = definition.name;
      final alias = _createAlias(canonical);
      if (_canonicalByWire.containsKey(alias)) {
        throw ArgumentError.value(
          canonical,
          'definitions',
          'Provider Tool aliases must be unique.',
        );
      }
      _wireByCanonical[canonical] = alias;
      _canonicalByWire[alias] = canonical;
    }
  }

  final Map<String, String> _wireByCanonical = {};
  final Map<String, String> _canonicalByWire = {};

  String wire(String canonical) => _wireByCanonical[canonical] ?? canonical;

  String canonical(String wireName) => _canonicalByWire[wireName] ?? wireName;

  String _createAlias(String canonical) {
    if (canonical.length <= 64 &&
        RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(canonical)) {
      return canonical;
    }
    var base = canonical.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    if (base.isEmpty) base = 'tool';
    final hash = _stableToolNameHash(canonical);
    final maximumBaseLength = 64 - hash.length - 1;
    if (base.length > maximumBaseLength) {
      base = base.substring(0, maximumBaseLength);
    }
    return '${base}_$hash';
  }
}

String _stableToolNameHash(String value) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

List<Map<String, Object?>> _anthropicSkillTools(
  List<SkillCatalogEntry> catalog, {
  bool requireExplicitCompletion = false,
}) {
  return [
    for (final tool in _openAiSkillTools(
      catalog,
      requireExplicitCompletion: requireExplicitCompletion,
    ))
      {
        'name': _objectMap(tool['function'])['name'],
        'description': _objectMap(tool['function'])['description'],
        'input_schema': _objectMap(tool['function'])['parameters'],
      },
  ];
}

Map<String, Object?> _decodeArguments(Object? value) {
  if (value is Map) return _objectMap(value);
  if (value is! String || value.isEmpty) return const {};
  try {
    return _objectMap(jsonDecode(value));
  } on FormatException {
    return const {};
  }
}

Map<String, Object?> _objectMap(Object? value) {
  if (value is! Map) return const {};
  return value.map(
    (key, mapValue) => MapEntry(key.toString(), mapValue as Object?),
  );
}

List<Object?> _objectList(Object? value) {
  if (value is! List) return const [];
  return List<Object?>.from(value);
}

ModelTokenUsage _openAiUsage(Map<String, Object?> root, String model) {
  final usage = _objectMap(root['usage']);
  return ModelTokenUsage(
    model: model,
    inputTokens: _integer(usage['prompt_tokens']),
    outputTokens: _integer(usage['completion_tokens']),
    totalTokens: _integer(usage['total_tokens']),
  );
}

ModelTokenUsage _openAiResponsesUsage(Map<String, Object?> root, String model) {
  final usage = _objectMap(root['usage']);
  return ModelTokenUsage(
    model: model,
    inputTokens: _integer(usage['input_tokens']),
    outputTokens: _integer(usage['output_tokens']),
    totalTokens: _integer(usage['total_tokens']),
  );
}

ModelTokenUsage _anthropicUsage(Map<String, Object?> root, String model) {
  final usage = _objectMap(root['usage']);
  final input = _integer(usage['input_tokens']);
  final output = _integer(usage['output_tokens']);
  return ModelTokenUsage(
    model: model,
    inputTokens: input,
    outputTokens: output,
    totalTokens: input + output,
  );
}

int _integer(Object? value, {int fallback = 0}) {
  return switch (value) {
    final int number => number,
    final num number => number.toInt(),
    _ => int.tryParse(value?.toString() ?? '') ?? fallback,
  };
}

String _streamedText(Object? value) {
  if (value is String) return value;
  if (value is! List) return '';
  final text = StringBuffer();
  for (final item in value) {
    final part = _objectMap(item);
    final value = part['text'] ?? part['content'];
    if (value != null) text.write(value);
  }
  return text.toString();
}

Stream<String> _sseData(Stream<List<int>> bytes) async* {
  var data = StringBuffer();
  var hasData = false;
  final lines = bytes.transform(utf8.decoder).transform(const LineSplitter());
  await for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      if (hasData) yield data.toString();
      data = StringBuffer();
      hasData = false;
      continue;
    }
    if (line.startsWith(':')) continue;
    if (line.startsWith('data:')) {
      if (hasData) data.write('\n');
      data.write(line.substring(5).trimLeft());
      hasData = true;
      continue;
    }
    if (hasData) {
      data
        ..write('\n')
        ..write(line);
    }
  }
  if (hasData) yield data.toString();
}
