import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:stars/data/repositories/ai_provider_repository_impl.dart';
import 'package:stars/data/repositories/file_conversation_model_log_repository.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/models/ai_models.dart';

void main() {
  late Directory root;
  late FileConversationModelLogRepository logs;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('stars-conversation-logs-');
    logs = FileConversationModelLogRepository(
      directoryProvider: () async => root,
    );
  });
  tearDown(() async {
    await logs.dispose();
    await root.delete(recursive: true);
  });

  test(
    'preferences persist per conversation and ignore the former global switch',
    () async {
      await File(
        p.join(root.path, 'settings.json'),
      ).writeAsString('{"enabled":true}');
      final first = logs.forConversation('first');
      final second = logs.forConversation('second');
      expect(await first.enabled, isFalse);
      expect(await second.enabled, isFalse);
      expect(logs.forConversation('first'), same(first));
      await first.setEnabled(true);
      expect(await second.enabled, isFalse);
      final restarted = FileConversationModelLogRepository(
        directoryProvider: () async => root,
      );
      addTearDown(restarted.dispose);
      expect(await restarted.forConversation('first').enabled, isTrue);
      expect(await restarted.forConversation('second').enabled, isFalse);
      expect(
        (await first.load()).directoryPath,
        isNot((await second.load()).directoryPath),
      );
    },
  );

  test(
    'arbitrary IDs remain inside the root and records keep their bound chat ID',
    () async {
      final repository = logs.forConversation('../../会话/../test');
      await repository.setEnabled(true);
      final settings = await repository.load();
      expect(p.isWithin(root.path, settings.directoryPath), isTrue);
      repository.add({'event': 'request', 'chat_id': 'forged-chat'});
      await repository.flush();
      final entry =
          jsonDecode(
                await File(
                  p.join(settings.directoryPath, 'model-requests.jsonl'),
                ).readAsString(),
              )
              as Map;
      expect(entry['chat_id'], '../../会话/../test');
      expect(() => logs.forConversation(''), throwsArgumentError);
    },
  );

  test(
    'concurrent requests using the same bot write only to their own files',
    () async {
      for (final id in ['first', 'second']) {
        await logs.forConversation(id).setEnabled(true);
      }
      final providers = AiProviderRepositoryImpl(
        conversationLogSink: logs.forConversation,
      );
      final bot = _bot();
      final pending = <String, Completer<http.Response>>{};
      Future<void> invoke(String? id, String prompt) async {
        final provider = (id == null
                ? providers
                : providers.forConversation(id))
            .create(bot);
        final output = StringBuffer();
        provider.onResponse = output.write;
        await provider.generateText([
          ChatMessage(role: 'user', content: prompt),
        ]);
        expect(output.toString(), 'reply-$prompt');
      }

      await http.runWithClient(
        () async {
          final first = invoke('first', 'first-only');
          final second = invoke('second', 'second-only');
          final disabled = invoke('disabled', 'disabled-only');
          final unscoped = invoke(null, 'unscoped');
          while (pending.length < 4) {
            await Future<void>.delayed(Duration.zero);
          }
          for (final prompt in [
            'second-only',
            'unscoped',
            'disabled-only',
            'first-only',
          ]) {
            pending[prompt]!.complete(
              http.Response(
                jsonEncode({
                  'message': {'content': 'reply-$prompt'},
                }),
                200,
              ),
            );
          }
          await Future.wait([first, second, disabled, unscoped]);
        },
        () => MockClient((request) {
          final body = jsonDecode(request.body) as Map;
          final prompt = (body['messages'] as List).single['content'] as String;
          final response = Completer<http.Response>();
          pending[prompt] = response;
          return response.future;
        }),
      );
      await logs.flush();
      for (final id in ['first', 'second']) {
        final directory = (await logs.forConversation(id).load()).directoryPath;
        final content =
            await File(
              p.join(directory, 'model-requests.jsonl'),
            ).readAsString();
        final events =
            const LineSplitter()
                .convert(content)
                .map((line) => jsonDecode(line) as Map)
                .toList();
        expect(events, hasLength(3));
        expect(events.every((e) => e['chat_id'] == id), isTrue);
        expect(content, contains('$id-only'));
        expect(
          content,
          isNot(contains('${id == 'first' ? 'second' : 'first'}-only')),
        );
        expect(content, isNot(contains('disabled-only')));
      }
      final disabledPath =
          (await logs.forConversation('disabled').load()).directoryPath;
      expect(await Directory(disabledPath).exists(), isFalse);
      expect(
        await File(p.join(root.path, 'model-requests.jsonl')).exists(),
        isFalse,
      );
    },
  );

  test(
    'turning a conversation off stops pending response writes without affecting another chat',
    () async {
      final first = logs.forConversation('first');
      final second = logs.forConversation('second');
      await first.setEnabled(true);
      await second.setEnabled(true);
      first.add({'event': 'request'});
      await first.flush();
      await first.setEnabled(false);
      first.add({'event': 'response'});
      second.add({'event': 'response'});
      await logs.flush();
      final firstLines =
          await File(
            p.join((await first.load()).directoryPath, 'model-requests.jsonl'),
          ).readAsLines();
      expect(firstLines, hasLength(1));
      final secondLines =
          await File(
            p.join((await second.load()).directoryPath, 'model-requests.jsonl'),
          ).readAsLines();
      expect(secondLines, hasLength(1));
      expect(jsonDecode(secondLines.single)['chat_id'], 'second');
    },
  );
}

Bot _bot() => Bot(
  id: 'shared-bot',
  name: 'test',
  avatar: '',
  provider: 'ollama',
  apiType: Bot.apiTypeOllama,
  baseURL: 'https://example.invalid',
  apiKey: '',
  model: 'model',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);
