import 'package:stars/domain/models/models.dart';

/// Evidence maturity understood by the application-side trust gate.
enum AnswerEvidenceState {
  none,
  legacyFormatOnly,
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
    this.criticalPersistenceSucceeded = true,
    this.failureReasonCode = '',
  }) : toolCalls = List<MessageToolCall>.unmodifiable(toolCalls),
       evidenceIds = List<String>.unmodifiable(evidenceIds);

  final MessageTerminalOutcome terminalOutcome;
  final bool providerSupportsAgentLoop;
  final bool reliabilityPolicyEnabled;
  final List<MessageToolCall> toolCalls;
  final AnswerEvidenceState evidenceState;
  final AnswerTrustGateResult gateResult;
  final List<String> evidenceIds;
  final bool criticalPersistenceSucceeded;
  final String failureReasonCode;
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
      return _unverified('provider_tools_unsupported');
    }
    if (!input.reliabilityPolicyEnabled) {
      return _unverified('reliability_policy_disabled');
    }
    if (input.toolCalls.isEmpty) {
      return _unverified('no_tool_evidence');
    }
    if (input.toolCalls.any(_isUnavailableToolCall)) {
      return _unverified('tool_unavailable');
    }
    if (input.toolCalls.any(_isRejectedToolCall)) {
      return _unverified('tool_rejected');
    }
    if (input.toolCalls.any(_isFailedToolCall)) {
      return _unverified('tool_failed');
    }
    if (input.toolCalls.any((call) => !_isSuccessfulToolCall(call))) {
      return _unverified('incomplete_tool_execution');
    }
    if (input.gateResult == AnswerTrustGateResult.notRun) {
      return _unverified('trust_gate_not_run');
    }

    return switch (input.evidenceState) {
      AnswerEvidenceState.none => _unverified('no_usable_evidence'),
      AnswerEvidenceState.legacyFormatOnly => _unverified(
        'legacy_evidence_unverified',
      ),
      AnswerEvidenceState.invalid => _failed('evidence_validation_failed'),
      AnswerEvidenceState.partiallyValidated => _validated(
        trustLevel: AnswerTrustLevel.partiallyVerified,
        reasonCode: 'partial_evidence_validated',
        evidenceIds: input.evidenceIds,
      ),
      AnswerEvidenceState.fullyValidated => _validated(
        trustLevel: AnswerTrustLevel.verified,
        reasonCode: 'all_evidence_validated',
        evidenceIds: input.evidenceIds,
      ),
    };
  }

  MessageGrounding _validated({
    required AnswerTrustLevel trustLevel,
    required String reasonCode,
    required List<String> evidenceIds,
  }) {
    try {
      return MessageGrounding(
        trustLevel: trustLevel,
        reasonCode: reasonCode,
        evidenceIds: evidenceIds,
      );
    } on ArgumentError {
      return _failed('evidence_validation_failed');
    }
  }

  MessageGrounding _unverified(String reasonCode) => MessageGrounding(
    trustLevel: AnswerTrustLevel.unverified,
    reasonCode: reasonCode,
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
