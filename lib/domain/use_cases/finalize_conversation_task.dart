import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/task_scheduling.dart';
import 'package:stars/domain/models/task_terminal_metrics.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/repositories/tool_evidence_repository.dart';
import 'package:stars/domain/services/answer_trust_policy.dart';
import 'package:stars/domain/services/grounded_answer_validator.dart';
import 'package:stars/domain/services/strict_grounding_policy.dart';
import 'package:stars/domain/services/task_evidence_scope.dart';
import 'package:stars/domain/services/task_terminal_summary_policy.dart';
import 'package:stars/domain/services/task_verification_preparation.dart';
import 'package:stars/domain/use_cases/conversation_task_runner_contracts.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_terminal.dart';

/// Replays only durable committing checkpoints. All model work precedes the
/// revision/lease-fenced terminal transaction; stale callback drafts are ignored.
final class FinalizeConversationTask {
  FinalizeConversationTask({
    required this.repository,
    required this.evidenceRepository,
    required this.ownerId,
    required this.newId,
    this.tools = const [],
    this.polisher,
    this.clock = const SystemTaskRunnerClock(),
    this.leaseDuration = const Duration(seconds: 30),
    this.limits = const TaskConcurrencyLimits(),
    TaskTerminalMetrics? metrics,
    NarrateConversationTaskTerminal? narrator,
  }) : metrics = metrics ?? TaskTerminalMetrics() {
    this.narrator =
        narrator ?? NarrateConversationTaskTerminal(metrics: this.metrics);
  }
  final ConversationTaskRepository repository;
  final ToolEvidenceRepository evidenceRepository;
  final String ownerId;
  final String Function() newId;
  final List<ToolDefinition> tools;
  final TaskTerminalPolisher? Function(ConversationTask)? polisher;
  final TaskRunnerClock clock;
  final Duration leaseDuration;
  final TaskConcurrencyLimits limits;
  final TaskTerminalMetrics metrics;
  late final NarrateConversationTaskTerminal narrator;
  final _active = <String>{};
  static const _summaryPolicy = TaskTerminalSummaryPolicy();

  Future<void> onReady(TaskSegmentResult result) async {
    await call(result.snapshot.task.taskId);
  }

  Future<ConversationTask?> call(String taskId) async {
    if (!_active.add(taskId)) return null;
    TaskLease? lease;
    final started = clock.now();
    try {
      var snapshot = await repository.getExecutionSnapshot(taskId);
      if (snapshot == null || snapshot.task.status.isTerminal) {
        return snapshot?.task;
      }
      if (!_ready(snapshot)) return null;
      final at = clock.now();
      lease = TaskLease(
        taskId: taskId,
        ownerId: ownerId,
        token: newId(),
        acquiredAt: at,
        expiresAt: at.add(leaseDuration),
      );
      final acquired = await repository.tryAcquireLease(
        taskId: taskId,
        expectedRevision: snapshot.task.revision,
        lease: lease,
        now: at,
        limits: limits,
      );
      if (acquired is! TaskWriteCommitted<TaskLease>) return null;
      snapshot = await repository.getExecutionSnapshot(taskId);
      if (snapshot == null ||
          !_ready(snapshot) ||
          snapshot.task.lease?.token != lease.token) {
        return null;
      }
      if (_summaryPolicy.needsReconciliation(snapshot)) {
        await repository.waitForTaskInput(
          taskId: taskId,
          expectedRevision: snapshot.task.revision,
          reason: TaskWaitingReason.reconciliation,
          reasonCode: TaskReasonCode.reconciliationRequired,
          now: clock.now(),
          lease: lease,
        );
        return null;
      }
      final state = snapshot.checkpoint!.execution!;
      final policy = snapshot.task.verificationPolicy;
      final validator = GroundedAnswerValidator(
        evidenceRepository: evidenceRepository,
        scope: TaskEvidenceScope(snapshot),
      );
      final acceptedTools =
          tools
              .where(
                (tool) => snapshot!.task.acceptance.allowedToolNames.contains(
                  tool.name,
                ),
              )
              .toList();
      final requirements = taskVerificationRequirements(
        snapshot,
        acceptedTools,
      );
      final failure =
          state.finalizationReason != null ||
          snapshot.task.cancelRequestedAt != null;
      final candidate =
          failure
              ? taskPartialCandidate(snapshot, acceptedTools)
              : state.candidate!;
      // The model chooses which results are useful to say. Validate those
      // claims, while checking write completion and postconditions separately
      // even if the reply omits their metadata or consists of a short receipt.
      final claimIds = candidate.claims.map((claim) => claim.claimId).toSet();
      final completionCoverage =
          failure
              ? null
              : await validator.evaluateCoverage(
                runId: taskId,
                requirements: taskVerificationRequirements(
                  snapshot,
                  acceptedTools,
                  includeObservations: false,
                ),
                evidenceIds: snapshot.evidence.map((e) => e.evidenceId),
                validatedAt: clock.now(),
              );
      var validation = await validator.validate(
        runId: taskId,
        candidate: candidate,
        requirements:
            failure
                ? requirements
                : requirements.where((r) => claimIds.contains(r.claimId)),
        validatedAt: clock.now(),
      );
      final incomplete =
          (completionCoverage != null && !completionCoverage.isComplete) ||
          validation.unmatchedRequirementIds.isNotEmpty ||
          validation.claims.any(
            (claim) => claim.trustLevel == ClaimTrustLevel.unverified,
          );
      final factualClaims =
          validation.claims
              .where((c) => c.trustLevel != ClaimTrustLevel.notVerifiable)
              .length +
          validation.unmatchedRequirementIds.length +
          (completionCoverage?.missingRequirementIds
                  .where((id) => !claimIds.contains(id))
                  .length ??
              0);
      final verifiedClaims =
          validation.claims
              .where((c) => c.trustLevel == ClaimTrustLevel.verified)
              .length;
      var suppressedClaims = 0;
      final strictFailure =
          !failure && policy.strictGroundingEnabled && incomplete;
      TaskTerminalSummary? summary;
      var narrationUsage = ModelTokenUsage.empty;
      String content;
      List<MessageClaimGrounding> claims;
      var status = ConversationTaskStatus.succeeded;
      if (failure || strictFailure) {
        if (strictFailure) {
          // Use only application-rendered facts for retained work in a failure.
          suppressedClaims =
              validation.claims
                  .where((c) => c.trustLevel == ClaimTrustLevel.unverified)
                  .length;
          validation = await validator.validate(
            runId: taskId,
            candidate: taskPartialCandidate(snapshot, acceptedTools),
            requirements: requirements,
            validatedAt: clock.now(),
          );
        }
        summary = _summaryPolicy.build(
          snapshot: snapshot,
          reasonCode:
              strictFailure
                  ? TaskReasonCode.verificationFailed
                  : state.finalizationReason ?? TaskReasonCode.cancelled,
          validation: validation,
        );
        status = summary.status;
        final narration = await narrator(
          summary: summary,
          language: snapshot.task.acceptance.language,
          polish: polisher?.call(snapshot.task),
          onTokenUsage: (usage) => narrationUsage = narrationUsage.merge(usage),
        );
        content = narration.text;
        final partial =
            validation
                .toMessageGrounding()
                .claims
                .where(
                  (claim) =>
                      claim.trustLevel == ClaimTrustLevel.verified &&
                      summary!.completedWorkSummary
                          .split('\n')
                          .contains(claim.claim.text),
                )
                .toList();
        // Keep each validated factual block distinct from operational narration.
        claims = _narratedClaims(
          content,
          summary.completedWorkSummary,
          partial,
        );
      } else {
        content = candidate.renderedText;
        claims = validation.toMessageGrounding().claims;
      }
      final outcome = switch (status) {
        ConversationTaskStatus.succeeded => MessageTerminalOutcome.completed,
        ConversationTaskStatus.cancelled => MessageTerminalOutcome.cancelled,
        _ => MessageTerminalOutcome.failed,
      };
      final grounding = const AnswerTrustPolicy().evaluateTaskResult(
        outcome: outcome,
        reliabilityEnabled: policy.reliabilityEnabled,
        claims: claims,
        incomplete: incomplete,
      );
      content = claims.map((claim) => claim.claim.text).join('\n\n');
      var message = Message(
        messageId: ConversationMessageIdentity.result(taskId),
        taskId: taskId,
        taskMessageKind: TaskMessageKind.result,
        turnId: snapshot.task.originTurnId,
        taskResultPolicy: TaskResultPresentationPolicy(
          strictGroundingEnabled: policy.strictGroundingEnabled,
          showVerificationStatus: policy.showVerificationStatus,
        ),
        runId: taskId,
        chatId: snapshot.task.chatId,
        botId: snapshot.task.botId,
        senderId: 'assistant',
        content: content,
        grounding: grounding,
        terminalOutcome: outcome,
        timestamp: clock.now(),
        tokenUsage: narrationUsage,
      );
      if (policy.strictGroundingEnabled) {
        final safe = const StrictGroundingPolicy().present(message);
        message = message.copyWith(content: safe.content);
      }
      // Narrative I/O may race cancellation or ownership. Re-read, then fence
      // both the verification event and terminal commit using this exact revision.
      final latest = await repository.getExecutionSnapshot(taskId);
      if (latest == null ||
          latest.task.revision != snapshot.task.revision ||
          latest.task.lease?.token != lease.token ||
          !_ready(latest)) {
        metrics.conflicts++;
        return latest?.task;
      }
      final verifiedAt = clock.now();
      final verifying = _verificationTask(latest.task, verifiedAt);
      final verifiedStatus =
          grounding.claims.any((c) => c.trustLevel == ClaimTrustLevel.verified)
              ? incomplete || failure || strictFailure
                  ? TaskVerificationStatus.partial
                  : TaskVerificationStatus.verified
              : incomplete
              ? TaskVerificationStatus.failed
              : TaskVerificationStatus.notStarted;
      final verification = await repository.appendProgress(
        ConversationTaskProgressUpdate(
          task: verifying,
          expectedRevision: latest.task.revision,
          lease: lease,
          now: verifiedAt,
          event: ConversationTaskEvent(
            taskId: taskId,
            sequence: latest.lastSequence + 1,
            planRevision: latest.task.planRevision,
            kind: TaskEventKind.verificationCompleted,
            occurredAt: verifiedAt,
            verificationStatus: verifiedStatus,
            safeSummary: 'Task evidence validation completed.',
          ),
        ),
      );
      if (verification is! TaskWriteCommitted<ConversationTask>) {
        metrics.conflicts++;
        return (await repository.getById(taskId));
      }
      final commitAt = clock.now();
      final terminal = verification.value.transitionTo(
        status,
        at: commitAt,
        phase: ConversationTaskPhase.committing,
        terminalSummary: summary,
      );
      final result = await repository.commitTerminalMessage(
        terminalTask: terminal,
        event: ConversationTaskEvent(
          taskId: taskId,
          sequence: latest.lastSequence + 2,
          planRevision: latest.task.planRevision,
          kind: TaskEventKind.terminal,
          occurredAt: commitAt,
          reasonCode: summary?.reasonCode,
          safeSummary: 'Task terminal result committed.',
        ),
        message: message.copyWith(timestamp: commitAt),
        expectedRevision: verification.revision,
        lease: lease,
        now: commitAt,
      );
      if (result is TaskWriteCommitted<ConversationTask>) {
        if (!result.reused) {
          metrics.committed++;
          metrics.factualClaims += factualClaims;
          metrics.verifiedClaims += verifiedClaims;
          metrics.suppressedClaims += suppressedClaims;
          final elapsed = clock.now().difference(started);
          metrics.commitLatency += elapsed;
          metrics.endToEndLatency += result.value.updatedAt.difference(
            snapshot.task.createdAt,
          );
          switch (status) {
            case ConversationTaskStatus.succeeded:
              metrics.succeeded++;
            case ConversationTaskStatus.cancelled:
              metrics.cancelled++;
              metrics.cancellationLatency += result.value.updatedAt.difference(
                snapshot.task.cancelRequestedAt!,
              );
            case ConversationTaskStatus.failed:
              metrics.failed++;
              metrics.failureCommitLatency += elapsed;
              if (summary?.reasonCode == TaskReasonCode.noProgress) {
                metrics.noProgressFailures++;
              }
            default:
              break;
          }
        }
        return result.value;
      }
      metrics.conflicts++;
      return await repository.getById(taskId);
    } finally {
      try {
        if (lease != null) {
          final task = await repository.getById(taskId);
          if (task?.lease?.token == lease.token &&
              task!.lease!.isValidAt(clock.now())) {
            await repository.releaseLease(
              lease: lease,
              expectedRevision: task.revision,
              now: clock.now(),
            );
          }
        }
      } finally {
        _active.remove(taskId);
      }
    }
  }
}

bool _ready(TaskExecutionSnapshot snapshot) =>
    !snapshot.task.status.isTerminal &&
    snapshot.task.status != ConversationTaskStatus.waitingForUser &&
    snapshot.task.phase == ConversationTaskPhase.committing &&
    (snapshot.checkpoint?.execution?.candidate != null ||
        snapshot.checkpoint?.execution?.finalizationReason != null);

ConversationTask _verificationTask(ConversationTask old, DateTime at) =>
    ConversationTask(
      taskId: old.taskId,
      chatId: old.chatId,
      botId: old.botId,
      originTurnId: old.originTurnId,
      originUserMessageId: old.originUserMessageId,
      retryOfTaskId: old.retryOfTaskId,
      title: old.title,
      objective: old.objective,
      acceptance: old.acceptance,
      progress: old.progress,
      createdAt: old.createdAt,
      updatedAt: at,
      status:
          old.cancelRequestedAt == null
              ? ConversationTaskStatus.running
              : ConversationTaskStatus.cancelRequested,
      phase: ConversationTaskPhase.committing,
      planRevision: old.planRevision,
      revision: old.revision + 1,
      lease: old.lease,
      cancellationSource: old.cancellationSource,
      cancelRequestedAt: old.cancelRequestedAt,
    );

List<MessageClaimGrounding> _narratedClaims(
  String text,
  String partialText,
  List<MessageClaimGrounding> partial,
) {
  MessageClaimGrounding operation(String value, int index) =>
      MessageClaimGrounding(
        claim: AnswerClaim(
          claimId: 'terminal:operation:$index',
          text: value,
          kind: ClaimKind.nonFactual,
        ),
        trustLevel: ClaimTrustLevel.notVerifiable,
        reasonCode: 'not_fact_checked',
      );
  if (partialText.isEmpty) return [operation(text, 0)];
  final at = text.indexOf(partialText);
  return [
    if (text.substring(0, at).trim().isNotEmpty)
      operation(text.substring(0, at).trim(), 0),
    ...partial,
    if (text.substring(at + partialText.length).trim().isNotEmpty)
      operation(text.substring(at + partialText.length).trim(), 1),
  ];
}
