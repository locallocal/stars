import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/grounded_answer_validator.dart';
import 'package:stars/domain/services/post_write_verification_policy.dart';
import 'package:stars/domain/services/task_evidence_scope.dart';

/// Rebuilds claim bindings and post-write requirements from committed evidence.
/// Final verification still belongs to the task's terminal-commit pipeline.
List<ClaimEvidenceRequirement> taskVerificationRequirements(
  TaskExecutionSnapshot snapshot,
  List<ToolDefinition> tools, {
  bool includeObservations = true,
}) {
  final requirements = <ClaimEvidenceRequirement>[];
  final scope = TaskEvidenceScope(snapshot);
  for (final evidence in snapshot.evidence) {
    if (!scope.contains(evidence, snapshot.task.taskId)) continue;
    if (evidence.evidenceKind != EvidenceKind.actionReceipt) {
      if (!includeObservations ||
          evidence.subject.isEmpty ||
          evidence.scope.isEmpty ||
          evidence.structuredFacts.isEmpty) {
        continue;
      }
      requirements.add(
        ClaimEvidenceRequirement(
          claimId: '${evidence.attemptId}:fact',
          claimKind:
              evidence.evidenceKind == EvidenceKind.observation
                  ? ClaimKind.currentFact
                  : ClaimKind.externalFact,
          allowedEvidenceKinds: {evidence.evidenceKind},
          subject: evidence.subject,
          scope: evidence.scope,
          requiredCapabilities: evidence.capabilities,
          requiredFactValues: {
            for (final fact in evidence.structuredFacts) fact.name: fact.value,
          },
          toolName: evidence.toolName,
          attemptId: evidence.attemptId,
        ),
      );
      continue;
    }
    final definition =
        tools.where((tool) => tool.name == evidence.toolName).firstOrNull;
    // A removed/changed tool cannot erase a committed write's postconditions.
    final writeTool = ToolDefinition(
      name: evidence.toolName,
      description: 'Committed write receipt',
      source: evidence.source,
      riskLevel: ToolRiskLevel.write,
      inputSchema: const {'type': 'object'},
      outputSchema: const {
        'type': 'object',
        'properties': toolEvidenceOutputSchemaProperties,
        'required': toolEvidenceOutputRequiredFields,
      },
      toolVersion: evidence.toolVersion,
      evidenceCapabilities: const {EvidenceKind.actionReceipt},
      evidenceScope: ToolEvidenceScopeRule(
        subject: evidence.subject,
        fixedScope: evidence.scope,
      ),
      capabilities: evidence.capabilities,
      mcpServerName: definition?.mcpServerName ?? '',
      requiresReadAfterWrite: true,
    );
    final plan = const PostWriteVerificationPolicy().plan(
      invocation: ToolInvocationRecord(
        runId: evidence.runId,
        invocationId: evidence.invocationId,
        attemptId: evidence.attemptId,
        providerCallId: evidence.providerCallId,
        name: evidence.toolName,
        source: evidence.source,
        riskLevel: writeTool.riskLevel,
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
      writeTool: writeTool,
      exposedTools: tools,
      reservedClaimIds: requirements.map((r) => r.claimId).toSet(),
    );
    if (plan != null) {
      final writeSequence =
          snapshot.events
              .where(
                (event) =>
                    event.kind == TaskEventKind.toolSucceeded &&
                    event.attemptId == evidence.attemptId,
              )
              .firstOrNull
              ?.sequence;
      final state = plan.stateRequirement;
      requirements.addAll([
        plan.actionRequirement,
        ClaimEvidenceRequirement(
          claimId: state.claimId,
          claimKind: state.claimKind,
          allowedEvidenceKinds: state.allowedEvidenceKinds,
          subject: state.subject,
          scope: state.scope,
          requiredCapabilities: state.requiredCapabilities,
          requiredFactNames: state.requiredFactNames,
          requiredFactValues: state.requiredFactValues,
          toolName: state.toolName,
          verificationAvailable: state.verificationAvailable,
          allowedAttemptIds: {
            if (writeSequence != null)
              for (final event in snapshot.events)
                if (event.kind == TaskEventKind.toolStarted &&
                    event.sequence > writeSequence &&
                    event.attemptId != null)
                  event.attemptId!,
          },
        ),
      ]);
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
