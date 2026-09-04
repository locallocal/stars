import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';

void main() {
  test('web-search-only runs use the normalized Provider session', () async {
    final factory = _NativeProviderFactory();
    final persisted = <Message>[];
    final controller = ChatGenerationViewModel(
      chatId: 'chat-1',
      bot: _bot,
      providerFactory: factory.create,
      messagePersister: (message) async {
        persisted.add(message);
        return message;
      },
      lastMessageUpdater: (_, _) async {},
      toolRegistry: StaticToolRegistry(const []),
    );
    addTearDown(controller.dispose);
    controller.capabilityProvider.setWebSearch(true);

    expect(
      await controller.startText(
        userMessage: Message(
          chatId: 'chat-1',
          botId: 'bot-1',
          senderId: 'user',
          content: 'Search the web',
          timestamp: DateTime.utc(2026, 9, 5),
        ),
        messages: [ChatMessage(role: 'user', content: 'Search the web')],
      ),
      isTrue,
    );
    await _waitFor(
      () => controller.snapshot.lifecycle == ChatRunLifecycle.completed,
    );

    final runProvider = factory.instances.last;
    expect(factory.instances, hasLength(2));
    expect(runProvider.openSessionCalls, 1);
    expect(runProvider.legacyGenerationCalls, 0);
    expect(controller.snapshot.streamingResponse, 'Search result');
    expect(persisted.last.grounding.trustLevel, AnswerTrustLevel.unverified);
    expect(persisted.last.grounding.reasonCode, 'no_tool_evidence');
  });
}

final class _NativeProviderFactory {
  final List<_NativeProvider> instances = [];

  AiProvider create(Bot bot) {
    final provider = _NativeProvider(bot);
    instances.add(provider);
    return provider;
  }
}

final class _NativeProvider extends AiProvider {
  _NativeProvider(super.bot);

  int openSessionCalls = 0;
  int legacyGenerationCalls = 0;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
    supportsNativeToolEvidence: true,
  );

  @override
  AgentModelSession openModelSession(ModelRequest request) {
    openSessionCalls += 1;
    expect(request.tools, isEmpty);
    expect(request.options.webSearch, isTrue);
    return const _NativeSession();
  }

  @override
  Future<void> generateText(List<ChatMessage> messages) async {
    legacyGenerationCalls += 1;
    throw StateError('Legacy generation must not handle normalized search.');
  }
}

final class _NativeSession implements AgentModelSession {
  const _NativeSession();

  @override
  Stream<ModelEvent> start() => Stream.fromIterable(const [
    TextDelta('Search result'),
    ModelTurnCompleted(stopReason: 'stop'),
  ]);

  @override
  Stream<ModelEvent> continueWith(List<ToolResult> results) =>
      throw StateError('The search-only response completes in one turn.');

  @override
  Stream<ModelEvent> continueWithReliabilityFeedback(String feedback) =>
      throw StateError('The search-only response does not need repair.');

  @override
  Stream<ModelEvent> synthesizeGroundedAnswer(
    GroundedAnswerSynthesisRequest request,
  ) => Stream.fromIterable([
    GroundedAnswerProduced(
      GroundedAnswerCandidate(nonFactualText: request.draftText),
    ),
    const ModelTurnCompleted(stopReason: 'stop'),
  ]);

  @override
  Future<void> cancel() async {}

  @override
  void close() {}
}

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    if (predicate()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the generation state to settle.');
}

final _bot = Bot(
  id: 'bot-1',
  name: 'OpenAI',
  avatar: '',
  provider: 'OpenAI',
  baseURL: '',
  apiKey: 'test-key',
  apiType: Bot.apiTypeOpenAI,
  model: 'gpt-5.6-sol',
  systemPrompt: '',
  createTimestamp: DateTime.utc(2026, 9, 5),
  modifyTimestamp: DateTime.utc(2026, 9, 5),
);
