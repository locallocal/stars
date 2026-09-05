import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/grounding_metrics_repository.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/domain/services/grounding_metrics_service.dart';

void main() {
  test(
    'records resolution, persistence, rejection and duplicate counters',
    () async {
      final evidence = _evidence('run-1');
      final metrics = _MetricsRepository();
      final service = GroundingMetricsService(
        repository: metrics,
        evidenceRepository: _EvidenceRepository({
          evidence.evidenceId: evidence,
        }),
      );
      final accepted = AnswerClaim(
        claimId: 'accepted',
        text: 'Accepted fact',
        kind: ClaimKind.currentFact,
        evidenceIds: [evidence.evidenceId],
      );
      final rejected = AnswerClaim(
        claimId: 'rejected',
        text: 'Rejected fact',
        kind: ClaimKind.externalFact,
        evidenceIds: const ['missing-attempt:evidence'],
      );
      final message = Message(
        messageId: 'run-1-assistant',
        turnId: 'run-1-turn',
        runId: 'run-1',
        chatId: 'chat-1',
        botId: 'bot-1',
        senderId: 'bot-1',
        content: 'User-visible answer must not enter metrics.',
        processInfo: const MessageProcessInfo(
          toolCalls: [
            MessageToolCall(
              invocationId: 'write-1',
              providerCallId: 'provider-write-1',
              name: 'notes.write',
              status: 'succeeded',
              riskLevel: 'write',
              resultSummary: 'raw tool response must not enter metrics',
            ),
            MessageToolCall(
              invocationId: 'write-2',
              providerCallId: 'provider-write-1',
              name: 'notes.write',
              status: 'succeeded',
              riskLevel: 'write',
            ),
          ],
        ),
        grounding: MessageGrounding(
          trustLevel: AnswerTrustLevel.partiallyVerified,
          reasonCode: 'some_claims_verified',
          evidenceIds: [evidence.evidenceId],
          claims: [
            MessageClaimGrounding(
              claim: accepted,
              trustLevel: ClaimTrustLevel.verified,
              acceptedEvidenceIds: [evidence.evidenceId],
              reasonCode: 'evidence_accepted',
            ),
            MessageClaimGrounding(
              claim: rejected,
              trustLevel: ClaimTrustLevel.unverified,
              reasonCode: 'evidence_not_found',
            ),
          ],
        ),
        terminalOutcome: MessageTerminalOutcome.completed,
        timestamp: DateTime.utc(2026),
      );

      await service.recordTerminalMessage(message);
      final snapshot = await metrics.snapshot();

      expect(snapshot.total(GroundingMetricName.evidenceReferenceTotal), 2);
      expect(snapshot.total(GroundingMetricName.evidenceReferenceResolved), 1);
      expect(snapshot.evidenceReferenceResolutionRate, .5);
      expect(snapshot.verifiedEvidencePersistenceRate, 1);
      expect(snapshot.total(GroundingMetricName.gateRejection), 1);
      expect(snapshot.total(GroundingMetricName.duplicateSideEffect), 1);
    },
  );

  test(
    'Provider diagnostics and content never cross the metric boundary',
    () async {
      final metrics = _MetricsRepository();
      final service = GroundingMetricsService(
        repository: metrics,
        evidenceRepository: _EvidenceRepository(const {}),
      );
      await service.recordProviderFailure(
        ProviderFailure.transport(
          endpointKind: ProviderEndpointKind.responses,
          cause: StateError(
            'https://provider.test/v1?api_key=secret user-body raw-tool-output',
          ),
        ),
      );
      await service.recordProviderFailure(
        ProviderFailure.invalidResponse(
          endpointKind: ProviderEndpointKind.responses,
        ),
      );

      final stored = metrics.deltas
          .map((delta) => '${delta.name.name}:${delta.category}:${delta.count}')
          .join('|');
      expect(
        stored,
        'providerFailure:transport:1|providerFailure:invalid_response:1',
      );
      expect(stored, isNot(contains('provider.test')));
      expect(stored, isNot(contains('secret')));
      expect(stored, isNot(contains('user-body')));
      expect(stored, isNot(contains('raw-tool-output')));
    },
  );

  test(
    'detects an accepted claim whose evidence is no longer durable',
    () async {
      final evidence = _evidence('run-2');
      final metrics = _MetricsRepository();
      final service = GroundingMetricsService(
        repository: metrics,
        evidenceRepository: _EvidenceRepository(const {}),
      );
      final claim = AnswerClaim(
        claimId: 'claim_1',
        text: 'Fact',
        kind: ClaimKind.currentFact,
        evidenceIds: [evidence.evidenceId],
      );
      await service.recordTerminalMessage(
        Message(
          messageId: 'run-2-assistant',
          turnId: 'run-2-turn',
          runId: 'run-2',
          chatId: 'chat-1',
          botId: 'bot-1',
          senderId: 'bot-1',
          content: 'Fact',
          grounding: MessageGrounding(
            trustLevel: AnswerTrustLevel.verified,
            reasonCode: 'all_evidence_validated',
            evidenceIds: [evidence.evidenceId],
            claims: [
              MessageClaimGrounding(
                claim: claim,
                trustLevel: ClaimTrustLevel.verified,
                acceptedEvidenceIds: [evidence.evidenceId],
              ),
            ],
          ),
          terminalOutcome: MessageTerminalOutcome.completed,
          timestamp: DateTime.utc(2026),
        ),
      );

      final snapshot = await metrics.snapshot();
      expect(snapshot.total(GroundingMetricName.unsupportedClaimPass), 1);
      expect(snapshot.verifiedEvidencePersistenceRate, 0);
      expect(const GroundingReleaseGate().evaluate(snapshot).passes, isFalse);
    },
  );
}

final class _MetricsRepository implements GroundingMetricsRepository {
  final List<GroundingMetricDelta> deltas = [];

  @override
  Future<void> record(
    Iterable<GroundingMetricDelta> values, {
    String observationId = '',
  }) async {
    deltas.addAll(values);
  }

  @override
  Future<GroundingMetricsSnapshot> snapshot() async {
    final counters = <GroundingMetricName, Map<String, int>>{};
    for (final delta in deltas) {
      final categories = counters[delta.name] ??= <String, int>{};
      categories[delta.category] =
          (categories[delta.category] ?? 0) + delta.count;
    }
    return GroundingMetricsSnapshot(counters);
  }
}

final class _EvidenceRepository implements ToolEvidenceRepository {
  const _EvidenceRepository(this.records);

  final Map<String, ToolEvidenceRecord> records;

  @override
  Future<void> commitRun({
    required String runId,
    required String chatId,
    required List<ToolInvocationEvent> invocationEvents,
    required List<ToolEvidenceRecord> evidenceRecords,
  }) async => throw UnimplementedError();

  @override
  Future<ToolEvidenceRecord?> getById(String evidenceId) async =>
      records[evidenceId];

  @override
  Future<List<ToolEvidenceRecord>> getForMessage(String messageId) async =>
      records.values
          .where((evidence) => evidence.messageId == messageId)
          .toList();

  @override
  Future<List<ToolInvocationEvent>> getInvocationEventsForRun(
    String runId,
  ) async => const [];

  @override
  Future<bool> verifyDigest(String evidenceId) async =>
      records.containsKey(evidenceId);
}

ToolEvidenceRecord _evidence(String runId) {
  final attemptId = '$runId-attempt';
  return ToolEvidenceRecord(
    evidenceId: '$attemptId:evidence',
    runId: runId,
    turnId: '$runId-turn',
    chatId: 'chat-1',
    messageId: '$runId-assistant',
    invocationId: '$runId-invocation',
    attemptId: attemptId,
    toolName: 'clock.read',
    toolVersion: '1',
    source: ToolSource.builtIn,
    capabilities: const {ToolCapability.localRead},
    terminalStatus: ToolInvocationStatus.succeeded,
    evidenceKind: EvidenceKind.observation,
    subject: 'clock',
    scope: const {'timezone': 'UTC'},
    resultSummary: 'One normalized fact.',
    argumentsDigest: 'a' * 64,
    resultDigest: 'b' * 64,
    structuredFacts: [StructuredFact(name: 'clock.hour', value: 12)],
    observedAt: DateTime.utc(2026),
    validUntil: DateTime.utc(2027),
    persisted: true,
  );
}
