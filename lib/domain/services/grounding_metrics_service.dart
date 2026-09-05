import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/grounding_metrics_repository.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';

/// Converts terminal protocol state into aggregate, content-free counters.
final class GroundingMetricsService {
  const GroundingMetricsService({
    required GroundingMetricsRepository repository,
    required ToolEvidenceRepository evidenceRepository,
  }) : _repository = repository,
       _evidenceRepository = evidenceRepository;

  final GroundingMetricsRepository _repository;
  final ToolEvidenceRepository _evidenceRepository;

  Future<void> recordTerminalMessage(Message message) async {
    final proposedIds = <String>[
      for (final claim in message.grounding.claims) ...claim.claim.evidenceIds,
    ];
    final resolved = <String, bool>{};
    for (final evidenceId in proposedIds.toSet()) {
      try {
        final evidence = await _evidenceRepository.getById(evidenceId);
        resolved[evidenceId] =
            evidence != null &&
            evidence.persisted &&
            evidence.runId == message.runId &&
            evidence.messageId == message.messageId &&
            await _evidenceRepository.verifyDigest(evidenceId);
      } on Object {
        resolved[evidenceId] = false;
      }
    }

    final deltas = <GroundingMetricDelta>[
      if (proposedIds.isNotEmpty)
        GroundingMetricDelta(
          name: GroundingMetricName.evidenceReferenceTotal,
          count: proposedIds.length,
        ),
      if (proposedIds.where((id) => resolved[id] ?? false).isNotEmpty)
        GroundingMetricDelta(
          name: GroundingMetricName.evidenceReferenceResolved,
          count: proposedIds.where((id) => resolved[id] ?? false).length,
        ),
    ];

    final claims = message.grounding.claims;
    var unsupportedPasses = 0;
    for (final claim in claims) {
      final requiresEvidence = _requiresEvidence(claim.claim.kind);
      final evidenceIsUsable =
          claim.acceptedEvidenceIds.isNotEmpty &&
          claim.acceptedEvidenceIds.every((id) => resolved[id] ?? false);
      if (claim.trustLevel == ClaimTrustLevel.verified &&
          requiresEvidence &&
          !evidenceIsUsable) {
        unsupportedPasses += 1;
      }
      if (requiresEvidence && claim.trustLevel != ClaimTrustLevel.verified) {
        deltas.add(
          GroundingMetricDelta(
            name: GroundingMetricName.gateRejection,
            category: _safeCategory(claim.reasonCode, 'verification_rejected'),
          ),
        );
      }
    }
    if (unsupportedPasses > 0) {
      deltas.add(
        GroundingMetricDelta(
          name: GroundingMetricName.unsupportedClaimPass,
          count: unsupportedPasses,
        ),
      );
    }
    if ((message.grounding.trustLevel == AnswerTrustLevel.failed ||
            (message.grounding.trustLevel == AnswerTrustLevel.unverified &&
                claims.isEmpty)) &&
        message.grounding.reasonCode.isNotEmpty) {
      deltas.add(
        GroundingMetricDelta(
          name: GroundingMetricName.gateRejection,
          category: _safeCategory(
            message.grounding.reasonCode,
            'answer_gate_rejected',
          ),
        ),
      );
    }

    if (message.grounding.trustLevel == AnswerTrustLevel.verified ||
        message.grounding.trustLevel == AnswerTrustLevel.partiallyVerified) {
      final required = message.grounding.evidenceIds;
      deltas.add(
        GroundingMetricDelta(
          name: GroundingMetricName.verifiedEvidenceRequired,
          count: required.length,
        ),
      );
      final persisted = required.where((id) => resolved[id] ?? false).length;
      if (persisted > 0) {
        deltas.add(
          GroundingMetricDelta(
            name: GroundingMetricName.verifiedEvidencePersisted,
            count: persisted,
          ),
        );
      }
    }

    final successfulWrites = <String, int>{};
    for (final call in message.processInfo.toolCalls) {
      if (call.status != ToolInvocationStatus.succeeded.name ||
          (call.riskLevel != ToolRiskLevel.write.name &&
              call.riskLevel != ToolRiskLevel.destructive.name)) {
        continue;
      }
      final identity =
          call.providerCallId.isNotEmpty
              ? call.providerCallId
              : call.invocationId;
      if (identity.isEmpty) continue;
      successfulWrites[identity] = (successfulWrites[identity] ?? 0) + 1;
    }
    final duplicateWrites = successfulWrites.values.fold<int>(
      0,
      (sum, count) => sum + (count > 1 ? count - 1 : 0),
    );
    if (duplicateWrites > 0) {
      deltas.add(
        GroundingMetricDelta(
          name: GroundingMetricName.duplicateSideEffect,
          count: duplicateWrites,
        ),
      );
    }

    final reasonCode = message.grounding.reasonCode;
    if (reasonCode.startsWith('provider_')) {
      deltas.add(
        GroundingMetricDelta(
          name: GroundingMetricName.providerFailure,
          category: _safeCategory(reasonCode, 'provider_failure'),
        ),
      );
    }
    if (deltas.isNotEmpty) {
      final observationId =
          'message_${sha256.convert(utf8.encode(message.messageId))}';
      await _repository.record(deltas, observationId: observationId);
    }
  }

  Future<void> recordProviderFailure(ProviderFailure failure) =>
      _repository.record([
        GroundingMetricDelta(
          name: GroundingMetricName.providerFailure,
          category: _enumCategory(failure.kind.name),
        ),
      ]);

  bool _requiresEvidence(ClaimKind kind) => switch (kind) {
    ClaimKind.externalFact ||
    ClaimKind.currentFact ||
    ClaimKind.completedAction ||
    ClaimKind.executionFailure => true,
    ClaimKind.userAssertion || ClaimKind.nonFactual => false,
  };

  String _safeCategory(String value, String fallback) =>
      RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(value) ? value : fallback;

  String _enumCategory(String value) => value.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}
