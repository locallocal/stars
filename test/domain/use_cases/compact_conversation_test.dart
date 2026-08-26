import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/context_summarizer.dart';
import 'package:stars/domain/repositories/conversation_memory_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/use_cases/compact_conversation.dart';

void main() {
  test(
    'summarizes a closed prefix while protecting the latest four turns',
    () async {
      final messages = _MessageRepository(_history(7));
      final memory = _MemoryRepository();
      late ContextSummaryRequest captured;
      final useCase = CompactConversation(
        messageRepository: messages,
        memoryRepository: memory,
        summarizerFactory:
            (_) => _Summarizer((request) {
              captured = request;
              return _validResult(request);
            }),
        clock: () => DateTime(2026, 8, 8),
      );

      final result = await useCase(bot: _bot(), chatId: 'chat_1');

      expect(result, ConversationCompactionResult.committed);
      expect(captured.sourceMessages.map((message) => message.turnId).toSet(), {
        'turn_0',
        'turn_1',
        'turn_2',
      });
      expect(memory.committed?.metadata.sourceEndMessageId, 'message_2_a');
      expect(memory.expectedRevision, 0);
    },
  );

  test('rejects Memory references outside the candidate snapshot', () async {
    final memory = _MemoryRepository();
    final useCase = CompactConversation(
      messageRepository: _MessageRepository(_history(7)),
      memoryRepository: memory,
      summarizerFactory:
          (_) => _Summarizer((request) {
            final now = DateTime(2026);
            return ContextSummaryResult(
              markdown: '# 会话摘要\n\n- text',
              items: [
                ConversationMemoryItem(
                  id: 'bad',
                  chatId: request.chatId,
                  memoryKey: 'bad',
                  kind: ConversationMemoryKind.fact,
                  content: 'invented',
                  sourceMessageIds: const ['outside_snapshot'],
                  createdAt: now,
                  updatedAt: now,
                ),
              ],
            );
          }),
    );

    expect(
      await useCase(bot: _bot(), chatId: 'chat_1'),
      ConversationCompactionResult.invalidSummary,
    );
    expect(memory.committed, isNull);
  });

  test('does not compact active assistant runs', () async {
    final history = _history(7);
    history.add(
      Message(
        messageId: 'active',
        turnId: 'turn_active',
        runId: 'run_active',
        chatId: 'chat_1',
        botId: 'bot_1',
        senderId: 'bot_1',
        content: 'partial',
        timestamp: DateTime(2026, 8, 8),
      ),
    );
    late ContextSummaryRequest captured;
    final useCase = CompactConversation(
      messageRepository: _MessageRepository(history),
      memoryRepository: _MemoryRepository(),
      summarizerFactory:
          (_) => _Summarizer((request) {
            captured = request;
            return _validResult(request);
          }),
    );

    await useCase(bot: _bot(), chatId: 'chat_1');

    expect(
      captured.sourceMessages,
      isNot(contains(predicate<Message>((m) => m.messageId == 'active'))),
    );
  });

  test('preserves original evidence ids across rolling summaries', () async {
    final previous = _previousSummary();
    final memory = _MemoryRepository(
      previousSummary: previous,
      state: ConversationMemoryState(
        chatId: 'chat_1',
        revision: 1,
        activeSummaryId: previous.metadata.id,
        coveredThroughMessageId: 'message_2_a',
        updatedAt: DateTime(2026),
      ),
    );
    late ContextSummaryRequest captured;
    final useCase = CompactConversation(
      messageRepository: _MessageRepository(_history(10)),
      memoryRepository: memory,
      summarizerFactory:
          (_) => _Summarizer((request) {
            captured = request;
            final now = DateTime(2026);
            return ContextSummaryResult(
              markdown:
                  '# 会话摘要\n\n- preserved\n'
                  '  <!-- sources: message_0_u -->',
              items: [
                ConversationMemoryItem(
                  id: 'preserved',
                  chatId: request.chatId,
                  memoryKey: 'fact.preserved',
                  kind: ConversationMemoryKind.fact,
                  content: 'preserved',
                  sourceMessageIds: const ['message_0_u'],
                  createdAt: now,
                  updatedAt: now,
                ),
              ],
            );
          }),
      clock: () => DateTime(2026, 8, 9),
    );

    final result = await useCase(bot: _bot(), chatId: 'chat_1');

    expect(result, ConversationCompactionResult.committed);
    expect(captured.previousSummary, same(previous));
    expect(
      captured.sourceEvidence.map((item) => item.messageId),
      contains('message_0_u'),
    );
    expect(memory.committed?.metadata.sourceStartMessageId, 'message_0_u');
    expect(memory.committed?.metadata.sourceEndMessageId, 'message_5_a');
    expect(
      memory.committed?.metadata.sourceMessageIds,
      containsAll(['message_0_u', 'message_3_u', 'message_5_a']),
    );
    expect(memory.committed?.metadata.markdownSchemaVersion, 2);
    expect(memory.committed?.metadata.promptVersion, 2);
  });
}

List<Message> _history(int turns) => [
  for (var turn = 0; turn < turns; turn++) ...[
    Message(
      messageId: 'message_${turn}_u',
      turnId: 'turn_$turn',
      chatId: 'chat_1',
      botId: 'bot_1',
      senderId: 'user_1',
      content: 'question $turn',
      timestamp: DateTime(2026, 8, 1).add(Duration(minutes: turn * 2)),
    ),
    Message(
      messageId: 'message_${turn}_a',
      turnId: 'turn_$turn',
      chatId: 'chat_1',
      botId: 'bot_1',
      senderId: 'bot_1',
      content: 'answer $turn',
      terminalOutcome: MessageTerminalOutcome.completed,
      timestamp: DateTime(2026, 8, 1).add(Duration(minutes: turn * 2 + 1)),
    ),
  ],
];

ContextSummaryResult _validResult(ContextSummaryRequest request) {
  final now = DateTime(2026);
  return ContextSummaryResult(
    markdown: '# 会话摘要\n\n## 关键事实与纠正\n\n- saved',
    items: [
      ConversationMemoryItem(
        id: '${request.summaryId}_memory',
        chatId: request.chatId,
        memoryKey: 'fact.saved',
        kind: ConversationMemoryKind.fact,
        content: 'saved',
        sourceMessageIds: [request.sourceMessages.first.messageId],
        createdAt: now,
        updatedAt: now,
      ),
    ],
  );
}

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

final class _MessageRepository implements MessageRepository {
  _MessageRepository(this.messages);

  final List<Message> messages;

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  Future<List<Message>> getMessages(String chatId) async => messages;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _MemoryRepository implements ConversationMemoryRepository {
  _MemoryRepository({this.previousSummary, ConversationMemoryState? state})
    : state =
          state ??
          ConversationMemoryState(chatId: 'chat_1', updatedAt: DateTime(2026));

  final ConversationSummaryDocument? previousSummary;
  final ConversationMemoryState state;
  ConversationSummaryDocument? committed;
  int? expectedRevision;
  final List<ConversationCompactionStatus> statuses = [];

  @override
  Stream<String> get changes => const Stream.empty();

  @override
  Future<bool> commitCompaction({
    required String chatId,
    required int expectedRevision,
    required ConversationSummaryDocument summary,
    required List<ConversationMemoryItem> items,
  }) async {
    this.expectedRevision = expectedRevision;
    committed = summary;
    return true;
  }

  @override
  Future<ConversationSummaryDocument?> getActiveSummary(String chatId) async =>
      previousSummary;

  @override
  Future<ConversationMemoryState> getState(String chatId) async => state;

  @override
  Future<void> setCompactionStatus(
    String chatId,
    ConversationCompactionStatus status, {
    String lastError = '',
  }) async {
    statuses.add(status);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ConversationSummaryDocument _previousSummary() {
  final now = DateTime(2026, 8, 8);
  return ConversationSummaryDocument(
    metadata: ConversationSummaryMetadata(
      id: 'summary_previous',
      chatId: 'chat_1',
      status: ConversationSummaryStatus.active,
      fileName: 'summary_previous.md',
      contentDigest: 'digest',
      sourceStartMessageId: 'message_0_u',
      sourceEndMessageId: 'message_2_a',
      sourceMessageIds: const [
        'message_0_u',
        'message_0_a',
        'message_1_u',
        'message_1_a',
        'message_2_u',
        'message_2_a',
      ],
      sourceDigest: 'source-digest',
      baseRevision: 0,
      createdAt: now,
      updatedAt: now,
    ),
    markdown:
        '# 会话摘要\n\n- preserved\n'
        '  <!-- sources: message_0_u -->',
  );
}

final class _Summarizer implements ContextSummarizer {
  const _Summarizer(this.callback);

  final ContextSummaryResult Function(ContextSummaryRequest request) callback;

  @override
  Future<ContextSummaryResult> summarize(ContextSummaryRequest request) async =>
      callback(request);
}
