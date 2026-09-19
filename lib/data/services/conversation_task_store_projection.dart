part of 'conversation_task_store.dart';

Future<TaskProgress> _project(
  DatabaseExecutor tx,
  Map<String, Object?> task,
) async {
  final taskId = task['task_id']! as String;
  final planRevision = task['plan_revision']! as int;
  final plans = await tx.query(
    'conversation_task_plans',
    where: 'task_id = ? AND plan_revision = ?',
    whereArgs: [taskId, planRevision],
  );
  if (plans.isEmpty) throw StateError('task_current_plan_missing');
  final plan = ConversationTaskPlanRecord(plans.single).toDomain();
  final events =
      (await tx.query(
        'conversation_task_events',
        where: 'task_id = ?',
        whereArgs: [taskId],
        orderBy: 'sequence',
      )).map((row) => ConversationTaskEventRecord(row).toDomain()).toList();
  final attempts = await tx.rawQuery(
    'SELECT execution.* FROM conversation_task_tool_attempts link '
    'JOIN tool_execution_records execution ON execution.attempt_id = link.attempt_id '
    'WHERE link.task_id = ?',
    [taskId],
  );
  final approvals =
      (await tx.query(
        'conversation_task_approvals',
        where: 'task_id = ?',
        whereArgs: [taskId],
        orderBy: 'requested_at, approval_id',
      )).map((row) => TaskApprovalDbRecord(row).toDomain()).toList();
  final checkpoints = await tx.query(
    'conversation_task_checkpoints',
    where: 'task_id = ? AND plan_revision = ?',
    whereArgs: [taskId, planRevision],
  );
  final checkpoint =
      checkpoints.isEmpty
          ? null
          : ConversationTaskCheckpointRecord(checkpoints.single).toDomain();
  final evidence =
      (await tx.rawQuery(
        'SELECT evidence.* FROM conversation_task_evidence_links link '
        'JOIN tool_evidence_records evidence ON evidence.evidence_id = link.evidence_id '
        'WHERE link.task_id = ? ORDER BY link.evidence_id',
        [taskId],
      )).map(_readTaskEvidence).whereType<ToolEvidenceRecord>().toList();
  final completed = {
    for (final step in plan.steps)
      if (step.status == TaskPlanStepStatus.completed) step.stepId,
  };
  final stepIds = plan.steps.map((step) => step.stepId).toSet();
  String? currentStep;
  var modelTurns = 0, recoveries = 0, noProgress = 0;
  var verification = TaskVerificationStatus.notStarted;
  var meaningfulAt = DateTime.fromMicrosecondsSinceEpoch(
    task['created_at']! as int,
    isUtc: true,
  );
  final segments = <String>{};
  var reason = '';
  String? latestAttempt;
  const meaningfulKinds = {
    TaskEventKind.planCreated,
    TaskEventKind.planRevised,
    TaskEventKind.stepStarted,
    TaskEventKind.stepCompleted,
    TaskEventKind.toolSucceeded,
    TaskEventKind.toolFailed,
    TaskEventKind.approvalRequested,
    TaskEventKind.approvalApproved,
    TaskEventKind.approvalDenied,
    TaskEventKind.evidenceAccepted,
    TaskEventKind.evidenceRejected,
    TaskEventKind.verificationStarted,
    TaskEventKind.verificationCompleted,
    TaskEventKind.terminal,
  };
  for (final event in events) {
    modelTurns += event.modelTurns;
    if (event.segmentId != null) segments.add(event.segmentId!);
    if (event.kind == TaskEventKind.processRecovered) recoveries++;
    if (event.kind == TaskEventKind.noProgress) noProgress++;
    if ({
      TaskEventKind.segmentProgress,
      TaskEventKind.approvalApproved,
      TaskEventKind.approvalDenied,
    }.contains(event.kind)) {
      noProgress = 0;
    }
    if (event.kind == TaskEventKind.segmentProgress ||
        (meaningfulKinds.contains(event.kind) &&
            (checkpoint?.execution == null ||
                !{
                  TaskEventKind.planRevised,
                  TaskEventKind.toolFailed,
                }.contains(event.kind)))) {
      meaningfulAt = event.occurredAt;
      if (checkpoint?.execution == null) noProgress = 0;
    }
    if (event.reasonCode != null) reason = _safeCode(event.reasonCode!);
    if (event.kind == TaskEventKind.approvalApproved) reason = '';
    if (event.kind == TaskEventKind.planRevised) {
      verification = TaskVerificationStatus.notStarted;
    }
    if (event.kind == TaskEventKind.verificationStarted) {
      verification = TaskVerificationStatus.verifying;
    }
    if (event.verificationStatus != null) {
      verification = event.verificationStatus!;
    }
    if (event.attemptId != null &&
        {
          TaskEventKind.toolQueued,
          TaskEventKind.toolStarted,
          TaskEventKind.toolSucceeded,
          TaskEventKind.toolFailed,
          TaskEventKind.toolRetry,
        }.contains(event.kind)) {
      latestAttempt = event.attemptId;
    }
    if (event.planRevision == planRevision) {
      if (event.kind == TaskEventKind.stepStarted) currentStep = event.stepId;
      if (event.kind == TaskEventKind.stepCompleted &&
          stepIds.contains(event.stepId)) {
        completed.add(event.stepId!);
        if (currentStep == event.stepId) currentStep = null;
      }
      if (checkpoint != null && checkpoint.sequence == event.sequence) {
        completed.addAll(checkpoint.completedStepIds.where(stepIds.contains));
        currentStep = checkpoint.nextStepId;
      }
    }
  }
  final terminal = task['completed_at'] != null;
  final pending =
      terminal
          ? <TaskApprovalRecord>[]
          : approvals.where((approval) => approval.decision == null).toList();
  if (pending.length > 1) throw StateError('task_multiple_pending_approvals');
  final approval = pending.isEmpty ? null : pending.single;
  // The approval row keeps its short audit summary. The same transaction's
  // checkpoint holds the exact, validated call that the user is approving.
  final approvalCall =
      approval?.attemptId == null
          ? null
          : checkpoint?.execution?.calls
              .where((pending) => pending.attemptId == approval!.attemptId)
              .firstOrNull;
  final approvalSummary =
      approval == null
          ? null
          : _safeText(
            approvalCall == null
                ? approval.safeActionSummary
                : 'Approve ${approvalCall.call.name}: ${jsonEncode(approvalCall.call.arguments)}',
            maximum: TaskProgress.maximumApprovalSummaryLength,
          );
  final latestRows = attempts.where(
    (row) => row['attempt_id'] == latestAttempt,
  );
  TaskToolProgress? latestTool;
  if (latestRows.isNotEmpty) {
    final tool = ToolExecutionDbRecord(latestRows.single).toDomain();
    latestTool = TaskToolProgress(
      attemptId: tool.attemptId,
      name: _safeText(tool.name, maximum: 256),
      status: tool.status,
      safeSummary: _safeText(
        tool.resultSummary.isEmpty ? tool.status.name : tool.resultSummary,
      ),
    );
  }
  final currentSteps = plan.steps.where((step) => step.stepId == currentStep);
  final currentSummary =
      currentSteps.isEmpty ? '' : _safeText(currentSteps.single.summary);
  final hash =
      sha256
          .convert(
            utf8.encode(
              jsonEncode({
                'planRevision': planRevision,
                'completed': completed.toList()..sort(),
                'currentStep': currentStep,
                'verification': verification.name,
                'tool':
                    latestTool == null
                        ? null
                        : [
                          latestTool.name,
                          latestTool.status.name,
                          latestTool.safeSummary,
                        ],
                'approval':
                    approval == null
                        ? null
                        : [approval.approvalId, approvalSummary],
                'jobs': [
                  for (final job
                      in checkpoint?.externalJobs ?? <TaskExternalJob>[])
                    [job.attemptId, job.externalJobId, job.safeStatus],
                ],
                'decisions': [
                  for (final item in approvals)
                    [item.approvalId, item.decision?.name],
                ],
                'evidence': evidence.map((item) => item.evidenceId).toList(),
              }),
            ),
          )
          .toString();
  return TaskProgress(
    totalSteps: plan.steps.length,
    completedSteps: completed.length,
    currentStepSummary: currentSummary,
    lastMeaningfulProgressAt: meaningfulAt,
    modelTurns: modelTurns,
    toolAttempts: attempts.length,
    recoveries: recoveries,
    segments: segments.length,
    noProgressSegments: noProgress,
    summaryHash: hash,
    latestTool: latestTool,
    pendingApprovalId: approval?.approvalId,
    pendingApprovalSummary: approvalSummary,
    approvalRequestedAt: approval?.requestedAt,
    reasonCode: reason,
    verificationStatus: verification,
  );
}

Future<ConversationTaskProgressSummary?> _summary(
  DatabaseExecutor tx,
  String taskId,
) async {
  final task = await _task(tx, taskId);
  return task == null ? null : _summaryOf(task);
}

ConversationTaskProgressSummary _summaryOf(ConversationTask task) =>
    ConversationTaskProgressSummary(
      taskId: task.taskId,
      chatId: task.chatId,
      title: _safeText(task.title, maximum: 200),
      status: task.status,
      phase: task.phase,
      planRevision: task.planRevision,
      summaryRevision: task.revision,
      progress: task.progress,
      updatedAt: task.updatedAt,
      createdAt: task.createdAt,
      leaseExpiresAt: task.lease?.expiresAt,
      waitingReason: task.waitingReason,
      terminalSummary:
          task.terminalSummary == null
              ? null
              : ConversationTaskRecord(
                _taskValues(task),
              ).toDomain(progress: task.progress).terminalSummary,
    );
