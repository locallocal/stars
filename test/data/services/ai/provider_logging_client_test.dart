import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stars/data/repositories/ai_provider_repository_impl.dart';
import 'package:stars/data/services/ai/moonshot.dart';
import 'package:stars/data/services/ai/provider_log_sink.dart';
import 'package:stars/data/services/ai/provider_logging_client.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/models/ai_models.dart';

void main() {
  late _Sink sink;
  setUp(() => sink = _Sink());
  ProviderLoggingClient client(http.Client inner, {int maxBodyBytes = 4096}) =>
      ProviderLoggingClient(
        inner: inner,
        sink: sink,
        bot: _bot(),
        operation: 'model',
        maxBodyBytes: maxBodyBytes,
      );

  test(
    'disabled diagnostics forward the original stream without logging',
    () async {
      sink.active = false;
      final original = http.StreamedResponse(Stream.value([1, 2, 3]), 200);
      final response = await client(
        _Sender((_) async => original),
      ).send(http.Request('GET', Uri.parse('https://example.test')));
      expect(identical(response, original), isTrue);
      expect(await response.stream.toBytes(), [1, 2, 3]);
      expect(sink.events, isEmpty);
    },
  );

  test(
    'captures correlated requests, tool definitions, usage and errors with redaction',
    () async {
      final logger = client(
        MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer test-api-secret');
          expect(jsonDecode(request.body)['messages'][0]['content'], '你好');
          return http.Response(
            jsonEncode({
              'error': {'message': 'rejected test-api-secret'},
              'usage': {'input_tokens': 23, 'output_tokens': 8},
            }),
            400,
            headers: {
              'content-type': 'application/json',
              'set-cookie': 'session-private',
            },
          );
        }),
      );
      final result = await logger.post(
        Uri.parse('https://user:pass@example.test/v1/chat?key=query-private'),
        headers: {
          'authorization': 'Bearer test-api-secret',
          'content-type': 'application/json',
          'x-api-key': 'header-private',
        },
        body: jsonEncode({
          'model': 'model',
          'messages': [
            {'role': 'user', 'content': '你好'},
          ],
          'tools': [
            {
              'type': 'function',
              'function': {'name': 'activate_skill'},
            },
          ],
          'parameters': {'api_key': 'nested-private'},
          'image_url': 'data:image/png;base64,YWJjZA==',
          'inline_data': {'data': 'YWJjZA=='},
          'images': ['YWJjZA=='],
          'url': 'https://blob.test/image?signature=signed-private',
        }),
      );
      expect(result.statusCode, 400);
      expect(sink.events.map((e) => e['event']), [
        'request',
        'response_headers',
        'response',
      ]);
      expect(sink.events.map((e) => e['request_id']).toSet(), hasLength(1));
      final body = sink.events.first['body'] as Map;
      expect(body['messages'], [
        {'role': 'user', 'content': '你好'},
      ]);
      expect(
        (body['tools'] as List).single['function']['name'],
        'activate_skill',
      );
      expect((sink.events.last['body'] as Map)['usage']['input_tokens'], 23);
      final encoded = jsonEncode(sink.events);
      for (final secret in [
        'test-api-secret',
        'header-private',
        'nested-private',
        'query-private',
        'signed-private',
        'session-private',
        'YWJjZA==',
        'user:pass',
      ]) {
        expect(encoded, isNot(contains(secret)), reason: secret);
      }
    },
  );

  test(
    'SSE passes each chunk immediately and decodes split UTF-8 in logs',
    () async {
      final source = StreamController<List<int>>();
      final logger = client(
        _Sender(
          (_) async => http.StreamedResponse(
            source.stream,
            200,
            headers: {'content-type': 'text/event-stream'},
          ),
        ),
      );
      final response = await logger.send(
        http.Request('POST', Uri.parse('https://example.test')),
      );
      final first = Completer<void>();
      final delivered = <int>[];
      final done = Completer<void>();
      response.stream.listen((bytes) {
        delivered.addAll(bytes);
        if (!first.isCompleted) first.complete();
      }, onDone: done.complete);
      final bytes = utf8.encode('data: {"delta":"你好"}\n\ndata: [DONE]\n\n');
      final split = bytes.indexOf(0xe4) + 1;
      source.add(bytes.sublist(0, split));
      await first.future;
      expect(delivered, bytes.sublist(0, split));
      expect(sink.events.where((e) => e['event'] == 'response'), isEmpty);
      source.add(bytes.sublist(split));
      await source.close();
      await done.future;
      expect(delivered, bytes);
      expect(jsonEncode(sink.events.last['body']), contains('你好'));
      expect(sink.events.last['outcome'], 'completed');
    },
  );

  test(
    'cancellation propagates while the server is idle and logs partial response',
    () async {
      final cancelled = Completer<void>();
      final source = StreamController<List<int>>(onCancel: cancelled.complete);
      final response = await client(
        _Sender((_) async => http.StreamedResponse(source.stream, 200)),
      ).send(http.Request('GET', Uri.parse('https://example.test')));
      final received = Completer<void>();
      final subscription = response.stream.listen((_) => received.complete());
      source.add(utf8.encode('partial'));
      await received.future;
      await subscription.cancel().timeout(const Duration(seconds: 1));
      await cancelled.future;
      expect(sink.events.last['outcome'], 'cancelled');
      expect(sink.events.last['body'], 'partial');
      await source.close();
    },
  );

  test(
    'transport and stream failures retain their original exceptions',
    () async {
      final failure = http.ClientException('failed test-api-secret');
      await expectLater(
        client(
          _Sender((_) async => throw failure),
        ).get(Uri.parse('https://example.test')),
        throwsA(same(failure)),
      );
      expect(sink.events.last['event'], 'transport_error');
      final response = await client(
        _Sender((_) async => http.StreamedResponse(Stream.error(failure), 200)),
      ).send(http.Request('GET', Uri.parse('https://example.test')));
      await expectLater(response.stream.toBytes(), throwsA(same(failure)));
      expect(sink.events.last['outcome'], 'stream_error');
      expect(jsonEncode(sink.events), isNot(contains('test-api-secret')));
    },
  );

  test(
    'diagnostic failures never reject a successful model response',
    () async {
      sink.throwOnAdd = true;
      final result = await client(
        MockClient((_) async => http.Response('ok', 200)),
      ).get(Uri.parse('https://example.test'));
      expect(result.body, 'ok');
      sink.throwOnEnabled = true;
      expect(
        (await client(
          MockClient((_) async => http.Response('ok', 200)),
        ).get(Uri.parse('https://example.test'))).body,
        'ok',
      );
    },
  );

  test(
    'truncated JSON is omitted and a partial SSE line is never retained',
    () async {
      const body = '{"credentials":"very-long-secret-that-must-not-leak"}';
      final result = await client(
        MockClient((_) async => http.Response(body, 200)),
        maxBodyBytes: 25,
      ).get(Uri.parse('https://example.test'));
      expect(result.body, body);
      expect(sink.events.last['body_truncated'], isTrue);
      expect(sink.events.last['body'], contains('capture limit'));
      expect(jsonEncode(sink.events), isNot(contains('very-long-secret')));
      final sse =
          'data: {"delta":"ok"}\n\ndata: {"credentials":"private-value"}\n\n';
      await client(
        MockClient(
          (_) async => http.Response(
            sse,
            200,
            headers: {'content-type': 'text/event-stream'},
          ),
        ),
        maxBodyBytes: 48,
      ).get(Uri.parse('https://example.test'));
      expect(jsonEncode(sink.events.last['body']), contains('ok'));
      expect(jsonEncode(sink.events.last['body']), isNot(contains('private')));
    },
  );

  test(
    'multipart and binary responses contain metadata without attachment bytes',
    () async {
      final logger = client(
        _Sender((request) async {
          await request.finalize().drain<void>();
          return http.StreamedResponse(
            Stream.value([1, 2, 3, 4]),
            200,
            headers: {'content-type': 'audio/mpeg'},
          );
        }),
      );
      final request =
          http.MultipartRequest('POST', Uri.parse('https://example.test'))
            ..fields['prompt'] = 'transcribe'
            ..files.add(
              http.MultipartFile.fromString(
                'file',
                'private file content',
                filename: 'private-name.wav',
              ),
            );
      final response = await logger.send(request);
      expect(await response.stream.toBytes(), [1, 2, 3, 4]);
      final body = sink.events.first['body'] as Map;
      expect(body['fields'], {'prompt': 'transcribe'});
      expect(body['files'], hasLength(1));
      expect(sink.events.last['body'], '[binary body omitted]');
      expect(jsonEncode(sink.events), isNot(contains('private')));
    },
  );

  test(
    'newline JSON redacts each frame and incomplete JSON is omitted',
    () async {
      const body =
          '{"delta":"one","refresh_token":"ndjson-private"}\n{"delta":"two","data":"YWJjZA=="}\n';
      final response = await client(
        MockClient((_) async => http.Response(body, 200)),
      ).get(Uri.parse('https://example.test'));
      expect(response.body, body);
      expect(sink.events.last['body'], isA<List>());
      expect(
        jsonEncode(sink.events.last['body']),
        isNot(contains('ndjson-private')),
      );
      expect(jsonEncode(sink.events.last['body']), isNot(contains('YWJjZA==')));
      await client(
        MockClient(
          (_) async => http.Response('{"refresh_token":"partial-private', 200),
        ),
      ).get(Uri.parse('https://example.test'));
      expect(
        sink.events.last['body'],
        '[incomplete or malformed JSON omitted]',
      );
    },
  );

  test(
    'factory instruments legacy provider calls while preserving the HTTP zone',
    () async {
      final repository = AiProviderRepositoryImpl(logSink: sink);
      final provider = repository.create(_bot(apiType: Bot.apiTypeOllama));
      final output = StringBuffer();
      provider.onResponse = output.write;
      await http.runWithClient(
        () => provider.generateText([
          ChatMessage(role: 'user', content: 'hello'),
        ]),
        () => MockClient(
          (_) async => http.Response('{"message":{"content":"world"}}\n', 200),
        ),
      );
      expect(output.toString(), 'world');
      expect(sink.events.map((e) => e['event']), [
        'request',
        'response_headers',
        'response',
      ]);
    },
  );

  test(
    'skill activation logs each turn with a distinct request ID and tool results',
    () async {
      final provider = Moonshot(
        _bot(apiType: Bot.apiTypeMoonshot),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'done'},
                },
              ],
            }),
            200,
          ),
        ),
      )..logSink = sink;
      final session = provider.openSkillToolSession(
        SkillToolSessionRequest(
          messages: [ChatMessage(role: 'user', content: 'save the file')],
          catalog: const [],
        ),
      );
      addTearDown(session.close);
      await session.start();
      await session.continueWith([
        const SkillToolResult(
          callId: 'call-1',
          name: 'activate_skill',
          content: 'activated',
        ),
      ]);
      final requests =
          sink.events.where((e) => e['event'] == 'request').toList();
      expect(requests, hasLength(2));
      expect(requests.map((e) => e['request_id']).toSet(), hasLength(2));
      expect(
        requests.every((e) => e['operation'] == 'skill_activation'),
        isTrue,
      );
      expect(jsonEncode(requests.last['body']), contains('activated'));
    },
  );
}

final class _Sink implements ProviderLogSink {
  bool active = true;
  bool throwOnAdd = false;
  bool throwOnEnabled = false;
  final events = <Map<String, Object?>>[];
  @override
  Future<bool> get enabled async {
    if (throwOnEnabled) throw StateError('unavailable');
    return active;
  }

  @override
  void add(Map<String, Object?> event) {
    if (throwOnAdd) throw StateError('disk failure');
    events.add(event);
  }
}

final class _Sender extends http.BaseClient {
  _Sender(this.sender);
  final Future<http.StreamedResponse> Function(http.BaseRequest) sender;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      sender(request);
}

Bot _bot({String apiType = Bot.apiTypeOpenAI}) => Bot(
  id: 'bot',
  name: 'test',
  avatar: '',
  provider: apiType,
  apiType: apiType,
  baseURL: 'https://example.test/v1/',
  apiKey: 'test-api-secret',
  model: 'kimi-k3',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);
