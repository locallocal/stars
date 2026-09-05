import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stars/data/services/ai/anthropic.dart';
import 'package:stars/data/services/ai/openai.dart';
import 'package:stars/data/services/ai/skill_tool_sessions.dart';
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
          ToolResult(
            callId: 'generic-1',
            name: 'calculate',
            content: '4',
            invocationId: 'invocation-1',
            attemptId: 'attempt-1',
            evidenceId: 'evidence-1',
          ),
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
    expect(envelope['evidence_id'], 'evidence-1');
    expect(envelope['invocation_id'], 'invocation-1');
    expect(envelope['attempt_id'], 'attempt-1');
    expect(envelope['provider_call_id'], 'generic-1');
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

  test('OpenAI Chat returns the shared grounded answer DTO', () async {
    final requests = <Map<String, Object?>>[];
    final client = MockClient((request) async {
      requests.add(
        (jsonDecode(request.body) as Map<Object?, Object?>).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': requests.length == 1 ? 'draft' : _groundedJson,
              },
              'finish_reason': 'stop',
            },
          ],
        }),
        200,
      );
    });
    final session = OpenAI(
      _bot,
      skillToolClient: client,
    ).openModelSession(_modelRequest);
    addTearDown(session.close);

    await session.start().toList();
    final events =
        await session.synthesizeGroundedAnswer(_groundedRequest).toList();

    _expectGroundedProtocol(events);
    expect(requests.last, isNot(contains('tools')));
    final messages = requests.last['messages']! as List<Object?>;
    final prompt =
        (messages.last as Map<Object?, Object?>)['content']! as String;
    expect(prompt, contains(_evidenceId));
    expect(prompt, contains('required_claims'));
    expect(prompt, contains('calculation.result'));
    expect(prompt, contains('Do not emit a legacy evidence footer'));
  });

  test('OpenAI Responses returns the shared grounded answer DTO', () async {
    final requests = <Map<String, Object?>>[];
    final client = MockClient((request) async {
      requests.add(
        (jsonDecode(request.body) as Map<Object?, Object?>).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      return http.Response(
        jsonEncode({
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'role': 'assistant',
              'content': [
                {
                  'type': 'output_text',
                  'text': requests.length == 1 ? 'draft' : _groundedJson,
                },
              ],
            },
          ],
        }),
        200,
      );
    });
    final session = OpenAI(
      _firstPartyBot,
      skillToolClient: client,
    ).openModelSession(_modelRequest);
    addTearDown(session.close);

    await session.start().toList();
    final events =
        await session.synthesizeGroundedAnswer(_groundedRequest).toList();

    _expectGroundedProtocol(events);
    expect(requests.last, isNot(contains('tools')));
    expect(requests.last, isNot(contains('include')));
  });

  test('Anthropic returns the shared grounded answer DTO', () async {
    final requests = <Map<String, Object?>>[];
    final client = MockClient((request) async {
      requests.add(
        (jsonDecode(request.body) as Map<Object?, Object?>).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
      return http.Response(
        jsonEncode({
          'content': [
            {
              'type': 'text',
              'text': requests.length == 1 ? 'draft' : _groundedJson,
            },
          ],
          'stop_reason': 'end_turn',
        }),
        200,
      );
    });
    final session = Anthropic(
      _bot,
      skillToolClient: client,
    ).openModelSession(_modelRequest);
    addTearDown(session.close);

    await session.start().toList();
    final events =
        await session.synthesizeGroundedAnswer(_groundedRequest).toList();

    _expectGroundedProtocol(events);
    expect(requests.last, isNot(contains('tools')));
  });

  test('structured synthesis rejects invalid Provider JSON', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount += 1;
      return http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': requestCount == 1 ? 'draft' : '{not-json'},
              'finish_reason': 'stop',
            },
          ],
        }),
        200,
      );
    });
    final session = OpenAI(
      _bot,
      skillToolClient: client,
    ).openModelSession(_modelRequest);
    addTearDown(session.close);

    await session.start().toList();
    final events =
        await session.synthesizeGroundedAnswer(_groundedRequest).toList();

    expect(events.whereType<GroundedAnswerProduced>(), isEmpty);
    expect(
      events.whereType<ModelTurnFailed>().single.code,
      'invalid_grounded_json',
    );
    expect(events.whereType<TextDelta>(), isEmpty);
  });

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

  test(
    'unsupported Anthropic native search output stays unnormalized',
    () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'content': [
              {
                'type': 'server_tool_use',
                'id': 'server-tool-1',
                'name': 'web_search',
                'input': {'query': 'latest'},
              },
              {
                'type': 'web_search_tool_result',
                'tool_use_id': 'server-tool-1',
                'content': [
                  {
                    'type': 'web_search_result',
                    'url': 'https://example.com/result',
                  },
                ],
              },
              {'type': 'text', 'text': 'Unverified search answer'},
            ],
            'stop_reason': 'end_turn',
          }),
          200,
        ),
      );
      final provider = Anthropic(_bot, skillToolClient: client);
      final session = provider.openModelSession(
        ModelRequest(
          messages: [ChatMessage(role: 'user', content: 'Search')],
          options: const ModelGenerationOptions(webSearch: true),
        ),
      );
      addTearDown(session.close);

      final events = await session.start().toList();

      expect(provider.capabilities.supportsNativeToolEvidence, isFalse);
      expect(events.whereType<ProviderNativeToolResult>(), isEmpty);
      expect(events.whereType<ToolCallRequested>(), isEmpty);
      expect(
        events.whereType<TextDelta>().single.text,
        'Unverified search answer',
      );
    },
  );

  test(
    '404 fails once with no trusted text or sensitive response data',
    () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests += 1;
        return http.Response(
          '{"error":{"message":"Authorization: Bearer sk-secret; Cookie=x"}}',
          404,
          headers: {'x-request-id': 'req-private-value'},
        );
      });
      final provider = OpenAI(_bot, skillToolClient: client);
      final session = provider.openModelSession(_modelRequest);
      addTearDown(session.close);

      final events = await session.start().toList();
      final event = events.whereType<ModelTurnFailed>().single;
      final failure = event.providerFailure!;

      expect(requests, 1);
      expect(events.whereType<TextDelta>(), isEmpty);
      expect(event.error, 'provider_endpoint_not_found');
      expect(failure.kind, ProviderFailureKind.notFound);
      expect(failure.httpStatus, 404);
      expect(failure.endpointKind, ProviderEndpointKind.chatCompletions);
      expect(failure.retryable, isFalse);
      expect(failure.requestTraceId, startsWith('trace_'));
      expect('$event ${failure.toString()}', isNot(contains('sk-secret')));
      expect('$event ${failure.toString()}', isNot(contains('Cookie=x')));
    },
  );

  test('401 and 403 are classified without retrying', () async {
    for (final (status, kind) in const [
      (401, ProviderFailureKind.authentication),
      (403, ProviderFailureKind.authorization),
    ]) {
      var requests = 0;
      final client = MockClient((request) async {
        requests += 1;
        return http.Response('sensitive provider body', status);
      });
      final session = OpenAI(
        _bot,
        skillToolClient: client,
      ).openModelSession(_modelRequest);

      final events = await session.start().toList();
      session.close();

      expect(requests, 1, reason: 'HTTP $status');
      expect(
        events.whereType<ModelTurnFailed>().single.providerFailure?.kind,
        kind,
        reason: 'HTTP $status',
      );
    }
  });

  test('408, 429, and 5xx retry as distinct requests in one session', () async {
    for (final (status, kind) in const [
      (408, ProviderFailureKind.timeout),
      (429, ProviderFailureKind.rateLimited),
      (503, ProviderFailureKind.server),
    ]) {
      var requests = 0;
      final client = MockClient((request) async {
        requests += 1;
        return http.Response('sensitive provider body', status);
      });
      final session = OpenAI(
        _bot,
        skillToolClient: client,
      ).openModelSession(_modelRequest);

      final events = await session.start().toList();
      session.close();

      expect(requests, 3, reason: 'HTTP $status');
      final event = events.whereType<ModelTurnFailed>().single;
      expect(event.providerFailure?.kind, kind, reason: 'HTTP $status');
      expect(event.providerFailure?.retryable, isTrue, reason: 'HTTP $status');
      expect(event.error, isNot(contains('sensitive provider body')));
    }
  });

  test(
    'quota exhaustion is distinguished from retryable rate limiting',
    () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests += 1;
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'insufficient_quota',
              'message': 'account detail that must not be exposed',
            },
          }),
          429,
        );
      });
      final session = OpenAI(
        _bot,
        skillToolClient: client,
      ).openModelSession(_modelRequest);
      addTearDown(session.close);

      final events = await session.start().toList();
      final event = events.whereType<ModelTurnFailed>().single;

      expect(requests, 1);
      expect(event.error, 'provider_quota_exceeded');
      expect(event.providerFailure?.kind, ProviderFailureKind.quotaExceeded);
      expect(event.providerFailure?.retryable, isFalse);
      expect(event.error, isNot(contains('account detail')));
    },
  );

  test(
    'a retryable failure can recover without publishing failure text',
    () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests += 1;
        if (requests == 1) return http.Response('try later', 429);
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'recovered'},
                'finish_reason': 'stop',
              },
            ],
          }),
          200,
        );
      });
      final session = OpenAI(
        _bot,
        skillToolClient: client,
      ).openModelSession(_modelRequest);
      addTearDown(session.close);

      final events = await session.start().toList();

      expect(requests, 2);
      expect(events.whereType<ModelTurnFailed>(), isEmpty);
      expect(events.whereType<TextDelta>().single.text, 'recovered');
    },
  );

  test('transport timeout becomes a structured Provider failure', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests += 1;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return http.Response('{}', 200);
    });
    final session = OpenAiSkillToolSession(
      bot: _bot,
      request: _request,
      formattedMessages: const [],
      uri: Uri.parse('https://example.test/v1/chat/completions'),
      headers: const {'Authorization': 'Bearer secret'},
      client: client,
      closeClient: false,
      decodeResponse: jsonDecode,
      requestTimeout: const Duration(milliseconds: 1),
    );
    addTearDown(session.close);

    await expectLater(
      session.start(),
      throwsA(
        isA<ProviderFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              ProviderFailureKind.timeout,
            )
            .having((failure) => failure.retryable, 'retryable', isTrue),
      ),
    );
    expect(requests, 3);
  });
}

void _expectGroundedProtocol(List<ModelEvent> events) {
  final candidate = events.whereType<GroundedAnswerProduced>().single.candidate;
  expect(events.whereType<TextDelta>(), isEmpty);
  expect(candidate.schemaVersion, 1);
  expect(candidate.claims.single.claimId, 'claim-1');
  expect(candidate.claims.single.kind, ClaimKind.externalFact);
  expect(candidate.claims.single.evidenceIds, [_evidenceId]);
  expect(candidate.renderedText, 'The answer is four.');
  expect(jsonEncode(candidate.toJson()), isNot(contains('provider')));
}

const _evidenceId = 'run-1:invocation:1:attempt:1:evidence';
const _groundedJson =
    '{"schema_version":1,"claims":[{"claim_id":"claim-1",'
    '"text":"The answer is four.","kind":"external_fact",'
    '"evidence_ids":["$_evidenceId"]}],"non_factual_text":""}';

final _groundedRequest = GroundedAnswerSynthesisRequest(
  draftText: 'draft',
  evidence: [
    GroundedEvidenceReference(
      evidenceId: _evidenceId,
      providerCallId: 'provider-call-1',
      toolName: 'calculate',
      isError: false,
    ),
  ],
  requiredClaims: [
    GroundedClaimSynthesisRequirement(
      claimId: 'claim-1',
      claimKind: ClaimKind.externalFact,
      subject: 'calculation:basic-arithmetic',
      scope: const {'expression': '2+2'},
      requiredFactNames: const {'calculation.result'},
      requiredFactValues: const {'calculation.result': 4},
      toolName: 'calculate',
    ),
  ],
);

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
