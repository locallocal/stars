import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stars/data/services/ai/anthropic.dart';
import 'package:stars/data/services/ai/moonshot.dart';
import 'package:stars/data/services/ai/openai.dart';
import 'package:stars/data/services/ai/provider_conversation_turn_router.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/models/turn_disposition.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/conversation_turn_router.dart';

import '../../../support/foreground_turn_fixtures.dart';

void main() {
  final input = foregroundInput();
  TurnRoutingRequest request({AgentCancellationToken? cancellation}) =>
      TurnRoutingRequest(
        cancellation: cancellation,
        bot: input.bot,
        userMessage: input.userMessage,
        language: input.language,
        messages: [
          ChatMessage(
            role: 'user',
            content: 'hello',
            reasoning: 'private thought',
          ),
        ],
      );

  test(
    'one contextual routing call generates an untemplated acknowledgement',
    () async {
      const draft = '我来把这份报告排成 HTML，做好后在这里告诉你。';
      const userText = '把刚才那份 RustFS 报告转成好看的 HTML';
      final provider = ForegroundProvider(
        input.bot,
        events:
            () => Stream.fromIterable([
              TextDelta(
                routeFrames('backgroundTask', [foregroundPlan(draft: draft)]),
              ),
              const ModelTurnCompleted(),
            ]),
      );
      final providers = ForegroundProviders((_) => provider);
      final events =
          await ProviderConversationTurnRouter(providers: providers)
              .route(
                TurnRoutingRequest(
                  bot: input.bot,
                  userMessage: input.userMessage,
                  language: input.language,
                  messages: [
                    ChatMessage(role: 'assistant', content: 'RustFS 调研报告已保存。'),
                    ChatMessage(role: 'user', content: userText),
                  ],
                ),
              )
              .toList();
      final plan =
          events.whereType<TurnDispositionCompleted>().single.disposition
              as BackgroundTaskRequest;
      expect(plan.acknowledgementDraft, draft);
      expect(providers.conversationScopes, [input.userMessage.chatId]);
      final session = provider.sessions.single;
      expect(session.starts, 1);
      expect(session.request.tools, isEmpty);
      expect(session.request.messages[0].content, 'RustFS 调研报告已保存。');
      expect(session.request.messages[1].content, userText);
      final instruction = session.request.messages.last.content;
      expect(instruction, contains('conversation context'));
      expect(instruction, contains('let them know here when it is finished'));
      expect(instruction, isNot(contains('{title}')));
      expect(instruction, isNot(contains('需要一些时间，已经记录')));
      expect(session.closed, isTrue);
    },
  );

  test('foreground cancellation closes a stalled provider session', () async {
    final stream = StreamController<ModelEvent>();
    final started = Completer<void>();
    final token = AgentCancellationToken();
    final provider = ForegroundProvider(
      input.bot,
      events: () {
        started.complete();
        return stream.stream;
      },
    );
    final router = ProviderConversationTurnRouter(
      providers: ForegroundProviders((_) => provider),
    );
    final result = router.route(request(cancellation: token)).toList();
    await started.future;
    token.cancel();
    final events = await result.timeout(const Duration(seconds: 1));
    expect(
      events.whereType<TurnRoutingFailed>().single.reason,
      TurnRoutingFailure.cancelled,
    );
    expect(events.whereType<TurnDispositionCompleted>(), isEmpty);
    expect(provider.sessions.single.closed, isTrue);
    expect(provider.sessions.single.cancellations, 1);
    await stream.close();
  });

  test(
    'one tool-free call; direct frames stream before the Provider terminal',
    () async {
      final stream = StreamController<ModelEvent>();
      final provider =
          ForegroundProvider(input.bot, events: () => stream.stream)
            ..setWebSearch(true)
            ..setDeepThinking(true);
      final router = ProviderConversationTurnRouter(
        providers: ForegroundProviders((_) => provider),
      );
      final events = <TurnRoutingEvent>[];
      final delta = Completer<void>();
      final result = router.route(request()).forEach((event) {
        events.add(event);
        if (event is DirectReplyDelta) delta.complete();
      });
      stream.add(const ReasoningDelta('must not be displayed'));
      stream.add(const TextDelta('{"kind":"directReply"}\n{"text":"hello"}\n'));
      await delta.future;
      expect(events.whereType<TurnDispositionCompleted>(), isEmpty);
      stream.add(const TextDelta('{"done":true}'));
      stream.add(
        const UsageReported(ModelTokenUsage(inputTokens: 4, outputTokens: 8)),
      );
      stream.add(const ModelTurnCompleted(stopReason: 'stop'));
      await stream.close();
      await result;
      final session = provider.sessions.single;
      expect(session.starts, 1);
      expect(session.closed, isTrue);
      expect(session.request.tools, isEmpty);
      expect(session.request.options.webSearch, isFalse);
      expect(session.request.options.deepThinking, isFalse);
      expect(session.request.options.allowParallelToolCalls, isFalse);
      expect(
        session.request.messages.every((message) => message.reasoning.isEmpty),
        isTrue,
      );
      expect(provider.webSearch, isFalse);
      expect(provider.deepThinking, isFalse);
      expect(events.whereType<TurnRoutingCallStarted>().length, 1);
      expect(
        events.whereType<TurnDispositionCompleted>().single.disposition,
        isA<DirectReply>(),
      );
      expect(events.whereType<TurnRoutingUsage>().single.usage.inputTokens, 4);
    },
  );

  test(
    'buffered legacy Provider publishes only after complete validation',
    () async {
      final release = Completer<void>();
      final hasText = Completer<void>();
      final provider = ForegroundProvider(
        input.bot,
        mode: ForegroundRoutingTransport.bufferedText,
        generate: (provider) async {
          provider.onResponse(
            routeFrames('directReply', [
              {'text': 'buffered'},
            ]),
          );
          hasText.complete();
          await release.future;
          provider.onComplete!();
        },
      );
      final router = ProviderConversationTurnRouter(
        providers: ForegroundProviders((_) => provider),
      );
      final events = <TurnRoutingEvent>[];
      final done = router.route(request()).forEach(events.add);
      await hasText.future;
      expect(events.whereType<DirectReplyDelta>(), isEmpty);
      release.complete();
      await done;
      expect(provider.legacyCalls, 1);
      expect(provider.sessions, isEmpty);
      expect(events.whereType<DirectReplyDelta>().single.text, 'buffered');
    },
  );

  test('malformed buffered text exposes no kind or draft', () async {
    final provider = ForegroundProvider(
      input.bot,
      mode: ForegroundRoutingTransport.bufferedText,
      generate: (p) async {
        p.onResponse(
          routeFrames('directReply', [
            {'text': 'hidden draft'},
          ], done: false),
        );
        p.onComplete!();
      },
    );
    final events =
        await ProviderConversationTurnRouter(
          providers: ForegroundProviders((_) => provider),
        ).route(request()).toList();
    expect(events.whereType<TurnDispositionStarted>(), isEmpty);
    expect(events.whereType<DirectReplyDelta>(), isEmpty);
    expect(
      events.whereType<TurnRoutingFailed>().single.reason,
      TurnRoutingFailure.invalidProtocol,
    );
  });

  final cases = <String, (List<ModelEvent>, TurnRoutingFailure)>{
    'unknown kind': (
      [
        const TextDelta('{"kind":"unknown"}\n{"text":"draft"}\n'),
        const ModelTurnCompleted(),
      ],
      TurnRoutingFailure.invalidProtocol,
    ),
    'truncated transport': (
      [
        TextDelta(
          routeFrames('directReply', [
            {'text': 'partial'},
          ]),
        ),
      ],
      TurnRoutingFailure.incompleteResponse,
    ),
    'output token limit': (
      [
        TextDelta(routeFrames('backgroundTask', [foregroundPlan()])),
        const ModelTurnCompleted(stopReason: 'length'),
      ],
      TurnRoutingFailure.incompleteResponse,
    ),
    'tool request': (
      [const ToolCallStarted(callId: 'c', name: 'read_file')],
      TurnRoutingFailure.forbiddenTool,
    ),
    'tool arguments': (
      [const ToolCallArgumentsDelta(callId: 'c', argumentsDelta: '{}')],
      TurnRoutingFailure.forbiddenTool,
    ),
    'tool result request': (
      [ToolCallRequested(callId: 'c', name: 'read_file', arguments: {})],
      TurnRoutingFailure.forbiddenTool,
    ),
    'provider error after text': (
      [
        const TextDelta('{"kind":"directReply"}\n{"text":"partial"}\n'),
        const ModelTurnFailed(error: 'api_key=private'),
      ],
      TurnRoutingFailure.providerFailed,
    ),
    'cancelled': (
      [const ModelTurnFailed(error: 'cancelled', code: 'cancelled')],
      TurnRoutingFailure.cancelled,
    ),
    'text after terminal': (
      [const ModelTurnCompleted(), const TextDelta('late')],
      TurnRoutingFailure.invalidProtocol,
    ),
    'duplicate terminal': (
      [const ModelTurnCompleted(), const ModelTurnCompleted()],
      TurnRoutingFailure.incompleteResponse,
    ),
  };
  for (final entry in cases.entries) {
    test('${entry.key} is recoverable and never completes a plan', () async {
      final provider = ForegroundProvider(
        input.bot,
        events: () => Stream.fromIterable(entry.value.$1),
      );
      final events =
          await ProviderConversationTurnRouter(
            providers: ForegroundProviders((_) => provider),
          ).route(request()).toList();
      expect(events.whereType<TurnDispositionCompleted>(), isEmpty);
      expect(
        events.whereType<TurnRoutingFailed>().single.reason,
        entry.value.$2,
      );
      expect(provider.sessions.single.closed, isTrue);
      expect(provider.sessions.single.cancellations, 1);
    });
  }

  test(
    'total timeout applies even while a Provider keeps sending reasoning',
    () async {
      final stream = StreamController<ModelEvent>();
      final timer = Timer.periodic(
        const Duration(milliseconds: 2),
        (_) => stream.add(const ReasoningDelta('still thinking')),
      );
      final provider = ForegroundProvider(
        input.bot,
        events: () => stream.stream,
      );
      try {
        final events =
            await ProviderConversationTurnRouter(
              providers: ForegroundProviders((_) => provider),
              timeout: const Duration(milliseconds: 25),
            ).route(request()).toList();
        expect(
          events.whereType<TurnRoutingFailed>().single.reason,
          TurnRoutingFailure.timedOut,
        );
        expect(provider.sessions.single.closed, isTrue);
      } finally {
        timer.cancel();
        await stream.close();
      }
    },
  );

  test(
    'unaudited Provider is rejected without making a model request',
    () async {
      final provider = ForegroundProvider(
        input.bot,
        mode: ForegroundRoutingTransport.unavailable,
      );
      final events =
          await ProviderConversationTurnRouter(
            providers: ForegroundProviders((_) => provider),
          ).route(request()).toList();
      expect(events.whereType<TurnRoutingCallStarted>(), isEmpty);
      expect(
        events.whereType<TurnRoutingFailed>().single.reason,
        TurnRoutingFailure.unsupportedProvider,
      );
      expect(provider.sessions, isEmpty);
      expect(provider.legacyCalls, 0);
    },
  );

  for (final model in ['moonshot-v1-128k', 'kimi-k2.6', 'kimi-k3']) {
    for (final kind in TurnDispositionKind.values) {
      test(
        'Moonshot $model routes ${kind.name} through one tool-free call',
        () async {
          final bot = foregroundBot(
            apiType: 'moonshot',
            provider: 'moonshot',
            model: model,
          );
          final body = routeFrames(kind.name, switch (kind) {
            TurnDispositionKind.directReply => [
              {'text': 'Hello.'},
            ],
            TurnDispositionKind.backgroundTask => [foregroundPlan()],
            TurnDispositionKind.taskStatusRequest => [
              {'taskId': null},
            ],
          });
          final requests = <Map<String, dynamic>>[];
          final client = MockClient((request) async {
            expect(request.url.path, endsWith('/chat/completions'));
            requests.add(jsonDecode(request.body) as Map<String, dynamic>);
            return http.Response(
              [
                'data: ${jsonEncode({
                  'choices': [
                    {
                      'delta': {'content': body, 'reasoning_content': 'private provider reasoning'},
                      'finish_reason': 'stop',
                    },
                  ],
                  'usage': {'prompt_tokens': 5, 'completion_tokens': 7},
                })}',
                'data: [DONE]',
                '',
              ].join('\n\n'),
              200,
              headers: {'content-type': 'text/event-stream; charset=utf-8'},
            );
          });
          addTearDown(client.close);
          final provider =
              Moonshot(bot, client: client)
                ..setWebSearch(true)
                ..setDeepThinking(true);
          final events =
              await ProviderConversationTurnRouter(
                    providers: ForegroundProviders((_) => provider),
                  )
                  .route(
                    TurnRoutingRequest(
                      bot: bot,
                      userMessage: input.userMessage,
                      language: input.language,
                      messages: request().messages,
                    ),
                  )
                  .toList();

          expect(
            events.whereType<TurnRoutingFailed>().map((event) => event.reason),
            isEmpty,
          );
          expect(
            events
                .whereType<TurnRoutingCallStarted>()
                .single
                .providerSupportsAgentLoop,
            isTrue,
          );
          expect(
            events
                .whereType<TurnDispositionCompleted>()
                .single
                .disposition
                .kind,
            kind,
          );
          expect(
            events
                .whereType<DirectReplyDelta>()
                .map((event) => event.text)
                .join(),
            kind == TurnDispositionKind.directReply ? 'Hello.' : '',
          );
          expect(
            events.whereType<TurnRoutingUsage>().single.usage.outputTokens,
            7,
          );
          expect(requests, hasLength(1));
          final sent = requests.single;
          expect(sent['model'], model);
          expect(sent['stream'], isTrue);
          for (final key in [
            'tools',
            'tool_choice',
            'parallel_tool_calls',
            'web_search_options',
          ]) {
            expect(sent, isNot(contains(key)), reason: key);
          }
          expect(
            jsonEncode(sent['messages']),
            isNot(contains('private thought')),
          );
          if (model == 'kimi-k3') {
            expect(sent['reasoning_effort'], 'low');
          } else if (model == 'kimi-k2.6') {
            expect(sent['thinking'], {'type': 'disabled'});
          } else {
            expect(sent, isNot(contains('thinking')));
            expect(sent, isNot(contains('reasoning_effort')));
          }
        },
      );
    }
  }

  for (final vendor in ['openai', 'anthropic']) {
    test(
      '$vendor actual transport omits all tool/native execution configuration',
      () async {
        final body = routeFrames('directReply', [
          {'text': 'Hello.'},
        ]);
        final requests = <Map<String, dynamic>>[];
        final client = MockClient((request) async {
          requests.add(jsonDecode(request.body) as Map<String, dynamic>);
          if (vendor == 'anthropic') {
            return http.Response(
              jsonEncode({
                'content': [
                  {'type': 'text', 'text': body},
                ],
                'stop_reason': 'end_turn',
              }),
              200,
            );
          }
          return http.Response(
            [
              'data: ${jsonEncode({
                'choices': [
                  {
                    'delta': {'content': body},
                    'finish_reason': null,
                  },
                ],
              })}',
              'data: ${jsonEncode({
                'choices': [
                  {'delta': <String, Object?>{}, 'finish_reason': 'stop'},
                ],
              })}',
              'data: [DONE]',
              '',
            ].join('\n\n'),
            200,
            headers: {'content-type': 'text/event-stream'},
          );
        });
        addTearDown(client.close);
        final AiProvider provider =
            vendor == 'anthropic'
                ? Anthropic(input.bot, skillToolClient: client)
                : OpenAI(input.bot, skillToolClient: client);
        provider.setWebSearch(true);
        provider.setDeepThinking(true);
        final events =
            await ProviderConversationTurnRouter(
              providers: ForegroundProviders((_) => provider),
            ).route(request()).toList();
        expect(
          events.whereType<TurnRoutingFailed>(),
          isEmpty,
          reason: events
              .whereType<TurnRoutingFailed>()
              .map((e) => e.reason.name)
              .join(', '),
        );
        expect(
          events.whereType<TurnDispositionCompleted>().single.disposition,
          isA<DirectReply>(),
        );
        expect(requests.length, 1);
        for (final key in [
          'tools',
          'tool_choice',
          'web_search_options',
          'thinking',
          'reasoning_effort',
        ]) {
          expect(requests.single, isNot(contains(key)), reason: key);
        }
      },
    );
  }

  test(
    'Responses transport is also one call with no native tool configuration',
    () async {
      final bot = foregroundBot(provider: 'openai', model: 'gpt-5.6-sol');
      final requests = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        requests.add(jsonDecode(request.body) as Map<String, dynamic>);
        expect(request.url.path, endsWith('/responses'));
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
                    'text': routeFrames('directReply', [
                      {'text': 'Hello'},
                    ]),
                  },
                ],
              },
            ],
          }),
          200,
        );
      });
      addTearDown(client.close);
      final provider = OpenAI(bot, skillToolClient: client);
      final events =
          await ProviderConversationTurnRouter(
                providers: ForegroundProviders((_) => provider),
              )
              .route(
                TurnRoutingRequest(
                  bot: bot,
                  userMessage: input.userMessage,
                  language: 'en',
                  messages: request().messages,
                ),
              )
              .toList();
      expect(events.whereType<TurnRoutingFailed>(), isEmpty);
      expect(events.whereType<TurnDispositionCompleted>(), hasLength(1));
      expect(requests, hasLength(1));
      expect(requests.single.containsKey('tools'), isFalse);
      expect(requests.single.containsKey('include'), isFalse);
    },
  );

  for (final model in ['gpt-4o-search-preview', 'o3-deep-research']) {
    test('native search model $model is refused before HTTP', () async {
      final bot = foregroundBot(model: model);
      final provider = OpenAI(
        bot,
        skillToolClient: MockClient(
          (_) async => throw StateError('No HTTP expected'),
        ),
      );
      final events =
          await ProviderConversationTurnRouter(
            providers: ForegroundProviders((_) => provider),
          ).route(request()).toList();
      expect(events.whereType<TurnRoutingCallStarted>(), isEmpty);
      expect(
        events.whereType<TurnRoutingFailed>().single.reason,
        TurnRoutingFailure.unsupportedProvider,
      );
    });
  }

  test(
    'unexpected native result cannot become a direct answer or task',
    () async {
      final native = ProviderNativeToolResult(
        definition: ToolDefinition(
          name: 'native_search',
          description: 'search',
          inputSchema: const {'type': 'object'},
          source: ToolSource.providerNative,
          riskLevel: ToolRiskLevel.readOnly,
        ),
        call: ToolCallRequest(callId: 'native-1', name: 'native_search'),
        result: ToolResult(
          callId: 'native-1',
          name: 'native_search',
          content: 'result',
          source: ToolSource.providerNative,
        ),
        reportedAt: foregroundTime,
      );
      final provider = ForegroundProvider(
        input.bot,
        events: () => Stream.fromIterable([native]),
      );
      final events =
          await ProviderConversationTurnRouter(
            providers: ForegroundProviders((_) => provider),
          ).route(request()).toList();
      expect(
        events.whereType<TurnRoutingFailed>().single.reason,
        TurnRoutingFailure.forbiddenTool,
      );
      expect(events.whereType<TurnDispositionCompleted>(), isEmpty);
    },
  );

  test(
    'routing model options reject executable tools before opening a session',
    () {
      for (final options in [
        const ModelGenerationOptions(foregroundRouting: true, webSearch: true),
        const ModelGenerationOptions(
          foregroundRouting: true,
          deepThinking: true,
        ),
        const ModelGenerationOptions(
          foregroundRouting: true,
          allowParallelToolCalls: true,
        ),
      ]) {
        expect(
          () => ModelRequest(messages: [], options: options),
          throwsArgumentError,
        );
      }
      expect(
        () => ModelRequest(
          messages: [],
          tools: [ForegroundTool().definition],
          options: const ModelGenerationOptions(foregroundRouting: true),
        ),
        throwsArgumentError,
      );
    },
  );
}
