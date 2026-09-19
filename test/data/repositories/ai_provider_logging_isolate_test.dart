import 'dart:async';
import 'dart:convert';
import 'package:stars/data/services/ai/provider_log_sink.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/ai_provider_repository_impl.dart';
import 'package:stars/data/repositories/file_conversation_model_log_repository.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  test(
    'media isolate forwards sanitized logs to the single file writer',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'stars-media-log-',
      );
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final logRepository = FileConversationModelLogRepository(
        directoryProvider: () async => Directory('${directory.path}/logs'),
      );
      final logs = logRepository.forConversation('media-chat');
      addTearDown(() async {
        await server.close(force: true);
        await logRepository.dispose();
        await directory.delete(recursive: true);
      });
      server.listen((request) async {
        final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        expect(body['input'], 'speech to log');
        expect(request.headers.value('authorization'), 'Bearer isolate-secret');
        request.response.headers.contentType = ContentType('audio', 'mpeg');
        request.response.add([1, 2, 3, 4]);
        await request.response.close();
      });
      await logs.setEnabled(true);
      final repository = AiProviderRepositoryImpl(
        conversationLogSink: logRepository.forConversation,
      ).forConversation('media-chat');
      final bot = Bot(
        id: 'speech',
        name: 'test',
        avatar: '',
        provider: Bot.apiTypeOpenAI,
        apiType: Bot.apiTypeOpenAI,
        model: 'tts-1',
        apiKey: 'isolate-secret',
        baseURL: 'http://127.0.0.1:${server.port}/v1/',
        systemPrompt: '',
        createTimestamp: DateTime(2026),
        modifyTimestamp: DateTime(2026),
      );
      final output = await repository.generateSpeech(
        bot: bot,
        prompt: 'speech to log',
        voiceType: 'alloy',
        outputDirectory: directory.path,
      );
      expect(await File(output).readAsBytes(), [1, 2, 3, 4]);
      await logs.flush();
      final content =
          await File(
            '${(await logs.load()).directoryPath}/model-requests.jsonl',
          ).readAsString();
      final entries =
          const LineSplitter()
              .convert(content)
              .map((line) => jsonDecode(line) as Map)
              .toList();
      expect(entries.map((e) => e['event']), [
        'request',
        'response_headers',
        'response',
      ]);
      expect(entries.map((e) => e['request_id']).toSet(), hasLength(1));
      expect(entries.first['body']['input'], 'speech to log');
      expect(
        entries.every((entry) => entry['chat_id'] == 'media-chat'),
        isTrue,
      );
      expect(entries.last['body'], '[binary body omitted]');
      expect(content, isNot(contains('isolate-secret')));
    },
  );
  for (final cancel in [true, false]) {
    test('media interruption is logged when cancel=$cancel', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((_) {});
      final sink = _RecordingSink();
      final repository = AiProviderRepositoryImpl(
        logSink: sink,
        mediaTimeout: const Duration(milliseconds: 400),
      );
      final bot = Bot(
        id: 'interrupted',
        name: 'test',
        avatar: '',
        provider: Bot.apiTypeOpenAI,
        apiType: Bot.apiTypeOpenAI,
        model: 'tts-1',
        apiKey: '',
        baseURL: 'http://127.0.0.1:${server.port}/v1/',
        systemPrompt: '',
        createTimestamp: DateTime(2026),
        modifyTimestamp: DateTime(2026),
      );
      final request = repository.generateSpeech(
        bot: bot,
        prompt: 'hello',
        voiceType: 'alloy',
        outputDirectory: '/unused',
      );
      final failed = expectLater(
        request,
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.kind,
            'kind',
            cancel ? AppFailureKind.cancelled : AppFailureKind.networkTimeout,
          ),
        ),
      );
      await sink.started.future;
      if (cancel) await repository.cancelMedia(bot.id);
      await failed;
      expect(sink.events.last['event'], 'request_interrupted');
      expect(sink.events.last['outcome'], cancel ? 'cancelled' : 'timeout');
      expect(sink.events.last['request_id'], sink.events.first['request_id']);
    });
  }
}

final class _RecordingSink implements ProviderLogSink {
  final started = Completer<void>();
  final events = <Map<String, Object?>>[];
  @override
  Future<bool> get enabled async => true;
  @override
  void add(Map<String, Object?> event) {
    events.add(event);
    if (event['event'] == 'request' && !started.isCompleted) started.complete();
  }
}
