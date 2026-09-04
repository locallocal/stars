import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stars/data/services/ai/openai.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  group('OpenAI documented model catalog', () {
    test('contains all 93 official model IDs plus the GPT-5.6 alias', () {
      expect(OpenAI.officialModelIds, hasLength(93));
      expect(OpenAI.officialModelIds, contains('gpt-5.6-sol'));
      expect(OpenAI.officialModelIds, contains('gpt-image-2'));
      expect(OpenAI.officialModelIds, contains('sora-2-pro'));
      expect(OpenAI.officialModelIds, contains('gpt-realtime-2.1'));
      expect(OpenAI.officialModelIds, contains('text-embedding-3-large'));
      expect(OpenAI.officialModelIds, contains('omni-moderation-latest'));
      expect(OpenAI.officialModelIds, isNot(contains('gpt-5.6')));

      final documentedIds =
          OpenAI.documentedModels.map((model) => model.modelId).toList();
      expect(documentedIds, contains('gpt-5.6'));
      expect(documentedIds.toSet(), hasLength(documentedIds.length));
    });

    test('exposes endpoint, lifecycle, limit, and native-tool metadata', () {
      final sol = OpenAI.documentedModels.singleWhere(
        (model) => model.modelId == 'gpt-5.6-sol',
      );
      final image = OpenAI.documentedModels.singleWhere(
        (model) => model.modelId == 'gpt-image-2',
      );
      final moderation = OpenAI.documentedModels.singleWhere(
        (model) => model.modelId == 'omni-moderation-latest',
      );

      expect(sol.taskType, AiModelTaskType.chat);
      expect(sol.lifecycle, AiModelLifecycle.recommended);
      expect(sol.contextWindowTokens, 1050000);
      expect(sol.maxInputTokens, 922000);
      expect(sol.maxOutputTokens, 128000);
      expect(sol.knowledgeCutoff, DateTime.utc(2026, 2, 16));
      expect(sol.supportedEndpoints, contains(AiModelEndpoint.responses));
      expect(sol.reasoningEfforts, containsAll(['none', 'high', 'xhigh']));
      expect(sol.nativeTools, containsAll(['web_search', 'skills', 'mcp']));
      expect(image.taskType, AiModelTaskType.imageGeneration);
      expect(image.outputModalities, [OutputModality.image]);
      expect(moderation.taskType, AiModelTaskType.moderation);
      expect(moderation.inputModalities, contains(InputModality.image));
    });

    test('drives selected-model capabilities from documented metadata', () {
      final frontier = OpenAI(_bot(model: 'gpt-5.5-pro'));
      final smallReasoner = OpenAI(_bot(model: 'o3-mini'));
      final speech = OpenAI(_bot(model: 'gpt-4o-mini-tts'));
      final video = OpenAI(_bot(model: 'sora-2-pro'));

      expect(frontier.supportWebSearch(), isTrue);
      expect(frontier.supportDeepThinking(), isTrue);
      expect(frontier.supportMcp(), isTrue);
      expect(frontier.getInputModalites(), contains(InputModality.image));
      expect(smallReasoner.getInputModalites(), [InputModality.text]);
      expect(speech.getOutputModalites(), [OutputModality.speech]);
      expect(speech.getSupportVoicTypes(), containsAll(['marin', 'cedar']));
      expect(video.getOutputModalites(), contains(OutputModality.video));
      expect(video.getSupportVideoRatios(), ['16:9', '9:16']);
    });
  });

  test(
    'fetchModels enriches chat models and filters unsupported task types',
    () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'data': [
              {'id': 'gpt-5.5-pro'},
              {'id': 'gpt-image-2'},
              {'id': 'text-embedding-3-large'},
              {'id': 'gpt-5.3-chat-latest'},
              {'id': 'custom-chat-model'},
            ],
          }),
          200,
        ),
      );
      final provider = OpenAI(
        _bot(model: 'gpt-5.5-pro'),
        skillToolClient: client,
      );

      final models = await provider.fetchModels();
      final ids = models.map((model) => model.modelId).toList();
      final pro = models.singleWhere((model) => model.modelId == 'gpt-5.5-pro');

      expect(ids.take(4), [
        'gpt-5.6-sol',
        'gpt-5.6',
        'gpt-5.6-terra',
        'gpt-5.6-luna',
      ]);
      expect(ids, containsAll(['gpt-5.5-pro', 'custom-chat-model']));
      expect(ids, isNot(contains('gpt-image-2')));
      expect(ids, isNot(contains('text-embedding-3-large')));
      expect(ids, isNot(contains('gpt-5.3-chat-latest')));
      expect(pro.taskType, AiModelTaskType.chat);
      expect(pro.supportedEndpoints, [
        AiModelEndpoint.responses,
        AiModelEndpoint.batch,
      ]);
      expect(pro.supportsDeepThinking, isTrue);
    },
  );

  test(
    'OpenAI-compatible providers keep their own catalog and capabilities',
    () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'data': [
              {'id': 'gpt-5.5-pro'},
              {'id': 'gpt-image-2'},
              {'id': 'vendor-chat-model'},
            ],
          }),
          200,
        ),
      );
      final provider = OpenAI(
        _bot(model: 'gpt-5.5-pro', provider: 'SiliconFlow'),
        skillToolClient: client,
      );

      final models = await provider.fetchModels();
      final ids = models.map((model) => model.modelId).toSet();

      expect(ids, {'gpt-5.5-pro', 'gpt-image-2', 'vendor-chat-model'});
      expect(provider.supportWebSearch(), isFalse);
      expect(provider.supportDeepThinking(), isFalse);
      expect(provider.supportMcp(), isFalse);
    },
  );

  test(
    'Responses-only models stream text, reasoning, search, and usage',
    () async {
      Map<String, dynamic>? requestBody;
      final client = MockClient((request) async {
        requestBody = Map<String, dynamic>.from(
          jsonDecode(request.body) as Map,
        );
        expect(request.url.path, '/v1/responses');
        return http.Response(
          '${_sse({'type': 'response.reasoning_summary_text.delta', 'delta': 'think'})}'
          '${_sse({'type': 'response.output_text.delta', 'delta': 'answer'})}'
          '${_sse({
            'type': 'response.completed',
            'response': {
              'usage': {'input_tokens': 8, 'output_tokens': 3},
            },
          })}',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      final provider =
          OpenAI(_bot(model: 'gpt-5.5-pro'), skillToolClient: client)
            ..setWebSearch(true)
            ..setDeepThinking(true);
      var answer = '';
      var reasoning = '';
      String? error;
      ModelTokenUsage? usage;
      provider.setCallbacks(
        onResponse: (value) => answer += value,
        onReasoningResponse: (value) => reasoning += value,
        onTokenUsage: (value) => usage = value,
        onError: (value) => error = value,
      );

      await provider.generateText([
        ChatMessage(role: 'system', content: 'be concise'),
        ChatMessage(role: 'user', content: 'hello'),
      ]);

      expect(error, isNull);
      expect(answer, 'answer');
      expect(reasoning, 'think');
      expect(requestBody?['tools'], [
        {'type': 'web_search'},
      ]);
      expect(requestBody?['reasoning'], {'effort': 'high', 'summary': 'auto'});
      expect(
        (requestBody?['input'] as List<Object?>).map(
          (item) => (item as Map<Object?, Object?>)['role'],
        ),
        ['developer', 'user'],
      );
      expect(usage?.inputTokens, 8);
      expect(usage?.outputTokens, 3);
    },
  );

  test(
    'Chat reasoning uses an effort supported by the selected model',
    () async {
      Map<String, dynamic>? requestBody;
      final client = MockClient((request) async {
        requestBody = Map<String, dynamic>.from(
          jsonDecode(request.body) as Map,
        );
        return http.Response(
          '${_sse({
            'choices': [
              {
                'delta': {'content': 'answer'},
              },
            ],
          })}data: [DONE]\n\n',
          200,
        );
      });
      final provider = OpenAI(_bot(model: 'o1-mini'), skillToolClient: client)
        ..setDeepThinking(true);

      await provider.generateText([
        ChatMessage(role: 'user', content: 'hello'),
      ]);

      expect(requestBody?['reasoning_effort'], 'medium');
    },
  );

  test(
    'Search Preview remains on Chat Completions with search options',
    () async {
      Map<String, dynamic>? requestBody;
      final client = MockClient((request) async {
        requestBody = Map<String, dynamic>.from(
          jsonDecode(request.body) as Map,
        );
        expect(request.url.path, '/v1/chat/completions');
        return http.Response(
          '${_sse({
            'choices': [
              {
                'delta': {'content': 'found'},
              },
            ],
          })}data: [DONE]\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      final provider = OpenAI(
        _bot(model: 'gpt-4o-search-preview'),
        skillToolClient: client,
      )..setWebSearch(true);
      var answer = '';
      provider.setCallbacks(onResponse: (value) => answer += value);

      await provider.generateText([ChatMessage(role: 'user', content: 'news')]);

      expect(answer, 'found');
      expect(requestBody?['web_search_options'], isEmpty);
    },
  );

  test('GPT Image generation persists base64 output', () async {
    final output = await Directory.systemTemp.createTemp('stars-openai-image-');
    addTearDown(() => output.delete(recursive: true));
    Map<String, dynamic>? requestBody;
    final client = MockClient((request) async {
      requestBody = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
      expect(request.url.path, '/v1/images/generations');
      return http.Response(
        jsonEncode({
          'data': [
            {
              'b64_json': base64Encode([1, 2, 3, 4]),
            },
          ],
        }),
        200,
      );
    });
    final provider = OpenAI(
      _bot(model: 'gpt-image-2'),
      skillToolClient: client,
    );

    final paths = await provider.generateImage(
      'otter',
      '1024x1024',
      output.path,
    );

    expect(requestBody?['model'], 'gpt-image-2');
    expect(requestBody, isNot(contains('response_format')));
    expect(await File(paths.single).readAsBytes(), [1, 2, 3, 4]);
  });

  test('GPT Image edits send reference images as multipart data', () async {
    final output = await Directory.systemTemp.createTemp('stars-openai-edit-');
    addTearDown(() => output.delete(recursive: true));
    final reference = File('${output.path}/reference.png');
    await reference.writeAsBytes([0x89, 0x50, 0x4e, 0x47]);
    final client = MockClient((request) async {
      expect(request.url.path, '/v1/images/edits');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(latin1.decode(request.bodyBytes), contains('name="image[]"'));
      return http.Response(
        jsonEncode({
          'data': [
            {
              'b64_json': base64Encode([5, 6, 7]),
            },
          ],
        }),
        200,
      );
    });
    final provider = OpenAI(
      _bot(model: 'gpt-image-2'),
      skillToolClient: client,
    );

    final paths = await provider.generateImage(
      'edit',
      '1024x1024',
      output.path,
      referenceImages: [reference.path],
    );

    expect(await File(paths.single).readAsBytes(), [5, 6, 7]);
  });

  test(
    'Speech generation sends the selected voice and writes MP3 bytes',
    () async {
      final output = await Directory.systemTemp.createTemp('stars-openai-tts-');
      addTearDown(() => output.delete(recursive: true));
      Map<String, dynamic>? requestBody;
      final client = MockClient((request) async {
        requestBody = Map<String, dynamic>.from(
          jsonDecode(request.body) as Map,
        );
        expect(request.url.path, '/v1/audio/speech');
        return http.Response.bytes([9, 8, 7], 200);
      });
      final provider = OpenAI(
        _bot(model: 'gpt-4o-mini-tts'),
        skillToolClient: client,
      );

      final path = await provider.generateSpeech('hello', 'cedar', output.path);

      expect(requestBody?['voice'], 'cedar');
      expect(requestBody?['response_format'], 'mp3');
      expect(await File(path).readAsBytes(), [9, 8, 7]);
    },
  );

  test('Sora generation creates a job and downloads completed video', () async {
    Map<String, dynamic>? createBody;
    final client = MockClient((request) async {
      if (request.method == 'POST' && request.url.path == '/v1/videos') {
        createBody = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        return http.Response(
          jsonEncode({'id': 'video-1', 'status': 'completed'}),
          200,
        );
      }
      if (request.method == 'GET' &&
          request.url.path == '/v1/videos/video-1/content') {
        return http.Response.bytes([0, 1, 2, 3], 200);
      }
      return http.Response('not found', 404);
    });
    final output = await Directory.systemTemp.createTemp('stars-openai-video-');
    addTearDown(() => output.delete(recursive: true));
    final provider = OpenAI(_bot(model: 'sora-2-pro'), skillToolClient: client);

    final path = await provider.generateVideo(
      'cinematic landscape',
      '9:16',
      output.path,
      const [],
    );

    expect(createBody?['size'], '1080x1920');
    expect(await File(path).readAsBytes(), [0, 1, 2, 3]);
  });

  test('Responses model session round-trips function call outputs', () async {
    final requests = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      requests.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
      if (requests.length == 1) {
        return http.Response(
          jsonEncode({
            'status': 'completed',
            'output': [
              {
                'type': 'reasoning',
                'summary': [
                  {'type': 'summary_text', 'text': 'checking'},
                ],
              },
              {
                'type': 'function_call',
                'id': 'fc-1',
                'call_id': 'call-1',
                'name': 'calculate',
                'arguments': '{"value":2}',
              },
            ],
            'usage': {
              'input_tokens': 10,
              'output_tokens': 4,
              'total_tokens': 14,
            },
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'role': 'assistant',
              'content': [
                {'type': 'output_text', 'text': 'four'},
              ],
            },
          ],
        }),
        200,
      );
    });
    final provider = OpenAI(
      _bot(model: 'gpt-5.6-sol'),
      skillToolClient: client,
    );
    final session = provider.openModelSession(
      ModelRequest(
        messages: [ChatMessage(role: 'user', content: 'calculate')],
        options: const ModelGenerationOptions(
          allowParallelToolCalls: true,
          deepThinking: true,
        ),
        tools: [_calculateTool],
      ),
    );
    addTearDown(session.close);

    final first = await session.start().toList();
    final second =
        await session.continueWith([
          ToolResult(
            callId: 'call-1',
            name: 'calculate',
            content: '4',
            invocationId: 'invocation-1',
            attemptId: 'attempt-1',
            evidenceId: 'evidence-1',
          ),
        ]).toList();

    expect(first.whereType<ReasoningDelta>().single.text, 'checking');
    expect(first.whereType<ToolCallRequested>().single.arguments, {'value': 2});
    expect(first.whereType<UsageReported>().single.usage.totalTokens, 14);
    expect(second.whereType<TextDelta>().single.text, 'four');
    final tools = requests.first['tools']! as List<Object?>;
    final tool = Map<String, dynamic>.from(tools.single as Map);
    expect(tool['name'], 'calculate');
    expect(tool, isNot(contains('function')));
    final continuedInput = requests.last['input']! as List<Object?>;
    expect(
      Map<String, dynamic>.from(continuedInput.last as Map),
      containsPair('type', 'function_call_output'),
    );
    final output =
        Map<String, dynamic>.from(continuedInput.last as Map)['output']!
            as String;
    final envelope = Map<String, dynamic>.from(jsonDecode(output) as Map);
    expect(envelope['type'], 'stars_tool_result');
    expect(envelope['evidence_id'], 'evidence-1');
    expect(envelope['invocation_id'], 'invocation-1');
    expect(envelope['attempt_id'], 'attempt-1');
    expect(envelope['provider_call_id'], 'call-1');
    expect(envelope['status'], 'success');
  });
}

String _sse(Map<String, Object?> event) => 'data: ${jsonEncode(event)}\n\n';

Bot _bot({required String model, String provider = 'OpenAI'}) => Bot(
  id: 'bot-openai',
  name: 'OpenAI',
  avatar: '',
  provider: provider,
  baseURL: 'https://example.test/v1/',
  apiKey: 'test-key',
  apiType: Bot.apiTypeOpenAI,
  model: model,
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

final _calculateTool = ToolDefinition(
  name: 'calculate',
  description: 'Double a number.',
  inputSchema: const {
    'type': 'object',
    'properties': {
      'value': {'type': 'integer'},
    },
    'required': ['value'],
    'additionalProperties': false,
  },
  source: ToolSource.builtIn,
  riskLevel: ToolRiskLevel.readOnly,
  capabilities: const {ToolCapability.compute},
);
