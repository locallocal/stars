import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/ui/features/chat/view_models/chat_generation_view_model.dart';

void main() {
  test('classifies a Provider failure when no message is produced', () async {
    final failure = ProviderFailure.fromHttp(
      statusCode: 503,
      endpointKind: ProviderEndpointKind.responses,
    );
    final observed = <ProviderFailure>[];
    final controller = ChatGenerationViewModel(
      chatId: 'chat-1',
      bot: _bot,
      providerFactory: (bot) => _FailingAgentProvider(bot, failure),
      messagePersister: (message) async => message,
      lastMessageUpdater: (_, _) async {},
      providerFailureObserver: (item) async {
        observed.add(item);
      },
      toolRegistry: StaticToolRegistry([_UnusedTool()]),
    );
    addTearDown(controller.dispose);

    await controller.startText(
      userMessage: Message(
        chatId: 'chat-1',
        botId: _bot.id,
        senderId: 'user-1',
        content: 'Hello',
        timestamp: DateTime.utc(2026),
      ),
      messages: [ChatMessage(role: 'user', content: 'Hello')],
      requestedToolNames: const {'clock.read'},
    );
    await _waitFor(
      () => controller.snapshot.lifecycle == ChatRunLifecycle.failed,
    );

    expect(observed, hasLength(1));
    expect(observed.single.kind, ProviderFailureKind.server);
    expect(controller.snapshot.terminalMessage, isNull);
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
  createTimestamp: DateTime.utc(2026),
  modifyTimestamp: DateTime.utc(2026),
);

final class _FailingAgentProvider extends AiProvider {
  _FailingAgentProvider(super.bot, this.failure);

  final ProviderFailure failure;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );

  @override
  AgentModelSession openModelSession(ModelRequest request) =>
      _FailingAgentSession(failure);

  @override
  Future<void> generateText(List<ChatMessage> messages) =>
      throw StateError('Legacy generation must not run.');
}

final class _FailingAgentSession implements AgentModelSession {
  const _FailingAgentSession(this.failure);

  final ProviderFailure failure;

  @override
  Stream<ModelEvent> start() =>
      Stream<ModelEvent>.value(ModelTurnFailed.fromProvider(failure));

  @override
  Stream<ModelEvent> continueWith(List<ToolResult> results) =>
      throw StateError('A failed turn cannot continue.');

  @override
  Stream<ModelEvent> continueWithReliabilityFeedback(String feedback) =>
      throw StateError('A failed turn cannot continue.');

  @override
  Stream<ModelEvent> synthesizeGroundedAnswer(
    GroundedAnswerSynthesisRequest request, {
    List<ToolResult> pendingToolResults = const [],
  }) => throw StateError('A failed turn cannot synthesize.');

  @override
  Future<void> cancel() async {}

  @override
  void close() {}
}

final class _UnusedTool implements ExecutableTool {
  @override
  final ToolDefinition definition = ToolDefinition(
    name: 'clock.read',
    description: 'Read a clock.',
    inputSchema: const {'type': 'object'},
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.readOnly,
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) => throw StateError('Provider failure must happen first.');
}

Future<void> _waitFor(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    if (predicate()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the generation state to settle.');
}
