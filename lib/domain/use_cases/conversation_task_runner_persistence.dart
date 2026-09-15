part of 'conversation_task_runner.dart';

extension _TaskSegmentPersistence on _TaskSegment {
  Future<void> _check({bool allowCancellation = false}) async {
    final latest = await runner.repository.getExecutionSnapshot(task.taskId);
    if (latest == null) throw const _TaskFenceLost();
    snapshot = latest;
    final held = task.lease;
    if (task.status.isTerminal ||
        held == null ||
        held.token != lease.token ||
        held.ownerId != lease.ownerId ||
        held.acquiredAt != lease.acquiredAt ||
        !held.isValidAt(now)) {
      throw const _TaskFenceLost();
    }
    if (!allowCancellation &&
        (task.cancelRequestedAt != null || interruption?.isCancelled == true)) {
      throw const AgentRunCancelledException();
    }
  }

  Future<T> _operation<T>(
    Future<T> Function(AgentCancellationToken) action,
    Duration timeout, {
    bool cleanup = false,
  }) async {
    await _check(allowCancellation: cleanup);
    final token = AgentCancellationToken();
    var finished = false;
    if (!cleanup) {
      unawaited(
        cancellation.whenCancelled.then((_) {
          if (!finished) token.cancel();
        }),
      );
    }
    if (interruption != null) {
      unawaited(
        interruption!.whenCancelled.then((_) {
          if (!finished) token.cancel();
        }),
      );
    }
    try {
      final value = await runner.clock.timeout(
        Future.any<T>([
          action(token),
          token.whenCancelled.then<T>(
            (_) => throw const AgentRunCancelledException(),
          ),
        ]),
        timeout,
      );
      await _check(allowCancellation: cleanup);
      return value;
    } finally {
      finished = true;
      token.cancel();
    }
  }

  Future<void> _save(
    TaskEventKind kind, {
    ConversationTaskStatus? status,
    String? stepId,
    int modelCount = 0,
    ConversationTaskPlan? plan,
    ToolExecutionRecord? tool,
    TaskToolAttemptLink? link,
    ToolEvidenceRecord? evidence,
    TaskApprovalRecord? approval,
    String? attemptId,
    String? reason,
    DateTime? nextRunAt,
    bool cleanup = false,
  }) => writeGate.run(() async {
    await _check(allowCancellation: cleanup);
    final at = now;
    final old = task;
    if (plan case final acceptedPlan?) {
      plan = ConversationTaskPlan(
        taskId: acceptedPlan.taskId,
        revision: acceptedPlan.revision,
        objective: acceptedPlan.objective,
        steps: acceptedPlan.steps,
        allowedToolNames: acceptedPlan.allowedToolNames,
        createdAt: at,
      );
    }
    if (approval case final requestedApproval?) {
      approval = TaskApprovalRecord(
        approvalId: requestedApproval.approvalId,
        taskId: requestedApproval.taskId,
        requestRevision: old.revision + 1,
        safeActionSummary: requestedApproval.safeActionSummary,
        requestedAt: at,
        attemptId: requestedApproval.attemptId,
      );
    }
    final updated = ConversationTask(
      taskId: old.taskId,
      chatId: old.chatId,
      botId: old.botId,
      originTurnId: old.originTurnId,
      originUserMessageId: old.originUserMessageId,
      title: old.title,
      objective: old.objective,
      acceptance: old.acceptance,
      progress: old.progress,
      createdAt: old.createdAt,
      updatedAt: at,
      status: status ?? old.status,
      phase: phase,
      planRevision: plan?.revision ?? old.planRevision,
      revision: old.revision + 1,
      waitingReason:
          status == ConversationTaskStatus.waitingForUser
              ? TaskWaitingReason.approval
              : status == null
              ? old.waitingReason
              : null,
      lease: old.lease,
      nextRunAt: nextRunAt,
      cancellationSource: old.cancellationSource,
      cancelRequestedAt: old.cancelRequestedAt,
    );
    final sequence = snapshot.lastSequence + 1;
    final checkpoint = ConversationTaskCheckpoint(
      taskId: task.taskId,
      segmentId: segmentId,
      planRevision: updated.planRevision,
      sequence: sequence,
      phase: phase,
      savedAt: at,
      nextStepId: nextStep,
      completedStepIds: completed.toList(),
      pendingAttemptIds: [
        for (final call in calls)
          if (call.attemptId != null) call.attemptId!,
      ],
      evidenceCursor: snapshot.evidence.length + (evidence == null ? 0 : 1),
      externalJobs: jobs,
      execution: TaskExecutionState(
        calls: calls,
        stepStarted: stepStarted,
        replanRequired: replan,
        consecutiveFailures: failures,
        backoffCount: backoffs,
        candidate: candidate,
        finalizationReason: finalizationReason,
        sideEffectsUnknown: unknownEffects,
        segmentStartDigest: startDigest,
      ),
    );
    final result = await runner.repository.appendProgress(
      ConversationTaskProgressUpdate(
        task: updated,
        expectedRevision: old.revision,
        lease: lease,
        now: at,
        event: ConversationTaskEvent(
          taskId: old.taskId,
          sequence: sequence,
          kind: kind,
          occurredAt: at,
          safeSummary: 'Task execution: ${kind.name}.',
          planRevision: updated.planRevision,
          modelTurns: modelCount,
          segmentId: segmentId,
          stepId: stepId,
          attemptId: tool?.attemptId ?? attemptId,
          approvalId: approval?.approvalId,
          evidenceId: evidence?.evidenceId,
          reasonCode: reason,
        ),
        plan: plan,
        checkpoint: checkpoint,
        toolExecution: tool,
        toolAttemptLink: link,
        approval: approval,
        evidence: evidence,
        evidenceLink:
            evidence == null
                ? null
                : TaskEvidenceLink(
                  taskId: task.taskId,
                  segmentId: evidence.runId,
                  attemptId: evidence.attemptId,
                  evidenceId: evidence.evidenceId,
                ),
      ),
    );
    if (result is! TaskWriteCommitted<ConversationTask>) {
      throw const _TaskFenceLost();
    }
    snapshot = (await runner.repository.getExecutionSnapshot(task.taskId))!;
  });

  Future<void> _release({DateTime? nextRunAt}) => writeGate.run(() async {
    await _check(allowCancellation: true);
    final result = await runner.repository.releaseLease(
      lease: lease,
      expectedRevision: task.revision,
      now: now,
      nextRunAt: nextRunAt,
    );
    if (result is! TaskWriteCommitted<ConversationTask>) {
      throw const _TaskFenceLost();
    }
    snapshot = (await runner.repository.getExecutionSnapshot(task.taskId))!;
  });

  Future<TaskSegmentResult> _finishCandidate() async {
    phase = ConversationTaskPhase.committing;
    await _save(TaskEventKind.resultCommitting);
    await _release();
    return TaskCompletionCandidate(snapshot, candidate!);
  }

  Future<TaskSegmentResult> _finishFinalization(
    String reason, {
    bool unknown = false,
    bool cleanup = false,
  }) async {
    finalizationReason = reason;
    unknownEffects = unknown;
    phase = ConversationTaskPhase.committing;
    await _save(
      TaskEventKind.resultCommitting,
      reason: reason,
      cleanup: cleanup,
    );
    await _release();
    return TaskNeedsSafeFinalization(
      snapshot,
      reason,
      sideEffectsUnknown: unknown,
    );
  }

  Future<TaskSegmentResult> _approvalWait(String approvalId) async {
    await _noteProgress();
    await _release();
    return TaskApprovalWait(snapshot, approvalId);
  }

  Future<TaskSegmentResult> _jobWait(TaskExternalJob job) async {
    await _noteProgress();
    final scheduled =
        job.nextPollAt.isAfter(now)
            ? job.nextPollAt
            : now.add(limits.initialBackoff);
    await _save(TaskEventKind.segmentCheckpoint, nextRunAt: scheduled);
    await _release(nextRunAt: scheduled);
    return TaskExternalJobWait(snapshot, scheduled);
  }

  Future<TaskSegmentResult> _backoff({DateTime? until}) async {
    await _noteProgress();
    backoffs++;
    final base = min(
      limits.maxBackoff.inMicroseconds.toDouble(),
      limits.initialBackoff.inMicroseconds * pow(2, min(backoffs - 1, 30)),
    );
    final delay = min(
      limits.maxBackoff.inMicroseconds,
      max(1, (base * (0.5 + runner.jitter().clamp(0.0, 1.0))).round()),
    );
    final scheduled = until ?? now.add(Duration(microseconds: delay));
    await _save(TaskEventKind.retryScheduled, nextRunAt: scheduled);
    await _release(nextRunAt: scheduled);
    return TaskBackoff(snapshot, scheduled);
  }

  Future<void> _noteProgress() async {
    if (startDigest.isNotEmpty && startDigest != _digest()) {
      await _save(TaskEventKind.segmentProgress);
    }
  }

  Future<TaskSegmentResult> _continue() async {
    final madeProgress = startDigest != _digest();
    await _save(
      madeProgress ? TaskEventKind.segmentProgress : TaskEventKind.noProgress,
    );
    if (task.progress.noProgressSegments >= limits.maxNoProgressSegments) {
      return _finishFinalization(TaskReasonCode.noProgress);
    }
    await _release();
    return TaskContinueSegment(snapshot);
  }

  /// Excludes revision, timestamps, reasoning, repeated failures and poll times.
  /// Repeating the same plan or observation cannot fabricate forward progress.
  String _digest() => _hash({
    'plan': [
      for (final step in snapshot.plan.steps) [step.stepId, step.summary],
    ],
    'completed': completed.toList()..sort(),
    'actions':
        {
            ...calls.map((call) => call.idempotencyKey),
            ...snapshot.attemptLinks.map((link) => link.idempotencyKey),
          }.toList()
          ..sort(),
    'successes':
        {
            for (final link in snapshot.attemptLinks)
              if (snapshot.attempts.any(
                (a) =>
                    a.attemptId == link.attemptId &&
                    a.status == ToolInvocationStatus.succeeded,
              ))
                link.idempotencyKey,
          }.toList()
          ..sort(),
    'evidence': snapshot.evidence.map((e) => e.evidenceId).toList()..sort(),
    'jobs': [
      for (final job in jobs) [job.externalJobId, job.safeStatus],
    ],
    'decisions': [
      for (final approval in snapshot.approvals)
        [approval.approvalId, approval.decision?.name],
    ],
    'candidate': candidate?.toJson(),
  });
}
