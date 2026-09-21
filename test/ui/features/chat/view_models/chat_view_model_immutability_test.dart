import '../../../../support/idle_chat_generation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/attachment_repository.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/conversation_draft_repository.dart';
import 'package:stars/domain/repositories/message_action_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/use_cases/chat_workflow_facade.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/create_user_message.dart';
import 'package:stars/domain/use_cases/generate_media_turn.dart';
import 'package:stars/domain/use_cases/get_task_message_execution.dart';
import 'package:stars/domain/use_cases/persist_conversation_assets.dart';
import 'package:stars/domain/use_cases/prepare_text_generation.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';
import 'package:stars/ui/features/chat/view_models/chat_interaction_facade.dart';
import 'package:stars/ui/features/chat/view_models/chat_view_model.dart';
import 'package:stars/ui/features/chat/view_models/message_action_view_model.dart';

void main() {
  test('publishes immutable cached and loaded message snapshots', () async {
    final repository = _MutableMessageRepository([_message('message-1')]);
    final harness = _createHarness(repository);
    addTearDown(harness.dispose);

    final cachedSnapshot = harness.viewModel.cachedMessages!;

    expect(() => cachedSnapshot.clear(), throwsUnsupportedError);
    repository.messages.add(_message('message-2'));
    expect(cachedSnapshot, hasLength(1));

    await harness.viewModel.loadMessages();
    final loadedSnapshot = harness.viewModel.messages;
    expect(loadedSnapshot, hasLength(2));
    expect(() => loadedSnapshot.clear(), throwsUnsupportedError);

    repository.messages.add(_message('message-3'));
    expect(loadedSnapshot, hasLength(2));

    await harness.viewModel.loadMessages();
    expect(harness.viewModel.messages, hasLength(3));
    expect(loadedSnapshot, hasLength(2));
  });

  test('updates workflow and generation provider together', () {
    final harness = _createHarness(_MutableMessageRepository(const []));
    addTearDown(harness.dispose);
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
            'requires_approval': true,
          },
        ],
      },
      createTimestamp: _bot.createTimestamp,
      modifyTimestamp: DateTime(2026, 2),
    );

    harness.viewModel.updateBot(updatedBot);

    expect(harness.viewModel.bot, same(updatedBot));
    expect(
      harness.viewModel.generationViewModel.capabilityProvider.bot,
      same(updatedBot),
    );
    expect(harness.viewModel.bot.mcpTools.single.remoteName, 'search');
  });

  test(
    'task totals stay immutable across pagination and refresh, then clear',
    () async {
      final latest = _taskProgressMessage('latest', 80);
      final earlier = _taskProgressMessage('earlier', 40);
      final repository = _MutableMessageRepository([latest])
        ..earlierMessages = [earlier];
      final harness = _createHarness(repository);
      addTearDown(harness.dispose);
      final vm = harness.viewModel;
      await vm.loadMessages();
      final snapshot = vm.taskTokenUsage;
      expect(snapshot['latest']!.inputTokens, 80);
      expect(() => snapshot.clear(), throwsUnsupportedError);
      await vm.loadEarlierMessages();
      expect(vm.taskTokenUsage['earlier']!.inputTokens, 40);
      expect(snapshot.containsKey('earlier'), isFalse);
      await vm.loadMessages();
      expect(vm.taskTokenUsage['earlier']!.inputTokens, 40);
      expect(vm.taskTokenUsage['latest']!.inputTokens, 80);
      await vm.clearHistory();
      expect(vm.taskTokenUsage, isEmpty);
    },
  );
}

_ChatHarness _createHarness(_MutableMessageRepository messages) {
  final chats = _StubChatRepository();
  final providers = _StubAiProviderRepository();
  final attachments = _StubAttachmentRepository();
  final persistAssets = PersistConversationAssets(repository: attachments);
  final workflow = ChatWorkflowFacade(
    chatId: 'chat-1',
    bot: _bot,
    messageRepository: messages,
    chatRepository: chats,
    aiProviderRepository: providers,
    attachmentRepository: attachments,
    conversationDraftRepository: _StubConversationDraftRepository(),
    createUserMessage: CreateUserMessage(messageRepository: messages),
    persistConversationAssets: persistAssets,
    getTaskMessageExecution: GetTaskMessageExecution(
      () => throw StateError('Status replies use saved summaries'),
    ),
    generateMediaTurn: GenerateMediaTurn(
      messageRepository: messages,
      chatRepository: chats,
      providerRepository: providers,
      attachmentRepository: attachments,
      persistConversationAssets: persistAssets,
    ),
    prepareTextGeneration: PrepareTextGeneration(
      composeChatTurn: _unusedComposeChatTurn,
      aiProviderRepository: providers,
    ),
  );
  final generationRegistry = idleChatGenerationRegistry(
    providerFactory: providers.create,
  );
  final generationViewModel = generationRegistry.viewModelFor(
    workflow.chatId,
    workflow.bot,
  );
  final viewModel = ChatViewModel(
    interaction: ChatInteractionFacade(
      workflow: workflow,
      messageActions: MessageActionViewModel(
        repository: _StubMessageActionRepository(),
      ),
      generationRegistry: generationRegistry,
      generationViewModel: generationViewModel,
    ),
  );
  return _ChatHarness(
    viewModel: viewModel,
    generationRegistry: generationRegistry,
  );
}

Future<PreparedChatTurn> _unusedComposeChatTurn({
  required Bot bot,
  required List<Message> history,
  required Message userMessage,
  required String currentUserId,
  AiProvider? skillToolProvider,
  bool foregroundOnly = false,
  String? backgroundTaskObjective,
}) {
  throw UnimplementedError();
}

final class _ChatHarness {
  const _ChatHarness({
    required this.viewModel,
    required this.generationRegistry,
  });

  final ChatViewModel viewModel;
  final ChatGenerationRegistry generationRegistry;

  void dispose() {
    viewModel.dispose();
    generationRegistry.clear();
  }
}

final class _MutableMessageRepository implements PaginatedMessageRepository {
  _MutableMessageRepository(this.messages);

  final List<Message> messages;
  List<Message> earlierMessages = const [];

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  String createId(String prefix) => '$prefix-id';

  @override
  Future<List<Message>> getMessages(String chatId) async => messages;

  @override
  Future<MessagePage> getMessagePage(
    String chatId, {
    MessageCursor? before,
    int limit = 50,
  }) async => MessagePage(
    messages: before == null ? messages : earlierMessages,
    hasMore: before == null && earlierMessages.isNotEmpty,
    nextCursor:
        before == null && earlierMessages.isNotEmpty
            ? MessageCursor(timestamp: DateTime(2026), messageId: 'cursor')
            : null,
  );

  @override
  MessagePage? peekMessagePage(String chatId) =>
      MessagePage(messages: messages, hasMore: false);

  @override
  Future<Message> upsertMessage(Message message) async => message;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _StubChatRepository implements ChatRepository {
  @override
  Stream<List<Chat>> get changes => const Stream<List<Chat>>.empty();

  @override
  Future<void> clearHistory(String id) async {}

  @override
  void invalidate() {}

  @override
  Future<void> updateLastMessage(String id, String content) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _StubAiProviderRepository implements AiProviderRepository {
  @override
  AiProvider create(Bot bot) => _StubAiProvider(bot);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _StubAiProvider extends AiProvider {
  _StubAiProvider(super.bot);

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class _StubAttachmentRepository implements AttachmentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _StubConversationDraftRepository
    implements ConversationDraftRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _StubMessageActionRepository implements MessageActionRepository {
  @override
  String? get localFileHomeDirectory => null;

  @override
  Future<bool> localFileExists(String path) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final Bot _bot = Bot(
  id: 'bot-1',
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

Message _message(String id) => Message(
  messageId: id,
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'user-1',
  content: id,
  timestamp: DateTime(2026),
);

Message _taskProgressMessage(String id, int inputTokens) => Message(
  messageId: id,
  taskMessageKind: TaskMessageKind.status,
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: 'bot-1',
  content: 'Task progress',
  timestamp: DateTime(2026),
  taskStatusSummaries: [
    ConversationTaskProgressSummary(
      taskId: 'task-1',
      chatId: 'chat-1',
      title: 'Report',
      status: ConversationTaskStatus.running,
      phase: ConversationTaskPhase.executing,
      planRevision: 1,
      summaryRevision: 1,
      updatedAt: DateTime(2026),
      progress: TaskProgress(
        totalSteps: 2,
        lastMeaningfulProgressAt: DateTime(2026),
        tokenUsage: ModelTokenUsage(inputTokens: inputTokens, outputTokens: 10),
      ),
    ),
  ],
);
