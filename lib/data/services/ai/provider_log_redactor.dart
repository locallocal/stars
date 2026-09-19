import 'dart:convert';

/// Sanitizes provider credentials and attachment bytes before they reach disk.
final class ProviderLogRedactor {
  ProviderLogRedactor({required this.apiKey});
  final String apiKey;
  static const hidden = '[REDACTED]';
  static const _credentials = {
    'authorization',
    'proxyauthorization',
    'apikey',
    'xapikey',
    'key',
    'accesstoken',
    'refreshtoken',
    'idtoken',
    'token',
    'password',
    'secret',
    'clientsecret',
    'cookie',
    'setcookie',
    'credential',
    'credentials',
  };

  Object? value(Object? input, {String key = ''}) {
    final normalized = key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    if (_credentials.contains(normalized)) return hidden;
    if (input is Map) {
      return {
        for (final entry in input.entries)
          text(entry.key.toString()): value(
            entry.value,
            key: entry.key.toString(),
          ),
      };
    }
    if (input is List) {
      return input.map((item) => value(item, key: key)).toList();
    }
    if (input is String) {
      if ({
            'b64json',
            'imagedata',
            'audiodata',
            'images',
            'base64',
          }.contains(normalized) ||
          normalized == 'data' &&
              input.length >= 4 &&
              input.length % 4 == 0 &&
              RegExp(r'^[A-Za-z0-9+/=\s]+$').hasMatch(input)) {
        return '[attachment omitted: ${input.length} characters]';
      }
      return text(input);
    }
    return input;
  }

  Map<String, String> headers(Map<String, String> source) => {
    for (final entry in source.entries)
      entry.key:
          {
                'content-type',
                'content-length',
                'accept',
                'user-agent',
                'retry-after',
                'x-request-id',
                'request-id',
                'anthropic-version',
                'openai-version',
              }.contains(entry.key.toLowerCase())
              ? text(entry.value)
              : hidden,
  };

  String url(Uri uri) {
    final sanitized = _url(uri);
    return apiKey.isEmpty ? sanitized : sanitized.replaceAll(apiKey, hidden);
  }

  String _url(Uri uri) =>
      uri
          .replace(
            userInfo: '',
            fragment: '',
            queryParameters:
                uri.hasQuery
                    ? {for (final key in uri.queryParameters.keys) key: hidden}
                    : null,
          )
          .toString();

  String text(String source) {
    var result = apiKey.isEmpty ? source : source.replaceAll(apiKey, hidden);
    result = result.replaceAll(
      RegExp(r'data:[^\s"\x27,;]+(?:;[^,\s]*)?;base64,[A-Za-z0-9+/=\r\n]+'),
      '[attachment omitted]',
    );
    result = result.replaceAll(
      RegExp(r'Bearer\s+[^\s"\x27,}]+', caseSensitive: false),
      'Bearer $hidden',
    );
    result = result.replaceAll(RegExp(r'\bsk-[A-Za-z0-9_-]{8,}'), hidden);
    result = result.replaceAllMapped(
      RegExp(
        r'("(?:api[_-]?key|authorization|access[_-]?token|password|secret|token)"\s*:\s*")[^"\r\n]*',
        caseSensitive: false,
      ),
      (match) => '${match[1]}$hidden',
    );
    result = result.replaceAllMapped(RegExp(r'https?://[^\s"<>\x27]+'), (
      match,
    ) {
      final uri = Uri.tryParse(match[0]!);
      return uri == null ? '[URL omitted]' : _url(uri);
    });
    return result;
  }

  Object? body(String source, {required bool eventStream}) {
    if (eventStream) {
      return const LineSplitter().convert(source).map((line) {
        if (!line.startsWith('data:')) return text(line);
        final payload = line.substring(5).trimLeft();
        return {'data': _decode(payload)};
      }).toList();
    }
    final lines =
        const LineSplitter()
            .convert(source)
            .where((line) => line.trim().isNotEmpty)
            .toList();
    if (lines.length > 1 &&
        lines.every((line) => line.trimLeft().startsWith('{'))) {
      return lines.map(_decode).toList();
    }
    return _decode(source);
  }

  Object? _decode(String source) {
    try {
      return value(jsonDecode(source));
    } on FormatException {
      final trimmed = source.trimLeft();
      if (trimmed != '[DONE]' &&
          (trimmed.startsWith('{') || trimmed.startsWith('['))) {
        return '[incomplete or malformed JSON omitted]';
      }
      return text(source);
    }
  }
}
