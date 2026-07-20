import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/use_cases/create_chat.dart';

void main() {
  test('CreateChat builds unique immutable chats and persists them', () async {
    final repository = _FakeChatRepository();
    final now = DateTime(2026, 7, 21, 10);
    final createChat = CreateChat(chatRepository: repository, clock: () => now);

    final first = await createChat(_bot);
    final second = await createChat(_bot);

    expect(first.id, isNot(second.id));
    expect(first.botId, _bot.id);
    expect(first.createTimestamp, now);
    expect(first.modifyTimestamp, now);
    expect(repository.added, [first, second]);
  });
}

final _bot = Bot(
  id: 'bot-1',
  name: 'Assistant',
  avatar: '',
  provider: 'OpenAI',
  baseURL: 'https://example.test',
  apiKey: 'secret',
  apiType: Bot.apiTypeOpenAI,
  model: 'test-model',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

class _FakeChatRepository implements ChatRepository {
  final List<Chat> added = [];
  final StreamController<List<Chat>> controller =
      StreamController<List<Chat>>.broadcast();

  @override
  Stream<List<Chat>> get changes => controller.stream;

  @override
  Future<void> addChat(Chat chat) async => added.add(chat);

  @override
  Future<void> clearHistory(String id) async {}

  @override
  Future<void> deleteChat(String id) async {}

  @override
  Future<void> deleteChatsForBot(String botId) async {}

  @override
  Future<Chat?> getChat(String id) async => null;

  @override
  Future<List<Chat>> getChats({bool forceRefresh = false}) async => added;

  @override
  void invalidate() {}

  @override
  Future<void> updateLastMessage(String id, String content) async {}
}
