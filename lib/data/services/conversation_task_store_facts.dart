part of 'conversation_task_store.dart';

Future<void> _validateProgressFacts(
  DatabaseExecutor tx,
  ConversationTask old,
  ConversationTaskProgressUpdate update,
) async {
  final event = update.event, task = update.task;
  final eventStatus = switch (event.kind) {
    TaskEventKind.started ||
    TaskEventKind.resumed => ConversationTaskStatus.running,
    TaskEventKind.paused => ConversationTaskStatus.paused,
    TaskEventKind.waitingForUser => ConversationTaskStatus.waitingForUser,
    _ => null,
  };
  if (eventStatus != null && task.status != eventStatus) {
    throw ArgumentError(
      'Lifecycle event must match the persisted task status.',
    );
  }
  final plan = update.plan;
  if (plan == null
      ? task.planRevision != old.planRevision
      : (plan.revision != old.planRevision + 1 ||
          event.kind != TaskEventKind.planRevised ||
          plan.createdAt != event.occurredAt)) {
    throw ArgumentError(
      'Plan revisions must be appended with a planRevised event.',
    );
  }
  if (event.kind == TaskEventKind.planRevised && plan == null) {
    throw ArgumentError('Missing revised plan.');
  }
  final currentPlan =
      plan ??
      ConversationTaskPlanRecord(
        (await tx.query(
          'conversation_task_plans',
          where: 'task_id = ? AND plan_revision = ?',
          whereArgs: [task.taskId, task.planRevision],
        )).single,
      ).toDomain();
  final stepIds = currentPlan.steps.map((step) => step.stepId).toSet();
  if (event.stepId != null && !stepIds.contains(event.stepId)) {
    throw ArgumentError('Unknown plan step.');
  }
  final checkpoint = update.checkpoint;
  if (checkpoint != null) {
    if (checkpoint.sequence != event.sequence ||
        checkpoint.savedAt != event.occurredAt ||
        checkpoint.phase != task.phase ||
        checkpoint.segmentId != event.segmentId ||
        !stepIds.containsAll(checkpoint.completedStepIds) ||
        (checkpoint.nextStepId != null &&
            !stepIds.contains(checkpoint.nextStepId))) {
      throw ArgumentError('Checkpoint must describe this event and plan.');
    }
    for (final attempt in {
      ...checkpoint.pendingAttemptIds,
      ...checkpoint.externalJobs.map((job) => job.attemptId),
    }) {
      if (attempt == update.toolAttemptLink?.attemptId) continue;
      if ((await tx.query(
        'conversation_task_tool_attempts',
        where: 'task_id = ? AND attempt_id = ?',
        whereArgs: [task.taskId, attempt],
      )).isEmpty) {
        throw ArgumentError('Checkpoint references an unknown task attempt.');
      }
    }
  }
  if (event.kind == TaskEventKind.externalJobUpdated &&
      (checkpoint == null ||
          !checkpoint.externalJobs.any(
            (job) => job.attemptId == event.attemptId,
          ))) {
    throw ArgumentError(
      'External job updates require a persisted checkpoint handle.',
    );
  }
  final pending = await tx.query(
    'conversation_task_approvals',
    where: 'task_id = ? AND decision IS NULL',
    whereArgs: [task.taskId],
  );
  if (pending.isNotEmpty &&
      (task.status != old.status || update.approval != null)) {
    throw ArgumentError(
      'Pending approvals must be decided through decideApproval.',
    );
  }
  final approval = update.approval;
  if (pending.isNotEmpty &&
      update.toolExecution != null &&
      !_toolTerminal(update.toolExecution!.status)) {
    throw ArgumentError('Pending approval prevents new tool execution.');
  }
  if (approval != null &&
      (event.kind != TaskEventKind.approvalRequested ||
          event.approvalId != approval.approvalId ||
          task.status != ConversationTaskStatus.waitingForUser ||
          task.waitingReason != TaskWaitingReason.approval ||
          approval.decision != null ||
          approval.requestRevision != task.revision ||
          approval.requestedAt != event.occurredAt)) {
    throw ArgumentError(
      'Approval request and waiting state must be committed together.',
    );
  }
  if ((event.kind == TaskEventKind.approvalRequested && approval == null) ||
      (task.waitingReason == TaskWaitingReason.approval &&
          pending.isEmpty &&
          approval == null)) {
    throw ArgumentError('Approval waiting requires its request fact.');
  }
  if ({
    TaskEventKind.approvalApproved,
    TaskEventKind.approvalDenied,
    TaskEventKind.cancellationRequested,
    TaskEventKind.terminal,
    TaskEventKind.queued,
    TaskEventKind.planCreated,
  }.contains(event.kind)) {
    throw ArgumentError(
      'This event requires its dedicated transaction entry point.',
    );
  }
  final toolKind = {
    TaskEventKind.toolQueued,
    TaskEventKind.toolStarted,
    TaskEventKind.toolSucceeded,
    TaskEventKind.toolFailed,
    TaskEventKind.toolRetry,
  }.contains(event.kind);
  if (toolKind != (update.toolExecution != null)) {
    throw ArgumentError('Tool events require their execution record.');
  }
  if (update.toolExecution == null && update.toolAttemptLink != null) {
    throw ArgumentError('Attempt links require an execution.');
  }
  if (event.kind == TaskEventKind.verificationCompleted &&
      !{
        TaskVerificationStatus.verified,
        TaskVerificationStatus.partial,
        TaskVerificationStatus.failed,
      }.contains(event.verificationStatus)) {
    throw ArgumentError('Verification completion requires its conclusion.');
  }
  if (event.verificationStatus != null &&
      event.kind != TaskEventKind.verificationCompleted) {
    throw ArgumentError(
      'Verification conclusions require a verificationCompleted event.',
    );
  }
  if (event.kind == TaskEventKind.verificationStarted &&
      task.phase != ConversationTaskPhase.verifying) {
    throw ArgumentError('Verification start must enter its execution phase.');
  }
}

Future<void> _writeTool(
  DatabaseExecutor tx,
  ConversationTask old,
  ConversationTaskProgressUpdate update,
) async {
  final tool = update.toolExecution;
  if (tool == null) return;
  final event = update.event;
  final values = {...ToolExecutionDbRecord.fromDomain(tool).values};
  final attemptId = values['attempt_id'];
  if (event.attemptId != attemptId ||
      event.segmentId == null ||
      tool.callId.isEmpty ||
      tool.name.isEmpty ||
      !old.acceptance.allowedToolNames.contains(tool.name) ||
      tool.updatedAt.isBefore(tool.startedAt) ||
      tool.updatedAt.isAfter(update.now) ||
      (tool.durationMs != null && tool.durationMs! < 0)) {
    throw ArgumentError('Invalid tool identity, scope or timestamps.');
  }
  final terminal = _toolTerminal(tool.status);
  if (terminal != (tool.completedAt != null) ||
      (terminal && tool.durationMs == null) ||
      (tool.completedAt != null &&
          (tool.completedAt!.isBefore(tool.startedAt) ||
              tool.completedAt!.isAfter(tool.updatedAt)))) {
    throw ArgumentError(
      'Terminal attempts require a completion time and duration.',
    );
  }
  final expectedKind = switch (tool.status) {
    ToolInvocationStatus.requested ||
    ToolInvocationStatus.awaitingApproval => TaskEventKind.toolQueued,
    ToolInvocationStatus.running => TaskEventKind.toolStarted,
    ToolInvocationStatus.succeeded ||
    ToolInvocationStatus.duplicateReused => TaskEventKind.toolSucceeded,
    _ => TaskEventKind.toolFailed,
  };
  if (event.kind != expectedKind &&
      !(event.kind == TaskEventKind.toolRetry && !terminal)) {
    throw ArgumentError('Tool lifecycle event does not match its status.');
  }
  final rows = await tx.query(
    'tool_execution_records',
    where: 'attempt_id = ?',
    whereArgs: [attemptId],
  );
  final link = update.toolAttemptLink;
  if (rows.isEmpty) {
    if (terminal ||
        link == null ||
        link.attemptId != attemptId ||
        link.segmentId != event.segmentId) {
      throw ArgumentError(
        'Save the attempt and idempotency key before invoking the tool.',
      );
    }
    final previous = await tx.rawQuery(
      'SELECT link.attempt_number, execution.status FROM conversation_task_tool_attempts link '
      'JOIN tool_execution_records execution ON execution.attempt_id = link.attempt_id '
      'WHERE link.task_id = ? AND link.idempotency_key = ? ORDER BY link.attempt_number DESC LIMIT 1',
      [old.taskId, link.idempotencyKey],
    );
    if (link.attemptNumber !=
            (previous.isEmpty
                ? 1
                : (previous.single['attempt_number']! as int) + 1) ||
        (previous.isNotEmpty &&
            (!_toolTerminal(
                  ToolInvocationStatus.values.byName(
                    previous.single['status']! as String,
                  ),
                ) ||
                {
                  ToolInvocationStatus.succeeded.name,
                  ToolInvocationStatus.duplicateReused.name,
                }.contains(previous.single['status']))) ||
        (link.attemptNumber > 1) != (event.kind == TaskEventKind.toolRetry)) {
      throw const _TaskConflict(TaskWriteConflictReason.duplicateIdentity);
    }
  } else {
    final existing = rows.single;
    if (_toolTerminal(
      ToolInvocationStatus.values.byName(existing['status']! as String),
    )) {
      throw const _TaskConflict(TaskWriteConflictReason.duplicateIdentity);
    }
    final links = await tx.query(
      'conversation_task_tool_attempts',
      where: 'task_id = ? AND attempt_id = ?',
      whereArgs: [old.taskId, attemptId],
    );
    if (links.isEmpty ||
        (link != null &&
            !_sameMap(
              links.single,
              TaskToolAttemptLinkRecord.fromDomain(link).values,
            ))) {
      throw const _TaskConflict(TaskWriteConflictReason.duplicateIdentity);
    }
    for (final key in [
      'execution_id',
      'invocation_id',
      'attempt_id',
      'provider_call_id',
      'run_id',
      'turn_id',
      'message_id',
      'chat_id',
      'bot_id',
      'call_id',
      'tool_name',
      'source',
      'risk_level',
      'started_at',
    ]) {
      if (existing[key] != values[key]) {
        throw const _TaskConflict(TaskWriteConflictReason.duplicateIdentity);
      }
    }
    if ((values['updated_at']! as int) < (existing['updated_at']! as int) ||
        (!terminal &&
            tool.status != ToolInvocationStatus.running &&
            !(existing['status'] == ToolInvocationStatus.requested.name &&
                tool.status == ToolInvocationStatus.awaitingApproval))) {
      throw ArgumentError('Tool lifecycle cannot move backwards.');
    }
    if (existing['status'] == ToolInvocationStatus.awaitingApproval.name &&
        {
          ToolInvocationStatus.running,
          ToolInvocationStatus.succeeded,
          ToolInvocationStatus.duplicateReused,
        }.contains(tool.status)) {
      final decisions = await tx.query(
        'conversation_task_approvals',
        where: 'task_id = ? AND attempt_id = ? AND decision = ?',
        whereArgs: [old.taskId, attemptId, TaskApprovalDecision.approved.name],
      );
      if (decisions.isEmpty) {
        throw ArgumentError('Tool approval must be saved before invocation.');
      }
    }
    if ({
      ToolInvocationStatus.running,
      ToolInvocationStatus.succeeded,
      ToolInvocationStatus.duplicateReused,
    }.contains(tool.status)) {
      final blocked = await tx.query(
        'conversation_task_approvals',
        where:
            'task_id = ? AND attempt_id = ? AND (decision IS NULL OR decision = ?)',
        whereArgs: [old.taskId, attemptId, TaskApprovalDecision.denied.name],
      );
      if (blocked.isNotEmpty) {
        throw ArgumentError('Tool execution is not approved.');
      }
    }
  }
  // No raw arguments or exception detail belongs in the task audit projection.
  values['arguments_summary'] = '';
  values['detail'] = _safeText(event.safeSummary);
  for (final key in ['tool_title', 'mcp_server_name', 'result_summary']) {
    values[key] = _safeText(values[key]! as String);
  }
  values['error_code'] = _safeCode(tool.errorCode);
  values['approval_status'] = _safeCode(tool.approvalStatus);
  if (rows.isEmpty) {
    await tx.insert('tool_execution_records', values);
    await tx.insert(
      'conversation_task_tool_attempts',
      TaskToolAttemptLinkRecord.fromDomain(link!).values,
    );
  } else {
    await tx.update(
      'tool_execution_records',
      values,
      where: 'attempt_id = ?',
      whereArgs: [attemptId],
    );
  }
}

Future<void> _writeApproval(
  DatabaseExecutor tx,
  ConversationTaskProgressUpdate update,
) async {
  final approval = update.approval;
  if (approval == null) return;
  if ((await tx.query(
    'conversation_task_approvals',
    columns: ['approval_id'],
    where: 'approval_id = ?',
    whereArgs: [approval.approvalId],
  )).isNotEmpty) {
    throw const _TaskConflict(TaskWriteConflictReason.duplicateIdentity);
  }
  if (approval.attemptId != null &&
      (await tx.query(
        'conversation_task_tool_attempts',
        where: 'task_id = ? AND attempt_id = ?',
        whereArgs: [approval.taskId, approval.attemptId],
      )).isEmpty) {
    throw ArgumentError('Approval attempt belongs to another task.');
  }
  await tx.insert('conversation_task_approvals', {
    ...TaskApprovalDbRecord.fromDomain(approval).values,
    'safe_action_summary': _safeText(approval.safeActionSummary),
  });
}

Future<void> _writeCheckpoint(
  DatabaseExecutor tx,
  ConversationTaskProgressUpdate update,
) async {
  final checkpoint = update.checkpoint;
  if (checkpoint == null) return;
  final values = {
    ...ConversationTaskCheckpointRecord.fromDomain(checkpoint).values,
  };
  values['checkpoint_json'] = jsonEncode(
    _safeObject(jsonDecode(values['checkpoint_json']! as String)),
  );
  final rows = await tx.query(
    'conversation_task_checkpoints',
    where: 'task_id = ? AND plan_revision = ?',
    whereArgs: [checkpoint.taskId, checkpoint.planRevision],
  );
  if (rows.isEmpty) {
    await tx.insert('conversation_task_checkpoints', values);
  } else {
    if ((rows.single['sequence']! as int) >= checkpoint.sequence) {
      throw const _TaskConflict(TaskWriteConflictReason.duplicateIdentity);
    }
    final previous = ConversationTaskCheckpointRecord(rows.single).toDomain();
    if (!checkpoint.completedStepIds.toSet().containsAll(
          previous.completedStepIds,
        ) ||
        checkpoint.evidenceCursor < previous.evidenceCursor) {
      throw ArgumentError(
        'Checkpoints cannot forget completed work or evidence.',
      );
    }
    await tx.update(
      'conversation_task_checkpoints',
      values,
      where: 'task_id = ? AND plan_revision = ?',
      whereArgs: [checkpoint.taskId, checkpoint.planRevision],
    );
  }
}

Future<void> _writeEvidence(
  DatabaseExecutor tx,
  ConversationTaskProgressUpdate update,
) async {
  final evidence = update.evidence, link = update.evidenceLink;
  if ((evidence == null) != (link == null)) {
    throw ArgumentError('Evidence requires its immutable task link.');
  }
  if (evidence != null && link != null) {
    if (evidence.evidenceId != link.evidenceId ||
        evidence.attemptId != link.attemptId ||
        update.event.evidenceId != evidence.evidenceId ||
        evidence.observedAt.isAfter(update.now)) {
      throw ArgumentError('Mismatched evidence references.');
    }
    final attempts = await tx.rawQuery(
      'SELECT execution.* FROM conversation_task_tool_attempts link '
      'JOIN tool_execution_records execution ON execution.attempt_id = link.attempt_id '
      'WHERE link.task_id = ? AND link.segment_id = ? AND link.attempt_id = ?',
      [link.taskId, link.segmentId, link.attemptId],
    );
    if (attempts.isEmpty) {
      throw ArgumentError('Evidence requires its recorded attempt.');
    }
    final attempt = attempts.single;
    if (attempt['status'] != evidence.terminalStatus.name ||
        attempt['tool_name'] != evidence.toolName ||
        attempt['run_id'] != evidence.runId ||
        attempt['invocation_id'] != evidence.invocationId ||
        attempt['provider_call_id'] != evidence.providerCallId ||
        attempt['source'] != evidence.source.name) {
      throw ArgumentError('Evidence does not match its completed attempt.');
    }
    // Evidence is a prepared, digest-bound object. Reject unsafe data instead of
    // changing its meaning after the producer has computed the evidence digest.
    final values = ToolEvidenceDbRecord.fromDomain(evidence).values;
    for (final key in ['result_summary', 'subject']) {
      if (_safeText(values[key]! as String) != values[key]) {
        throw ArgumentError('Evidence must be sanitized before persistence.');
      }
    }
    for (final key in ['scope_json', 'structured_facts_json']) {
      final value = jsonDecode(values[key]! as String);
      if (!_sameJson(value, _safeObject(value))) {
        throw ArgumentError('Evidence facts contain unsafe content.');
      }
    }
    final rows = await tx.query(
      'tool_evidence_records',
      where: 'evidence_id = ?',
      whereArgs: [evidence.evidenceId],
    );
    if (rows.isEmpty) {
      await tx.insert('tool_evidence_records', values);
    } else if (!_sameMap(rows.single, values)) {
      throw const _TaskConflict(TaskWriteConflictReason.duplicateIdentity);
    }
    final links = await tx.query(
      'conversation_task_evidence_links',
      where: 'evidence_id = ?',
      whereArgs: [evidence.evidenceId],
    );
    final linkValues = TaskEvidenceLinkRecord.fromDomain(link).values;
    if (links.isEmpty) {
      await tx.insert('conversation_task_evidence_links', linkValues);
    } else if (!_sameMap(links.single, linkValues)) {
      throw const _TaskConflict(TaskWriteConflictReason.duplicateIdentity);
    }
  }
  if (update.event.evidenceId != null &&
      (await tx.query(
        'conversation_task_evidence_links',
        where: 'task_id = ? AND evidence_id = ?',
        whereArgs: [update.task.taskId, update.event.evidenceId],
      )).isEmpty) {
    throw ArgumentError('Event evidence belongs to another task.');
  }
}

bool _toolTerminal(ToolInvocationStatus status) =>
    !{
      ToolInvocationStatus.requested,
      ToolInvocationStatus.awaitingApproval,
      ToolInvocationStatus.running,
    }.contains(status);
