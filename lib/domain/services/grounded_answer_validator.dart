import 'dart:convert';

import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';

export 'package:stars/domain/models/grounded_answer.dart' show ClaimTrustLevel;

/// Application-owned semantic constraints for one answer claim.
///
/// These constraints must be derived from the verification request or a typed
/// rendering template, never copied from model output. This is what lets the
/// validator compare a claim with an evidence subject and scope without
/// guessing semantics from prose.
final class ClaimEvidenceRequirement {
  ClaimEvidenceRequirement({
    required String claimId,
    required Set<EvidenceKind> allowedEvidenceKinds,
    this.claimKind,
    this.subject = '',
    Map<String, Object?> scope = const {},
    Set<ToolCapability> requiredCapabilities = const {},
    Set<String> requiredFactNames = const {},
    Map<String, Object?> requiredFactValues = const {},
    this.toolName = '',
    this.attemptId = '',
    this.verificationAvailable = true,
  }) : claimId = _normalizedRequiredText(claimId, 'claimId'),
       allowedEvidenceKinds = Set<EvidenceKind>.unmodifiable(
         allowedEvidenceKinds,
       ),
       scope = _freezeJsonMap(scope, 'scope'),
       requiredCapabilities = Set<ToolCapability>.unmodifiable(
         requiredCapabilities,
       ),
       requiredFactValues = _freezeJsonMap(
         requiredFactValues,
         'requiredFactValues',
       ),
       requiredFactNames = Set<String>.unmodifiable(
         <String>{
           ...requiredFactNames,
           ...requiredFactValues.keys,
         }.map((name) => _normalizedRequiredText(name, 'requiredFactNames')),
       ) {
    _requireNormalizedOptionalText(subject, 'subject');
    _requireNormalizedOptionalText(toolName, 'toolName');
    _requireNormalizedOptionalText(attemptId, 'attemptId');
    if (this.allowedEvidenceKinds.isEmpty) {
      throw ArgumentError.value(
        allowedEvidenceKinds,
        'allowedEvidenceKinds',
        'A claim requirement must allow at least one evidence kind.',
      );
    }
  }

  final String claimId;
  final ClaimKind? claimKind;
  final Set<EvidenceKind> allowedEvidenceKinds;
  final String subject;
  final Map<String, Object?> scope;
  final Set<ToolCapability> requiredCapabilities;
  final Set<String> requiredFactNames;
  final Map<String, Object?> requiredFactValues;

  /// Optional identity constraints for the exact supporting Tool attempt.
  final String toolName;
  final String attemptId;

  /// False when policy requires a state claim to remain unverified because no
  /// authorized verifier was available for this run.
  final bool verificationAvailable;
}

/// A conservative semantic review performed after deterministic validation.
///
/// Returning false can reject an otherwise valid binding. Returning true can
/// never rescue a binding rejected by the deterministic checks.
abstract interface class ClaimEvidenceReviewer {
  Future<bool> supports({
    required AnswerClaim claim,
    required ToolEvidenceRecord evidence,
  });
}

enum EvidenceRejectionReason {
  claimDoesNotAcceptEvidence,
  claimHasNoEvidence,
  claimRequirementMissing,
  claimRequirementInvalid,
  evidenceNotFound,
  evidenceLedgerUnavailable,
  evidenceRunMismatch,
  evidenceNotPersisted,
  evidenceIntegrityInvalid,
  evidenceTerminalStatusInvalid,
  evidenceKindMismatch,
  evidenceCapabilityMismatch,
  evidenceSubjectMismatch,
  evidenceScopeMismatch,
  evidenceNotYetObserved,
  evidenceValidityMissing,
  evidenceExpired,
  evidenceSchemaInvalid,
  evidenceTruncated,
  evidenceEmpty,
  evidenceFactValueMismatch,
  verificationUnavailable,
  executionFailureEvidenceMismatch,
  actionReceiptCannotSupportState,
  modelReviewRejected,
}

final class EvidenceValidationIssue {
  const EvidenceValidationIssue({
    required this.evidenceId,
    required this.reason,
  });

  final String evidenceId;
  final EvidenceRejectionReason reason;
}

final class ClaimValidationResult {
  ClaimValidationResult({
    required this.claim,
    required this.trustLevel,
    List<String> acceptedEvidenceIds = const [],
    List<EvidenceValidationIssue> issues = const [],
  }) : acceptedEvidenceIds = List<String>.unmodifiable(acceptedEvidenceIds),
       issues = List<EvidenceValidationIssue>.unmodifiable(issues);

  final AnswerClaim claim;
  final ClaimTrustLevel trustLevel;
  final List<String> acceptedEvidenceIds;
  final List<EvidenceValidationIssue> issues;
}

final class GroundedAnswerValidationResult {
  GroundedAnswerValidationResult({
    required this.trustLevel,
    required this.reasonCode,
    required List<ClaimValidationResult> claims,
    required List<String> evidenceIds,
    this.nonFactualText = '',
    List<String> unmatchedRequirementIds = const [],
  }) : claims = List<ClaimValidationResult>.unmodifiable(claims),
       evidenceIds = List<String>.unmodifiable(evidenceIds),
       unmatchedRequirementIds = List<String>.unmodifiable(
         unmatchedRequirementIds,
       );

  final AnswerTrustLevel trustLevel;
  final String reasonCode;
  final List<ClaimValidationResult> claims;
  final String nonFactualText;

  /// Only deterministically accepted, actually referenced evidence IDs.
  final List<String> evidenceIds;
  final List<String> unmatchedRequirementIds;

  MessageGrounding toMessageGrounding() => MessageGrounding(
    trustLevel: trustLevel,
    reasonCode: reasonCode,
    evidenceIds: evidenceIds,
    claims: [
      for (final result in claims)
        MessageClaimGrounding(
          claim: result.claim,
          trustLevel: result.trustLevel,
          acceptedEvidenceIds: result.acceptedEvidenceIds,
          reasonCode: _claimValidationReason(result),
        ),
      if (nonFactualText.isNotEmpty)
        MessageClaimGrounding(
          claim: AnswerClaim(
            claimId: _nonFactualClaimId(claims),
            text: nonFactualText,
            kind: ClaimKind.nonFactual,
          ),
          trustLevel: ClaimTrustLevel.notVerifiable,
          reasonCode: 'not_fact_checked',
        ),
    ],
  );
}

String _nonFactualClaimId(List<ClaimValidationResult> claims) {
  final claimIds = claims.map((result) => result.claim.claimId).toSet();
  var suffix = 1;
  var candidate = 'non_factual_text';
  while (claimIds.contains(candidate)) {
    suffix += 1;
    candidate = 'non_factual_text_$suffix';
  }
  return candidate;
}

String _claimValidationReason(ClaimValidationResult result) {
  if (result.trustLevel == ClaimTrustLevel.verified) {
    return 'evidence_accepted';
  }
  if (result.trustLevel == ClaimTrustLevel.notVerifiable) {
    return 'not_fact_checked';
  }
  return result.issues.firstOrNull?.reason.name ?? 'verification_unavailable';
}

final class EvidenceRequirementCoverage {
  EvidenceRequirementCoverage({
    required List<String> coveredRequirementIds,
    required List<String> missingRequirementIds,
    required List<String> evidenceIds,
  }) : coveredRequirementIds = List<String>.unmodifiable(coveredRequirementIds),
       missingRequirementIds = List<String>.unmodifiable(missingRequirementIds),
       evidenceIds = List<String>.unmodifiable(evidenceIds);

  final List<String> coveredRequirementIds;
  final List<String> missingRequirementIds;
  final List<String> evidenceIds;

  bool get isComplete => missingRequirementIds.isEmpty;
}

/// Validates model-proposed claim bindings against the persisted fact ledger.
final class GroundedAnswerValidator {
  const GroundedAnswerValidator({
    required ToolEvidenceRepository evidenceRepository,
    ClaimEvidenceReviewer? reviewer,
  }) : _evidenceRepository = evidenceRepository,
       _reviewer = reviewer;

  final ToolEvidenceRepository _evidenceRepository;
  final ClaimEvidenceReviewer? _reviewer;

  Future<GroundedAnswerValidationResult> validate({
    required String runId,
    required GroundedAnswerCandidate candidate,
    required Iterable<ClaimEvidenceRequirement> requirements,
    required DateTime validatedAt,
  }) async {
    final normalizedRunId = _normalizedRequiredText(runId, 'runId');
    final instant = validatedAt.toUtc();
    final requirementByClaim = <String, ClaimEvidenceRequirement>{};
    for (final requirement in requirements) {
      if (requirementByClaim.containsKey(requirement.claimId)) {
        throw ArgumentError.value(
          requirement.claimId,
          'requirements',
          'Claim requirements must have unique claim IDs.',
        );
      }
      requirementByClaim[requirement.claimId] = requirement;
    }

    final loadedEvidence = <String, Future<_LedgerEvidence>>{};
    Future<_LedgerEvidence> loadEvidence(String evidenceId) =>
        loadedEvidence.putIfAbsent(evidenceId, () => _load(evidenceId));

    final claimResults = <ClaimValidationResult>[];
    for (final claim in candidate.claims) {
      claimResults.add(
        await _validateClaim(
          claim: claim,
          requirement: requirementByClaim[claim.claimId],
          runId: normalizedRunId,
          validatedAt: instant,
          loadEvidence: loadEvidence,
        ),
      );
    }

    final claimIds = candidate.claims.map((claim) => claim.claimId).toSet();
    final unmatchedRequirementIds = [
      for (final requirement in requirementByClaim.values)
        if (!claimIds.contains(requirement.claimId)) requirement.claimId,
    ];

    final verifiableClaims = claimResults.where(
      (result) => result.trustLevel != ClaimTrustLevel.notVerifiable,
    );
    final verifiedCount =
        verifiableClaims
            .where((result) => result.trustLevel == ClaimTrustLevel.verified)
            .length;
    final verifiableCount =
        verifiableClaims.length + unmatchedRequirementIds.length;
    final trustLevel =
        verifiableCount == 0 || verifiedCount == 0
            ? AnswerTrustLevel.unverified
            : verifiedCount == verifiableCount
            ? AnswerTrustLevel.verified
            : AnswerTrustLevel.partiallyVerified;
    final reasonCode = switch (trustLevel) {
      AnswerTrustLevel.verified => 'all_claims_verified',
      AnswerTrustLevel.partiallyVerified => 'some_claims_verified',
      AnswerTrustLevel.unverified when verifiableCount == 0 =>
        'no_verifiable_claims',
      AnswerTrustLevel.unverified => 'no_claims_verified',
      AnswerTrustLevel.failed => 'evidence_validation_failed',
    };
    final acceptedIds = <String>{};
    for (final result in claimResults) {
      acceptedIds.addAll(result.acceptedEvidenceIds);
    }
    return GroundedAnswerValidationResult(
      trustLevel: trustLevel,
      reasonCode: reasonCode,
      claims: claimResults,
      evidenceIds: acceptedIds.toList(growable: false),
      nonFactualText: candidate.nonFactualText,
      unmatchedRequirementIds: unmatchedRequirementIds,
    );
  }

  /// Checks whether persisted evidence covers application-authored needs
  /// before any final answer is synthesized.
  Future<EvidenceRequirementCoverage> evaluateCoverage({
    required String runId,
    required Iterable<ClaimEvidenceRequirement> requirements,
    required Iterable<String> evidenceIds,
    required DateTime validatedAt,
  }) async {
    final normalizedRunId = _normalizedRequiredText(runId, 'runId');
    final ids = List<String>.unmodifiable(evidenceIds.toSet());
    final loadedEvidence = <String, Future<_LedgerEvidence>>{};
    Future<_LedgerEvidence> loadEvidence(String evidenceId) =>
        loadedEvidence.putIfAbsent(evidenceId, () => _load(evidenceId));
    final covered = <String>[];
    final missing = <String>[];
    final acceptedEvidenceIds = <String>{};
    final seenRequirements = <String>{};

    for (final requirement in requirements) {
      if (!seenRequirements.add(requirement.claimId)) {
        throw ArgumentError.value(
          requirement.claimId,
          'requirements',
          'Claim requirements must have unique claim IDs.',
        );
      }
      final claimKind = requirement.claimKind;
      if (claimKind == null || !_requiresEvidence(claimKind)) {
        throw ArgumentError.value(
          claimKind,
          'requirements',
          'Coverage requirements need an evidence-bearing claim kind.',
        );
      }
      final claim = AnswerClaim(
        claimId: requirement.claimId,
        text: 'Verification requirement ${requirement.claimId}.',
        kind: claimKind,
        evidenceIds: ids,
      );
      final result = await _validateClaim(
        claim: claim,
        requirement: requirement,
        runId: normalizedRunId,
        validatedAt: validatedAt.toUtc(),
        loadEvidence: loadEvidence,
        applyReviewer: false,
      );
      if (result.trustLevel == ClaimTrustLevel.verified) {
        covered.add(requirement.claimId);
        acceptedEvidenceIds.addAll(result.acceptedEvidenceIds);
      } else {
        missing.add(requirement.claimId);
      }
    }
    return EvidenceRequirementCoverage(
      coveredRequirementIds: covered,
      missingRequirementIds: missing,
      evidenceIds: acceptedEvidenceIds.toList(growable: false),
    );
  }

  Future<ClaimValidationResult> _validateClaim({
    required AnswerClaim claim,
    required ClaimEvidenceRequirement? requirement,
    required String runId,
    required DateTime validatedAt,
    required Future<_LedgerEvidence> Function(String evidenceId) loadEvidence,
    bool applyReviewer = true,
  }) async {
    if (!_requiresEvidence(claim.kind)) {
      return ClaimValidationResult(
        claim: claim,
        trustLevel: ClaimTrustLevel.notVerifiable,
        issues: [
          for (final evidenceId in claim.evidenceIds)
            EvidenceValidationIssue(
              evidenceId: evidenceId,
              reason: EvidenceRejectionReason.claimDoesNotAcceptEvidence,
            ),
        ],
      );
    }
    if (claim.evidenceIds.isEmpty) {
      return ClaimValidationResult(
        claim: claim,
        trustLevel: ClaimTrustLevel.unverified,
        issues: const [
          EvidenceValidationIssue(
            evidenceId: '',
            reason: EvidenceRejectionReason.claimHasNoEvidence,
          ),
        ],
      );
    }
    if (requirement == null) {
      return ClaimValidationResult(
        claim: claim,
        trustLevel: ClaimTrustLevel.unverified,
        issues: [
          for (final evidenceId in claim.evidenceIds)
            EvidenceValidationIssue(
              evidenceId: evidenceId,
              reason: EvidenceRejectionReason.claimRequirementMissing,
            ),
        ],
      );
    }
    if (!_isRequirementValidForClaim(requirement, claim.kind)) {
      return ClaimValidationResult(
        claim: claim,
        trustLevel: ClaimTrustLevel.unverified,
        issues: [
          for (final evidenceId in claim.evidenceIds)
            EvidenceValidationIssue(
              evidenceId: evidenceId,
              reason: EvidenceRejectionReason.claimRequirementInvalid,
            ),
        ],
      );
    }
    if (!requirement.verificationAvailable) {
      return ClaimValidationResult(
        claim: claim,
        trustLevel: ClaimTrustLevel.unverified,
        issues: [
          for (final evidenceId in claim.evidenceIds)
            EvidenceValidationIssue(
              evidenceId: evidenceId,
              reason: EvidenceRejectionReason.verificationUnavailable,
            ),
        ],
      );
    }

    final acceptedIds = <String>[];
    final issues = <EvidenceValidationIssue>[];
    for (final evidenceId in claim.evidenceIds) {
      final ledgerEvidence = await loadEvidence(evidenceId);
      final reason = _rejectDeterministically(
        ledgerEvidence: ledgerEvidence,
        claim: claim,
        requirement: requirement,
        runId: runId,
        validatedAt: validatedAt,
      );
      if (reason != null) {
        issues.add(
          EvidenceValidationIssue(evidenceId: evidenceId, reason: reason),
        );
        continue;
      }
      final evidence = ledgerEvidence.record!;
      final reviewer = applyReviewer ? _reviewer : null;
      if (reviewer != null) {
        var supported = false;
        try {
          supported = await reviewer.supports(claim: claim, evidence: evidence);
        } on Object {
          supported = false;
        }
        if (!supported) {
          issues.add(
            EvidenceValidationIssue(
              evidenceId: evidenceId,
              reason: EvidenceRejectionReason.modelReviewRejected,
            ),
          );
          continue;
        }
      }
      acceptedIds.add(evidenceId);
    }
    return ClaimValidationResult(
      claim: claim,
      trustLevel:
          acceptedIds.isEmpty
              ? ClaimTrustLevel.unverified
              : ClaimTrustLevel.verified,
      acceptedEvidenceIds: acceptedIds,
      issues: issues,
    );
  }

  EvidenceRejectionReason? _rejectDeterministically({
    required _LedgerEvidence ledgerEvidence,
    required AnswerClaim claim,
    required ClaimEvidenceRequirement requirement,
    required String runId,
    required DateTime validatedAt,
  }) {
    if (ledgerEvidence.unavailable) {
      return EvidenceRejectionReason.evidenceLedgerUnavailable;
    }
    final evidence = ledgerEvidence.record;
    if (evidence == null) return EvidenceRejectionReason.evidenceNotFound;
    if (evidence.runId != runId) {
      return EvidenceRejectionReason.evidenceRunMismatch;
    }
    if (!evidence.persisted) {
      return EvidenceRejectionReason.evidenceNotPersisted;
    }
    if (!ledgerEvidence.integrityValid) {
      return EvidenceRejectionReason.evidenceIntegrityInvalid;
    }
    final hardKindFailure = _hardKindFailure(claim.kind, evidence.evidenceKind);
    if (hardKindFailure != null) return hardKindFailure;
    if (!_hasCompatibleTerminalStatus(claim.kind, evidence)) {
      return EvidenceRejectionReason.evidenceTerminalStatusInvalid;
    }
    if (!requirement.allowedEvidenceKinds.contains(evidence.evidenceKind)) {
      return EvidenceRejectionReason.evidenceKindMismatch;
    }
    if (!_capabilitiesSupportKind(evidence) ||
        !evidence.capabilities.containsAll(requirement.requiredCapabilities)) {
      return EvidenceRejectionReason.evidenceCapabilityMismatch;
    }
    if (requirement.toolName.isNotEmpty &&
        evidence.toolName != requirement.toolName) {
      return EvidenceRejectionReason.evidenceSubjectMismatch;
    }
    if (requirement.attemptId.isNotEmpty &&
        evidence.attemptId != requirement.attemptId) {
      return EvidenceRejectionReason.evidenceSubjectMismatch;
    }
    if (evidence.evidenceKind != EvidenceKind.executionFailure) {
      if (evidence.subject != requirement.subject) {
        return EvidenceRejectionReason.evidenceSubjectMismatch;
      }
      if (!_sameJson(evidence.scope, requirement.scope)) {
        return EvidenceRejectionReason.evidenceScopeMismatch;
      }
    }
    if (validatedAt.isBefore(evidence.observedAt.toUtc())) {
      return EvidenceRejectionReason.evidenceNotYetObserved;
    }
    if (claim.kind == ClaimKind.currentFact && evidence.validUntil == null) {
      return EvidenceRejectionReason.evidenceValidityMissing;
    }
    final validUntil = evidence.validUntil?.toUtc();
    if (validUntil != null && !validatedAt.isBefore(validUntil)) {
      return EvidenceRejectionReason.evidenceExpired;
    }
    if (evidence.evidenceKind != EvidenceKind.executionFailure) {
      if (!evidence.schemaValid) {
        return EvidenceRejectionReason.evidenceSchemaInvalid;
      }
      if (evidence.truncated) {
        return EvidenceRejectionReason.evidenceTruncated;
      }
      if (evidence.resultSummary.trim().isEmpty ||
          evidence.structuredFacts.isEmpty) {
        return EvidenceRejectionReason.evidenceEmpty;
      }
      final factNames =
          evidence.structuredFacts.map((fact) => fact.name).toSet();
      if (!factNames.containsAll(requirement.requiredFactNames)) {
        return EvidenceRejectionReason.evidenceEmpty;
      }
      final factsByName = <String, Object?>{
        for (final fact in evidence.structuredFacts) fact.name: fact.value,
      };
      for (final expected in requirement.requiredFactValues.entries) {
        if (!_sameJson(factsByName[expected.key], expected.value)) {
          return EvidenceRejectionReason.evidenceFactValueMismatch;
        }
      }
    }
    return null;
  }

  Future<_LedgerEvidence> _load(String evidenceId) async {
    try {
      final record = await _evidenceRepository.getById(evidenceId);
      if (record == null) return const _LedgerEvidence();
      if (!record.persisted) return _LedgerEvidence(record: record);
      final integrityValid = await _evidenceRepository.verifyDigest(evidenceId);
      return _LedgerEvidence(record: record, integrityValid: integrityValid);
    } on Object {
      return const _LedgerEvidence(unavailable: true);
    }
  }
}

final class _LedgerEvidence {
  const _LedgerEvidence({
    this.record,
    this.integrityValid = false,
    this.unavailable = false,
  });

  final ToolEvidenceRecord? record;
  final bool integrityValid;
  final bool unavailable;
}

bool _requiresEvidence(ClaimKind kind) => switch (kind) {
  ClaimKind.externalFact ||
  ClaimKind.currentFact ||
  ClaimKind.completedAction ||
  ClaimKind.executionFailure => true,
  ClaimKind.userAssertion || ClaimKind.nonFactual => false,
};

bool _isRequirementValidForClaim(
  ClaimEvidenceRequirement requirement,
  ClaimKind kind,
) {
  if (requirement.claimKind != null && requirement.claimKind != kind) {
    return false;
  }
  if (kind == ClaimKind.executionFailure) {
    return requirement.allowedEvidenceKinds.length == 1 &&
        requirement.allowedEvidenceKinds.contains(
          EvidenceKind.executionFailure,
        ) &&
        (requirement.toolName.isNotEmpty || requirement.attemptId.isNotEmpty);
  }
  return requirement.subject.isNotEmpty &&
      requirement.scope.isNotEmpty &&
      requirement.requiredCapabilities.isNotEmpty &&
      requirement.requiredFactNames.isNotEmpty;
}

bool _hasCompatibleTerminalStatus(ClaimKind kind, ToolEvidenceRecord evidence) {
  if (kind == ClaimKind.executionFailure) {
    return const <ToolInvocationStatus>{
      ToolInvocationStatus.failed,
      ToolInvocationStatus.denied,
      ToolInvocationStatus.cancelled,
      ToolInvocationStatus.timedOut,
    }.contains(evidence.terminalStatus);
  }
  return evidence.terminalStatus == ToolInvocationStatus.succeeded;
}

EvidenceRejectionReason? _hardKindFailure(
  ClaimKind claimKind,
  EvidenceKind evidenceKind,
) {
  if (evidenceKind == EvidenceKind.executionFailure ||
      claimKind == ClaimKind.executionFailure) {
    return evidenceKind == EvidenceKind.executionFailure &&
            claimKind == ClaimKind.executionFailure
        ? null
        : EvidenceRejectionReason.executionFailureEvidenceMismatch;
  }
  if (evidenceKind == EvidenceKind.actionReceipt &&
      claimKind != ClaimKind.completedAction) {
    return EvidenceRejectionReason.actionReceiptCannotSupportState;
  }
  return switch (claimKind) {
    ClaimKind.currentFact when evidenceKind != EvidenceKind.observation =>
      EvidenceRejectionReason.evidenceKindMismatch,
    ClaimKind.completedAction when evidenceKind != EvidenceKind.actionReceipt =>
      EvidenceRejectionReason.evidenceKindMismatch,
    ClaimKind.externalFact ||
    ClaimKind.userAssertion ||
    ClaimKind.nonFactual => null,
    ClaimKind.currentFact ||
    ClaimKind.completedAction ||
    ClaimKind.executionFailure => null,
  };
}

bool _capabilitiesSupportKind(ToolEvidenceRecord evidence) {
  const read = <ToolCapability>{
    ToolCapability.localRead,
    ToolCapability.externalRead,
    ToolCapability.network,
  };
  const write = <ToolCapability>{
    ToolCapability.localWrite,
    ToolCapability.externalWrite,
  };
  final hasRead = evidence.capabilities.any(read.contains);
  final hasWrite = evidence.capabilities.any(write.contains);
  return switch (evidence.evidenceKind) {
    EvidenceKind.observation => hasRead && !hasWrite,
    EvidenceKind.calculation =>
      evidence.capabilities.contains(ToolCapability.compute) &&
          !hasRead &&
          !hasWrite,
    EvidenceKind.actionReceipt => hasWrite,
    EvidenceKind.executionFailure => true,
  };
}

String _normalizedRequiredText(String value, String name) {
  if (value.isEmpty || value.trim() != value) {
    throw ArgumentError.value(
      value,
      name,
      'Value must be non-empty and normalized.',
    );
  }
  return value;
}

void _requireNormalizedOptionalText(String value, String name) {
  if (value.trim() != value) {
    throw ArgumentError.value(value, name, 'Value must be normalized.');
  }
}

Map<String, Object?> _freezeJsonMap(Map<String, Object?> value, String name) {
  try {
    final decoded = jsonDecode(jsonEncode(value));
    if (decoded is! Map<String, Object?>) throw const FormatException();
    return Map<String, Object?>.unmodifiable(
      decoded.map((key, item) => MapEntry(key, _freezeJsonValue(item))),
    );
  } on Object catch (error) {
    throw ArgumentError.value(value, name, 'Value must be JSON-safe: $error');
  }
}

Object? _freezeJsonValue(Object? value) => switch (value) {
  final Map<String, Object?> map => Map<String, Object?>.unmodifiable(
    map.map((key, item) => MapEntry(key, _freezeJsonValue(item))),
  ),
  final List<Object?> list => List<Object?>.unmodifiable(
    list.map(_freezeJsonValue),
  ),
  _ => value,
};

bool _sameJson(Object? left, Object? right) =>
    _canonicalJson(left) == _canonicalJson(right);

String _canonicalJson(Object? value) => jsonEncode(switch (value) {
  final Map<String, Object?> map => <String, Object?>{
    for (final key in (map.keys.toList()..sort()))
      key: jsonDecode(_canonicalJson(map[key])),
  },
  final List<Object?> list => [
    for (final item in list) jsonDecode(_canonicalJson(item)),
  ],
  _ => value,
});
