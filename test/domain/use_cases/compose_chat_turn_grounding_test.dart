import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/bot_skill_binding_repository.dart';
import 'package:stars/domain/repositories/conversation_memory_repository.dart';
import 'package:stars/domain/repositories/skill_repository.dart';
import 'package:stars/domain/use_cases/compose_chat_turn.dart';
import 'package:stars/domain/use_cases/prepare_conversation_context.dart';

void main() {
  test('fallback wraps explicitly continued partial output as data', () async {
    final result = await _compose(primary: false)(
      bot: _bot(),
      history: [
        _message(
          messageId: 'user-partial',
          turnId: 'turn-partial',
          senderId: 'user-1',
          content: 'continue the interrupted task',
        ),
        _message(
          messageId: 'assistant-partial',
          turnId: 'turn-partial',
          runId: 'run-partial',
          senderId: 'bot-1',
          content: 'partial <fact>',
          reasoning: 'discarded reasoning',
          terminalOutcome: MessageTerminalOutcome.cancelled,
          hasPartialContent: true,
          grounding: MessageGrounding(
            trustLevel: AnswerTrustLevel.failed,
            reasonCode: 'cancelled',
          ),
          images: const ['unsafe-image'],
          files: const ['unsafe-file'],
        ),
      ],
      userMessage: _message(
        messageId: 'current',
        turnId: 'turn-current',
        senderId: 'user-1',
        content: 'resume',
      ),
      currentUserId: 'user-1',
      includeUntrustedPartialOutput: true,
    );

    final assistant = result.messages.singleWhere(
      (message) => message.role == 'assistant',
    );
    expect(assistant.content, contains('<untrusted_partial_output'));
    expect(assistant.content, contains('run_id="run-partial"'));
    expect(assistant.content, contains('terminal="cancelled"'));
    expect(assistant.content, contains('trust="failed"'));
    expect(assistant.content, contains('reason_code="cancelled"'));
    expect(assistant.content, contains('partial &lt;fact&gt;'));
    expect(assistant.reasoning, isEmpty);
    expect(assistant.images, isEmpty);
    expect(assistant.files, isEmpty);
  });

  test('primary and fallback paths project the same trust semantics', () async {
    final history = [
      _message(
        messageId: 'user-failed',
        turnId: 'turn-failed',
        senderId: 'user-1',
        content: 'failed question',
      ),
      _message(
        messageId: 'assistant-failed',
        turnId: 'turn-failed',
        runId: 'run-failed',
        senderId: 'bot-1',
        content: 'failed secret',
        terminalOutcome: MessageTerminalOutcome.failed,
      ),
      _message(
        messageId: 'user-completed',
        turnId: 'turn-completed',
        senderId: 'user-1',
        content: 'completed question',
      ),
      _message(
        messageId: 'assistant-completed',
        turnId: 'turn-completed',
        runId: 'run-completed',
        senderId: 'bot-1',
        content: 'completed answer',
        terminalOutcome: MessageTerminalOutcome.completed,
      ),
    ];
    final current = _message(
      messageId: 'current',
      turnId: 'turn-current',
      senderId: 'user-1',
      content: 'follow-up',
    );

    final primary = await _compose(primary: true)(
      bot: _bot(),
      history: history,
      userMessage: current,
      currentUserId: 'user-1',
    );
    final fallback = await _compose(primary: false)(
      bot: _bot(),
      history: history,
      userMessage: current,
      currentUserId: 'user-1',
    );
    List<String> projected(PreparedChatTurn turn) => [
      for (final message in turn.messages.where(
        (message) => message.role != 'system',
      ))
        '${message.role}\n${message.content}',
    ];

    expect(projected(primary), projected(fallback));
    expect(projected(primary).join('\n'), isNot(contains('failed secret')));
    expect(projected(primary).join('\n'), contains('trust="unverified"'));
  });
}

ComposeChatTurn _compose({required bool primary}) => ComposeChatTurn(
  skillRepository: _EmptySkillRepository(),
  bindingRepository: _EmptyBindingRepository(),
  prepareConversationContext:
      primary
          ? PrepareConversationContext(
            memoryRepository: _EmptyMemoryRepository(),
            aiProviderRepository: _ContextAiRepository(),
          )
          : null,
  conversationArtifactsDirectoryProvider:
      (conversationId) async => '/data/Stars/chats/$conversationId',
  starsSystemPromptProvider: (_) => '<test_application_prompt />',
);

Bot _bot() => Bot(
  id: 'bot-1',
  name: 'Assistant',
  avatar: '',
  provider: 'OpenAI',
  baseURL: 'https://example.test',
  apiKey: 'secret',
  apiType: Bot.apiTypeOpenAI,
  model: 'model',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);

Message _message({
  required String messageId,
  required String turnId,
  required String senderId,
  required String content,
  String runId = '',
  String reasoning = '',
  MessageTerminalOutcome? terminalOutcome,
  bool hasPartialContent = false,
  MessageGrounding grounding = const MessageGrounding.unverified(),
  List<String> images = const [],
  List<String> files = const [],
}) => Message(
  messageId: messageId,
  turnId: turnId,
  runId: runId,
  chatId: 'chat-1',
  botId: 'bot-1',
  senderId: senderId,
  content: content,
  reasoning: reasoning,
  terminalOutcome: terminalOutcome,
  hasPartialContent: hasPartialContent,
  grounding: grounding,
  images: images,
  files: files,
  timestamp: DateTime(2026, 7, 26),
);

final class _EmptySkillRepository implements SkillRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _EmptyBindingRepository implements BotSkillBindingRepository {
  @override
  Future<List<BotSkillBinding>> getForBot(String botId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _EmptyMemoryRepository implements ConversationMemoryRepository {
  @override
  Stream<String> get changes => const Stream.empty();

  @override
  Future<ConversationSummaryDocument?> getActiveSummary(String chatId) async =>
      null;

  @override
  Future<List<ConversationMemoryItem>> getItems(String chatId) async =>
      const [];

  @override
  Future<ConversationMemoryState> getState(String chatId) async =>
      ConversationMemoryState(chatId: chatId, updatedAt: DateTime(2026));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ContextAiRepository implements AiProviderRepository {
  @override
  Future<AiModelInfo?> getModelInfo(Bot bot) async => AiModelInfo(
    modelId: bot.model,
    providerId: bot.provider,
    inputModalities: const [InputModality.text],
    outputModalities: const [OutputModality.text],
    contextWindowTokens: 4096,
    maxOutputTokens: 512,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
