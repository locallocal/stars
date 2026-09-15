import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/grounded_answer_validator.dart';
import 'package:stars/domain/services/post_write_verification_policy.dart';

/// Rebuilds post-write requirements from committed receipts after a restart.
/// Final verification still belongs to the task's terminal-commit pipeline.
List<ClaimEvidenceRequirement> taskVerificationRequirements(
  TaskExecutionSnapshot snapshot,
  List<ToolDefinition> tools,
) {
  final requirements = <ClaimEvidenceRequirement>[];
  for (final evidence in snapshot.evidence) {
    if (evidence.terminalStatus != ToolInvocationStatus.succeeded ||
        evidence.evidenceKind != EvidenceKind.actionReceipt) {
      continue;
    }
    final definition =
        tools.where((tool) => tool.name == evidence.toolName).firstOrNull;
    if (definition == null) continue;
    final plan = const PostWriteVerificationPolicy().plan(
      invocation: ToolInvocationRecord(
        runId: evidence.runId,
        invocationId: evidence.invocationId,
        attemptId: evidence.attemptId,
        providerCallId: evidence.providerCallId,
        name: evidence.toolName,
        source: evidence.source,
        riskLevel: definition.riskLevel,
        status: evidence.terminalStatus,
        startedAt: evidence.observedAt,
        evidenceCandidate: ToolEvidenceCandidate(
          toolVersion: evidence.toolVersion,
          capabilities: evidence.capabilities,
          evidenceKind: evidence.evidenceKind,
          subject: evidence.subject,
          scope: evidence.scope,
          structuredFacts: evidence.structuredFacts,
          argumentsDigest: evidence.argumentsDigest,
          resultDigest: evidence.resultDigest,
          observedAt: evidence.observedAt,
          validUntil: evidence.validUntil,
        ),
      ),
      writeTool: definition,
      exposedTools: tools,
      reservedClaimIds: requirements.map((r) => r.claimId).toSet(),
    );
    if (plan != null) {
      requirements.addAll([plan.actionRequirement, plan.stateRequirement]);
    }
  }
  return List.unmodifiable(requirements);
}

List<GroundedClaimSynthesisRequirement> groundedSynthesisRequirements(
  Iterable<ClaimEvidenceRequirement> requirements,
) => [
  for (final requirement in requirements)
    GroundedClaimSynthesisRequirement(
      claimId: requirement.claimId,
      claimKind: requirement.claimKind,
      subject: requirement.subject,
      scope: requirement.scope,
      requiredFactNames: requirement.requiredFactNames,
      requiredFactValues: requirement.requiredFactValues,
      toolName: requirement.toolName,
      verificationAvailable: requirement.verificationAvailable,
    ),
];
