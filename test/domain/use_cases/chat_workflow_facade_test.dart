import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/conversation_draft_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/use_cases/chat_workflow_facade.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/create_user_message.dart';
import 'package:stars/domain/use_cases/generate_media_turn.dart';
import 'package:stars/domain/use_cases/persist_conversation_assets.dart';
import 'package:stars/domain/use_cases/prepare_text_generation.dart';

void main() {
  test(
    'normalizes paginated history and delegates injected workflows',
    () async {
      final messages = _PagedMessages();
      final chats = _FakeChats();
      final assets = _FakeAssets();
      final providers = _FakeProviders();
      final drafts = _MemoryDrafts();
      final persistAssets = PersistConversationAssets(repository: assets);
      final facade = ChatWorkflowFacade(
        chatId: 'chat-1',
        bot: _bot,
        messageRepository: messages,
        chatRepository: chats,
        aiProviderRepository: providers,
        attachmentRepository: assets,
        conversationDraftRepository: drafts,
        createUserMessage: CreateUserMessage(messageRepository: messages),
        persistConversationAssets: persistAssets,
        generateMediaTurn: GenerateMediaTurn(
          messageRepository: messages,
          chatRepository: chats,
          providerRepository: providers,
          attachmentRepository: assets,
          persistConversationAssets: persistAssets,
        ),
        prepareTextGeneration: PrepareTextGeneration(
          aiProviderRepository: providers,
          composeChatTurn:
              ({
                required bot,
                required history,
                required userMessage,
                required currentUserId,
                skillToolProvider,
              }) async => PreparedChatTurn(
                messages: const [],
                activatedSkills: const [],
              ),
        ),
      );

      final cached = facade.peekHistory();
      expect(cached?.messages.map((message) => message.messageId), ['cached']);
      expect(cached?.hasMore, isTrue);
      expect(
        () => cached!.messages.add(_message('mutate')),
        throwsUnsupportedError,
      );

      final first = await facade.loadHistory();
      expect(first.messages.map((message) => message.messageId), ['latest']);
      expect(first.nextCursor?.messageId, 'cursor');
      final earlier = await facade.loadHistory(before: first.nextCursor);
      expect(earlier.messages.map((message) => message.messageId), ['earlier']);
      expect(messages.requestedCursors, [null, first.nextCursor]);

      final user = facade.createUserMessage(
        currentUserId: 'user-1',
        content: 'hello',
      );
      expect(user.chatId, 'chat-1');
      expect(user.botId, 'bot-1');
      expect(user.messageId, startsWith('message-'));
      expect(await facade.persistAssets(['/tmp/source.png']), [
        '/conversation/source.png',
      ]);

      const draft = ConversationDraft(text: 'draft');
      await facade.writeDraft(draft);
      expect(await facade.readDraft(), same(draft));
      await facade.deleteDraft();
      expect(await facade.readDraft(), isNull);
    },
  );

  test('uses updated Bot configuration for an existing conversation', () async {
    final messages = _PagedMessages();
    final chats = _FakeChats();
    final assets = _FakeAssets();
    final providers = _FakeProviders();
    final persistAssets = PersistConversationAssets(repository: assets);
    Bot? preparedBot;
    final facade = ChatWorkflowFacade(
      chatId: 'chat-1',
      bot: _bot,
      messageRepository: messages,
      chatRepository: chats,
      aiProviderRepository: providers,
      attachmentRepository: assets,
      conversationDraftRepository: _MemoryDrafts(),
      createUserMessage: CreateUserMessage(messageRepository: messages),
      persistConversationAssets: persistAssets,
      generateMediaTurn: GenerateMediaTurn(
        messageRepository: messages,
        chatRepository: chats,
        providerRepository: providers,
        attachmentRepository: assets,
        persistConversationAssets: persistAssets,
      ),
      prepareTextGeneration: PrepareTextGeneration(
        aiProviderRepository: providers,
        composeChatTurn: ({
          required bot,
          required history,
          required userMessage,
          required currentUserId,
          skillToolProvider,
        }) async {
          preparedBot = bot;
          return PreparedChatTurn(
            messages: const [],
            activatedSkills: const [],
          );
        },
      ),
    );
    final updatedBot = Bot(
      id: _bot.id,
      name: _bot.name,
      avatar: _bot.avatar,
      provider: _bot.provider,
      baseURL: _bot.baseURL,
      apiKey: _bot.apiKey,
      apiType: _bot.apiType,
      model: _bot.model,
      systemPrompt: _bot.systemPrompt,
      parameters: {
        Bot.parameterMcpTools: [
          {
            'server_id': 'server-1',
            'remote_name': 'search',
            'requires_approval': false,
          },
        ],
      },
      createTimestamp: _bot.createTimestamp,
      modifyTimestamp: DateTime(2026, 2),
    );

    facade.updateBot(updatedBot);
    await facade.prepareTextTurn(
      history: const [],
      userMessage: _message('user-message'),
      currentUserId: 'user-1',
    );

    expect(facade.bot, same(updatedBot));
    expect(preparedBot, same(updatedBot));
    expect(preparedBot!.mcpTools.single.remoteName, 'search');
  });
}

final _bot = Bot(
  id: 'bot-1',
  name: 'Bot',
  avatar: '',
  provider: 'test',
  baseURL: '',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'test-model',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

Message _message(String id) => Message(
  messageId: id,
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'user-1',
  content: id,
  timestamp: DateTime(2026),
);

final class _PagedMessages implements PaginatedMessageRepository {
  int _sequence = 0;
  final List<MessageCursor?> requestedCursors = [];
  final MessageCursor cursor = MessageCursor(
    timestamp: DateTime(2026),
    messageId: 'cursor',
  );

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  String createId(String prefix) => '$prefix-${++_sequence}';

  @override
  MessagePage? peekMessagePage(String chatId) => MessagePage(
    messages: [_message('cached')],
    hasMore: true,
    nextCursor: cursor,
  );

  @override
  Future<MessagePage> getMessagePage(
    String chatId, {
    MessageCursor? before,
    int limit = 50,
  }) async {
    requestedCursors.add(before);
    return MessagePage(
      messages: [_message(before == null ? 'latest' : 'earlier')],
      hasMore: before == null,
      nextCursor: before == null ? cursor : null,
    );
  }

  @override
  Future<Message> upsertMessage(Message message) async => message;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeChats implements ChatRepository {
  @override
  Stream<List<Chat>> get changes => const Stream<List<Chat>>.empty();

  @override
  Future<void> updateLastMessage(String id, String content) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeAssets implements ConversationAssetRepository {
  @override
  Future<String?> captureImage() async => '/tmp/camera.png';

  @override
  Future<String> getOutputDirectory(String chatId) async => '/conversation';

  @override
  Future<List<String>> persistAssets({
    required String chatId,
    required Iterable<String> sourcePaths,
  }) async => [
    for (final source in sourcePaths) '/conversation/${source.split('/').last}',
  ];

  @override
  Future<String?> selectFile() async => '/tmp/file.txt';

  @override
  Future<String?> selectImage() async => '/tmp/image.png';
}

final class _FakeProviders implements AiProviderRepository {
  @override
  AiProvider create(Bot bot) => _FakeProvider(bot);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeProvider extends AiProvider {
  _FakeProvider(super.bot);

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class _MemoryDrafts implements ConversationDraftRepository {
  ConversationDraft? draft;

  @override
  Future<void> delete(String chatId) async => draft = null;

  @override
  Future<ConversationDraft?> read(String chatId) async => draft;

  @override
  Future<void> write(String chatId, ConversationDraft draft) async {
    this.draft = draft;
  }
}
