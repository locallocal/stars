import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stars/data/services/ai/moonshot.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  group('Moonshot documented model catalog', () {
    test('enables automatic Skills and MCP for every selected model', () {
      for (final model in [
        'kimi-k3',
        'kimi-k2.6',
        'moonshot-v1-128k',
        'custom-model',
      ]) {
        final provider = Moonshot(_bot(model: model));

        expect(
          provider.capabilities.supportsAutomaticSkillActivation,
          isTrue,
          reason: model,
        );
        expect(provider.supportMcp(), isTrue, reason: model);
      }
    });

    test('drives selected-model reasoning and input capabilities', () {
      final k3 = Moonshot(_bot(model: 'kimi-k3'));
      final k26 = Moonshot(_bot(model: 'kimi-k2.6'));
      final text = Moonshot(_bot(model: 'moonshot-v1-128k'));
      final vision = Moonshot(_bot(model: 'moonshot-v1-128k-vision-preview'));

      expect(k3.supportDeepThinking(), isTrue);
      expect(k3.supportWebSearch(), isTrue);
      expect(k3.getInputModalites(), [
        InputModality.text,
        InputModality.image,
        InputModality.video,
      ]);
      expect(k26.supportDeepThinking(), isTrue);
      expect(k26.supportWebSearch(), isTrue);
      expect(k26.getInputModalites(), contains(InputModality.video));
      expect(text.supportDeepThinking(), isFalse);
      expect(text.supportWebSearch(), isFalse);
      expect(text.getInputModalites(), [InputModality.text]);
      expect(vision.getInputModalites(), [
        InputModality.text,
        InputModality.image,
      ]);
    });

    test('merges the official list with the live models endpoint', () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'data': [
              {'id': 'kimi-k3'},
              {'id': 'custom-model'},
            ],
          }),
          200,
        ),
      );
      final provider = Moonshot(_bot(model: 'kimi-k3'), client: client);

      final models = await provider.fetchModels();
      final ids = models.map((model) => model.modelId).toList();

      expect(ids.take(5), [
        'kimi-k3',
        'kimi-k2.7-code',
        'kimi-k2.7-code-highspeed',
        'kimi-k2.6',
        'kimi-k2.5',
      ]);
      expect(ids, contains('moonshot-v1-128k-vision-preview'));
      expect(ids.last, 'custom-model');
      expect(models.first.contextWindowTokens, 1048576);
      expect(models.first.supportsDeepThinking, isTrue);
      expect(models.every((model) => model.supportsMcp == true), isTrue);
      expect(models.every((model) => model.supportsSkills == true), isTrue);
      expect(
        models.every((model) => model.supportsAutomaticSkillActivation == true),
        isTrue,
      );
    });
  });

  group('Moonshot agent tools', () {
    test('runs automatic Skill activation through chat completions', () async {
      final requestBodies = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        requestBodies.add(
          Map<String, dynamic>.from(jsonDecode(request.body) as Map),
        );
        if (requestBodies.length > 1) {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'done'},
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': null,
                  'reasoning_content': 'The xlsx Skill is relevant.',
                  'tool_calls': [
                    {
                      'id': 'skill-1',
                      'type': 'function',
                      'function': {
                        'name': 'activate_skill',
                        'arguments': '{"name":"release-notes"}',
                      },
                    },
                  ],
                },
              },
            ],
          }),
          200,
        );
      });
      final provider = Moonshot(_bot(model: 'kimi-k3'), client: client);
      final session = provider.openSkillToolSession(
        SkillToolSessionRequest(
          messages: [ChatMessage(role: 'user', content: 'Write release notes')],
          catalog: const [
            SkillCatalogEntry(
              id: 'user:release-notes',
              name: 'release-notes',
              description: 'Prepare release notes.',
              contentDigest: 'digest',
              priority: 0,
            ),
          ],
        ),
      );
      addTearDown(session.close);

      final turn = await session.start();
      await session.continueWith([
        SkillToolResult(
          callId: turn.calls.single.callId,
          name: turn.calls.single.name,
          content: 'activated',
        ),
      ]);

      expect(turn.calls.single.name, 'activate_skill');
      expect(turn.calls.single.arguments, {'name': 'release-notes'});
      expect(requestBodies.first['tool_choice'], 'auto');
      expect(requestBodies.first['parallel_tool_calls'], isFalse);
      expect(requestBodies.first['reasoning_effort'], 'low');
      final continuedMessages = requestBodies.last['messages'] as List;
      final assistant = continuedMessages[1] as Map;
      expect(assistant['role'], 'assistant');
      expect(assistant['reasoning_content'], 'The xlsx Skill is relevant.');
      expect((continuedMessages.last as Map)['role'], 'tool');
    });

    test('round-trips MCP tool calls through chat completions', () async {
      Map<String, dynamic>? requestBody;
      final client = MockClient((request) async {
        requestBody = Map<String, dynamic>.from(
          jsonDecode(request.body) as Map,
        );
        final tools = requestBody!['tools'] as List;
        final function = (tools.single as Map)['function'] as Map;
        return http.Response(
          '${_sse({
            'choices': [
              {
                'delta': {
                  'tool_calls': [
                    {
                      'index': 0,
                      'id': 'mcp-1',
                      'type': 'function',
                      'function': {'name': function['name'], 'arguments': '{"query":"Moonshot"}'},
                    },
                  ],
                },
                'finish_reason': 'tool_calls',
              },
            ],
          })}'
          'data: [DONE]\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      final provider = Moonshot(_bot(model: 'custom-model'), client: client);
      final session = provider.openModelSession(
        ModelRequest(
          messages: [ChatMessage(role: 'user', content: 'Search docs')],
          tools: [
            ToolDefinition(
              name: 'mcp.docs.search',
              description: 'Search documents.',
              inputSchema: const {
                'type': 'object',
                'properties': {
                  'query': {'type': 'string'},
                },
                'required': ['query'],
              },
              source: ToolSource.mcp,
              riskLevel: ToolRiskLevel.readOnly,
              capabilities: const {ToolCapability.network},
            ),
          ],
        ),
      );
      addTearDown(session.close);

      final events = await session.start().toList();

      final call = events.whereType<ToolCallRequested>().single;
      expect(call.name, 'mcp.docs.search');
      expect(call.arguments, {'query': 'Moonshot'});
      expect(requestBody?['tool_choice'], 'auto');
      expect(requestBody?['parallel_tool_calls'], isFalse);
      expect(requestBody?['stream'], isTrue);
      expect(requestBody?['stream_options'], {'include_usage': true});
    });

    test('streams MCP model text as incremental agent events', () async {
      Map<String, dynamic>? requestBody;
      final client = MockClient((request) async {
        requestBody = Map<String, dynamic>.from(
          jsonDecode(request.body) as Map,
        );
        return http.Response(
          '${_sse({
            'choices': [
              {
                'delta': {'content': 'Hello'},
              },
            ],
          })}'
          '${_sse({
            'choices': [
              {
                'delta': {'content': ' Moonshot'},
              },
            ],
          })}'
          '${_sse({
            'choices': [
              {
                'delta': <String, Object?>{},
                'finish_reason': 'stop',
                'usage': {'prompt_tokens': 12, 'completion_tokens': 2, 'total_tokens': 14},
              },
            ],
          })}'
          'data: [DONE]\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      final provider = Moonshot(_bot(model: 'kimi-k2.6'), client: client);
      final session = provider.openModelSession(
        ModelRequest(
          messages: [ChatMessage(role: 'user', content: 'Say hello')],
          tools: [
            ToolDefinition(
              name: 'mcp.docs.search',
              description: 'Search documents.',
              inputSchema: const {'type': 'object'},
              source: ToolSource.mcp,
              riskLevel: ToolRiskLevel.readOnly,
            ),
          ],
          options: const ModelGenerationOptions(deepThinking: true),
        ),
      );
      addTearDown(session.close);

      final events = await session.start().toList();

      expect(events.whereType<TextDelta>().map((event) => event.text), [
        'Hello',
        ' Moonshot',
      ]);
      expect(events.whereType<UsageReported>().single.usage.totalTokens, 14);
      expect(events.whereType<ModelTurnCompleted>().single.stopReason, 'stop');
      expect(requestBody?['stream'], isTrue);
      expect(requestBody?['stream_options'], {'include_usage': true});
      expect(requestBody?['thinking'], {'type': 'enabled'});
    });
  });

  group('Moonshot thinking configuration', () {
    test('preserves K3 assistant reasoning in later turns', () async {
      Map<String, dynamic>? requestBody;
      final client = MockClient((request) async {
        requestBody = Map<String, dynamic>.from(
          jsonDecode(request.body) as Map,
        );
        return http.Response(
          'data: ${jsonEncode({
            'choices': [
              {
                'delta': {'content': 'continued'},
                'finish_reason': 'stop',
              },
            ],
          })}\n\ndata: [DONE]\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      final provider = Moonshot(_bot(model: 'kimi-k3'), client: client);
      final session = provider.openModelSession(
        ModelRequest(
          messages: [
            ChatMessage(role: 'user', content: 'first question'),
            ChatMessage(
              role: 'assistant',
              content: 'first answer',
              reasoning: 'preserved reasoning',
            ),
            ChatMessage(role: 'user', content: 'follow-up'),
          ],
        ),
      );
      addTearDown(session.close);

      await session.start().toList();

      final messages = requestBody?['messages'] as List;
      expect(messages[1], {
        'role': 'assistant',
        'content': 'first answer',
        'reasoning_content': 'preserved reasoning',
      });
    });

    test('sends the K2.6 thinking mode selected by the user', () async {
      final disabled = await _requestBodyFor(
        model: 'kimi-k2.6',
        deepThinking: false,
      );
      final enabled = await _requestBodyFor(
        model: 'kimi-k2.6',
        deepThinking: true,
      );

      expect(disabled['thinking'], {'type': 'disabled'});
      expect(enabled['thinking'], {'type': 'enabled'});
    });

    test('maps the thinking switch to K3 reasoning effort', () async {
      final low = await _requestBodyFor(model: 'kimi-k3', deepThinking: false);
      final max = await _requestBodyFor(model: 'kimi-k3', deepThinking: true);

      expect(low, isNot(contains('thinking')));
      expect(low['reasoning_effort'], 'low');
      expect(max, isNot(contains('thinking')));
      expect(max['reasoning_effort'], 'max');
    });
  });

  group('Moonshot built-in web search', () {
    test('declares the official web search tool alongside reasoning', () async {
      final body = await _requestBodyFor(
        model: 'kimi-k2.6',
        deepThinking: true,
        webSearch: true,
      );

      expect(body['thinking'], {'type': 'enabled'});
      expect(body['tools'], [
        {
          'type': 'builtin_function',
          'function': {'name': r'$web_search'},
        },
      ]);
    });

    test('echoes web search arguments until Kimi returns an answer', () async {
      final requestBodies = <Map<String, dynamic>>[];
      var requestCount = 0;
      final client = MockClient((request) async {
        requestBodies.add(
          Map<String, dynamic>.from(jsonDecode(request.body) as Map),
        );
        requestCount += 1;
        if (requestCount == 1) {
          return http.Response(
            '${_sse({
              'choices': [
                {
                  'delta': {
                    'reasoning_content': 'searching',
                    'tool_calls': [
                      {
                        'index': 0,
                        'id': 'search-1',
                        'type': 'function',
                        'function': {'name': r'$web_search', 'arguments': '{"query":'},
                      },
                    ],
                  },
                },
              ],
            })}'
            '${_sse({
              'choices': [
                {
                  'delta': {
                    'tool_calls': [
                      {
                        'index': 0,
                        'function': {'arguments': '"Moonshot"}'},
                      },
                    ],
                  },
                  'finish_reason': 'tool_calls',
                },
              ],
            })}'
            'data: [DONE]\n\n',
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        }
        return http.Response(
          '${_sse({
            'choices': [
              {
                'delta': {'content': 'final answer'},
                'finish_reason': 'stop',
              },
            ],
          })}'
          'data: [DONE]\n\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      });
      var response = '';
      var reasoning = '';
      var completed = false;
      final provider =
          Moonshot(_bot(model: 'kimi-k3'), client: client)
            ..setWebSearch(true)
            ..setDeepThinking(true)
            ..setCallbacks(
              onResponse: (value) => response += value,
              onReasoningResponse: (value) => reasoning += value,
              onComplete: () => completed = true,
            );

      await provider.generateText([
        ChatMessage(role: 'user', content: 'latest Moonshot news'),
      ]);

      expect(requestBodies, hasLength(2));
      expect(response, 'final answer');
      expect(reasoning, 'searching');
      expect(completed, isTrue);
      expect(requestBodies.every((body) => body.containsKey('tools')), isTrue);
      expect(requestBodies.first['reasoning_effort'], 'max');

      final followUpMessages = requestBodies.last['messages'] as List;
      final assistant = followUpMessages[followUpMessages.length - 2] as Map;
      final tool = followUpMessages.last as Map;
      expect(assistant['reasoning_content'], 'searching');
      expect((assistant['tool_calls'] as List).single, {
        'id': 'search-1',
        'type': 'function',
        'function': {
          'name': r'$web_search',
          'arguments': '{"query":"Moonshot"}',
        },
      });
      expect(tool, {
        'role': 'tool',
        'tool_call_id': 'search-1',
        'name': r'$web_search',
        'content': '{"query":"Moonshot"}',
      });
    });
  });
}

Future<Map<String, dynamic>> _requestBodyFor({
  required String model,
  required bool deepThinking,
  bool webSearch = false,
}) async {
  Map<String, dynamic>? requestBody;
  final client = MockClient((request) async {
    requestBody = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
    return http.Response(
      'data: ${jsonEncode({
        'choices': [
          {
            'delta': {'content': 'done'},
          },
        ],
      })}\n\ndata: [DONE]\n\n',
      200,
      headers: {'content-type': 'text/event-stream'},
    );
  });
  final provider =
      Moonshot(_bot(model: model), client: client)
        ..setDeepThinking(deepThinking)
        ..setWebSearch(webSearch)
        ..setCallbacks(onResponse: (_) {});

  await provider.generateText([ChatMessage(role: 'user', content: 'hello')]);

  expect(requestBody, isNotNull);
  return requestBody!;
}

String _sse(Map<String, Object?> data) => 'data: ${jsonEncode(data)}\n\n';

Bot _bot({required String model}) => Bot(
  id: 'bot-moonshot-$model',
  name: model,
  avatar: '',
  provider: 'Moonshot',
  baseURL: 'https://api.moonshot.cn/v1/',
  apiKey: 'test-key',
  apiType: Bot.apiTypeMoonshot,
  model: model,
  systemPrompt: '',
  createTimestamp: DateTime.fromMillisecondsSinceEpoch(1),
  modifyTimestamp: DateTime.fromMillisecondsSinceEpoch(1),
);
