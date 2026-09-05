import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/domain/services/grounded_answer_validator.dart';
import 'package:stars/domain/use_cases/agent_run_coordinator.dart';

void main() {
  group('AgentRunCoordinator Observe-Verify-Synthesize loop', () {
    test(
      'does not verify or synthesize before terminal evidence commits',
      () async {
        final tool = _CalculationEvidenceTool();
        final evidenceId = _evidenceId(1);
        final session = _LoopModelSession(
          turns: [
            [
              ToolCallRequested(
                callId: 'calculate-1',
                name: tool.definition.name,
                arguments: const {'value': 2},
              ),
              const ModelTurnCompleted(stopReason: 'tool_calls'),
            ],
            [
              const TextDelta('Draft: four.'),
              const ModelTurnCompleted(stopReason: 'stop'),
            ],
          ],
          synthesisCandidates: [
            _candidate(
              text: 'The result is 4.',
              kind: ClaimKind.externalFact,
              evidenceIds: [evidenceId],
            ),
          ],
        );
        final repository = _MemoryEvidenceRepository();
        final terminalCommitStarted = Completer<void>();
        final allowTerminalCommit = Completer<void>();
        final persister = _EvidencePersister(
          repository,
          beforeTerminalCommit: () async {
            if (!terminalCommitStarted.isCompleted) {
              terminalCommitStarted.complete();
            }
            await allowTerminalCommit.future;
          },
        );
        final events = <AgentRunEvent>[];
        final coordinator = _coordinator(
          tool: tool,
          repository: repository,
          persister: persister.call,
        );

        final run = coordinator.run(
          provider: _LoopProvider(session),
          request: _request(
            toolNames: {tool.definition.name},
            requirements: [_calculationRequirement()],
          ),
          onRunEvent: events.add,
        );
        await terminalCommitStarted.future;

        expect(session.synthesisRequests, isEmpty);
        expect(session.continuations, isEmpty);
        expect(
          events.whereType<AgentRunStateChanged>().map((event) => event.phase),
          isNot(contains(AgentRunPhase.verifying)),
        );

        allowTerminalCommit.complete();
        final result = await run;

        expect(result.status, AgentRunStatus.completed, reason: result.error);
        expect(
          result.groundedValidation?.trustLevel,
          AnswerTrustLevel.verified,
        );
        expect(repository.records, contains(evidenceId));
        expect(session.synthesisRequests, hasLength(1));
        expect(result.toolInvocations.single.runId, 'run-1');
        expect(events, everyElement(isA<AgentRunEvent>()));
        expect(events.map((event) => event.runId).toSet(), {'run-1'});
        expect(
          result.stateTransitions.map((event) => event.phase),
          containsAllInOrder([
            AgentRunPhase.planning,
            AgentRunPhase.executing,
            AgentRunPhase.observing,
            AgentRunPhase.verifying,
            AgentRunPhase.synthesizing,
            AgentRunPhase.committing,
            AgentRunPhase.completed,
          ]),
        );
      },
    );

    test(
      'sends missing-evidence feedback and continues within budget',
      () async {
        final tool = _CalculationEvidenceTool();
        final evidenceId = _evidenceId(1);
        final session = _LoopModelSession(
          turns: [
            [
              const TextDelta('I need evidence.'),
              const ModelTurnCompleted(stopReason: 'stop'),
            ],
            [
              ToolCallRequested(
                callId: 'calculate-after-feedback',
                name: tool.definition.name,
                arguments: const {'value': 2},
              ),
              const ModelTurnCompleted(stopReason: 'tool_calls'),
            ],
            [
              const TextDelta('Draft after observation.'),
              const ModelTurnCompleted(stopReason: 'stop'),
            ],
          ],
          synthesisCandidates: [
            _candidate(
              text: 'The result is 4.',
              kind: ClaimKind.externalFact,
              evidenceIds: [evidenceId],
            ),
          ],
        );
        final repository = _MemoryEvidenceRepository();
        final coordinator = _coordinator(
          tool: tool,
          repository: repository,
          persister: _EvidencePersister(repository).call,
        );

        final result = await coordinator.run(
          provider: _LoopProvider(session),
          request: _request(
            toolNames: {tool.definition.name},
            requirements: [_calculationRequirement()],
          ),
        );

        expect(result.status, AgentRunStatus.completed, reason: result.error);
        expect(
          result.groundedValidation?.trustLevel,
          AnswerTrustLevel.verified,
        );
        expect(tool.executions, 1);
        expect(session.reliabilityFeedback, hasLength(1));
        expect(
          session.reliabilityFeedback.single,
          contains('stars_missing_evidence'),
        );
        expect(
          session.reliabilityFeedback.single,
          contains('"run_id":"run-1"'),
        );
        expect(result.degradedReason, isEmpty);
      },
    );

    test(
      'degrades when missing evidence exhausts the observation budget',
      () async {
        final session = _LoopModelSession(
          turns: [
            [
              const TextDelta('Unsupported draft.'),
              const ModelTurnCompleted(stopReason: 'stop'),
            ],
          ],
          synthesisCandidates: [
            _candidate(
              text: 'The unsupported result is 4.',
              kind: ClaimKind.externalFact,
            ),
          ],
        );
        final repository = _MemoryEvidenceRepository();
        final coordinator = AgentRunCoordinator(
          toolRegistry: StaticToolRegistry(const []),
          toolPolicy: const DefaultToolPolicy(),
          limits: const AgentRunLimits(
            maxModelTurns: 1,
            maxReliabilityRepairs: 0,
          ),
          groundedAnswerValidator: GroundedAnswerValidator(
            evidenceRepository: repository,
          ),
        );

        final result = await coordinator.run(
          provider: _LoopProvider(session),
          request: _request(
            toolNames: const {},
            requirements: [_calculationRequirement()],
          ),
        );

        expect(result.status, AgentRunStatus.completed, reason: result.error);
        expect(result.degradedReason, 'verification_budget_exhausted');
        expect(
          result.groundedValidation?.trustLevel,
          AnswerTrustLevel.unverified,
        );
        expect(result.text, 'The unsupported result is 4.');
        expect(session.reliabilityFeedback, isEmpty);
      },
    );

    test(
      'does not request more evidence after tool-call budget is spent',
      () async {
        final tool = _CalculationEvidenceTool();
        final evidenceId = _evidenceId(1);
        final session = _LoopModelSession(
          turns: [
            [
              ToolCallRequested(
                callId: 'calculate-1',
                name: tool.definition.name,
                arguments: const {'value': 2},
              ),
              const ModelTurnCompleted(stopReason: 'tool_calls'),
            ],
            [
              const TextDelta('Draft with mismatched evidence.'),
              const ModelTurnCompleted(stopReason: 'stop'),
            ],
          ],
          synthesisCandidates: [
            _candidate(
              text: 'The result is 4.',
              kind: ClaimKind.externalFact,
              evidenceIds: [evidenceId],
            ),
          ],
        );
        final repository = _MemoryEvidenceRepository();
        final coordinator = AgentRunCoordinator(
          toolRegistry: StaticToolRegistry([tool]),
          toolPolicy: const DefaultToolPolicy(),
          limits: const AgentRunLimits(
            maxToolCalls: 1,
            maxReliabilityRepairs: 0,
          ),
          toolInvocationPersister: _EvidencePersister(repository).call,
          groundedAnswerValidator: GroundedAnswerValidator(
            evidenceRepository: repository,
          ),
        );

        final result = await coordinator.run(
          provider: _LoopProvider(session),
          request: _request(
            toolNames: {tool.definition.name},
            requirements: [
              ClaimEvidenceRequirement(
                claimId: 'claim-1',
                claimKind: ClaimKind.externalFact,
                allowedEvidenceKinds: const {EvidenceKind.calculation},
                subject: 'calculation:different',
                scope: const {'value': 2},
                requiredCapabilities: const {ToolCapability.compute},
                requiredFactNames: const {'calculation.result'},
              ),
            ],
          ),
        );

        expect(result.status, AgentRunStatus.completed, reason: result.error);
        expect(result.degradedReason, 'verification_budget_exhausted');
        expect(
          result.groundedValidation?.trustLevel,
          AnswerTrustLevel.unverified,
        );
        expect(session.reliabilityFeedback, isEmpty);
        expect(tool.executions, 1);
      },
    );

    test(
      'repairs synthesis once without repeating a write side effect',
      () async {
        final tool = _ActionEvidenceTool();
        final evidenceId = _evidenceId(1);
        final session = _LoopModelSession(
          turns: [
            [
              ToolCallRequested(
                callId: 'write-1',
                name: tool.definition.name,
                arguments: const {'note_id': 'note-1'},
              ),
              const ModelTurnCompleted(stopReason: 'tool_calls'),
            ],
            [
              const TextDelta('Draft write result.'),
              const ModelTurnCompleted(stopReason: 'stop'),
            ],
          ],
          synthesisCandidates: [
            _candidate(
              text: 'The note now contains the final content.',
              kind: ClaimKind.currentFact,
              evidenceIds: [evidenceId],
            ),
            _candidate(
              text: 'The save tool reported that the action completed.',
              kind: ClaimKind.completedAction,
              evidenceIds: [evidenceId],
            ),
          ],
        );
        final repository = _MemoryEvidenceRepository();
        final coordinator = AgentRunCoordinator(
          toolRegistry: StaticToolRegistry([tool]),
          toolPolicy: const _AllowToolPolicy(),
          toolInvocationPersister: _EvidencePersister(repository).call,
          groundedAnswerValidator: GroundedAnswerValidator(
            evidenceRepository: repository,
          ),
        );

        final result = await coordinator.run(
          provider: _LoopProvider(session),
          request: _request(
            toolNames: {tool.definition.name},
            requirements: [_actionRequirement()],
          ),
        );

        expect(result.status, AgentRunStatus.completed, reason: result.error);
        expect(
          result.groundedValidation?.trustLevel,
          AnswerTrustLevel.verified,
        );
        expect(tool.executions, 1);
        expect(session.synthesisRequests, hasLength(2));
        expect(session.synthesisRequests.first.reliabilityFeedback, isEmpty);
        expect(
          session.synthesisRequests.last.reliabilityFeedback,
          contains('stars_grounded_answer_repair'),
        );
        expect(
          result.stateTransitions.where(
            (event) => event.phase == AgentRunPhase.synthesizing,
          ),
          hasLength(2),
        );
      },
    );

    test('verifies a local write with a paired read observation', () async {
      final write = _PostWriteEvidenceTool(
        name: 'local_write',
        source: ToolSource.builtIn,
        riskLevel: ToolRiskLevel.write,
        capabilities: const {ToolCapability.localWrite},
      );
      final read = _PostReadEvidenceTool(
        name: 'local_read',
        source: ToolSource.builtIn,
        capabilities: const {ToolCapability.localRead},
      );
      final session = _LoopModelSession(
        turns: [
          [
            ToolCallRequested(
              callId: 'write-1',
              name: write.definition.name,
              arguments: const {'resource_id': 'item-1'},
            ),
            const ModelTurnCompleted(stopReason: 'tool_calls'),
          ],
          [
            const TextDelta('The write needs independent verification.'),
            const ModelTurnCompleted(stopReason: 'stop'),
          ],
          [
            ToolCallRequested(
              callId: 'read-1',
              name: read.definition.name,
              arguments: const {'resource_id': 'item-1'},
            ),
            const ModelTurnCompleted(stopReason: 'tool_calls'),
          ],
          [
            const TextDelta('The persisted resource is version 2.'),
            const ModelTurnCompleted(stopReason: 'stop'),
          ],
        ],
        synthesisCandidates: [
          _postWriteCandidate(
            actionEvidenceId: _evidenceId(1),
            stateEvidenceId: _evidenceId(2),
          ),
        ],
      );
      final repository = _MemoryEvidenceRepository();
      final coordinator = AgentRunCoordinator(
        toolRegistry: StaticToolRegistry([write, read]),
        toolPolicy: const _AllowToolPolicy(),
        toolInvocationPersister: _EvidencePersister(repository).call,
        groundedAnswerValidator: GroundedAnswerValidator(
          evidenceRepository: repository,
        ),
      );

      final result = await coordinator.run(
        provider: _LoopProvider(session),
        request: _request(
          toolNames: {write.definition.name, read.definition.name},
          requirements: const [],
        ),
      );

      expect(result.status, AgentRunStatus.completed, reason: result.error);
      expect(result.groundedValidation?.trustLevel, AnswerTrustLevel.verified);
      expect(write.executions, 1);
      expect(read.executions, 1);
      expect(result.verificationRequirements, hasLength(2));
      expect(session.reliabilityFeedback.single, contains('local_read'));
      expect(session.synthesisRequests.single.requiredClaims, hasLength(2));
    });

    test('MCP read failure cannot verify the final state', () async {
      for (final isIdempotent in <bool>[true, false]) {
        final outcome = await _runMcpWriteVerification(
          readFails: true,
          runtimeReadSubject: 'resource:item',
          isIdempotent: isIdempotent,
        );

        expect(outcome.result.status, AgentRunStatus.completed);
        expect(
          outcome.result.groundedValidation?.trustLevel,
          AnswerTrustLevel.partiallyVerified,
        );
        expect(outcome.result.degradedReason, 'verification_budget_exhausted');
        expect(outcome.write.definition.isIdempotent, isIdempotent);
        expect(outcome.write.executions, 1);
        expect(outcome.read.executions, 1);
        expect(
          outcome.result.groundedAnswer?.claims.single.kind,
          ClaimKind.completedAction,
        );
      }
    });

    test('MCP read with a different subject cannot verify the write', () async {
      final outcome = await _runMcpWriteVerification(
        readFails: false,
        runtimeReadSubject: 'resource:other',
      );

      expect(outcome.result.status, AgentRunStatus.completed);
      expect(
        outcome.result.groundedValidation?.trustLevel,
        AnswerTrustLevel.partiallyVerified,
      );
      expect(outcome.write.executions, 1);
      expect(outcome.read.executions, 1);
      expect(
        outcome.result.toolInvocations.last.errorCode,
        'tool_evidence_scope_mismatch',
      );
    });

    test(
      'shell post-write repair reports only the receipt and never reruns',
      () async {
        final shell = _PostWriteEvidenceTool(
          name: 'shell_write',
          source: ToolSource.builtIn,
          riskLevel: ToolRiskLevel.destructive,
          capabilities: const {
            ToolCapability.process,
            ToolCapability.localWrite,
          },
        );
        final actionId = _postWriteActionClaimId;
        final stateId = _postWriteStateClaimId;
        final receiptId = _evidenceId(1);
        final session = _LoopModelSession(
          turns: [
            [
              ToolCallRequested(
                callId: 'shell-1',
                name: shell.definition.name,
                arguments: const {'resource_id': 'item-1'},
              ),
              const ModelTurnCompleted(stopReason: 'tool_calls'),
            ],
            [
              const TextDelta('The command reported success.'),
              const ModelTurnCompleted(stopReason: 'stop'),
            ],
          ],
          synthesisCandidates: [
            GroundedAnswerCandidate(
              claims: [
                AnswerClaim(
                  claimId: stateId,
                  text: 'The resource is definitely version 2.',
                  kind: ClaimKind.currentFact,
                  evidenceIds: [receiptId],
                ),
              ],
            ),
            GroundedAnswerCandidate(
              claims: [
                AnswerClaim(
                  claimId: actionId,
                  text: 'The shell tool reported that the action completed.',
                  kind: ClaimKind.completedAction,
                  evidenceIds: [receiptId],
                ),
              ],
            ),
          ],
        );
        final repository = _MemoryEvidenceRepository();
        final coordinator = AgentRunCoordinator(
          toolRegistry: StaticToolRegistry([shell]),
          toolPolicy: const _AllowToolPolicy(),
          toolInvocationPersister: _EvidencePersister(repository).call,
          groundedAnswerValidator: GroundedAnswerValidator(
            evidenceRepository: repository,
          ),
        );

        final result = await coordinator.run(
          provider: _LoopProvider(session),
          request: _request(
            toolNames: {shell.definition.name},
            requirements: const [],
          ),
        );

        expect(result.status, AgentRunStatus.completed, reason: result.error);
        expect(result.degradedReason, 'post_write_verification_unavailable');
        expect(
          result.groundedValidation?.trustLevel,
          AnswerTrustLevel.partiallyVerified,
        );
        expect(
          result.groundedAnswer?.claims.single.kind,
          ClaimKind.completedAction,
        );
        expect(shell.executions, 1);
        expect(session.synthesisRequests, hasLength(2));
      },
    );

    test('total timeout cancels a run blocked in verification', () async {
      final tool = _CalculationEvidenceTool();
      final session = _LoopModelSession(
        turns: [
          [
            ToolCallRequested(
              callId: 'calculate-1',
              name: tool.definition.name,
              arguments: const {'value': 2},
            ),
            const ModelTurnCompleted(stopReason: 'tool_calls'),
          ],
        ],
        synthesisCandidates: const [],
      );
      final repository = _MemoryEvidenceRepository(hangOnRead: true);
      final coordinator = AgentRunCoordinator(
        toolRegistry: StaticToolRegistry([tool]),
        toolPolicy: const DefaultToolPolicy(),
        limits: const AgentRunLimits(totalTimeout: Duration(milliseconds: 30)),
        toolInvocationPersister: _EvidencePersister(repository).call,
        groundedAnswerValidator: GroundedAnswerValidator(
          evidenceRepository: repository,
        ),
      );

      final result = await coordinator.run(
        provider: _LoopProvider(session),
        request: _request(
          toolNames: {tool.definition.name},
          requirements: [_calculationRequirement()],
        ),
      );

      expect(result.status, AgentRunStatus.timedOut);
      expect(result.error, 'agent_run_timeout');
      expect(session.cancelled, isTrue);
      expect(result.stateTransitions.last.phase, AgentRunPhase.timedOut);
      expect(session.synthesisRequests, isEmpty);
    });
  });
}

AgentRunCoordinator _coordinator({
  required ExecutableTool tool,
  required _MemoryEvidenceRepository repository,
  required ToolInvocationPersister persister,
}) => AgentRunCoordinator(
  toolRegistry: StaticToolRegistry([tool]),
  toolPolicy: const DefaultToolPolicy(),
  toolInvocationPersister: persister,
  groundedAnswerValidator: GroundedAnswerValidator(
    evidenceRepository: repository,
  ),
);

AgentRunRequest _request({
  required Set<String> toolNames,
  required List<ClaimEvidenceRequirement> requirements,
}) => AgentRunRequest(
  runId: 'run-1',
  turnId: 'turn-1',
  messageId: 'message-1',
  chatId: 'chat-1',
  botId: 'bot-1',
  messages: [ChatMessage(role: 'user', content: 'Verify this request.')],
  requestedToolNames: toolNames,
  verificationRequirements: requirements,
);

ClaimEvidenceRequirement _calculationRequirement() => ClaimEvidenceRequirement(
  claimId: 'claim-1',
  claimKind: ClaimKind.externalFact,
  allowedEvidenceKinds: const {EvidenceKind.calculation},
  subject: 'calculation:double',
  scope: const {'value': 2},
  requiredCapabilities: const {ToolCapability.compute},
  requiredFactNames: const {'calculation.result'},
);

ClaimEvidenceRequirement _actionRequirement() => ClaimEvidenceRequirement(
  claimId: 'claim-1',
  claimKind: ClaimKind.completedAction,
  allowedEvidenceKinds: const {EvidenceKind.actionReceipt},
  subject: 'note:item',
  scope: const {'note_id': 'note-1'},
  requiredCapabilities: const {ToolCapability.externalWrite},
  requiredFactNames: const {'action.completed'},
);

GroundedAnswerCandidate _candidate({
  required String text,
  required ClaimKind kind,
  List<String> evidenceIds = const [],
}) => GroundedAnswerCandidate(
  claims: [
    AnswerClaim(
      claimId: 'claim-1',
      text: text,
      kind: kind,
      evidenceIds: evidenceIds,
    ),
  ],
);

const _postWriteActionClaimId = 'run-1:invocation:1:attempt:1:action';
const _postWriteStateClaimId = 'run-1:invocation:1:attempt:1:state';

GroundedAnswerCandidate _postWriteCandidate({
  required String actionEvidenceId,
  required String stateEvidenceId,
}) => GroundedAnswerCandidate(
  claims: [
    AnswerClaim(
      claimId: _postWriteActionClaimId,
      text: 'The write tool reported that the action completed.',
      kind: ClaimKind.completedAction,
      evidenceIds: [actionEvidenceId],
    ),
    AnswerClaim(
      claimId: _postWriteStateClaimId,
      text: 'The independent read observed resource version 2.',
      kind: ClaimKind.currentFact,
      evidenceIds: [stateEvidenceId],
    ),
  ],
);

Future<
  ({
    AgentRunResult result,
    _PostWriteEvidenceTool write,
    _PostReadEvidenceTool read,
  })
>
_runMcpWriteVerification({
  required bool readFails,
  required String runtimeReadSubject,
  bool isIdempotent = false,
}) async {
  final write = _PostWriteEvidenceTool(
    name: 'mcp_write',
    source: ToolSource.mcp,
    riskLevel: ToolRiskLevel.write,
    capabilities: const {ToolCapability.network, ToolCapability.externalWrite},
    mcpServerName: 'server-1',
    isIdempotent: isIdempotent,
  );
  final read = _PostReadEvidenceTool(
    name: 'mcp_read',
    source: ToolSource.mcp,
    capabilities: const {ToolCapability.network, ToolCapability.externalRead},
    mcpServerName: 'server-1',
    fails: readFails,
    runtimeSubject: runtimeReadSubject,
  );
  final session = _LoopModelSession(
    turns: [
      [
        ToolCallRequested(
          callId: 'write-1',
          name: write.definition.name,
          arguments: const {'resource_id': 'item-1'},
        ),
        const ModelTurnCompleted(stopReason: 'tool_calls'),
      ],
      [
        const TextDelta('The write needs verification.'),
        const ModelTurnCompleted(stopReason: 'stop'),
      ],
      [
        ToolCallRequested(
          callId: 'read-1',
          name: read.definition.name,
          arguments: const {'resource_id': 'item-1'},
        ),
        const ModelTurnCompleted(stopReason: 'tool_calls'),
      ],
      [
        const TextDelta('Only the action receipt remains supported.'),
        const ModelTurnCompleted(stopReason: 'stop'),
      ],
    ],
    synthesisCandidates: [
      GroundedAnswerCandidate(
        claims: [
          AnswerClaim(
            claimId: _postWriteActionClaimId,
            text: 'The MCP tool reported that the action completed.',
            kind: ClaimKind.completedAction,
            evidenceIds: [_evidenceId(1)],
          ),
        ],
      ),
    ],
  );
  final repository = _MemoryEvidenceRepository();
  final coordinator = AgentRunCoordinator(
    toolRegistry: StaticToolRegistry([write, read]),
    toolPolicy: const _AllowToolPolicy(),
    limits: const AgentRunLimits(maxModelTurns: 4, maxReliabilityRepairs: 0),
    toolInvocationPersister: _EvidencePersister(repository).call,
    groundedAnswerValidator: GroundedAnswerValidator(
      evidenceRepository: repository,
    ),
  );
  final result = await coordinator.run(
    provider: _LoopProvider(session),
    request: _request(
      toolNames: {write.definition.name, read.definition.name},
      requirements: const [],
    ),
  );
  return (result: result, write: write, read: read);
}

String _evidenceId(int invocation) =>
    'run-1:invocation:$invocation:attempt:1:evidence';

final class _LoopModelSession implements AgentModelSession {
  _LoopModelSession({
    required List<List<ModelEvent>> turns,
    required List<GroundedAnswerCandidate> synthesisCandidates,
  }) : _turns = List<List<ModelEvent>>.of(turns),
       _synthesisCandidates = List<GroundedAnswerCandidate>.of(
         synthesisCandidates,
       );

  final List<List<ModelEvent>> _turns;
  final List<GroundedAnswerCandidate> _synthesisCandidates;
  final List<List<ToolResult>> continuations = <List<ToolResult>>[];
  final List<String> reliabilityFeedback = <String>[];
  final List<GroundedAnswerSynthesisRequest> synthesisRequests =
      <GroundedAnswerSynthesisRequest>[];
  var _turnIndex = 0;
  var _synthesisIndex = 0;
  bool cancelled = false;

  @override
  Stream<ModelEvent> start() => _nextTurn();

  @override
  Stream<ModelEvent> continueWith(List<ToolResult> results) {
    continuations.add(List<ToolResult>.of(results));
    return _nextTurn();
  }

  @override
  Stream<ModelEvent> continueWithReliabilityFeedback(String feedback) {
    reliabilityFeedback.add(feedback);
    return _nextTurn();
  }

  @override
  Stream<ModelEvent> synthesizeGroundedAnswer(
    GroundedAnswerSynthesisRequest request,
  ) async* {
    synthesisRequests.add(request);
    final candidate = _synthesisCandidates[_synthesisIndex++];
    yield GroundedAnswerProduced(candidate);
    yield const ModelTurnCompleted(stopReason: 'stop');
  }

  Stream<ModelEvent> _nextTurn() =>
      Stream<ModelEvent>.fromIterable(_turns[_turnIndex++]);

  @override
  Future<void> cancel() async {
    cancelled = true;
  }

  @override
  void close() {}
}

final class _LoopProvider extends AiProvider {
  _LoopProvider(this.session) : super(_bot);

  final AgentModelSession session;

  @override
  AiProviderCapabilities get capabilities => const AiProviderCapabilities(
    supportsStructuredToolCalls: true,
    supportsToolResults: true,
  );

  @override
  AgentModelSession openModelSession(ModelRequest request) => session;

  @override
  Future<void> generateText(List<ChatMessage> messages) async {}
}

final class _CalculationEvidenceTool implements ExecutableTool {
  @override
  final ToolDefinition definition = ToolDefinition(
    name: 'evidence_calculate',
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

  int executions = 0;

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
    final observedAt = DateTime.now().toUtc().subtract(
      const Duration(seconds: 1),
    );
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

final class _ActionEvidenceTool implements ExecutableTool {
  @override
  final ToolDefinition definition = ToolDefinition(
    name: 'save_note',
    description: 'Save a note.',
    inputSchema: const {
      'type': 'object',
      'properties': {
        'note_id': {'type': 'string'},
      },
      'required': ['note_id'],
      'additionalProperties': false,
    },
    outputSchema: const {
      'type': 'object',
      'properties': {
        'saved': {'type': 'boolean'},
        ...toolEvidenceOutputSchemaProperties,
      },
      'required': ['saved', ...toolEvidenceOutputRequiredFields],
      'additionalProperties': false,
    },
    source: ToolSource.builtIn,
    riskLevel: ToolRiskLevel.write,
    capabilities: const {ToolCapability.externalWrite},
    toolVersion: '1.0.0',
    evidenceCapabilities: const {EvidenceKind.actionReceipt},
    evidenceScope: ToolEvidenceScopeRule(
      subject: 'note:item',
      argumentToScope: const {'note_id': 'note_id'},
    ),
  );

  int executions = 0;

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    executions += 1;
    final scope = <String, Object?>{'note_id': call.arguments['note_id']};
    final facts = [StructuredFact(name: 'action.completed', value: true)];
    final observedAt = DateTime.now().toUtc().subtract(
      const Duration(seconds: 1),
    );
    return ToolResult(
      callId: call.callId,
      name: call.name,
      content: 'saved',
      structuredContent: {
        'saved': true,
        ...toolEvidenceOutputMetadata(
          evidenceKind: EvidenceKind.actionReceipt,
          subject: 'note:item',
          scope: scope,
          structuredFacts: facts,
          observedAt: observedAt,
        ),
      },
      evidenceKind: EvidenceKind.actionReceipt,
      subject: 'note:item',
      scope: scope,
      structuredFacts: facts,
      observedAt: observedAt,
    );
  }
}

final class _PostWriteEvidenceTool implements ExecutableTool {
  _PostWriteEvidenceTool({
    required String name,
    required ToolSource source,
    required ToolRiskLevel riskLevel,
    required Set<ToolCapability> capabilities,
    String mcpServerName = '',
    bool isIdempotent = false,
  }) : definition = ToolDefinition(
         name: name,
         mcpServerName: mcpServerName,
         description: 'Write a versioned resource.',
         inputSchema: const {
           'type': 'object',
           'properties': {
             'resource_id': {'type': 'string'},
           },
           'required': ['resource_id'],
           'additionalProperties': false,
         },
         outputSchema: _postWriteEvidenceSchema,
         source: source,
         riskLevel: riskLevel,
         capabilities: capabilities,
         toolVersion: '1.0.0',
         evidenceCapabilities: const {EvidenceKind.actionReceipt},
         evidenceScope: ToolEvidenceScopeRule(
           subject: 'resource:item',
           argumentToScope: const {'resource_id': 'resource_id'},
         ),
         requiresReadAfterWrite: true,
         isIdempotent: isIdempotent,
       );

  @override
  final ToolDefinition definition;

  int executions = 0;

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    executions += 1;
    final scope = <String, Object?>{
      'resource_id': call.arguments['resource_id'],
    };
    final facts = <StructuredFact>[
      StructuredFact(name: 'action.completed', value: true),
      StructuredFact(name: 'resource.version', value: 2),
      StructuredFact(name: 'resource.digest', value: 'digest-2'),
    ];
    final observedAt = DateTime.now().toUtc().subtract(
      const Duration(seconds: 1),
    );
    return ToolResult(
      callId: call.callId,
      name: call.name,
      content: 'write completed',
      structuredContent: {
        'ok': true,
        ...toolEvidenceOutputMetadata(
          evidenceKind: EvidenceKind.actionReceipt,
          subject: 'resource:item',
          scope: scope,
          structuredFacts: facts,
          observedAt: observedAt,
        ),
      },
      evidenceKind: EvidenceKind.actionReceipt,
      subject: 'resource:item',
      scope: scope,
      structuredFacts: facts,
      observedAt: observedAt,
    );
  }
}

final class _PostReadEvidenceTool implements ExecutableTool {
  _PostReadEvidenceTool({
    required String name,
    required ToolSource source,
    required Set<ToolCapability> capabilities,
    String mcpServerName = '',
    this.fails = false,
    this.runtimeSubject = 'resource:item',
  }) : definition = ToolDefinition(
         name: name,
         mcpServerName: mcpServerName,
         description: 'Read a versioned resource.',
         inputSchema: const {
           'type': 'object',
           'properties': {
             'resource_id': {'type': 'string'},
           },
           'required': ['resource_id'],
           'additionalProperties': false,
         },
         outputSchema: _postWriteEvidenceSchema,
         source: source,
         riskLevel: ToolRiskLevel.readOnly,
         capabilities: capabilities,
         toolVersion: '1.0.0',
         evidenceCapabilities: const {EvidenceKind.observation},
         evidenceScope: ToolEvidenceScopeRule(
           subject: 'resource:item',
           argumentToScope: const {'resource_id': 'resource_id'},
         ),
         defaultEvidenceValidity: const Duration(minutes: 5),
       );

  @override
  final ToolDefinition definition;
  final bool fails;
  final String runtimeSubject;

  int executions = 0;

  @override
  Future<ToolResult> execute(
    ToolCallRequest call,
    AgentCancellationToken cancellationToken,
  ) async {
    executions += 1;
    if (fails) {
      return ToolResult(
        callId: call.callId,
        name: call.name,
        content: 'read failed',
        isError: true,
        errorCode: 'read_failed',
      );
    }
    final scope = <String, Object?>{
      'resource_id': call.arguments['resource_id'],
    };
    final facts = <StructuredFact>[
      StructuredFact(name: 'resource.version', value: 2),
      StructuredFact(name: 'resource.digest', value: 'digest-2'),
    ];
    final observedAt = DateTime.now().toUtc().subtract(
      const Duration(seconds: 1),
    );
    return ToolResult(
      callId: call.callId,
      name: call.name,
      content: 'version 2',
      structuredContent: {
        'ok': true,
        ...toolEvidenceOutputMetadata(
          evidenceKind: EvidenceKind.observation,
          subject: runtimeSubject,
          scope: scope,
          structuredFacts: facts,
          observedAt: observedAt,
        ),
      },
      evidenceKind: EvidenceKind.observation,
      subject: runtimeSubject,
      scope: scope,
      structuredFacts: facts,
      observedAt: observedAt,
    );
  }
}

const Map<String, Object?> _postWriteEvidenceSchema = {
  'type': 'object',
  'properties': {
    'ok': {'type': 'boolean'},
    ...toolEvidenceOutputSchemaProperties,
  },
  'required': ['ok', ...toolEvidenceOutputRequiredFields],
  'additionalProperties': false,
};

final class _AllowToolPolicy implements ToolPolicy {
  const _AllowToolPolicy();

  @override
  ToolPolicyDecision evaluate(
    ToolDefinition definition,
    ToolCallRequest call,
    ToolPolicyContext context,
  ) => const ToolPolicyDecision.allow();
}

final class _EvidencePersister {
  const _EvidencePersister(this.repository, {this.beforeTerminalCommit});

  final _MemoryEvidenceRepository repository;
  final Future<void> Function()? beforeTerminalCommit;

  Future<void> call(ToolExecutionRecord record) async {
    final candidate = record.evidenceCandidate;
    if (record.status != ToolInvocationStatus.succeeded || candidate == null) {
      return;
    }
    await beforeTerminalCommit?.call();
    final evidence = ToolEvidenceRecord(
      evidenceId: ToolEvidenceRecord.evidenceIdForAttempt(record.attemptId),
      runId: record.runId,
      turnId: record.turnId,
      chatId: record.chatId,
      messageId: record.messageId,
      invocationId: record.invocationId,
      attemptId: record.attemptId,
      providerCallId: record.providerCallId,
      toolName: record.name,
      toolVersion: candidate.toolVersion,
      source: record.source,
      capabilities: candidate.capabilities,
      terminalStatus: record.status,
      evidenceKind: candidate.evidenceKind,
      subject: candidate.subject,
      scope: candidate.scope,
      resultSummary: '${record.name} produced evidence.',
      argumentsDigest: candidate.argumentsDigest,
      resultDigest: candidate.resultDigest,
      structuredFacts: candidate.structuredFacts,
      observedAt: candidate.observedAt,
      validUntil: candidate.validUntil,
      persisted: true,
    );
    repository.records[evidence.evidenceId] = evidence;
  }
}

final class _MemoryEvidenceRepository implements ToolEvidenceRepository {
  _MemoryEvidenceRepository({this.hangOnRead = false});

  final bool hangOnRead;
  final Map<String, ToolEvidenceRecord> records =
      <String, ToolEvidenceRecord>{};

  @override
  Future<ToolEvidenceRecord?> getById(String evidenceId) {
    if (hangOnRead) return Completer<ToolEvidenceRecord?>().future;
    return Future<ToolEvidenceRecord?>.value(records[evidenceId]);
  }

  @override
  Future<bool> verifyDigest(String evidenceId) async =>
      records.containsKey(evidenceId);

  @override
  Future<void> commitRun({
    required String runId,
    required String chatId,
    required List<ToolInvocationEvent> invocationEvents,
    required List<ToolEvidenceRecord> evidenceRecords,
  }) async {
    for (final evidence in evidenceRecords) {
      records[evidence.evidenceId] = evidence;
    }
  }

  @override
  Future<List<ToolEvidenceRecord>> getForMessage(String messageId) async =>
      records.values
          .where((evidence) => evidence.messageId == messageId)
          .toList(growable: false);

  @override
  Future<List<ToolInvocationEvent>> getInvocationEventsForRun(
    String runId,
  ) async => const [];
}

final _bot = Bot(
  id: 'bot-1',
  name: 'Loop Bot',
  avatar: '',
  provider: 'test',
  baseURL: '',
  apiKey: '',
  apiType: Bot.apiTypeOpenAI,
  model: 'test-model',
  systemPrompt: 'test',
  createTimestamp: DateTime.utc(2026),
  modifyTimestamp: DateTime.utc(2026),
);
