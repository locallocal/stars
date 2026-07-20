import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/bot_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/ui/features/chats/view_models/chat_list_view_model.dart';

void main() {
  test(
    'ChatListViewModel loads immutable state and filters by bot or preview',
    () async {
      final chatRepository = _FakeChatRepository([
        _chat('chat-1', 'bot-1', 'Architecture notes'),
        _chat('chat-2', 'bot-2', 'Weekend plan'),
      ]);
      final botRepository = _FakeBotRepository([
        _bot('bot-1', 'Planner'),
        _bot('bot-2', 'Coder'),
      ]);
      final viewModel = ChatListViewModel(
        chatRepository: chatRepository,
        botRepository: botRepository,
      );
      addTearDown(viewModel.dispose);

      await viewModel.load();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.error, isNull);
      expect(viewModel.chats, hasLength(2));
      expect(
        () => viewModel.chats.add(_chat('x', 'x', 'x')),
        throwsUnsupportedError,
      );

      viewModel.search('coder');
      expect(viewModel.filteredChats.map((chat) => chat.id), ['chat-2']);

      viewModel.search('architecture');
      expect(viewModel.filteredChats.map((chat) => chat.id), ['chat-1']);
    },
  );

  test(
    'ChatListViewModel exposes repository failures as presentation state',
    () async {
      final viewModel = ChatListViewModel(
        chatRepository: _FakeChatRepository(const [], error: StateError('db')),
        botRepository: _FakeBotRepository(const []),
      );
      addTearDown(viewModel.dispose);

      await viewModel.load();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.error, isA<StateError>());
    },
  );
}

Bot _bot(String id, String name) => Bot(
  id: id,
  name: name,
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

Chat _chat(String id, String botId, String preview) => Chat(
  id: id,
  botId: botId,
  lastMessage: preview,
  lastMessageTimestamp: DateTime(2026),
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository(this.items, {this.error});

  final List<Chat> items;
  final Object? error;
  final StreamController<List<Chat>> controller =
      StreamController<List<Chat>>.broadcast();

  @override
  Stream<List<Chat>> get changes => controller.stream;

  @override
  Future<List<Chat>> getChats({bool forceRefresh = false}) async {
    if (error case final error?) throw error;
    return items;
  }

  @override
  Future<void> addChat(Chat chat) async {}

  @override
  Future<void> clearHistory(String id) async {}

  @override
  Future<void> deleteChat(String id) async {}

  @override
  Future<void> deleteChatsForBot(String botId) async {}

  @override
  Future<Chat?> getChat(String id) async => null;

  @override
  void invalidate() {}

  @override
  Future<void> updateLastMessage(String id, String content) async {}
}

class _FakeBotRepository implements BotRepository {
  _FakeBotRepository(this.items);

  final List<Bot> items;
  final StreamController<List<Bot>> controller =
      StreamController<List<Bot>>.broadcast();

  @override
  Stream<List<Bot>> get changes => controller.stream;

  @override
  Future<List<Bot>> getBots({bool forceRefresh = false}) async => items;

  @override
  Future<void> addBot(Bot bot) async {}

  @override
  Future<void> deleteBot(String id) async {}

  @override
  Future<Bot?> getBot(String id) async => null;

  @override
  Future<void> updateBot(Bot bot) async {}
}
