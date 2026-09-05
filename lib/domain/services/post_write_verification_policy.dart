import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/services/grounded_answer_validator.dart';

/// Application-owned postconditions derived from one persisted write receipt.
final class PostWriteVerificationPlan {
  PostWriteVerificationPlan({
    required this.actionRequirement,
    required this.stateRequirement,
    this.verificationToolName = '',
  });

  final ClaimEvidenceRequirement actionRequirement;
  final ClaimEvidenceRequirement stateRequirement;
  final String verificationToolName;

  bool get hasPairedRead => verificationToolName.isNotEmpty;
}

/// Converts a successful write receipt into action and final-state gates.
///
/// A read Tool is paired only when it is already exposed for this run, has an
/// observation contract for the same subject, and has no write/process power.
/// Tool discovery and permission expansion remain outside this policy.
final class PostWriteVerificationPolicy {
  const PostWriteVerificationPolicy();

  PostWriteVerificationPlan? plan({
    required ToolInvocationRecord invocation,
    required ToolDefinition writeTool,
    required Iterable<ToolDefinition> exposedTools,
    Set<String> reservedClaimIds = const {},
  }) {
    final receipt = invocation.evidenceCandidate;
    if (!writeTool.requiresReadAfterWrite ||
        invocation.status != ToolInvocationStatus.succeeded ||
        receipt == null ||
        receipt.evidenceKind != EvidenceKind.actionReceipt) {
      return null;
    }

    final actionFacts = <String, Object?>{};
    final postconditionFacts = <String, Object?>{};
    for (final fact in receipt.structuredFacts) {
      if (fact.name.startsWith('action.')) {
        actionFacts[fact.name] = fact.value;
      } else {
        postconditionFacts[fact.name] = fact.value;
      }
    }
    // A completed-action claim always requires an affirmative completion
    // receipt. A successful call that reports only acceptance (or false) must
    // not be promoted to action completion.
    actionFacts['action.completed'] = true;
    if (postconditionFacts.isEmpty) {
      // An undeclared postcondition can never be satisfied accidentally.
      postconditionFacts['postcondition.confirmed'] = true;
    }

    final matchingReads = exposedTools.where(
      (candidate) => _canVerify(
        writeTool: writeTool,
        readTool: candidate,
        subject: receipt.subject,
      ),
    );
    final pairedRead = matchingReads.length == 1 ? matchingReads.single : null;
    final requiredReadCapabilities =
        pairedRead?.capabilities ?? _fallbackReadCapabilities(writeTool);
    final allocatedClaimIds = <String>{...reservedClaimIds};
    final actionClaimId = _allocateClaimId(
      '${invocation.attemptId}:action',
      allocatedClaimIds,
    );
    final stateClaimId = _allocateClaimId(
      '${invocation.attemptId}:state',
      allocatedClaimIds,
    );

    return PostWriteVerificationPlan(
      actionRequirement: ClaimEvidenceRequirement(
        claimId: actionClaimId,
        claimKind: ClaimKind.completedAction,
        allowedEvidenceKinds: const {EvidenceKind.actionReceipt},
        subject: receipt.subject,
        scope: receipt.scope,
        requiredCapabilities: writeTool.capabilities,
        requiredFactNames: actionFacts.keys.toSet(),
        requiredFactValues: actionFacts,
        toolName: writeTool.name,
        attemptId: invocation.attemptId,
      ),
      stateRequirement: ClaimEvidenceRequirement(
        claimId: stateClaimId,
        claimKind: ClaimKind.currentFact,
        allowedEvidenceKinds: const {EvidenceKind.observation},
        subject: receipt.subject,
        scope: receipt.scope,
        requiredCapabilities: requiredReadCapabilities,
        requiredFactNames: postconditionFacts.keys.toSet(),
        requiredFactValues: postconditionFacts,
        toolName: pairedRead?.name ?? '',
        verificationAvailable: pairedRead != null,
      ),
      verificationToolName: pairedRead?.name ?? '',
    );
  }

  bool _canVerify({
    required ToolDefinition writeTool,
    required ToolDefinition readTool,
    required String subject,
  }) {
    if (readTool.name == writeTool.name ||
        readTool.riskLevel != ToolRiskLevel.readOnly ||
        !readTool.evidenceCapabilities.contains(EvidenceKind.observation) ||
        readTool.evidenceScope?.subject != subject ||
        readTool.capabilities.any(
          const <ToolCapability>{
            ToolCapability.localWrite,
            ToolCapability.externalWrite,
            ToolCapability.process,
          }.contains,
        )) {
      return false;
    }
    if (readTool.source != writeTool.source) return false;
    return writeTool.source != ToolSource.mcp ||
        readTool.mcpServerName == writeTool.mcpServerName;
  }

  Set<ToolCapability> _fallbackReadCapabilities(ToolDefinition writeTool) {
    if (writeTool.capabilities.contains(ToolCapability.localWrite)) {
      return const {ToolCapability.localRead};
    }
    if (writeTool.capabilities.contains(ToolCapability.externalWrite)) {
      return const {ToolCapability.externalRead};
    }
    return const {ToolCapability.localRead};
  }

  String _allocateClaimId(String base, Set<String> allocated) {
    var candidate = base;
    var suffix = 2;
    while (!allocated.add(candidate)) {
      candidate = '$base:$suffix';
      suffix += 1;
    }
    return candidate;
  }
}
