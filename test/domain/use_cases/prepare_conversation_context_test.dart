import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/conversation_memory_repository.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
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

  test(
    'isolates unsuccessful and partial assistant output by default',
    () async {
      final useCase = PrepareConversationContext(
        memoryRepository: _MemoryRepository(),
        aiProviderRepository: _AiRepository(contextWindow: 4096, output: 512),
      );
      final history = [
        _message(0, true, 'failed question'),
        _message(
          0,
          false,
          'failed secret',
          runId: 'run-failed',
          terminalOutcome: MessageTerminalOutcome.failed,
        ),
        _message(1, true, 'cancelled question'),
        _message(
          1,
          false,
          'cancelled secret',
          runId: 'run-cancelled',
          terminalOutcome: MessageTerminalOutcome.cancelled,
        ),
        _message(2, true, 'empty response question'),
        _message(
          2,
          false,
          'empty response secret',
          runId: 'run-empty',
          terminalOutcome: MessageTerminalOutcome.emptyResponse,
        ),
        _message(3, true, 'partial question'),
        _message(
          3,
          false,
          'partial secret',
          runId: 'run-partial',
          hasPartialContent: true,
        ),
        _message(4, true, 'completed question'),
        _message(4, false, 'completed answer', runId: 'run-completed'),
      ];

      final result = await useCase(
        bot: _bot(),
        systemPrompt: '',
        history: history,
        userMessage: _current('follow-up'),
        currentUserId: 'user_1',
        providerSupportsHistoryLookup: true,
      );

      expect(result.report.includedTurnIds, ['turn_4']);
      expect(
        result.report.includedTurnIds,
        isNot(containsAll(['turn_0', 'turn_1', 'turn_2', 'turn_3'])),
      );
      final serialized = result.messages
          .map((message) => message.content)
          .join('\n');
      expect(serialized, isNot(contains('failed secret')));
      expect(serialized, isNot(contains('cancelled secret')));
      expect(serialized, isNot(contains('empty response secret')));
      expect(serialized, isNot(contains('partial secret')));

      final assistant = result.messages.singleWhere(
        (message) => message.role == 'assistant',
      );
      expect(assistant.content, contains('<assistant_history_output'));
      expect(assistant.content, contains('run_id="run-completed"'));
      expect(assistant.content, contains('terminal="completed"'));
      expect(assistant.content, contains('trust="unverified"'));
      expect(
        assistant.content,
        contains('<content>completed answer</content>'),
      );
    },
  );

  test('wraps explicitly continued partial output as untrusted data', () async {
    final useCase = PrepareConversationContext(
      memoryRepository: _MemoryRepository(),
      aiProviderRepository: _AiRepository(contextWindow: 4096, output: 512),
    );

    final result = await useCase(
      bot: _bot(),
      systemPrompt: '',
      history: [
        _message(0, true, 'continue the interrupted task'),
        _message(
          0,
          false,
          'partial <fact> & more',
          reasoning: 'discarded reasoning',
          runId: 'run-partial',
          terminalOutcome: MessageTerminalOutcome.failed,
          hasPartialContent: true,
          grounding: MessageGrounding(
            trustLevel: AnswerTrustLevel.failed,
            reasonCode: 'provider_failed',
          ),
          images: const ['unsafe-image'],
          files: const ['unsafe-file'],
        ),
      ],
      userMessage: _current('resume'),
      currentUserId: 'user_1',
      providerSupportsHistoryLookup: true,
      includeUntrustedPartialOutput: true,
    );

    expect(result.report.includedTurnIds, ['turn_0']);
    final assistant = result.messages.singleWhere(
      (message) => message.role == 'assistant',
    );
    expect(assistant.content, contains('<untrusted_partial_output'));
    expect(assistant.content, contains('run_id="run-partial"'));
    expect(assistant.content, contains('terminal="failed"'));
    expect(assistant.content, contains('trust="failed"'));
    expect(assistant.content, contains('reason_code="provider_failed"'));
    expect(
      assistant.content,
      contains('<content>partial &lt;fact&gt; &amp; more</content>'),
    );
    expect(assistant.content, isNot(contains('partial <fact>')));
    expect(assistant.reasoning, isEmpty);
    expect(assistant.images, isEmpty);
    expect(assistant.files, isEmpty);
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
            kind: ConversationMemoryKind.userAssertion,
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
    expect(memory.content, contains('kind="userAssertion"'));
    expect(memory.content, contains('confidence="0.9"'));
    expect(memory.content, contains('source_message_ids="message_0_u"'));
    expect(memory.content, isNot(contains('午餐喜欢吃面条')));
  });

  test(
    'does not recall a pinned assistant fact without verified claim evidence',
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
              state: ConversationMemoryItemState.pinned,
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

  test(
    'marks an expired current claim for fresh verification with provenance',
    () async {
      final observedAt = DateTime.utc(2026, 9, 5, 10);
      final validUntil = DateTime.utc(2026, 9, 5, 11);
      final evaluatedAt = DateTime.utc(2026, 9, 5, 12);
      final evidence = _currentStatusEvidence(
        observedAt: observedAt,
        validUntil: validUntil,
      );
      final assistant = _statusAssistant(evidence);
      final useCase = PrepareConversationContext(
        memoryRepository: _MemoryRepository(
          items: [
            ConversationMemoryItem(
              id: 'expired-health',
              chatId: 'chat_1',
              memoryKey: 'production.health',
              kind: ConversationMemoryKind.fact,
              content: 'Production is healthy.',
              confidence: 1,
              sourceMessageIds: const ['message_status_a'],
              sourceClaimIds: const ['message_status_a#claim-health'],
              expiresAt: validUntil,
              createdAt: observedAt,
              updatedAt: observedAt,
            ),
          ],
        ),
        aiProviderRepository: _AiRepository(contextWindow: 4096, output: 512),
        toolEvidenceRepository: _EvidenceRepository({
          evidence.evidenceId: evidence,
        }),
        clock: () => evaluatedAt,
      );

      final result = await useCase(
        bot: _bot(),
        systemPrompt: '',
        history: [
          Message(
            messageId: 'message_status_u',
            turnId: 'turn_status',
            chatId: 'chat_1',
            botId: 'bot_1',
            senderId: 'user_1',
            content: 'Check production.',
            timestamp: observedAt,
          ),
          assistant,
        ],
        userMessage: _current('What is the production status now?'),
        currentUserId: 'user_1',
        providerSupportsHistoryLookup: true,
      );

      expect(result.report.includedMemoryIds, isEmpty);
      final history = result.messages.singleWhere(
        (message) => message.role == 'assistant',
      );
      expect(history.content, contains('terminal="completed"'));
      expect(history.content, contains('id="claim-health"'));
      expect(
        history.content,
        contains(
          'kind="current_fact" trust="unverified" '
          'requires_reverification="true"',
        ),
      );
      expect(history.content, contains('tool="status.read"'));
      expect(history.content, contains('source="builtIn"'));
      expect(
        history.content,
        contains('observed_at="2026-09-05T10:00:00.000Z"'),
      );
      expect(history.content, contains('Production was healthy at 10:00Z.'));
      expect(history.content, contains('<verification_requirements>'));
      expect(
        history.content,
        contains('reason="historical_observation_expired"'),
      );
      final verification = result.messages.singleWhere(
        (message) => message.content.startsWith('<conversation_memory'),
      );
      expect(verification.content, contains('<verification_requirements>'));
      expect(
        verification.content,
        contains('claim_ref="message_status_a#claim-health"'),
      );
      expect(verification.content, contains('A fresh observation is required'));
    },
  );

  test('recalls a fresh fact Memory with nested evidence provenance', () async {
    final observedAt = DateTime.utc(2026, 9, 5, 10);
    final validUntil = DateTime.utc(2026, 9, 5, 11);
    final evaluatedAt = DateTime.utc(2026, 9, 5, 10, 30);
    final evidence = _currentStatusEvidence(
      observedAt: observedAt,
      validUntil: validUntil,
    );
    final assistant = _statusAssistant(evidence);
    final useCase = PrepareConversationContext(
      memoryRepository: _MemoryRepository(
        items: [
          ConversationMemoryItem(
            id: 'fresh-health',
            chatId: 'chat_1',
            memoryKey: 'production.health',
            kind: ConversationMemoryKind.fact,
            content: 'Production is healthy.',
            confidence: 1,
            sourceMessageIds: const ['message_status_a'],
            sourceClaimIds: const ['message_status_a#claim-health'],
            expiresAt: validUntil,
            createdAt: observedAt,
            updatedAt: observedAt,
          ),
        ],
      ),
      aiProviderRepository: _AiRepository(contextWindow: 4096, output: 512),
      toolEvidenceRepository: _EvidenceRepository({
        evidence.evidenceId: evidence,
      }),
      clock: () => evaluatedAt,
    );

    final result = await useCase(
      bot: _bot(),
      systemPrompt: '',
      history: [
        Message(
          messageId: 'message_status_u',
          turnId: 'turn_status',
          chatId: 'chat_1',
          botId: 'bot_1',
          senderId: 'user_1',
          content: 'Check production.',
          timestamp: observedAt,
        ),
        assistant,
      ],
      userMessage: _current('What is the production health?'),
      currentUserId: 'user_1',
      providerSupportsHistoryLookup: true,
    );

    expect(result.report.includedMemoryIds, ['fresh-health']);
    final memory = result.messages.singleWhere(
      (message) => message.content.startsWith('<conversation_memory'),
    );
    expect(memory.content, contains('<conversation_memory version="3"'));
    expect(
      memory.content,
      contains('<claim ref="message_status_a#claim-health"'),
    );
    expect(memory.content, contains('trust="verified"'));
    expect(memory.content, contains('requires_reverification="false"'));
    expect(memory.content, contains('tool="status.read"'));
    expect(memory.content, contains('observed_at="2026-09-05T10:00:00.000Z"'));
    expect(memory.content, contains('Production was healthy at 10:00Z.'));
  });
}

Message _message(
  int turn,
  bool user,
  String content, {
  String reasoning = '',
  String runId = '',
  MessageTerminalOutcome terminalOutcome = MessageTerminalOutcome.completed,
  bool hasPartialContent = false,
  MessageGrounding grounding = const MessageGrounding.unverified(),
  List<String> images = const [],
  List<String> files = const [],
}) => Message(
  messageId: 'message_${turn}_${user ? 'u' : 'a'}',
  turnId: 'turn_$turn',
  runId: user ? '' : runId,
  chatId: 'chat_1',
  botId: 'bot_1',
  senderId: user ? 'user_1' : 'bot_1',
  content: content,
  reasoning: reasoning,
  images: images,
  files: files,
  grounding: grounding,
  terminalOutcome: user ? null : terminalOutcome,
  hasPartialContent: user ? false : hasPartialContent,
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

final class _EvidenceRepository implements ToolEvidenceRepository {
  const _EvidenceRepository(this.records);

  final Map<String, ToolEvidenceRecord> records;

  @override
  Future<ToolEvidenceRecord?> getById(String evidenceId) async =>
      records[evidenceId];

  @override
  Future<bool> verifyDigest(String evidenceId) async =>
      records.containsKey(evidenceId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Message _statusAssistant(ToolEvidenceRecord evidence) => Message(
  messageId: 'message_status_a',
  turnId: 'turn_status',
  runId: 'run-status',
  chatId: 'chat_1',
  botId: 'bot_1',
  senderId: 'bot_1',
  content: 'Production is healthy.',
  grounding: MessageGrounding(
    trustLevel: AnswerTrustLevel.verified,
    reasonCode: 'all_evidence_validated',
    claims: [
      MessageClaimGrounding(
        claim: AnswerClaim(
          claimId: 'claim-health',
          text: 'Production is healthy.',
          kind: ClaimKind.currentFact,
          evidenceIds: [evidence.evidenceId],
        ),
        trustLevel: ClaimTrustLevel.verified,
        acceptedEvidenceIds: [evidence.evidenceId],
      ),
    ],
  ),
  terminalOutcome: MessageTerminalOutcome.completed,
  timestamp: evidence.observedAt,
);

ToolEvidenceRecord _currentStatusEvidence({
  required DateTime observedAt,
  required DateTime validUntil,
}) => ToolEvidenceRecord(
  evidenceId: 'attempt-status:evidence',
  runId: 'run-status',
  turnId: 'turn_status',
  chatId: 'chat_1',
  messageId: 'message_status_a',
  invocationId: 'invocation-status',
  attemptId: 'attempt-status',
  toolName: 'status.read',
  toolVersion: '1.0.0',
  source: ToolSource.builtIn,
  capabilities: const {ToolCapability.externalRead},
  terminalStatus: ToolInvocationStatus.succeeded,
  evidenceKind: EvidenceKind.observation,
  subject: 'service:production',
  scope: const {'service': 'production'},
  resultSummary: 'Production was healthy at 10:00Z.',
  argumentsDigest: _digestA,
  resultDigest: _digestB,
  structuredFacts: [StructuredFact(name: 'service.health', value: 'healthy')],
  observedAt: observedAt,
  validUntil: validUntil,
  persisted: true,
);

const _digestA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _digestB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
