import 'dart:convert';

import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/grounded_answer_validator.dart';
import 'package:stars/domain/services/task_safe_data.dart';
import 'package:stars/domain/services/task_terminal_narration_policy.dart';
import 'package:stars/domain/services/task_verification_preparation.dart';

/// Derives facts from committed attempts/checkpoints, never model prose or errors.
final class TaskTerminalSummaryPolicy {
  const TaskTerminalSummaryPolicy();

  bool needsReconciliation(TaskExecutionSnapshot snapshot) =>
      snapshot.checkpoint?.execution?.sideEffectsUnknown == true ||
      snapshot.checkpoint?.externalJobs.isNotEmpty == true ||
      snapshot.attempts.any(
        (attempt) => attempt.status == ToolInvocationStatus.running,
      );

  TaskSideEffectStatus sideEffects(TaskExecutionSnapshot snapshot) {
    if (needsReconciliation(snapshot)) return TaskSideEffectStatus.unknown;
    final writes = snapshot.attempts.where(
      (attempt) => attempt.riskLevel != ToolRiskLevel.readOnly,
    );
    if (writes.any(
      (attempt) => attempt.status == ToolInvocationStatus.succeeded,
    )) {
      // A successful receipt is not a rollback. Be conservative for all writes.
      return TaskSideEffectStatus.irreversible;
    }
    return writes.isEmpty
        ? TaskSideEffectStatus.none
        : TaskSideEffectStatus.reconciled;
  }

  TaskTerminalSummary build({
    required TaskExecutionSnapshot snapshot,
    required String reasonCode,
    required GroundedAnswerValidationResult validation,
  }) {
    final cancelled = snapshot.task.cancelRequestedAt != null;
    final reason =
        cancelled ? TaskReasonCode.cancelled : safeReasonCode(reasonCode);
    final words = TaskTerminalStrings(snapshot.task.acceptance.language);
    final effects = sideEffects(snapshot);
    if (effects == TaskSideEffectStatus.unknown) {
      throw StateError('task_reconciliation_required');
    }
    final verified =
        validation.claims
            .where(
              (claim) =>
                  claim.trustLevel == ClaimTrustLevel.verified &&
                  terminalSafeText(claim.claim.text),
            )
            .take(8)
            .toList();
    final completed = verified.map((claim) => claim.claim.text).join('\n');
    final safeCompleted = completed.length <= 4000 ? completed : '';
    return TaskTerminalSummary(
      status:
          cancelled
              ? ConversationTaskStatus.cancelled
              : ConversationTaskStatus.failed,
      reasonCode: reason,
      safeReason: words.reason(reason),
      completedWorkSummary: safeCompleted,
      // Only persisted, validated result handles; never raw paths or model URLs.
      retainedArtifacts:
          safeCompleted.isEmpty
              ? []
              : [
                for (final id in verified
                    .expand((claim) => claim.acceptedEvidenceIds)
                    .toSet()
                    .take(16))
                  'evidence:$id',
              ],
      sideEffectStatus: effects,
      canRetry: effects == TaskSideEffectStatus.none,
      suggestedNextActions: [
        effects == TaskSideEffectStatus.none ? words.retry : words.review,
      ],
      cancellationSource: snapshot.task.cancellationSource,
    );
  }

  String safeReasonCode(String code) =>
      const {
            TaskReasonCode.noProgress,
            TaskReasonCode.invalidPlan,
            TaskReasonCode.permissionDenied,
            TaskReasonCode.missingCredentials,
            TaskReasonCode.providerUnavailable,
            TaskReasonCode.botUnavailable,
            TaskReasonCode.verificationFailed,
          }.contains(code)
          ? code
          : 'task_execution_failed';
}

bool terminalSafeText(String value) =>
    value.length <= 2000 &&
    taskSafeText(value, maximum: 2000, structured: true) == value &&
    !RegExp(
      r'(?:^|[\s"\x27(:])(?:/|[A-Za-z]:\\)|https?://|encrypted://|[\x00-\x1f\x7f]',
      caseSensitive: false,
    ).hasMatch(value);

/// Typed rendering gives failure/cancellation partial facts the same evidence
/// gate as success, without asking a model to invent completed work.
GroundedAnswerCandidate taskPartialCandidate(
  TaskExecutionSnapshot snapshot,
  List<ToolDefinition> tools,
) {
  final requirements = taskVerificationRequirements(snapshot, tools);
  final claims = <AnswerClaim>[];
  for (final requirement in requirements.take(8)) {
    final text = requirement.requiredFactValues.entries
        .map((entry) => '${entry.key}: ${jsonEncode(entry.value)}')
        .join('; ');
    if (text.isEmpty || !terminalSafeText(text)) continue;
    claims.add(
      AnswerClaim(
        claimId: requirement.claimId,
        text: text,
        kind: requirement.claimKind!,
        evidenceIds:
            snapshot.evidence.map((e) => e.evidenceId).take(64).toList(),
      ),
    );
  }
  return GroundedAnswerCandidate(
    claims: claims,
    nonFactualText:
        claims.isEmpty
            ? TaskTerminalStrings(snapshot.task.acceptance.language).noResults
            : '',
  );
}
