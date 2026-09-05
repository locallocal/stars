import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/answer_trust_policy.dart';

void main() {
  const policy = AnswerTrustPolicy();

  group('AnswerTrustPolicy', () {
    test('verifies only fully validated evidence after a passed gate', () {
      final grounding = policy.evaluate(_input());

      expect(grounding.trustLevel, AnswerTrustLevel.verified);
      expect(grounding.reasonCode, 'all_evidence_validated');
      expect(grounding.evidenceIds, ['evidence-1']);
    });

    test('preserves partial validation without upgrading the whole answer', () {
      final grounding = policy.evaluate(
        _input(evidenceState: AnswerEvidenceState.partiallyValidated),
      );

      expect(grounding.trustLevel, AnswerTrustLevel.partiallyVerified);
      expect(grounding.reasonCode, 'partial_evidence_validated');
      expect(grounding.evidenceIds, ['evidence-1']);
    });

    test('legacy evidence footer can never produce a verified answer', () {
      final grounding = policy.evaluate(
        _input(
          evidenceState: AnswerEvidenceState.legacyFormatOnly,
          evidenceIds: const [],
        ),
      );

      expect(grounding.trustLevel, AnswerTrustLevel.unverified);
      expect(grounding.reasonCode, 'legacy_evidence_unverified');
      expect(grounding.evidenceIds, isEmpty);
    });

    test('structured claims stay unverified before claim validation', () {
      final grounding = policy.evaluate(
        _input(evidenceState: AnswerEvidenceState.structuredUnvalidated),
      );

      expect(grounding.trustLevel, AnswerTrustLevel.unverified);
      expect(grounding.reasonCode, 'structured_claims_unvalidated');
      expect(grounding.evidenceIds, isEmpty);
    });

    test('fully unverified validation preserves claim boundaries', () {
      final claim = MessageClaimGrounding(
        claim: AnswerClaim(
          claimId: 'claim-unverified',
          text: 'Production is healthy.',
          kind: ClaimKind.currentFact,
        ),
        trustLevel: ClaimTrustLevel.unverified,
      );

      final result = policy.evaluate(
        _input(
          evidenceState: AnswerEvidenceState.none,
          evidenceIds: const [],
          claims: [claim],
        ),
      );

      expect(result.trustLevel, AnswerTrustLevel.unverified);
      expect(result.reasonCode, 'no_usable_evidence');
      expect(result.claims, [same(claim)]);
      expect(result.evidenceIds, isEmpty);
    });

    test('no-tool answers retain factual claim failure details', () {
      final claim = MessageClaimGrounding(
        claim: AnswerClaim(
          claimId: 'claim-unverified',
          text: 'Production is healthy.',
          kind: ClaimKind.currentFact,
        ),
        trustLevel: ClaimTrustLevel.unverified,
        reasonCode: 'claimHasNoEvidence',
      );

      final result = policy.evaluate(
        _input(
          toolCalls: const [],
          evidenceState: AnswerEvidenceState.none,
          evidenceIds: const [],
          claims: [claim],
        ),
      );

      expect(result.reasonCode, 'no_tool_evidence');
      expect(result.claims, [same(claim)]);
    });

    test('creative-only answers remain explicitly not fact checked', () {
      final claim = MessageClaimGrounding(
        claim: AnswerClaim(
          claimId: 'non_factual_text',
          text: 'A fictional story.',
          kind: ClaimKind.nonFactual,
        ),
        trustLevel: ClaimTrustLevel.notVerifiable,
        reasonCode: 'not_fact_checked',
      );

      final result = policy.evaluate(
        _input(
          toolCalls: const [],
          evidenceState: AnswerEvidenceState.none,
          evidenceIds: const [],
          claims: [claim],
        ),
      );

      expect(result.reasonCode, 'no_verifiable_claims');
      expect(result.claims, [same(claim)]);
    });

    test('duplicate reuse does not replace or downgrade a successful call', () {
      final grounding = policy.evaluate(
        _input(
          toolCalls: const [
            MessageToolCall(name: 'save_note', status: 'succeeded'),
            MessageToolCall(name: 'save_note', status: 'duplicateReused'),
          ],
        ),
      );

      expect(grounding.trustLevel, AnswerTrustLevel.verified);
      expect(grounding.reasonCode, 'all_evidence_validated');
    });

    test(
      'completed answers fail closed when a trust prerequisite is absent',
      () {
        final cases = <String, ({AnswerTrustPolicyInput input, String reason})>{
          'provider has no Agent Loop': (
            input: _input(providerSupportsAgentLoop: false),
            reason: 'provider_tools_unsupported',
          ),
          'reliability prompt is disabled': (
            input: _input(reliabilityPolicyEnabled: false),
            reason: 'reliability_policy_disabled',
          ),
          'no eligible verification tool is available': (
            input: _input(
              verificationUnavailableReason: 'verification_tool_unavailable',
            ),
            reason: 'verification_tool_unavailable',
          ),
          'no tools were called': (
            input: _input(toolCalls: const []),
            reason: 'no_tool_evidence',
          ),
          'tool approval was denied': (
            input: _input(
              toolCalls: const [
                MessageToolCall(
                  name: 'read_weather',
                  status: 'denied',
                  approvalStatus: 'deny',
                ),
              ],
            ),
            reason: 'tool_rejected',
          ),
          'tool was unavailable': (
            input: _input(
              toolCalls: const [
                MessageToolCall(
                  name: 'read_weather',
                  status: 'denied',
                  errorCode: 'tool_not_available',
                ),
              ],
            ),
            reason: 'tool_unavailable',
          ),
          'tool execution is not terminal': (
            input: _input(
              toolCalls: const [
                MessageToolCall(name: 'read_weather', status: 'succeeded'),
                MessageToolCall(name: 'read_file', status: 'running'),
              ],
            ),
            reason: 'incomplete_tool_execution',
          ),
          'gate did not run': (
            input: _input(gateResult: AnswerTrustGateResult.notRun),
            reason: 'trust_gate_not_run',
          ),
        };

        for (final entry in cases.entries) {
          final grounding = policy.evaluate(entry.value.input);
          expect(
            grounding.trustLevel,
            AnswerTrustLevel.unverified,
            reason: entry.key,
          );
          expect(grounding.reasonCode, entry.value.reason, reason: entry.key);
          expect(grounding.evidenceIds, isEmpty, reason: entry.key);
        }
      },
    );

    test('maps provider terminal outcomes independently from completion', () {
      final cases = <MessageTerminalOutcome, AnswerTrustLevel>{
        MessageTerminalOutcome.completed: AnswerTrustLevel.verified,
        MessageTerminalOutcome.cancelled: AnswerTrustLevel.unverified,
        MessageTerminalOutcome.failed: AnswerTrustLevel.failed,
        MessageTerminalOutcome.emptyResponse: AnswerTrustLevel.unverified,
      };

      for (final entry in cases.entries) {
        final grounding = policy.evaluate(
          _input(
            terminalOutcome: entry.key,
            failureReasonCode:
                entry.key == MessageTerminalOutcome.failed
                    ? 'provider_timeout'
                    : '',
          ),
        );
        expect(grounding.trustLevel, entry.value, reason: entry.key.name);
      }
    });

    test('gate and critical persistence failures produce failed trust', () {
      final gateFailure = policy.evaluate(
        _input(gateResult: AnswerTrustGateResult.failed),
      );
      final persistenceFailure = policy.evaluate(
        _input(criticalPersistenceSucceeded: false),
      );
      final invalidEvidence = policy.evaluate(
        _input(evidenceState: AnswerEvidenceState.invalid),
      );

      expect(gateFailure.trustLevel, AnswerTrustLevel.failed);
      expect(gateFailure.reasonCode, 'answer_trust_gate_failed');
      expect(persistenceFailure.trustLevel, AnswerTrustLevel.failed);
      expect(persistenceFailure.reasonCode, 'critical_persistence_failed');
      expect(invalidEvidence.trustLevel, AnswerTrustLevel.failed);
      expect(invalidEvidence.reasonCode, 'evidence_validation_failed');
    });

    test('does not expose unsafe provider failure details as reason codes', () {
      final grounding = policy.evaluate(
        _input(
          terminalOutcome: MessageTerminalOutcome.failed,
          failureReasonCode: 'HTTP 500: secret response body',
        ),
      );

      expect(grounding.trustLevel, AnswerTrustLevel.failed);
      expect(grounding.reasonCode, 'provider_failed');
    });
  });
}

AnswerTrustPolicyInput _input({
  MessageTerminalOutcome terminalOutcome = MessageTerminalOutcome.completed,
  bool providerSupportsAgentLoop = true,
  bool reliabilityPolicyEnabled = true,
  List<MessageToolCall> toolCalls = const [
    MessageToolCall(name: 'read_weather', status: 'succeeded'),
  ],
  AnswerEvidenceState evidenceState = AnswerEvidenceState.fullyValidated,
  AnswerTrustGateResult gateResult = AnswerTrustGateResult.passed,
  List<String> evidenceIds = const ['evidence-1'],
  List<MessageClaimGrounding> claims = const [],
  bool criticalPersistenceSucceeded = true,
  String failureReasonCode = '',
  String verificationUnavailableReason = '',
}) => AnswerTrustPolicyInput(
  terminalOutcome: terminalOutcome,
  providerSupportsAgentLoop: providerSupportsAgentLoop,
  reliabilityPolicyEnabled: reliabilityPolicyEnabled,
  toolCalls: toolCalls,
  evidenceState: evidenceState,
  gateResult: gateResult,
  evidenceIds: evidenceIds,
  claims: claims,
  criticalPersistenceSucceeded: criticalPersistenceSucceeded,
  failureReasonCode: failureReasonCode,
  verificationUnavailableReason: verificationUnavailableReason,
);
