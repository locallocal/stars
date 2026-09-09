import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/ui/features/bots/view_models/bot_token_usage_view_model.dart';

void main() {
  test('loads and sorts per-conversation usage with chat previews', () async {
    final messages = _FakeMessageRepository([
      _record(
        'small',
        'chat-small',
        DateTime(2026, 7, 24, 9),
        input: 20,
        output: 5,
      ),
      _record(
        'large',
        'chat-large',
        DateTime(2026, 7, 26, 10),
        input: 60,
        output: 15,
      ),
    ]);
    final chats = _FakeChatRepository([
      _chat('chat-small', 'Short conversation'),
      _chat('chat-large', 'Large conversation'),
    ]);
    final viewModel = BotTokenUsageViewModel(
      botId: 'bot-1',
      messageRepository: messages,
      chatRepository: chats,
      now: () => DateTime(2026, 7, 27, 12),
    );
    addTearDown(viewModel.dispose);

    await viewModel.load();

    expect(viewModel.usage.effectiveTotalTokens, 100);
    expect(viewModel.conversationUsages.map((entry) => entry.chatId), [
      'chat-large',
      'chat-small',
    ]);
    expect(viewModel.conversationUsages.first.preview, 'Large conversation');
    expect(viewModel.conversationUsages.first.usage.effectiveTotalTokens, 75);
    expect(viewModel.dailyBuckets, hasLength(3));
    expect(viewModel.dailyBuckets[0].usage.effectiveTotalTokens, 25);
    expect(viewModel.dailyBuckets[1].usage.effectiveTotalTokens, 0);
    expect(viewModel.dailyBuckets[2].usage.effectiveTotalTokens, 75);

    viewModel.selectDay(DateTime(2026, 7, 26));

    expect(viewModel.visibleBuckets, hasLength(24));
    expect(viewModel.visibleBuckets[10].usage.effectiveTotalTokens, 75);

    viewModel.showDaily();
    expect(viewModel.visibleBuckets, same(viewModel.dailyBuckets));
  });

  test(
    'combines usage from all deleted conversations into one entry',
    () async {
      final messages = _FakeMessageRepository([
        _record(
          'live',
          'chat-live',
          DateTime(2026, 7, 24, 9),
          input: 40,
          output: 10,
        ),
        _record(
          'deleted-a',
          'chat-deleted-a',
          DateTime(2026, 7, 25, 10),
          input: 20,
          output: 5,
        ),
        _record(
          'deleted-b',
          'chat-deleted-b',
          DateTime(2026, 7, 26, 11),
          input: 10,
          output: 15,
        ),
      ]);
      final viewModel = BotTokenUsageViewModel(
        botId: 'bot-1',
        messageRepository: messages,
        chatRepository: _FakeChatRepository([
          _chat('chat-live', 'Active conversation'),
        ]),
        now: () => DateTime(2026, 7, 27, 12),
      );
      addTearDown(viewModel.dispose);

      await viewModel.load();

      expect(viewModel.usage.effectiveTotalTokens, 100);
      expect(viewModel.conversationUsages, hasLength(2));
      final deleted = viewModel.conversationUsages.singleWhere(
        (entry) => entry.isDeleted,
      );
      expect(deleted.chatId, isNull);
      expect(deleted.preview, isEmpty);
      expect(deleted.usage.inputTokens, 30);
      expect(deleted.usage.outputTokens, 20);
      expect(deleted.usage.effectiveTotalTokens, 50);
    },
  );
}

ModelTokenUsageRecord _record(
  String id,
  String chatId,
  DateTime timestamp, {
  required int input,
  required int output,
}) {
  return ModelTokenUsageRecord(
    messageId: id,
    chatId: chatId,
    botId: 'bot-1',
    timestamp: timestamp,
    usage: ModelTokenUsage(
      inputTokens: input,
      outputTokens: output,
      totalTokens: input + output,
    ),
  );
}

Chat _chat(String id, String lastMessage) => Chat(
  id: id,
  botId: 'bot-1',
  lastMessage: lastMessage,
  lastMessageTimestamp: DateTime(2026, 7, 26),
  createTimestamp: DateTime(2026, 7, 26),
  modifyTimestamp: DateTime(2026, 7, 26),
);

class _FakeMessageRepository implements MessageRepository {
  _FakeMessageRepository(this.records);

  final List<ModelTokenUsageRecord> records;

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<List<ModelTokenUsageRecord>> getTokenUsageRecordsForBot(
    String botId,
  ) async => records;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository(this.chats);

  final List<Chat> chats;

  @override
  Stream<List<Chat>> get changes => const Stream<List<Chat>>.empty();

  @override
  Future<List<Chat>> getChats({bool forceRefresh = false}) async => chats;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
