import 'package:stars/domain/models/models.dart';

/// Minimal application-owned Tool exposure for one verification run.
final class VerificationToolDiscoveryResult {
  VerificationToolDiscoveryResult({
    Set<String> toolNames = const {},
    this.unavailableReason = '',
  }) : toolNames = Set<String>.unmodifiable(toolNames);

  final Set<String> toolNames;
  final String unavailableReason;
}

/// Selects safe verification Tools from an explicit application allowlist.
///
/// The registry is never enumerated wholesale. Equivalent evidence contracts
/// collapse to one deterministic candidate, and a Tool already requested by a
/// Skill is not exposed a second time through the verification channel.
final class VerificationToolDiscovery {
  const VerificationToolDiscovery();

  VerificationToolDiscoveryResult discover({
    required ToolRegistry? registry,
    required Set<String> candidateToolNames,
    Set<String> requestedToolNames = const {},
    Set<EvidenceKind> requiredEvidenceKinds = basicVerificationEvidenceKinds,
  }) {
    if (candidateToolNames.isEmpty) {
      return VerificationToolDiscoveryResult();
    }
    if (registry == null || requiredEvidenceKinds.isEmpty) {
      return VerificationToolDiscoveryResult(
        unavailableReason: 'verification_tool_unavailable',
      );
    }

    final coveredContracts = <String>{};
    var hasEligibleRequestedTool = false;
    for (final name in requestedToolNames) {
      final definition = registry.find(name)?.definition;
      if (definition == null ||
          !isEligibleVerificationTool(
            definition,
            requiredEvidenceKinds: requiredEvidenceKinds,
          )) {
        continue;
      }
      hasEligibleRequestedTool = true;
      coveredContracts.addAll(
        _evidenceContracts(definition, requiredEvidenceKinds),
      );
    }

    final selected = <String>{};
    for (final definition in registry.list(allowedNames: candidateToolNames)) {
      if (!isEligibleVerificationTool(
            definition,
            requiredEvidenceKinds: requiredEvidenceKinds,
          ) ||
          requestedToolNames.contains(definition.name)) {
        continue;
      }
      final contracts = _evidenceContracts(definition, requiredEvidenceKinds);
      if (contracts.every(coveredContracts.contains)) continue;
      selected.add(definition.name);
      coveredContracts.addAll(contracts);
    }

    return VerificationToolDiscoveryResult(
      toolNames: selected,
      unavailableReason:
          selected.isEmpty && !hasEligibleRequestedTool
              ? 'verification_tool_unavailable'
              : '',
    );
  }

  Set<String> _evidenceContracts(
    ToolDefinition definition,
    Set<EvidenceKind> requiredEvidenceKinds,
  ) {
    final capabilities =
        definition.capabilities.map((item) => item.name).toList()..sort();
    final subject = definition.evidenceScope!.subject;
    return {
      for (final kind in definition.evidenceCapabilities)
        if (requiredEvidenceKinds.contains(kind))
          '${kind.name}|$subject|${capabilities.join(',')}',
    };
  }
}
