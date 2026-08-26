import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stars/data/services/ai/anthropic.dart';
import 'package:stars/data/services/ai/openai.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';

void main() {
  test('OpenAI uses structured Skill tools and returns tool results', () async {
    final requests = <Map<String, Object?>>[];
    var requestIndex = 0;
    final client = MockClient((request) async {
      requests.add(
        (jsonDecode(request.body) as Map<Object?, Object?>).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      requestIndex += 1;
      if (requestIndex == 1) {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': null,
                  'tool_calls': [
                    {
                      'id': 'call-1',
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
            'usage': {
              'prompt_tokens': 10,
              'completion_tokens': 2,
              'total_tokens': 12,
            },
          }),
          200,
        );
      }
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
    });
    final provider = OpenAI(_bot, skillToolClient: client);
    final session = provider.openSkillToolSession(_request);
    addTearDown(session.close);

    final first = await session.start();
    expect(first.calls.single.name, 'activate_skill');
    expect(first.calls.single.arguments, {'name': 'release-notes'});
    expect(first.tokenUsage.effectiveTotalTokens, 12);

    final second = await session.continueWith(const [
      SkillToolResult(
        callId: 'call-1',
        name: 'activate_skill',
        content: 'activated',
      ),
    ]);
    expect(second.isComplete, isTrue);
    expect(requests, hasLength(2));
    expect(requests.first['parallel_tool_calls'], isFalse);
    expect(requests.first['tools'], hasLength(2));
    final secondMessages = requests.last['messages']! as List<Object?>;
    final toolMessage = secondMessages.last as Map<Object?, Object?>;
    expect(toolMessage['role'], 'tool');
    expect(toolMessage['tool_call_id'], 'call-1');
  });

  test('OpenAI Responses Skill session round-trips function outputs', () async {
    final requests = <Map<String, Object?>>[];
    final client = MockClient((request) async {
      requests.add(
        (jsonDecode(request.body) as Map<Object?, Object?>).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      if (requests.length == 1) {
        return http.Response(
          jsonEncode({
            'output': [
              {
                'type': 'function_call',
                'id': 'fc-1',
                'call_id': 'call-1',
                'name': 'activate_skill',
                'arguments': '{"name":"release-notes"}',
              },
            ],
            'usage': {
              'input_tokens': 9,
              'output_tokens': 2,
              'total_tokens': 11,
            },
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'output': [
            {
              'type': 'message',
              'role': 'assistant',
              'content': [
                {'type': 'output_text', 'text': 'done'},
              ],
            },
          ],
        }),
        200,
      );
    });
    final provider = OpenAI(_firstPartyBot, skillToolClient: client);
    final session = provider.openSkillToolSession(_request);
    addTearDown(session.close);

    final first = await session.start();
    final second = await session.continueWith(const [
      SkillToolResult(
        callId: 'call-1',
        name: 'activate_skill',
        content: 'activated',
      ),
    ]);

    expect(first.calls.single.name, 'activate_skill');
    expect(first.calls.single.arguments, {'name': 'release-notes'});
    expect(first.tokenUsage.totalTokens, 11);
    expect(second.isComplete, isTrue);
    final tools = requests.first['tools']! as List<Object?>;
    expect((tools.first as Map<Object?, Object?>)['name'], 'activate_skill');
    expect(tools.first as Map<Object?, Object?>, isNot(contains('function')));
    final continuedInput = requests.last['input']! as List<Object?>;
    expect(
      (continuedInput.last as Map<Object?, Object?>)['type'],
      'function_call_output',
    );
  });

  test('Anthropic parses tool_use blocks and reports usage', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'content': [
            {
              'type': 'tool_use',
              'id': 'tool-1',
              'name': 'activate_skill',
              'input': {'name': 'release-notes'},
            },
          ],
          'usage': {'input_tokens': 14, 'output_tokens': 3},
        }),
        200,
      ),
    );
    final provider = Anthropic(_bot, skillToolClient: client);
    final session = provider.openSkillToolSession(_request);
    addTearDown(session.close);

    final turn = await session.start();

    expect(turn.calls.single.callId, 'tool-1');
    expect(turn.calls.single.arguments['name'], 'release-notes');
    expect(turn.tokenUsage.inputTokens, 14);
    expect(turn.tokenUsage.outputTokens, 3);
    expect(turn.tokenUsage.effectiveTotalTokens, 17);
  });

  test('OpenAI generic model session maps tools and result turns', () async {
    final requests = <Map<String, Object?>>[];
    var requestIndex = 0;
    final client = MockClient((request) async {
      requests.add(
        (jsonDecode(request.body) as Map<Object?, Object?>).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      requestIndex += 1;
      return http.Response(
        requestIndex == 1
            ? jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': 'checking',
                    'tool_calls': [
                      {
                        'id': 'generic-1',
                        'type': 'function',
                        'function': {
                          'name': 'calculate',
                          'arguments': '{"value":2}',
                        },
                      },
                    ],
                  },
                  'finish_reason': 'tool_calls',
                },
              ],
            })
            : jsonEncode({
              'choices': [
                {
                  'message': {'content': 'four'},
                  'finish_reason': 'stop',
                },
              ],
            }),
        200,
      );
    });
    final provider = OpenAI(_bot, skillToolClient: client);
    final session = provider.openModelSession(_modelRequest);
    addTearDown(session.close);

    final first = await session.start().toList();
    expect(first.whereType<TextDelta>().single.text, 'checking');
    expect(first.whereType<ToolCallRequested>().single.arguments, {'value': 2});

    final second =
        await session.continueWith([
          ToolResult(callId: 'generic-1', name: 'calculate', content: '4'),
        ]).toList();
    expect(second.whereType<TextDelta>().single.text, 'four');
    final sentTools = requests.first['tools']! as List<Object?>;
    expect(sentTools, hasLength(1));
    expect(requests.first['parallel_tool_calls'], isTrue);
    final continuedMessages = requests.last['messages']! as List<Object?>;
    expect(
      (continuedMessages.last as Map<Object?, Object?>)['tool_call_id'],
      'generic-1',
    );
    final envelope =
        jsonDecode(
              (continuedMessages.last as Map<Object?, Object?>)['content']!
                  as String,
            )
            as Map<String, Object?>;
    expect(envelope['type'], 'stars_tool_result');
    expect(envelope['evidence_id'], 'generic-1');
    expect(envelope['status'], 'success');
    expect(envelope['truncated'], isFalse);
  });

  test(
    'Anthropic generic model session emits reasoning and tool call',
    () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'content': [
              {'type': 'thinking', 'thinking': 'reasoning'},
              {
                'type': 'tool_use',
                'id': 'generic-2',
                'name': 'calculate',
                'input': {'value': 3},
              },
            ],
            'stop_reason': 'tool_use',
          }),
          200,
        ),
      );
      final provider = Anthropic(_bot, skillToolClient: client);
      final session = provider.openModelSession(_modelRequest);
      addTearDown(session.close);

      final events = await session.start().toList();

      expect(events.whereType<ReasoningDelta>().single.text, 'reasoning');
      expect(events.whereType<ToolCallRequested>().single.callId, 'generic-2');
      expect(
        events.whereType<ModelTurnCompleted>().single.stopReason,
        'tool_use',
      );
    },
  );

  test('provider-safe aliases round-trip canonical MCP Tool names', () async {
    Map<String, Object?>? sentPayload;
    final client = MockClient((request) async {
      sentPayload = (jsonDecode(request.body) as Map<Object?, Object?>).map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final tools = sentPayload!['tools']! as List<Object?>;
      final function =
          (tools.single as Map<Object?, Object?>)['function']!
              as Map<Object?, Object?>;
      final wireName = function['name']! as String;
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': null,
                'tool_calls': [
                  {
                    'id': 'mcp-call-1',
                    'type': 'function',
                    'function': {'name': wireName, 'arguments': '{}'},
                  },
                ],
              },
              'finish_reason': 'tool_calls',
            },
          ],
        }),
        200,
      );
    });
    final provider = OpenAI(_bot, skillToolClient: client);
    final request = ModelRequest(
      messages: [ChatMessage(role: 'user', content: 'Search')],
      tools: [
        ToolDefinition(
          name: 'mcp.docs.search',
          description: 'Search documents.',
          inputSchema: const {'type': 'object'},
          source: ToolSource.mcp,
          riskLevel: ToolRiskLevel.readOnly,
          capabilities: const {ToolCapability.network},
        ),
      ],
    );
    final session = provider.openModelSession(request);
    addTearDown(session.close);

    final events = await session.start().toList();
    final tools = sentPayload!['tools']! as List<Object?>;
    final function =
        (tools.single as Map<Object?, Object?>)['function']!
            as Map<Object?, Object?>;

    expect(function['name'], isNot('mcp.docs.search'));
    expect(function['name'], matches(RegExp(r'^[A-Za-z0-9_-]{1,64}$')));
    expect(
      events.whereType<ToolCallRequested>().single.name,
      'mcp.docs.search',
    );
  });
}

final _bot = Bot(
  id: 'bot-1',
  name: 'Bot',
  avatar: '',
  provider: 'test',
  baseURL: 'https://example.test/v1/',
  apiKey: 'secret',
  apiType: Bot.apiTypeOpenAI,
  model: 'test-model',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

final _firstPartyBot = Bot(
  id: 'bot-openai',
  name: 'OpenAI',
  avatar: '',
  provider: 'OpenAI',
  baseURL: 'https://example.test/v1/',
  apiKey: 'secret',
  apiType: Bot.apiTypeOpenAI,
  model: 'gpt-5.6-sol',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

final _request = SkillToolSessionRequest(
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
);

final _modelRequest = ModelRequest(
  messages: [ChatMessage(role: 'user', content: 'Calculate')],
  options: const ModelGenerationOptions(allowParallelToolCalls: true),
  tools: [
    ToolDefinition(
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
    ),
  ],
);
