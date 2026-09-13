import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  group('BotExportDocument', () {
    test('round-trips portable Bot settings without secrets', () {
      final source = Bot(
        id: 'private-database-id',
        name: 'Research Bot',
        avatar: '/private/avatar.png',
        provider: 'OpenAI',
        baseURL: 'https://example.invalid/v1',
        apiKey: 'super-secret-api-key',
        apiType: Bot.apiTypeOpenAI,
        model: 'gpt-test',
        systemPrompt: 'Be precise.',
        parameters: const {
          Bot.parameterSupportsMcp: true,
          Bot.parameterSupportsAutomaticSkillActivation: true,
          Bot.parameterSupportsSkills: true,
          Bot.parameterContextWindowTokens: 128000,
          Bot.parameterInputModalities: ['text', 'image'],
          Bot.parameterOutputModalities: ['text'],
          Bot.parameterMcpServers: ['docs'],
          Bot.parameterMcpTools: [
            {
              'server_id': 'docs',
              'remote_name': 'search',
              'requires_approval': true,
            },
          ],
        },
        createTimestamp: DateTime.utc(2025),
        modifyTimestamp: DateTime.utc(2026),
      );

      final encoded = jsonEncode(BotExportDocument.fromBot(source));

      expect(encoded, isNot(contains('super-secret-api-key')));
      expect(encoded, isNot(contains('api_key')));
      expect(encoded, isNot(contains('apiKey')));
      expect(encoded, isNot(contains('/private/avatar.png')));
      expect(encoded, isNot(contains('private-database-id')));

      final document = BotExportDocument.fromJson(
        (jsonDecode(encoded) as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      final importedAt = DateTime.utc(2026, 9, 13);
      final imported = document.toImportedBot(
        id: 'new-local-id',
        timestamp: importedAt,
      );

      expect(imported.id, 'new-local-id');
      expect(imported.apiKey, isEmpty);
      expect(imported.avatar, isEmpty);
      expect(imported.name, source.name);
      expect(imported.provider, source.provider);
      expect(imported.baseURL, source.baseURL);
      expect(imported.model, source.model);
      expect(imported.systemPrompt, source.systemPrompt);
      expect(imported.configuredContextWindowTokens, 128000);
      expect(imported.configuredInputModalities, [
        InputModality.text,
        InputModality.image,
      ]);
      expect(imported.mcpServerIds, {'docs'});
      expect(imported.mcpTools.single.serverId, 'docs');
      expect(imported.mcpTools.single.remoteName, 'search');
      expect(imported.createTimestamp, importedAt);
      expect(imported.modifyTimestamp, importedAt);
    });

    test('rejects unknown fields, including attempted credentials', () {
      final source =
          BotExportDocument(
            name: 'Bot',
            provider: 'OpenAI',
            baseUrl: '',
            apiType: Bot.apiTypeOpenAI,
            model: 'gpt-test',
            systemPrompt: '',
          ).toJson();
      final bot = Map<String, Object?>.from(source['bot']! as Map);
      bot['api_key'] = 'must-not-be-imported';
      final tampered = Map<String, Object?>.from(source)..['bot'] = bot;

      expect(() => BotExportDocument.fromJson(tampered), throwsFormatException);
    });

    test('rejects unsupported document versions', () {
      final source =
          BotExportDocument(
            name: 'Bot',
            provider: 'OpenAI',
            baseUrl: '',
            apiType: Bot.apiTypeOpenAI,
            model: 'gpt-test',
            systemPrompt: '',
          ).toJson();
      final futureVersion = Map<String, Object?>.from(source)..['version'] = 2;

      expect(
        () => BotExportDocument.fromJson(futureVersion),
        throwsFormatException,
      );
    });
  });
}
