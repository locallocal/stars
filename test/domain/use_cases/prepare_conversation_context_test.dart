import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/conversation_memory_repository.dart';
import 'package:stars/domain/use_cases/context_budgeter.dart';
import 'package:stars/domain/use_cases/prepare_conversation_context.dart';

void main() {
  test(
    'keeps whole recent turns and registers bounded history lookup',
    () async {
      final memory = _MemoryRepository(summary: _summary());
      final useCase = PrepareConversationContext(
        memoryRepository: memory,
        aiProviderRepository: _AiRepository(contextWindow: 1800, output: 200),
        budgeter: const ContextBudgeter(
          policy: ContextBudgetPolicy(
            protocolOverheadTokens: 0,
            minimumSafetyMarginTokens: 100,
            safetyMarginRatio: 0,
            minimumRecentTurns: 2,
          ),
        ),
      );
      final history = <Message>[];
      for (var index = 0; index < 6; index++) {
        history
          ..add(
            _message(
              index,
              true,
              'user ${List.filled(25, 'question').join(' ')}',
            ),
          )
          ..add(
            _message(
              index,
              false,
              'assistant ${List.filled(25, 'response').join(' ')}',
            ),
          );
      }

      final result = await useCase(
        bot: _bot(),
        systemPrompt: 'Follow system rules.',
        history: history,
        userMessage: _current('What was the exact earlier decision?'),
        currentUserId: 'user_1',
        providerSupportsHistoryLookup: true,
      );

      expect(result.report.includedTurnIds, isNotEmpty);
      expect(result.report.omittedTurnIds, isNotEmpty);
      expect(
        result.report.includedTurnIds.length +
            result.report.omittedTurnIds.length,
        6,
      );
      expect(result.report.historyLookupAvailable, isTrue);
      expect(result.report.historyLookupReserveTokens, greaterThan(0));
      expect(
        result.messages.last.content,
        'What was the exact earlier decision?',
      );
      expect(
        result.messages.map((message) => message.content),
        contains(predicate<String>((text) => text.contains('rolling_summary'))),
      );
    },
  );

  test(
    'reports unsupported history lookup instead of parsing pseudo calls',
    () async {
      final useCase = PrepareConversationContext(
        memoryRepository: _MemoryRepository(summary: _summary()),
        aiProviderRepository: _AiRepository(contextWindow: 4096, output: 512),
      );

      final result = await useCase(
        bot: _bot(),
        systemPrompt: '',
        history: const [],
        userMessage: _current('continue'),
        currentUserId: 'user_1',
        providerSupportsHistoryLookup: false,
      );

      expect(result.report.historyLookupAvailable, isFalse);
      expect(result.report.warnings, contains('history_lookup_unavailable'));
    },
  );

  test('omits failed turns whose assistant response is empty', () async {
    final useCase = PrepareConversationContext(
      memoryRepository: _MemoryRepository(),
      aiProviderRepository: _AiRepository(contextWindow: 4096, output: 512),
    );

    final result = await useCase(
      bot: _bot(),
      systemPrompt: '',
      history: [
        _message(0, true, 'failed question'),
        _message(0, false, '', terminalOutcome: MessageTerminalOutcome.failed),
      ],
      userMessage: _current('retry question'),
      currentUserId: 'user_1',
      providerSupportsHistoryLookup: true,
    );

    expect(result.report.includedTurnIds, isNot(contains('turn_0')));
    expect(result.messages.map((message) => message.content), [
      'retry question',
    ]);
    expect(
      result.messages.every(
        (message) =>
            message.content.trim().isNotEmpty ||
            message.images.isNotEmpty ||
            message.files.isNotEmpty,
      ),
      isTrue,
    );
  });

  test('preserves assistant reasoning in prepared history', () async {
    final useCase = PrepareConversationContext(
      memoryRepository: _MemoryRepository(),
      aiProviderRepository: _AiRepository(contextWindow: 4096, output: 512),
    );

    final result = await useCase(
      bot: _bot(),
      systemPrompt: '',
      history: [
        _message(0, true, 'question'),
        _message(0, false, 'answer', reasoning: 'preserved reasoning'),
      ],
      userMessage: _current('follow-up'),
      currentUserId: 'user_1',
      providerSupportsHistoryLookup: true,
    );

    final assistant = result.messages.singleWhere(
      (message) => message.role == 'assistant',
    );
    expect(assistant.reasoning, 'preserved reasoning');
  });

  test(
    'does not expose history lookup when its system Skill is disabled',
    () async {
      final useCase = PrepareConversationContext(
        memoryRepository: _MemoryRepository(summary: _summary()),
        aiProviderRepository: _AiRepository(contextWindow: 4096, output: 512),
      );

      final result = await useCase(
        bot: _bot(),
        systemPrompt: '',
        history: const [],
        userMessage: _current('continue'),
        currentUserId: 'user_1',
        providerSupportsHistoryLookup: true,
        conversationHistorySkillEnabled: false,
      );

      expect(result.report.historyLookupAvailable, isFalse);
      expect(result.report.warnings, contains('history_lookup_unavailable'));
    },
  );

  test('does not silently truncate P0 content', () async {
    final useCase = PrepareConversationContext(
      memoryRepository: _MemoryRepository(),
      aiProviderRepository: _AiRepository(contextWindow: 1000, output: 400),
      budgeter: const ContextBudgeter(
        policy: ContextBudgetPolicy(
          protocolOverheadTokens: 0,
          minimumSafetyMarginTokens: 100,
          safetyMarginRatio: 0,
        ),
      ),
    );

    expect(
      () => useCase(
        bot: _bot(),
        systemPrompt: List.filled(1200, 's').join(),
        history: const [],
        userMessage: _current(List.filled(1200, 'u').join()),
        currentUserId: 'user_1',
        providerSupportsHistoryLookup: true,
      ),
      throwsA(isA<ContextBudgetException>()),
    );
  });

  test('keeps Kimi K3 one-million-token context usable', () async {
    final useCase = PrepareConversationContext(
      memoryRepository: _MemoryRepository(),
      aiProviderRepository: _AiRepository(
        contextWindow: 1048576,
        output: 1048576,
      ),
    );

    final result = await useCase(
      bot: _bot(),
      systemPrompt: '',
      history: const [],
      userMessage: _current('hello'),
      currentUserId: 'user_1',
      providerSupportsHistoryLookup: true,
    );

    expect(result.report.contextWindowTokens, 1048576);
    expect(result.report.inputBudgetTokens, 991796);
    expect(
      result.report.warnings,
      contains('max_output_reservation_defaulted'),
    );
  });

  test('recalls relevant Chinese Memory and rejects unrelated items', () async {
    final source = _message(0, true, '项目资料');
    final now = DateTime(2026, 8, 8);
    final useCase = PrepareConversationContext(
      memoryRepository: _MemoryRepository(
        items: [
          ConversationMemoryItem(
            id: 'relevant',
            chatId: 'chat_1',
            memoryKey: 'project.deadline',
            kind: ConversationMemoryKind.fact,
            content: '项目截止日期是九月十日',
            confidence: 0.9,
            importance: 0.8,
            sourceMessageIds: [source.messageId],
            createdAt: now,
            updatedAt: now,
          ),
          ConversationMemoryItem(
            id: 'unrelated',
            chatId: 'chat_1',
            memoryKey: 'lunch.preference',
            kind: ConversationMemoryKind.preference,
            content: '午餐喜欢吃面条',
            confidence: 1,
            importance: 1,
            sourceMessageIds: [source.messageId],
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
      aiProviderRepository: _AiRepository(contextWindow: 4096, output: 512),
    );

    final result = await useCase(
      bot: _bot(),
      systemPrompt: '',
      history: [source, _message(0, false, '收到')],
      userMessage: _current('项目截止日期是什么时候？'),
      currentUserId: 'user_1',
      providerSupportsHistoryLookup: true,
    );

    expect(result.report.includedMemoryIds, ['relevant']);
    final memory = result.messages.singleWhere(
      (message) => message.content.contains('<conversation_memory'),
    );
    expect(memory.content, contains('key="project.deadline"'));
    expect(memory.content, contains('confidence="0.9"'));
    expect(memory.content, contains('source_message_ids="message_0_u"'));
    expect(memory.content, isNot(contains('午餐喜欢吃面条')));
  });

  test(
    'does not recall an assistant fact without successful tool evidence',
    () async {
      final assistant = _message(0, false, '服务器状态是健康');
      final now = DateTime(2026, 8, 8);
      final useCase = PrepareConversationContext(
        memoryRepository: _MemoryRepository(
          items: [
            ConversationMemoryItem(
              id: 'assistant_fact',
              chatId: 'chat_1',
              memoryKey: 'server.health',
              kind: ConversationMemoryKind.fact,
              content: '服务器状态是健康',
              confidence: 0.9,
              sourceMessageIds: [assistant.messageId],
              createdAt: now,
              updatedAt: now,
            ),
          ],
        ),
        aiProviderRepository: _AiRepository(contextWindow: 4096, output: 512),
      );

      final result = await useCase(
        bot: _bot(),
        systemPrompt: '',
        history: [_message(0, true, '检查服务器'), assistant],
        userMessage: _current('服务器状态怎么样？'),
        currentUserId: 'user_1',
        providerSupportsHistoryLookup: true,
      );

      expect(result.report.includedMemoryIds, isEmpty);
    },
  );
}

Message _message(
  int turn,
  bool user,
  String content, {
  String reasoning = '',
  MessageTerminalOutcome terminalOutcome = MessageTerminalOutcome.completed,
}) => Message(
  messageId: 'message_${turn}_${user ? 'u' : 'a'}',
  turnId: 'turn_$turn',
  chatId: 'chat_1',
  botId: 'bot_1',
  senderId: user ? 'user_1' : 'bot_1',
  content: content,
  reasoning: reasoning,
  terminalOutcome: user ? null : terminalOutcome,
  timestamp: DateTime(2026, 8, 1).add(Duration(minutes: turn)),
);

Message _current(String content) => Message(
  messageId: 'current',
  turnId: 'current_turn',
  chatId: 'chat_1',
  botId: 'bot_1',
  senderId: 'user_1',
  content: content,
  timestamp: DateTime(2026, 8, 8),
);

Bot _bot() => Bot(
  id: 'bot_1',
  name: 'Bot',
  avatar: '',
  provider: 'Test',
  baseURL: '',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'model',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

ConversationSummaryDocument _summary() {
  final now = DateTime(2026, 8, 8);
  return ConversationSummaryDocument(
    metadata: ConversationSummaryMetadata(
      id: 'summary_1',
      chatId: 'chat_1',
      status: ConversationSummaryStatus.active,
      fileName: 'summary_1.md',
      contentDigest: 'digest',
      contentBytes: 10,
      sourceStartMessageId: 'message_0_u',
      sourceEndMessageId: 'message_1_a',
      sourceMessageIds: const ['message_0_u', 'message_1_a'],
      sourceDigest: 'sources',
      baseRevision: 0,
      createdAt: now,
      updatedAt: now,
    ),
    markdown: '# 会话摘要\n\n## 已确认决策\n\n- Use the desktop layout.',
  );
}

final class _MemoryRepository implements ConversationMemoryRepository {
  _MemoryRepository({this.summary, this.items = const []});

  final ConversationSummaryDocument? summary;
  final List<ConversationMemoryItem> items;

  @override
  Stream<String> get changes => const Stream.empty();

  @override
  Future<ConversationSummaryDocument?> getActiveSummary(String chatId) async =>
      summary;

  @override
  Future<List<ConversationMemoryItem>> getItems(String chatId) async => items;

  @override
  Future<ConversationMemoryState> getState(String chatId) async =>
      ConversationMemoryState(chatId: chatId, updatedAt: DateTime(2026));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _AiRepository implements AiProviderRepository {
  _AiRepository({required this.contextWindow, required this.output});

  final int contextWindow;
  final int output;

  @override
  Future<AiModelInfo?> getModelInfo(Bot bot) async => AiModelInfo(
    modelId: bot.model,
    providerId: bot.provider,
    inputModalities: const [InputModality.text],
    outputModalities: const [OutputModality.text],
    contextWindowTokens: contextWindow,
    maxOutputTokens: output,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
