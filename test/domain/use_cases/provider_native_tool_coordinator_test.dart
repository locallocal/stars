import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/use_cases/agent_run_coordinator.dart';

void main() {
  group('Provider-native Tool coordination', () {
    test(
      'records lifecycle and produces a scoped observation candidate',
      () async {
        final reported = _providerWebSearchResult();
        final session = _FakeModelSession([
          [
            reported,
            const TextDelta(
              'Current result.\n<stars_evidence call_ids="native-search-1" />',
            ),
            const ModelTurnCompleted(stopReason: 'stop'),
          ],
        ]);
        final persisted = <ToolExecutionRecord>[];
        final coordinator = AgentRunCoordinator(
          toolRegistry: StaticToolRegistry(const []),
          toolPolicy: const DefaultToolPolicy(),
          toolInvocationPersister: (record) async => persisted.add(record),
        );

        final result = await coordinator.run(
          provider: _FakeProvider(session),
          request: _request(),
        );

        expect(result.status, AgentRunStatus.completed);
        expect(result.text, 'Current result.');
        expect(persisted.map((record) => record.status), [
          ToolInvocationStatus.requested,
          ToolInvocationStatus.running,
          ToolInvocationStatus.succeeded,
        ]);
        final terminal = persisted.last;
        expect(terminal.source, ToolSource.providerNative);
        expect(terminal.providerCallId, 'native-search-1');
        expect(terminal.evidenceCandidate, isNotNull);
        expect(
          terminal.evidenceCandidate!.evidenceKind,
          EvidenceKind.observation,
        );
        expect(
          terminal.evidenceCandidate!.validUntil,
          DateTime.utc(2026, 9, 5, 10, 15),
        );
        expect(
          terminal
              .evidenceCandidate!
              .structuredFacts
              .single
              .attributes['provider_reference_id'],
          'provider-message-1:url_citation:0',
        );
      },
    );

    test('failed native search cannot support a factual footer', () async {
      final session = _FakeModelSession([
        [
          _providerWebSearchResult(isError: true),
          const TextDelta(
            'The result could not be verified.\n'
            '<stars_evidence call_ids="" />',
          ),
          const ModelTurnCompleted(stopReason: 'stop'),
        ],
      ]);
      final coordinator = AgentRunCoordinator(
        toolRegistry: StaticToolRegistry(const []),
        toolPolicy: const DefaultToolPolicy(),
      );

      final result = await coordinator.run(
        provider: _FakeProvider(session),
        request: _request(),
      );

      expect(result.status, AgentRunStatus.completed);
      expect(result.toolInvocations.single.status, ToolInvocationStatus.failed);
      expect(result.toolInvocations.single.evidenceCandidate, isNull);
    });

    test('combines Provider-native and MCP evidence in one ledger', () async {
      final mcpTool = _EvidenceMcpTool();
      final session = _FakeModelSession([
        [
          _providerWebSearchResult(),
          ToolCallRequested(
            callId: 'mcp-read-1',
            name: mcpTool.definition.name,
            arguments: const {'resource_id': 'record-1'},
          ),
          const ModelTurnCompleted(stopReason: 'tool_calls'),
        ],
        [
          const TextDelta(
            'Combined result.\n'
            '<stars_evidence '
            'call_ids="native-search-1,mcp-read-1" />',
          ),
          const ModelTurnCompleted(stopReason: 'stop'),
        ],
      ]);
      final persisted = <ToolExecutionRecord>[];
      final coordinator = AgentRunCoordinator(
        toolRegistry: StaticToolRegistry([mcpTool]),
        toolPolicy: const DefaultToolPolicy(
          allowNetwork: true,
          allowExternalRead: true,
        ),
        toolInvocationPersister: (record) async => persisted.add(record),
      );

      final result = await coordinator.run(
        provider: _FakeProvider(session),
        request: _request(toolNames: {mcpTool.definition.name}),
      );

      expect(result.status, AgentRunStatus.completed);
      expect(result.toolInvocations, hasLength(2));
      final terminal =
          persisted
              .where(
                (record) => record.status == ToolInvocationStatus.succeeded,
              )
              .toList();
      expect(terminal, hasLength(2));
      expect(terminal.map((record) => record.source).toSet(), {
        ToolSource.providerNative,
        ToolSource.mcp,
      });
      expect(
        terminal.every((record) => record.evidenceCandidate != null),
        isTrue,
      );
    });
  });
}

ProviderNativeToolResult _providerWebSearchResult({bool isError = false}) {
  final observedAt = DateTime.utc(2026, 9, 5, 10);
  final definition = ToolDefinition(
    name: 'openai.responses.web_search',
    description: 'Provider-hosted search.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'action': {'type': 'string'},
      },
      'required': ['action'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'citation': {'type': 'string'},
        ...toolEvidenceOutputSchemaProperties,
      },
      'required': ['citation', ...toolEvidenceOutputRequiredFields],
      'additionalProperties': false,
    },
    source: ToolSource.providerNative,
    riskLevel: ToolRiskLevel.readOnly,
    capabilities: const {ToolCapability.network, ToolCapability.externalRead},
    toolVersion: 'openai.responses.web_search.1',
    evidenceCapabilities: const {EvidenceKind.observation},
    evidenceScope: ToolEvidenceScopeRule(
      subject: 'web:search',
      argumentToScope: const {'action': 'action'},
    ),
    defaultEvidenceValidity: const Duration(minutes: 15),
  );
  const scope = <String, Object?>{'action': 'search'};
  final fact = StructuredFact(
    name: 'web.citation.1',
    value: 'Current result.',
    attributes: const {
      'provider_reference_id': 'provider-message-1:url_citation:0',
      'source_resource_id': 'url:reference-1',
    },
  );
  final call = ToolCallRequest(
    callId: 'native-search-1',
    name: definition.name,
    arguments: scope,
  );
  final result =
      isError
          ? ToolResult(
            callId: call.callId,
            name: call.name,
            content: 'Provider search returned no citation.',
            isError: true,
            errorCode: 'provider_native_citation_missing',
            source: ToolSource.providerNative,
            observedAt: observedAt,
          )
          : ToolResult(
            callId: call.callId,
            name: call.name,
            content: 'Provider search returned one citation.',
            structuredContent: {
              'citation': 'Current result.',
              ...toolEvidenceOutputMetadata(
                evidenceKind: EvidenceKind.observation,
                subject: 'web:search',
                scope: scope,
                structuredFacts: [fact],
                observedAt: observedAt,
              ),
            },
            source: ToolSource.providerNative,
            schemaValid: true,
            evidenceKind: EvidenceKind.observation,
            subject: 'web:search',
            scope: scope,
            structuredFacts: [fact],
            observedAt: observedAt,
          );
  return ProviderNativeToolResult(
    definition: definition,
    call: call,
    result: result,
    reportedAt: observedAt,
  );
}

AgentRunRequest _request({Set<String> toolNames = const {}}) => AgentRunRequest(
  runId: 'run-native-1',
  chatId: 'chat-1',
  botId: 'bot-1',
  messages: [ChatMessage(role: 'user', content: 'latest')],
  requestedToolNames: toolNames,
);

final class _EvidenceMcpTool implements ExecutableTool {
  @override
  final ToolDefinition definition = ToolDefinition(
    name: 'mcp.records.read',
    description: 'Read a remote record.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'resource_id': {'type': 'string'},
      },
      'required': ['resource_id'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'state': {'type': 'string'},
        ...toolEvidenceOutputSchemaProperties,
      },
      'required': ['state', ...toolEvidenceOutputRequiredFields],
      'additionalProperties': false,
    },
    source: ToolSource.mcp,
    riskLevel: ToolRiskLevel.readOnly,
    capabilities: const {ToolCapability.network, ToolCapability.externalRead},
    toolVersion: '1.0.0',
    evidenceCapabilities: const {EvidenceKind.observation},
    evidenceScope: ToolEvidenceScopeRule(
      subject: 'resource:record',
      argumentToScope: const {'resource_id': 'resource_id'},
    ),
    defaultEvidenceValidity: const Duration(minutes: 5),
  );

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    final observedAt = DateTime.utc(2026, 9, 5, 10);
    final scope = <String, Object?>{
      'resource_id': call.arguments['resource_id'],
    };
    final facts = [StructuredFact(name: 'record.state', value: 'ready')];
    return ToolResult(
      callId: call.callId,
      name: call.name,
      content: 'ready',
      structuredContent: {
        'state': 'ready',
        ...toolEvidenceOutputMetadata(
          evidenceKind: EvidenceKind.observation,
          subject: 'resource:record',
          scope: scope,
          structuredFacts: facts,
          observedAt: observedAt,
        ),
      },
      source: ToolSource.mcp,
      evidenceKind: EvidenceKind.observation,
      subject: 'resource:record',
      scope: scope,
      structuredFacts: facts,
      observedAt: observedAt,
    );
  }
}

final class _FakeModelSession implements AgentModelSession {
  _FakeModelSession(this.turns);

  final List<List<ModelEvent>> turns;
  var _turn = 0;

  @override
  Stream<ModelEvent> start() => Stream.fromIterable(turns[_turn++]);

  @override
  Stream<ModelEvent> continueWith(List<ToolResult> results) =>
      Stream.fromIterable(turns[_turn++]);

  @override
  Stream<ModelEvent> continueWithReliabilityFeedback(String feedback) =>
      Stream.fromIterable(turns[_turn++]);

  @override
  Stream<ModelEvent> synthesizeGroundedAnswer(
    GroundedAnswerSynthesisRequest request, {
    List<ToolResult> pendingToolResults = const [],
  }) => Stream.fromIterable([
    GroundedAnswerProduced(
      GroundedAnswerCandidate.parseProviderOutput(
        request.draftText,
        allowedEvidenceIds: request.allowedEvidenceIds,
        providerCallToEvidenceId: request.legacyEvidenceAliases,
      ),
    ),
    const ModelTurnCompleted(stopReason: 'stop'),
  ]);

  @override
  Future<void> cancel() async {}

  @override
  void close() {}
}

final class _FakeProvider extends AiProvider {
  _FakeProvider(this.session) : super(_bot);

  final AgentModelSession session;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
    supportsNativeToolEvidence: true,
  );

  @override
  AgentModelSession openModelSession(ModelRequest request) => session;

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final _bot = Bot(
  id: 'bot-1',
  name: 'Test bot',
  avatar: '',
  provider: 'test',
  baseURL: '',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'test',
  systemPrompt: '',
  createTimestamp: DateTime(2026),
  modifyTimestamp: DateTime(2026),
);
