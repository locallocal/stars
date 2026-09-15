import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:stars/domain/models/bot.dart';

/// Identifies accepted model behavior without copying credentials into a task.
String taskProviderConfigurationDigest(Bot bot) =>
    sha256
        .convert(
          utf8.encode(
            jsonEncode({
              'apiType': bot.apiType,
              'model': bot.model,
              'endpoint': bot.baseURL,
              'systemPrompt': bot.systemPrompt,
              // SQLite stores absent options as an empty object. Both forms mean
              // the same provider behavior and must survive a repository reload.
              'parameters': _ordered(
                bot.parameters ?? const <String, Object?>{},
              ),
            }),
          ),
        )
        .toString();

Object? _ordered(Object? value) => switch (value) {
  final Map<String, dynamic> map => {
    for (final key in map.keys.toList()..sort()) key: _ordered(map[key]),
  },
  final List<Object?> list => list.map(_ordered).toList(),
  _ => value,
};
