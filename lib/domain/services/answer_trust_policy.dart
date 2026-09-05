import 'package:stars/domain/models/models.dart';

/// Evidence maturity understood by the application-side trust gate.
enum AnswerEvidenceState {
  none,
  legacyFormatOnly,
  structuredUnvalidated,
  partiallyValidated,
  fullyValidated,
  invalid,
}

/// Result of the deterministic application-side answer gate.
enum AnswerTrustGateResult { notRun, passed, failed }

/// Immutable inputs used to derive one assistant answer's trust metadata.
final class AnswerTrustPolicyInput {
  AnswerTrustPolicyInput({
    required this.terminalOutcome,
    required this.providerSupportsAgentLoop,
    required this.reliabilityPolicyEnabled,
    List<MessageToolCall> toolCalls = const [],
    this.evidenceState = AnswerEvidenceState.none,
    this.gateResult = AnswerTrustGateResult.notRun,
    List<String> evidenceIds = const [],
    List<MessageClaimGrounding> claims = const [],
    this.criticalPersistenceSucceeded = true,
    this.failureReasonCode = '',
    this.verificationUnavailableReason = '',
  }) : toolCalls = List<MessageToolCall>.unmodifiable(toolCalls),
       evidenceIds = List<String>.unmodifiable(evidenceIds),
       claims = List<MessageClaimGrounding>.unmodifiable(claims);

  final MessageTerminalOutcome terminalOutcome;
  final bool providerSupportsAgentLoop;
  final bool reliabilityPolicyEnabled;
  final List<MessageToolCall> toolCalls;
  final AnswerEvidenceState evidenceState;
  final AnswerTrustGateResult gateResult;
  final List<String> evidenceIds;
  final List<MessageClaimGrounding> claims;
  final bool criticalPersistenceSucceeded;
  final String failureReasonCode;
  final String verificationUnavailableReason;
}

/// Computes trust exclusively from application-observed terminal facts.
///
/// A Provider cannot directly choose the returned level. Legacy evidence
/// footers remain a formatting guard and deliberately cannot produce a
/// verified result.
final class AnswerTrustPolicy {
  const AnswerTrustPolicy();

  MessageGrounding evaluate(AnswerTrustPolicyInput input) {
    if (!input.criticalPersistenceSucceeded) {
      return _failed(
        _safeReasonCode(
          input.failureReasonCode,
          fallback: 'critical_persistence_failed',
        ),
      );
    }
    switch (input.terminalOutcome) {
      case MessageTerminalOutcome.failed:
        return _failed(
          _safeReasonCode(input.failureReasonCode, fallback: 'provider_failed'),
        );
      case MessageTerminalOutcome.cancelled:
        return _unverified('generation_cancelled');
      case MessageTerminalOutcome.emptyResponse:
        return _unverified('empty_response');
      case MessageTerminalOutcome.completed:
        break;
    }

    if (input.gateResult == AnswerTrustGateResult.failed) {
      return _failed('answer_trust_gate_failed');
    }
    if (!input.providerSupportsAgentLoop) {
      return _unverified('provider_tools_unsupported', claims: input.claims);
    }
    if (!input.reliabilityPolicyEnabled) {
      return _unverified('reliability_policy_disabled', claims: input.claims);
    }
    if (input.verificationUnavailableReason.isNotEmpty) {
      return _unverified(
        _safeReasonCode(
          input.verificationUnavailableReason,
          fallback: 'verification_tool_unavailable',
        ),
        claims: input.claims,
      );
    }
    if (input.claims.isNotEmpty &&
        input.claims.every(
          (claim) => claim.trustLevel == ClaimTrustLevel.notVerifiable,
        )) {
      return _unverified('no_verifiable_claims', claims: input.claims);
    }
    if (input.toolCalls.isEmpty) {
      return _unverified('no_tool_evidence', claims: input.claims);
    }
    if (input.toolCalls.any(_isUnavailableToolCall)) {
      return _unverified('tool_unavailable', claims: input.claims);
    }
    if (input.toolCalls.any(_isRejectedToolCall)) {
      return _unverified('tool_rejected', claims: input.claims);
    }
    if (input.toolCalls.any(_isFailedToolCall)) {
      return _unverified('tool_failed', claims: input.claims);
    }
    if (input.toolCalls.any((call) => !_isSuccessfulToolCall(call))) {
      return _unverified('incomplete_tool_execution', claims: input.claims);
    }
    if (input.gateResult == AnswerTrustGateResult.notRun) {
      return _unverified('trust_gate_not_run', claims: input.claims);
    }

    return switch (input.evidenceState) {
      AnswerEvidenceState.none => _unverified(
        'no_usable_evidence',
        claims: input.claims,
      ),
      AnswerEvidenceState.legacyFormatOnly => _unverified(
        'legacy_evidence_unverified',
      ),
      AnswerEvidenceState.structuredUnvalidated => _unverified(
        'structured_claims_unvalidated',
      ),
      AnswerEvidenceState.invalid => _failed('evidence_validation_failed'),
      AnswerEvidenceState.partiallyValidated => _validated(
        trustLevel: AnswerTrustLevel.partiallyVerified,
        reasonCode: 'partial_evidence_validated',
        evidenceIds: input.evidenceIds,
        claims: input.claims,
      ),
      AnswerEvidenceState.fullyValidated => _validated(
        trustLevel: AnswerTrustLevel.verified,
        reasonCode: 'all_evidence_validated',
        evidenceIds: input.evidenceIds,
        claims: input.claims,
      ),
    };
  }

  MessageGrounding _validated({
    required AnswerTrustLevel trustLevel,
    required String reasonCode,
    required List<String> evidenceIds,
    required List<MessageClaimGrounding> claims,
  }) {
    try {
      return MessageGrounding(
        trustLevel: trustLevel,
        reasonCode: reasonCode,
        evidenceIds: evidenceIds,
        claims: claims,
      );
    } on ArgumentError {
      return _failed('evidence_validation_failed');
    }
  }

  MessageGrounding _unverified(
    String reasonCode, {
    List<MessageClaimGrounding> claims = const [],
  }) => MessageGrounding(
    trustLevel: AnswerTrustLevel.unverified,
    reasonCode: reasonCode,
    claims: claims,
  );

  MessageGrounding _failed(String reasonCode) => MessageGrounding(
    trustLevel: AnswerTrustLevel.failed,
    reasonCode: reasonCode,
  );

  bool _isSuccessfulToolCall(MessageToolCall call) =>
      call.status == 'succeeded' ||
      call.status == 'completed' ||
      call.status == 'duplicateReused';

  bool _isUnavailableToolCall(MessageToolCall call) =>
      call.errorCode == 'tool_not_available' ||
      call.errorCode == 'tool_unavailable';

  bool _isRejectedToolCall(MessageToolCall call) =>
      call.status == 'denied' ||
      call.status == 'rejected' ||
      call.approvalStatus == 'deny';

  bool _isFailedToolCall(MessageToolCall call) =>
      call.status == 'failed' ||
      call.status == 'cancelled' ||
      call.status == 'timedOut' ||
      call.errorCode.isNotEmpty;

  String _safeReasonCode(String value, {required String fallback}) {
    final normalized = value.trim();
    return RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(normalized)
        ? normalized
        : fallback;
  }
}
