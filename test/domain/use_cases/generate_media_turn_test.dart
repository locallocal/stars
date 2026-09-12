import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/use_cases/generate_media_turn.dart';
import 'package:stars/domain/use_cases/persist_conversation_assets.dart';

void main() {
  late _MemoryMessages messages;
  late _MemoryChats chats;
  late _FakeAssets assets;
  late _FakeProviders providers;
  late GenerateMediaTurn useCase;

  setUp(() {
    messages = _MemoryMessages();
    chats = _MemoryChats();
    assets = _FakeAssets();
    providers = _FakeProviders();
    useCase = GenerateMediaTurn(
      messageRepository: messages,
      chatRepository: chats,
      providerRepository: providers,
      attachmentRepository: assets,
      persistConversationAssets: PersistConversationAssets(repository: assets),
    );
  });

  test('persists one complete image turn and both chat previews', () async {
    Message? submitted;
    final result = await useCase(
      _request(),
      onUserPersisted: (message) => submitted = message,
    );

    expect(submitted, result.userMessage);
    expect(result.userMessage.images, ['/conversation/reference.png']);
    expect(result.response.images, ['/conversation/generated.png']);
    expect(result.response.terminalOutcome, MessageTerminalOutcome.completed);
    expect(messages.persisted, [result.userMessage, result.response]);
    expect(chats.previews, ['draw a star', 'image generated']);
  });

  test('persists a failed terminal after the user message commits', () async {
    providers.error = StateError('provider unavailable');

    await expectLater(
      useCase(_request()),
      throwsA(
        isA<MediaTurnFailure>()
            .having((failure) => failure.userMessage, 'user', isNotNull)
            .having(
              (failure) => failure.terminalMessage?.terminalOutcome,
              'terminal outcome',
              MessageTerminalOutcome.failed,
            ),
      ),
    );
    expect(messages.persisted, hasLength(2));
  });
}

MediaTurnRequest _request() => MediaTurnRequest(
  kind: MediaTurnKind.image,
  chatId: 'chat',
  bot: _bot,
  currentUserId: 'me',
  prompt: 'draw a star',
  generatedPreview: 'image generated',
  resultDetail: 'result',
  attachmentDetail: 'attachment',
  sourceImagePaths: const ['/picker/reference.png'],
  imageSize: '1024x1024',
);

final _bot = Bot(
  id: 'bot',
  name: 'Bot',
  avatar: '',
  provider: 'Provider',
  baseURL: 'https://example.com',
  apiKey: 'key',
  apiType: Bot.apiTypeOpenAI,
  model: 'model',
  systemPrompt: '',
  createTimestamp: DateTime.utc(2026, 8, 14),
  modifyTimestamp: DateTime.utc(2026, 8, 14),
);

final class _MemoryMessages implements MessageRepository {
  final List<Message> persisted = [];
  int _ids = 0;

  @override
  Stream<void> get changes => const Stream.empty();

  @override
  String createId(String prefix) => '$prefix-${_ids++}';

  @override
  Future<Message> upsertMessage(Message message) async {
    persisted.add(message);
    return message;
  }

  @override
  Future<List<Message>> upsertMessages(Iterable<Message> messages) async =>
      messages.toList();

  @override
  Future<void> deleteMessages(String chatId) async {}

  @override
  Future<List<Message>> getMessages(String chatId) async => const [];

  @override
  Future<Map<String, ModelTokenUsage>> getTokenUsageByChatForBot(
    String botId,
  ) async => const {};

  @override
  Future<ModelTokenUsage> getTokenUsageForBot(String botId) async =>
      ModelTokenUsage.empty;

  @override
  Future<List<ModelTokenUsageRecord>> getTokenUsageRecordsForBot(
    String botId,
  ) async => const [];

  @override
  Future<List<ModelTokenUsageRecord>> getTokenUsageRecordsForChat(
    String chatId,
  ) async => const [];
}

final class _MemoryChats implements ChatRepository {
  final List<String> previews = [];

  @override
  Stream<List<Chat>> get changes => const Stream.empty();

  @override
  Future<void> updateLastMessage(String id, String content) async {
    previews.add(content);
  }

  @override
  Future<void> updateChatName(String id, String name) async {}

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
  Future<List<Chat>> getChats({bool forceRefresh = false}) async => const [];

  @override
  void invalidate() {}
}

final class _FakeAssets implements ConversationAssetRepository {
  @override
  Future<List<String>> persistAssets({
    required String chatId,
    required Iterable<String> sourcePaths,
  }) async => [
    for (final path in sourcePaths) '/conversation/${path.split('/').last}',
  ];

  @override
  Future<String> getOutputDirectory(String chatId) async => '/conversation';

  @override
  Future<String?> captureImage() async => null;

  @override
  Future<String?> selectFile() async => null;

  @override
  Future<String?> selectImage() async => null;
}

final class _FakeProviders implements AiProviderRepository {
  Object? error;

  @override
  Future<List<String>> generateImage({
    required Bot bot,
    required String prompt,
    required String size,
    required String outputDirectory,
    required List<String> referenceImages,
    required String style,
  }) async {
    if (error case final failure?) throw failure;
    return ['$outputDirectory/generated.png'];
  }

  @override
  AiProvider create(Bot bot) => throw UnimplementedError();

  @override
  Future<AiModelInfo?> getModelInfo(Bot bot) async => null;

  @override
  Future<List<AiModelInfo>> listModels(Bot bot) async => const [];

  @override
  Future<String> generateMusic({
    required Bot bot,
    required String prompt,
    required String outputDirectory,
    required String referenceMusic,
  }) => throw UnimplementedError();

  @override
  Future<String> generateSpeech({
    required Bot bot,
    required String prompt,
    required String voiceType,
    required String outputDirectory,
  }) => throw UnimplementedError();

  @override
  Future<String> generateVideo({
    required Bot bot,
    required String prompt,
    required String ratio,
    required String outputDirectory,
    required List<String> referenceImages,
  }) => throw UnimplementedError();
}
