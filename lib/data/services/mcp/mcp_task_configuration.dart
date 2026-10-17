import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:stars/domain/models/message.dart';

/// A reference bound to an accepted user message and its exact configuration.
/// Credentials stay in memory; only [safeArguments] enter task preparation.
final class McpTaskConfiguration {
  McpTaskConfiguration._({
    required this.reference,
    required this.arguments,
    required this.errorCode,
  });

  final String reference;
  final Map<String, Object?> arguments;
  final String? errorCode;

  Map<String, Object?> get safeArguments => {
    for (final entry in arguments.entries)
      if (entry.key != 'access_token' && entry.key != 'environment')
        entry.key: entry.value,
    'configuration_ref': reference,
  };

  static List<McpTaskConfiguration> fromMessages(
    Iterable<Message> messages, {
    required String senderId,
  }) {
    final configurations = <String, McpTaskConfiguration>{};
    for (final message in messages.where((m) => m.senderId == senderId)) {
      for (final object in _jsonObjects(message.content)) {
        final servers = object['mcpServers'];
        if (servers is! Map<String, Object?>) continue;
        for (final entry in servers.entries) {
          if (entry.value case final Map<String, Object?> config) {
            configurations[entry.key] = _parse(
              message.messageId,
              entry.key,
              config,
            );
          }
        }
      }
    }
    return configurations.values.toList(growable: false);
  }

  static McpTaskConfiguration _parse(
    String messageId,
    String name,
    Map<String, Object?> config,
  ) {
    final reference =
        sha256
            .convert(utf8.encode(jsonEncode([messageId, name, config])))
            .toString();
    final type =
        config['type'] ?? (config.containsKey('url') ? 'http' : 'stdio');
    String? error;
    final arguments = <String, Object?>{'name': name};
    if (type == 'http' ||
        type == 'streamable-http' ||
        type == 'streamable_http') {
      arguments.addAll({
        'transport_type': 'streamable_http',
        'endpoint': config['url'],
        'auth_type': 'none',
      });
      if (config.keys.any((key) => !{'type', 'url', 'headers'}.contains(key))) {
        error = 'mcp_unsupported_configuration';
      }
      final headers = config['headers'];
      if (headers != null) {
        if (headers is! Map<String, Object?>) {
          error = 'mcp_unsupported_headers';
        } else {
          for (final entry in headers.entries) {
            if (entry.key.toLowerCase() != 'authorization' ||
                entry.value is! String ||
                !RegExp(
                  r'^Bearer\s+',
                  caseSensitive: false,
                ).hasMatch(entry.value! as String)) {
              error = 'mcp_unsupported_headers';
              continue;
            }
            arguments['auth_type'] = 'oauth_access_token';
            arguments['access_token'] =
                (entry.value! as String)
                    .replaceFirst(
                      RegExp(r'^Bearer\s+', caseSensitive: false),
                      '',
                    )
                    .trim();
          }
        }
      }
    } else if (type == 'stdio') {
      arguments.addAll({
        'transport_type': 'stdio',
        'command': config['command'],
        'arguments': config['args'] ?? const <String>[],
        if (config['env'] != null) 'environment': config['env'],
      });
      if (config.keys.any(
        (key) => !{'type', 'command', 'args', 'env'}.contains(key),
      )) {
        error = 'mcp_unsupported_configuration';
      }
    } else {
      arguments['transport_type'] = type;
      error = 'invalid_mcp_transport';
    }
    return McpTaskConfiguration._(
      reference: reference,
      arguments: Map.unmodifiable(arguments),
      errorCode: error,
    );
  }
}

/// Reads JSON surrounded by prose or code fences without interpreting commands.
Iterable<Map<String, Object?>> _jsonObjects(String text) sync* {
  var depth = 0, start = 0;
  var quoted = false, escaped = false;
  for (var index = 0; index < text.length; index++) {
    final char = text[index];
    if (depth == 0) {
      if (char != '{') continue;
      start = index;
      depth = 1;
      continue;
    }
    if (quoted) {
      if (escaped) {
        escaped = false;
      } else if (char == r'\') {
        escaped = true;
      } else if (char == '"') {
        quoted = false;
      }
      continue;
    }
    if (char == '"') quoted = true;
    if (char == '{') depth++;
    if (char != '}' || --depth != 0) continue;
    try {
      final decoded = jsonDecode(text.substring(start, index + 1));
      if (decoded is Map<String, Object?>) yield decoded;
    } on FormatException {
      // Malformed source remains ordinary conversation text.
    }
  }
}
