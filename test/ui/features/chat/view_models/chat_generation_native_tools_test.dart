import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/use_cases/agent_run_coordinator.dart';
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

  test(
    'uses the prepared conversation turn limit and persists limit failures',
    () async {
      final tool = _EvidenceTool();
      final factory = _ToolLoopProviderFactory(tool.definition.name);
      final groundedMessages = <Message>[];
      var recoveryStages = 0;
      final controller = ChatGenerationViewModel(
        chatId: 'chat-1',
        bot: _bot,
        providerFactory: factory.create,
        messagePersister: (message) async => message,
        groundedMessagePersister: (message) async {
          groundedMessages.add(message);
          return message;
        },
        answerRecoveryCheckpointPersister: (message) async {
          recoveryStages += 1;
          throw StateError('Failed answers cannot be staged for recovery.');
        },
        lastMessageUpdater: (_, _) async {},
        toolRegistry: StaticToolRegistry([tool]),
        toolInvocationPersister: (_) async {},
        agentRunLimits: const AgentRunLimits(maxModelTurns: 1),
      );
      addTearDown(controller.dispose);

      expect(
        await controller.startTextWithPreparation(
          userMessage: Message(
            chatId: 'chat-1',
            botId: 'bot-1',
            senderId: 'user',
            content: 'Use the tool twice',
            timestamp: DateTime.utc(2026, 9, 5),
          ),
          prepare:
              (message) async => PreparedTextGeneration(
                userMessage: message,
                messages: [
                  ChatMessage(role: 'user', content: 'Use the tool twice'),
                ],
                requestedToolNames: {tool.definition.name},
                maxModelTurns: 2,
              ),
        ),
        isTrue,
      );
      await _waitFor(
        () => controller.snapshot.lifecycle == ChatRunLifecycle.failed,
      );

      expect(tool.executions, 1);
      expect(recoveryStages, 0);
      expect(groundedMessages, hasLength(1));
      expect(
        groundedMessages.single.grounding.reasonCode,
        'model_turn_limit_reached',
      );
      expect(groundedMessages.single.grounding.evidenceIds, hasLength(1));
      expect(
        groundedMessages.single.terminalOutcome,
        MessageTerminalOutcome.failed,
      );
    },
  );
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
    GroundedAnswerSynthesisRequest request, {
    List<ToolResult> pendingToolResults = const [],
  }) => Stream.fromIterable([
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

final class _ToolLoopProviderFactory {
  _ToolLoopProviderFactory(this.toolName);

  final String toolName;

  AiProvider create(Bot bot) => _ToolLoopProvider(bot, toolName);
}

final class _ToolLoopProvider extends AiProvider {
  _ToolLoopProvider(super.bot, this.toolName);

  final String toolName;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );

  @override
  AgentModelSession openModelSession(ModelRequest request) =>
      _ToolLimitSession(toolName);

  @override
  Future<void> generateText(List<ChatMessage> messages) =>
      throw StateError('The normalized Agent loop must be used.');
}

final class _ToolLimitSession implements AgentModelSession {
  _ToolLimitSession(this.toolName);

  final String toolName;

  @override
  Stream<ModelEvent> start() => Stream.fromIterable([
    ToolCallRequested(
      callId: 'call-1',
      name: toolName,
      arguments: const {'value': 2},
    ),
    const ModelTurnCompleted(stopReason: 'tool_calls'),
  ]);

  @override
  Stream<ModelEvent> continueWith(List<ToolResult> results) =>
      Stream.fromIterable([
        ToolCallRequested(
          callId: 'call-2',
          name: toolName,
          arguments: const {'value': 3},
        ),
        const ModelTurnCompleted(stopReason: 'tool_calls'),
      ]);

  @override
  Stream<ModelEvent> continueWithReliabilityFeedback(String feedback) =>
      throw StateError('Reliability repair is not expected.');

  @override
  Stream<ModelEvent> synthesizeGroundedAnswer(
    GroundedAnswerSynthesisRequest request, {
    List<ToolResult> pendingToolResults = const [],
  }) => throw StateError('Synthesis is not reached at the turn limit.');

  @override
  Future<void> cancel() async {}

  @override
  void close() {}
}

final class _EvidenceTool implements ExecutableTool {
  int executions = 0;

  @override
  final ToolDefinition definition = ToolDefinition(
    name: 'calculate',
    description: 'Double a number.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'value': {'type': 'integer'},
      },
      'required': ['value'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'result': {'type': 'integer'},
        ...toolEvidenceOutputSchemaProperties,
      },
      'required': ['result', ...toolEvidenceOutputRequiredFields],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.readOnly,
    capabilities: const {ToolCapability.compute},
    toolVersion: '1.0.0',
    evidenceCapabilities: const {EvidenceKind.calculation},
    evidenceScope: ToolEvidenceScopeRule(
      subject: 'calculation:double',
      argumentToScope: const {'value': 'value'},
    ),
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    executions += 1;
    final value = call.arguments['value']! as int;
    final scope = <String, Object?>{'value': value};
    final facts = [
      StructuredFact(name: 'calculation.result', value: value * 2),
    ];
    final observedAt = DateTime.utc(2026, 9, 5);
    return ToolResult(
      callId: call.callId,
      name: call.name,
      content: '${value * 2}',
      structuredContent: {
        'result': value * 2,
        ...toolEvidenceOutputMetadata(
          evidenceKind: EvidenceKind.calculation,
          subject: 'calculation:double',
          scope: scope,
          structuredFacts: facts,
          observedAt: observedAt,
        ),
      },
      evidenceKind: EvidenceKind.calculation,
      subject: 'calculation:double',
      scope: scope,
      structuredFacts: facts,
      observedAt: observedAt,
    );
  }
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
