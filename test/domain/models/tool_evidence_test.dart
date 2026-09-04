import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/tool.dart';

void main() {
  group('StructuredFact', () {
    test('deeply copies and freezes JSON values and attributes', () {
      final labels = <Object?>['current'];
      final value = <String, Object?>{'count': 2, 'labels': labels};
      final attributes = <String, Object?>{
        'source': <String, Object?>{'field': 'count'},
      };
      final fact = StructuredFact(
        name: 'resource.count',
        value: value,
        unit: 'items',
        attributes: attributes,
      );

      labels.add('mutated');
      value['count'] = 99;
      (attributes['source']! as Map<String, Object?>)['field'] = 'changed';

      final frozenValue = fact.value as Map<String, Object?>;
      expect(frozenValue['count'], 2);
      expect(frozenValue['labels'], ['current']);
      expect(fact.attributes['source'], {'field': 'count'});
      expect(() => frozenValue['count'] = 3, throwsUnsupportedError);
      expect(
        () => (frozenValue['labels']! as List<Object?>).add('blocked'),
        throwsUnsupportedError,
      );
      expect(
        () =>
            (fact.attributes['source']! as Map<String, Object?>)['field'] =
                'blocked',
        throwsUnsupportedError,
      );
    });

    test('rejects empty or non-JSON facts', () {
      expect(
        () => StructuredFact(name: 'resource.value', value: ''),
        throwsArgumentError,
      );
      expect(
        () => StructuredFact(name: 'resource.value', value: const []),
        throwsArgumentError,
      );
      expect(
        () => StructuredFact(name: 'resource.value', value: DateTime.utc(2026)),
        throwsArgumentError,
      );
      expect(
        () => StructuredFact(name: 'not normalized', value: 1),
        throwsArgumentError,
      );
    });
  });

  group('ToolInvocationEvent', () {
    test('represents lifecycle events without turning them into evidence', () {
      final requested = _event(status: ToolInvocationStatus.requested);
      final completed = _event(
        eventId: 'run-1:invocation:1:attempt:1:event:2',
        sequence: 2,
        status: ToolInvocationStatus.succeeded,
      );

      expect(requested.isTerminal, isFalse);
      expect(completed.isTerminal, isTrue);
      expect(requested.providerCallId, 'provider-call-1');
      expect(
        ToolInvocationEvent.eventIdForAttempt(
          'run-1:invocation:1:attempt:1',
          2,
        ),
        'run-1:invocation:1:attempt:1:event:2',
      );
    });

    test('validates application identities, sequence, and Provider IDs', () {
      expect(() => _event(eventId: ''), throwsArgumentError);
      expect(() => _event(eventId: 'event-1'), throwsArgumentError);
      expect(() => _event(runId: ' run-1'), throwsArgumentError);
      expect(() => _event(sequence: 0), throwsArgumentError);
      expect(
        () => _event(providerCallId: 'provider\ncall'),
        throwsArgumentError,
      );
      expect(
        () => _event(
          eventId: 'provider-call-1',
          providerCallId: 'provider-call-1',
        ),
        throwsArgumentError,
      );
    });
  });

  group('ToolEvidenceRecord business evidence', () {
    test('constructs typed observation, calculation, and action receipt', () {
      final observation = _observation(persisted: true);
      final calculation = _businessEvidence(
        evidenceKind: EvidenceKind.calculation,
        capabilities: {ToolCapability.compute},
        fact: StructuredFact(name: 'calculation.result', value: 4),
      );
      final receipt = _businessEvidence(
        evidenceKind: EvidenceKind.actionReceipt,
        capabilities: {ToolCapability.externalWrite},
        fact: StructuredFact(name: 'action.accepted', value: true),
      );

      expect(observation.canSupportBusinessFacts, isTrue);
      expect(observation.canSupportExecutionFailure, isFalse);
      expect(calculation.evidenceKind, EvidenceKind.calculation);
      expect(receipt.evidenceKind, EvidenceKind.actionReceipt);
    });

    test('deeply freezes capabilities, scope, and structured facts', () {
      final capabilities = <ToolCapability>{ToolCapability.localRead};
      final nestedScope = <Object?>['item-1'];
      final scope = <String, Object?>{'resource_ids': nestedScope};
      final facts = <StructuredFact>[
        StructuredFact(name: 'resource.exists', value: true),
      ];
      final evidence = _observation(
        capabilities: capabilities,
        scope: scope,
        structuredFacts: facts,
      );

      capabilities.add(ToolCapability.localWrite);
      nestedScope.add('item-2');
      scope['resource_ids'] = const ['changed'];
      facts.add(StructuredFact(name: 'resource.changed', value: true));

      expect(evidence.capabilities, {ToolCapability.localRead});
      expect(evidence.scope, {
        'resource_ids': ['item-1'],
      });
      expect(evidence.structuredFacts, hasLength(1));
      expect(
        () => evidence.capabilities.add(ToolCapability.compute),
        throwsUnsupportedError,
      );
      expect(
        () => (evidence.scope['resource_ids']! as List<Object?>).add('blocked'),
        throwsUnsupportedError,
      );
      expect(
        () => evidence.structuredFacts.add(
          StructuredFact(name: 'resource.blocked', value: true),
        ),
        throwsUnsupportedError,
      );
    });

    test('requires a real evidence-bearing terminal status', () {
      for (final status in const [
        ToolInvocationStatus.requested,
        ToolInvocationStatus.awaitingApproval,
        ToolInvocationStatus.running,
        ToolInvocationStatus.duplicateReused,
        ToolInvocationStatus.duplicateConflict,
        ToolInvocationStatus.duplicate,
      ]) {
        expect(
          () => _observation(terminalStatus: status),
          throwsArgumentError,
          reason: '$status cannot become standalone evidence',
        );
      }
    });

    test('rejects failed attempts as observations', () {
      for (final status in const [
        ToolInvocationStatus.failed,
        ToolInvocationStatus.denied,
        ToolInvocationStatus.timedOut,
        ToolInvocationStatus.cancelled,
      ]) {
        expect(
          () => _observation(terminalStatus: status),
          throwsArgumentError,
          reason: '$status can only support an execution failure',
        );
      }
    });

    test('rejects empty, truncated, or schema-invalid business results', () {
      expect(() => _observation(resultSummary: ''), throwsArgumentError);
      expect(
        () => _observation(structuredFacts: const []),
        throwsArgumentError,
      );
      expect(() => _observation(truncated: true), throwsArgumentError);
      expect(() => _observation(schemaValid: false), throwsArgumentError);
    });

    test('enforces evidence kind capability boundaries', () {
      expect(
        () => _observation(capabilities: {ToolCapability.compute}),
        throwsArgumentError,
      );
      expect(
        () => _observation(
          capabilities: {ToolCapability.localRead, ToolCapability.localWrite},
        ),
        throwsArgumentError,
      );
      expect(
        () => _businessEvidence(
          evidenceKind: EvidenceKind.calculation,
          capabilities: {ToolCapability.localRead},
        ),
        throwsArgumentError,
      );
      expect(
        () => _businessEvidence(
          evidenceKind: EvidenceKind.calculation,
          capabilities: {ToolCapability.compute, ToolCapability.externalWrite},
        ),
        throwsArgumentError,
      );
      expect(
        () => _businessEvidence(
          evidenceKind: EvidenceKind.calculation,
          capabilities: {ToolCapability.compute, ToolCapability.localRead},
        ),
        throwsArgumentError,
      );
      expect(
        () => _businessEvidence(
          evidenceKind: EvidenceKind.actionReceipt,
          capabilities: {ToolCapability.externalRead},
        ),
        throwsArgumentError,
      );
    });

    test('requires an expiry for externally mutable observations', () {
      expect(
        () => _observation(
          capabilities: {ToolCapability.externalRead},
          validUntil: null,
        ),
        throwsArgumentError,
      );

      final evidence = _observation(
        capabilities: {ToolCapability.externalRead},
        validUntil: DateTime.utc(2026, 1, 1, 12, 5),
        persisted: true,
      );

      expect(
        evidence.canSupportBusinessFactsAt(DateTime.utc(2026, 1, 1, 12, 4)),
        isTrue,
      );
      expect(
        evidence.canSupportBusinessFactsAt(DateTime.utc(2026, 1, 1, 12, 5)),
        isFalse,
      );
    });

    test('unpersisted evidence cannot support business facts', () {
      final evidence = _observation();

      expect(evidence.persisted, isFalse);
      expect(evidence.canSupportBusinessFacts, isFalse);
      expect(
        evidence.canSupportBusinessFactsAt(DateTime.utc(2026, 1, 1, 12, 1)),
        isFalse,
      );
    });
  });

  group('ToolEvidenceRecord execution failure', () {
    test('allows terminal errors to support only execution failure', () {
      for (final status in const [
        ToolInvocationStatus.failed,
        ToolInvocationStatus.denied,
        ToolInvocationStatus.timedOut,
        ToolInvocationStatus.cancelled,
      ]) {
        final evidence = _executionFailure(status: status, persisted: true);

        expect(evidence.evidenceKind, EvidenceKind.executionFailure);
        expect(evidence.structuredFacts, isEmpty);
        expect(evidence.canSupportBusinessFacts, isFalse);
        expect(evidence.canSupportExecutionFailure, isTrue);
      }
    });

    test('rejects success, facts, or a missing error code', () {
      expect(
        () => _executionFailure(status: ToolInvocationStatus.succeeded),
        throwsArgumentError,
      );
      expect(() => _executionFailure(errorCode: ''), throwsArgumentError);
      expect(
        () => _executionFailure(
          structuredFacts: [
            StructuredFact(name: 'resource.exists', value: false),
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('ToolEvidenceRecord identity and integrity', () {
    test('derives evidence identity without a Provider call ID', () {
      const attemptId = 'run-1:invocation:1:attempt:1';
      final first = _observation(providerCallId: 'openai-call-1');
      final second = _observation(providerCallId: 'mcp-call-9');

      expect(
        ToolEvidenceRecord.evidenceIdForAttempt(attemptId),
        'run-1:invocation:1:attempt:1:evidence',
      );
      expect(first.evidenceId, second.evidenceId);
      expect(first.evidenceId, isNot(first.providerCallId));
      expect(second.evidenceId, isNot(second.providerCallId));
    });

    test('rejects invalid identities and SHA-256 digests', () {
      expect(() => _observation(evidenceId: ''), throwsArgumentError);
      expect(() => _observation(evidenceId: 'evidence-1'), throwsArgumentError);
      expect(
        () => _observation(
          evidenceId: 'provider-call-1',
          providerCallId: 'provider-call-1',
        ),
        throwsArgumentError,
      );
      expect(
        () => _observation(argumentsDigest: 'not-a-digest'),
        throwsArgumentError,
      );
      expect(
        () => _observation(resultDigest: _upperDigest),
        throwsArgumentError,
      );
    });

    test('rejects invalid validity ranges and duplicate fact names', () {
      expect(
        () => _observation(validUntil: DateTime.utc(2026, 1, 1, 12)),
        throwsArgumentError,
      );
      expect(
        () => _observation(validUntil: DateTime.utc(2025, 12, 31)),
        throwsArgumentError,
      );
      expect(
        () => _observation(
          structuredFacts: [
            StructuredFact(name: 'resource.exists', value: true),
            StructuredFact(name: 'resource.exists', value: false),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('requires encrypted payload references and a retention expiry', () {
      expect(
        () => _observation(payloadRef: '', payloadExpiresAt: null),
        returnsNormally,
      );
      expect(
        () => _observation(includePayloadExpiry: false),
        throwsArgumentError,
      );
      expect(
        () => _observation(payloadRef: 'file:///raw-result'),
        throwsArgumentError,
      );
      expect(
        () => _observation(payloadExpiresAt: DateTime.utc(2026, 1, 1, 12)),
        throwsArgumentError,
      );
    });
  });
}

const _argumentsDigest =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _resultDigest =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _upperDigest =
    'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB';

ToolInvocationEvent _event({
  String eventId = 'run-1:invocation:1:attempt:1:event:1',
  String runId = 'run-1',
  String providerCallId = 'provider-call-1',
  int sequence = 1,
  ToolInvocationStatus status = ToolInvocationStatus.requested,
}) => ToolInvocationEvent(
  eventId: eventId,
  runId: runId,
  turnId: 'turn-1',
  chatId: 'chat-1',
  messageId: 'message-1',
  invocationId: 'run-1:invocation:1',
  attemptId: 'run-1:invocation:1:attempt:1',
  providerCallId: providerCallId,
  toolName: 'resource.read',
  toolVersion: '1.0.0',
  source: ToolSource.mcp,
  status: status,
  sequence: sequence,
  occurredAt: DateTime.utc(2026, 1, 1, 12),
);

ToolEvidenceRecord _observation({
  String evidenceId = 'run-1:invocation:1:attempt:1:evidence',
  String providerCallId = 'provider-call-1',
  Set<ToolCapability> capabilities = const {ToolCapability.localRead},
  ToolInvocationStatus terminalStatus = ToolInvocationStatus.succeeded,
  Map<String, Object?> scope = const {'resource_id': 'item-1'},
  String resultSummary = 'One resource observed.',
  String argumentsDigest = _argumentsDigest,
  String resultDigest = _resultDigest,
  List<StructuredFact>? structuredFacts,
  DateTime? validUntil,
  String payloadRef = 'encrypted://tool-results/evidence-1',
  DateTime? payloadExpiresAt,
  bool includePayloadExpiry = true,
  bool truncated = false,
  bool schemaValid = true,
  bool persisted = false,
}) => _businessEvidence(
  evidenceId: evidenceId,
  providerCallId: providerCallId,
  capabilities: capabilities,
  terminalStatus: terminalStatus,
  evidenceKind: EvidenceKind.observation,
  scope: scope,
  resultSummary: resultSummary,
  argumentsDigest: argumentsDigest,
  resultDigest: resultDigest,
  structuredFacts: structuredFacts,
  validUntil: validUntil,
  payloadRef: payloadRef,
  payloadExpiresAt: payloadExpiresAt,
  includePayloadExpiry: includePayloadExpiry,
  truncated: truncated,
  schemaValid: schemaValid,
  persisted: persisted,
);

ToolEvidenceRecord _businessEvidence({
  String evidenceId = 'run-1:invocation:1:attempt:1:evidence',
  String providerCallId = 'provider-call-1',
  Set<ToolCapability> capabilities = const {ToolCapability.localRead},
  ToolInvocationStatus terminalStatus = ToolInvocationStatus.succeeded,
  EvidenceKind evidenceKind = EvidenceKind.observation,
  Map<String, Object?> scope = const {'resource_id': 'item-1'},
  String resultSummary = 'One result.',
  String argumentsDigest = _argumentsDigest,
  String resultDigest = _resultDigest,
  StructuredFact? fact,
  List<StructuredFact>? structuredFacts,
  DateTime? validUntil,
  String payloadRef = 'encrypted://tool-results/evidence-1',
  DateTime? payloadExpiresAt,
  bool includePayloadExpiry = true,
  bool truncated = false,
  bool schemaValid = true,
  bool persisted = false,
}) => ToolEvidenceRecord(
  evidenceId: evidenceId,
  runId: 'run-1',
  turnId: 'turn-1',
  chatId: 'chat-1',
  messageId: 'message-1',
  invocationId: 'run-1:invocation:1',
  attemptId: 'run-1:invocation:1:attempt:1',
  providerCallId: providerCallId,
  toolName: 'resource.tool',
  toolVersion: '1.0.0',
  source: ToolSource.mcp,
  capabilities: capabilities,
  terminalStatus: terminalStatus,
  evidenceKind: evidenceKind,
  subject: 'resource:item-1',
  scope: scope,
  resultSummary: resultSummary,
  argumentsDigest: argumentsDigest,
  resultDigest: resultDigest,
  structuredFacts:
      structuredFacts ??
      [fact ?? StructuredFact(name: 'resource.exists', value: true)],
  observedAt: DateTime.utc(2026, 1, 1, 12),
  validUntil: validUntil,
  payloadRef: payloadRef,
  payloadExpiresAt:
      includePayloadExpiry
          ? payloadExpiresAt ??
              (payloadRef.isEmpty ? null : DateTime.utc(2026, 1, 2, 12))
          : payloadExpiresAt,
  truncated: truncated,
  schemaValid: schemaValid,
  persisted: persisted,
);

ToolEvidenceRecord _executionFailure({
  ToolInvocationStatus status = ToolInvocationStatus.failed,
  String errorCode = 'tool_execution_failed',
  List<StructuredFact> structuredFacts = const [],
  bool persisted = false,
}) => ToolEvidenceRecord(
  evidenceId: 'run-1:invocation:1:attempt:1:evidence',
  runId: 'run-1',
  turnId: 'turn-1',
  chatId: 'chat-1',
  messageId: 'message-1',
  invocationId: 'run-1:invocation:1',
  attemptId: 'run-1:invocation:1:attempt:1',
  providerCallId: 'provider-call-1',
  toolName: 'resource.write',
  toolVersion: '1.0.0',
  source: ToolSource.mcp,
  capabilities: const {ToolCapability.externalWrite},
  terminalStatus: status,
  evidenceKind: EvidenceKind.executionFailure,
  resultSummary: 'The tool attempt failed.',
  argumentsDigest: _argumentsDigest,
  resultDigest: _resultDigest,
  structuredFacts: structuredFacts,
  observedAt: DateTime.utc(2026, 1, 1, 12),
  truncated: true,
  schemaValid: false,
  persisted: persisted,
  errorCode: errorCode,
);
