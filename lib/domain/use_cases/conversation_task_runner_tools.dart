part of 'conversation_task_runner.dart';

extension _TaskSegmentTools on _TaskSegment {
  Future<TaskSegmentResult?> _skipDuplicate() async {
    duplicateCalls++;
    await _save(TaskEventKind.segmentCheckpoint);
    if (duplicateCalls >= limits.maxSameCallRetries) {
      calls.clear();
      return _finishFinalization(TaskReasonCode.noProgress);
    }
    return null;
  }

  TaskPendingCall _prepare(ToolCallRequest call) {
    final adapter = tools[call.name];
    if (adapter == null ||
        !snapshot.plan.allowedToolNames.contains(call.name) ||
        !adapter.checkpointArgumentNames.containsAll(call.arguments.keys) ||
        adapter.definition.source == ToolSource.providerNative ||
        call.callId.isEmpty ||
        call.callId.length > 256 ||
        taskSafeText(call.callId, maximum: 256) != call.callId ||
        jsonEncode(call.arguments).length > 64000 ||
        jsonEncode(call.arguments) !=
            jsonEncode(
              taskSafeObject(call.arguments, preserveFormatting: true),
            ) ||
        const JsonSchemaValidator()
            .validate(call.arguments, adapter.definition.inputSchema)
            .isNotEmpty) {
      throw ArgumentError('Invalid or unsafe task tool request.');
    }
    final fileRead = retainsTaskFileRead(adapter.definition);
    var key =
        'task-call:${_hash([
          task.taskId, call.name,
          if (adapter.definition.riskLevel == ToolRiskLevel.readOnly) nextStep,
          // Version the read context so old summary-only successes can be read once
          // under normal approval without changing any existing attempt identity.
          if (fileRead) 'file-context-v1',
          fileRead ? taskFileReadArguments(call.arguments) : call.arguments,
        ])}';
    if (fileRead &&
        !fileReads.any((page) => taskFileReadCovers(page, call, nextStep))) {
      final base = key;
      final ids =
          snapshot.attemptLinks
              .where(
                (link) =>
                    link.idempotencyKey == base ||
                    link.idempotencyKey.startsWith('$base:read:'),
              )
              .map((link) => link.attemptId)
              .toSet();
      final previous =
          snapshot.events
              .where(
                (event) =>
                    event.kind == TaskEventKind.toolSucceeded &&
                    ids.contains(event.attemptId),
              )
              .lastOrNull;
      if (previous != null) {
        // An evicted page or a subsequent write requires a fresh approved read.
        key = '$base:read:${_hash(previous.attemptId)}';
      }
    }
    if (!fileRead && adapter.definition.riskLevel == ToolRiskLevel.readOnly) {
      final base = key;
      final ids =
          snapshot.attemptLinks
              .where(
                (link) =>
                    link.idempotencyKey == base ||
                    link.idempotencyKey.startsWith('$base:observation:'),
              )
              .map((link) => link.attemptId)
              .toSet();
      final successes = snapshot.events.where(
        (event) =>
            event.kind == TaskEventKind.toolSucceeded &&
            ids.contains(event.attemptId),
      );
      final previous = successes.lastOrNull;
      if (previous != null) {
        final retained = toolResults.any(
          (item) => item.attemptId == previous.attemptId,
        );
        final changedSinceRead = snapshot.events.any(
          (event) =>
              event.kind == TaskEventKind.toolSucceeded &&
              event.sequence > previous.sequence &&
              snapshot.attempts.any(
                (attempt) =>
                    attempt.attemptId == event.attemptId &&
                    attempt.riskLevel != ToolRiskLevel.readOnly,
              ),
        );
        // Old checkpoints and evicted observations may be read again. Writes
        // never take this path, even when their result is no longer retained.
        if (!retained || changedSinceRead) {
          key = '$base:observation:${_hash(previous.attemptId)}';
        } else {
          key =
              snapshot.attemptLinks
                  .singleWhere((link) => link.attemptId == previous.attemptId)
                  .idempotencyKey;
        }
      }
    }
    return TaskPendingCall(
      call: call,
      toolVersion: adapter.definition.toolVersion,
      idempotencyKey: key,
    );
  }

  Future<TaskSegmentResult?> _tool() async {
    var pending = calls.first;
    final adapter = tools[pending.call.name];
    if (adapter == null ||
        adapter.definition.toolVersion != pending.toolVersion ||
        !adapter.checkpointArgumentNames.containsAll(
          pending.call.arguments.keys,
        ) ||
        const JsonSchemaValidator()
            .validate(pending.call.arguments, adapter.definition.inputSchema)
            .isNotEmpty ||
        !snapshot.plan.allowedToolNames.contains(pending.call.name)) {
      return _finishFinalization(
        TaskReasonCode.invalidPlan,
        unknown: pending.attemptId != null,
      );
    }
    final decision = runner.policy.evaluate(
      adapter.definition,
      pending.call,
      ToolPolicyContext(
        runId: segmentId,
        chatId: task.chatId,
        botId: task.botId,
        requestedToolNames: snapshot.plan.allowedToolNames,
        approvalExemptToolNames: snapshot.approvalExemptToolNames,
      ),
    );
    if (decision.outcome == ToolPolicyOutcome.deny) {
      return _finishFinalization(
        TaskReasonCode.permissionDenied,
        unknown: snapshot.attempts.any(
          (attempt) =>
              attempt.attemptId == pending.attemptId &&
              attempt.status == ToolInvocationStatus.running &&
              attempt.riskLevel != ToolRiskLevel.readOnly,
        ),
      );
    }
    if (pending.attemptId == null &&
        retainsTaskFileRead(adapter.definition) &&
        fileReads.any(
          (page) => taskFileReadCovers(page, pending.call, nextStep),
        )) {
      calls.removeAt(0);
      return _skipDuplicate();
    }
    if (pending.attemptId == null &&
        adapter.definition.riskLevel == ToolRiskLevel.readOnly) {
      // Earlier calls in the same model batch may have invalidated or evicted
      // this page since the pending call was prepared.
      pending = _prepare(pending.call);
      calls[0] = pending;
    }
    var record =
        snapshot.attempts
            .where((a) => a.attemptId == pending.attemptId)
            .firstOrNull;
    if (record == null) {
      final links =
          snapshot.attemptLinks
              .where((a) => a.idempotencyKey == pending.idempotencyKey)
              .toList()
            ..sort((a, b) => a.attemptNumber.compareTo(b.attemptNumber));
      final success = snapshot.attempts.where(
        (a) =>
            links.any((link) => link.attemptId == a.attemptId) &&
            a.status == ToolInvocationStatus.succeeded,
      );
      if (success.isNotEmpty) {
        calls.removeAt(0);
        return _skipDuplicate();
      }
      // A checkpoint must never detach from a possibly running side effect.
      if (links.isNotEmpty &&
          snapshot.attempts.any(
            (a) => a.attemptId == links.last.attemptId && a.completedAt == null,
          )) {
        calls[0] = pending.withAttempt(links.last.attemptId, reconcile: true);
        await _save(TaskEventKind.segmentCheckpoint);
        return null;
      }
      if (links.length > limits.maxSameCallRetries) {
        calls.clear();
        replan = true;
        phase = ConversationTaskPhase.planning;
        await _save(TaskEventKind.segmentCheckpoint);
        return null;
      }
      final number = links.isEmpty ? 1 : links.last.attemptNumber + 1;
      final id = 'attempt:${_hash([pending.idempotencyKey, number])}';
      pending = pending.withAttempt(id, retries: number - 1);
      calls[0] = pending;
      record = _record(
        pending,
        adapter.definition,
        decision.outcome == ToolPolicyOutcome.requireApproval
            ? ToolInvocationStatus.awaitingApproval
            : ToolInvocationStatus.requested,
      );
      await _save(
        number == 1 ? TaskEventKind.toolQueued : TaskEventKind.toolRetry,
        tool: record,
        link: TaskToolAttemptLink(
          taskId: task.taskId,
          segmentId: segmentId,
          attemptId: id,
          idempotencyKey: pending.idempotencyKey,
          attemptNumber: number,
        ),
      );
    }
    if (record.completedAt != null) {
      calls.removeAt(0);
      await _save(TaskEventKind.segmentCheckpoint);
      return null;
    }
    if (record.status == ToolInvocationStatus.requested &&
        decision.outcome == ToolPolicyOutcome.requireApproval) {
      record = _record(
        pending,
        adapter.definition,
        ToolInvocationStatus.awaitingApproval,
        previous: record,
      );
      await _save(TaskEventKind.toolQueued, tool: record);
    }
    if (record.status == ToolInvocationStatus.awaitingApproval) {
      final approval =
          snapshot.approvals
              .where((a) => a.attemptId == record!.attemptId)
              .lastOrNull;
      if (approval == null) {
        final request = TaskApprovalRecord(
          approvalId: 'approval:${_hash(record.attemptId)}',
          taskId: task.taskId,
          requestRevision: task.revision + 1,
          safeActionSummary: taskSafeText(
            'Approve ${adapter.definition.name}: ${jsonEncode(pending.call.arguments)}',
          ),
          requestedAt: now,
          attemptId: record.attemptId,
        );
        await _save(
          TaskEventKind.approvalRequested,
          status: ConversationTaskStatus.waitingForUser,
          approval: request,
          attemptId: record.attemptId,
        );
        return _approvalWait(request.approvalId);
      }
      if (approval.decision == null) return _approvalWait(approval.approvalId);
      if (approval.decision == TaskApprovalDecision.denied) {
        await _end(
          pending,
          adapter,
          record,
          ToolResult(
            callId: pending.call.callId,
            name: pending.call.name,
            content: 'Tool approval denied.',
            isError: true,
            errorCode: 'permission_denied',
          ),
          status: ToolInvocationStatus.denied,
        );
        return _finishFinalization(TaskReasonCode.permissionDenied);
      }
    }
    final job =
        jobs.where((job) => job.attemptId == record!.attemptId).firstOrNull;
    if (pending.reconcileRequired ||
        (record.status == ToolInvocationStatus.running && job == null)) {
      return _reconcile(pending, adapter, record, job);
    }
    if (job != null) {
      if (job.nextPollAt.isAfter(now)) return _jobWait(job);
      toolCalls++;
      ToolStartResult result;
      try {
        result = await _operation(
          (token) => adapter.poll(job, token),
          limits.pollTimeout,
        );
      } on AgentRunCancelledException {
        rethrow;
      } on _TaskFenceLost {
        rethrow;
      } on ProviderFailure catch (error) {
        if (!error.retryable) {
          return _finishFinalization(_providerReason(error), unknown: true);
        }
        return _backoff();
      } on Object {
        // A failed poll says nothing about the external operation's outcome.
        await _save(
          TaskEventKind.externalJobUpdated,
          attemptId: record.attemptId,
          reason: 'tool_poll_failed',
        );
        return _backoff();
      }
      return _acceptResult(pending, adapter, record, result);
    }
    record = _record(
      pending,
      adapter.definition,
      ToolInvocationStatus.running,
      previous: record,
    );
    await _save(TaskEventKind.toolStarted, tool: record);
    toolCalls++;
    ToolStartResult result;
    try {
      result = await _operation(
        (token) => adapter.start(pending.call, pending.idempotencyKey, token),
        limits.toolTimeout,
      );
    } on AgentRunCancelledException {
      rethrow;
    } on _TaskFenceLost {
      rethrow;
    } on ProviderFailure catch (error) {
      if (!error.retryable) {
        if (error.kind == ProviderFailureKind.invalidResponse &&
            adapter.definition.riskLevel != ToolRiskLevel.readOnly) {
          return _finishFinalization(
            TaskReasonCode.reconciliationRequired,
            unknown: true,
          );
        }
        await _end(
          pending,
          adapter,
          record,
          ToolResult(
            callId: pending.call.callId,
            name: pending.call.name,
            content: 'The tool provider rejected the operation.',
            isError: true,
            errorCode: error.code,
          ),
          status: ToolInvocationStatus.failed,
        );
        return _finishFinalization(_providerReason(error));
      }
      calls[0] = pending.withAttempt(pending.attemptId, reconcile: true);
      await _save(
        TaskEventKind.segmentCheckpoint,
        reason: 'tool_provider_unavailable',
      );
      return _backoff();
    } on Object catch (error) {
      if (adapter.definition.riskLevel != ToolRiskLevel.readOnly &&
          !adapter.guaranteesIdempotency) {
        calls[0] = pending.withAttempt(pending.attemptId, reconcile: true);
        await _save(
          TaskEventKind.segmentCheckpoint,
          reason: 'tool_outcome_unknown',
        );
        return _backoff();
      }
      return _failure(
        pending,
        adapter,
        record,
        ToolResult(
          callId: pending.call.callId,
          name: pending.call.name,
          content: 'Tool attempt did not complete.',
          isError: true,
          errorCode:
              error is TimeoutException ? 'tool_timeout' : 'tool_unavailable',
        ),
        status:
            error is TimeoutException
                ? ToolInvocationStatus.timedOut
                : ToolInvocationStatus.failed,
      );
    }
    return _acceptResult(pending, adapter, record, result);
  }

  Future<TaskSegmentResult?> _acceptResult(
    TaskPendingCall pending,
    TaskToolAdapter adapter,
    ToolExecutionRecord record,
    ToolStartResult result,
  ) async {
    switch (result) {
      case ToolJobStarted():
        TaskExternalJob job;
        try {
          job = TaskExternalJob(
            attemptId: record.attemptId,
            externalJobId: result.externalJobId,
            resumeHandle: result.resumeHandle,
            safeStatus: taskSafeText(result.safeStatus, maximum: 256),
            nextPollAt: result.nextPollAt,
          );
        } on ArgumentError {
          return _finishFinalization(
            TaskReasonCode.reconciliationRequired,
            unknown: true,
          );
        }
        if (taskSafeText(job.externalJobId, maximum: 256) !=
            job.externalJobId) {
          return _finishFinalization(
            TaskReasonCode.reconciliationRequired,
            unknown: true,
          );
        }
        jobs.removeWhere((old) => old.attemptId == record.attemptId);
        jobs.add(job);
        calls[0] = pending.withAttempt(record.attemptId);
        await _save(
          TaskEventKind.externalJobUpdated,
          attemptId: record.attemptId,
        );
        return _jobWait(job);
      case ToolCompleted():
        if (result.result.callId != pending.call.callId ||
            result.result.name != pending.call.name) {
          return _failure(
            pending,
            adapter,
            record,
            ToolResult(
              callId: pending.call.callId,
              name: pending.call.name,
              content: 'Tool response identity mismatch.',
              isError: true,
              errorCode: 'invalid_tool_output',
            ),
          );
        }
        final validated = const ToolResultValidator().validate(
          adapter.definition,
          pending.call,
          result.result,
        );
        if (validated.result.isError) {
          return _failure(pending, adapter, record, validated.result);
        }
        if (adapter.definition.name == resolveSkillSourceToolName &&
            !usableTaskSkillSources(
              prepareTaskToolObservation(
                attemptId: record.attemptId,
                result: validated.result,
              ),
            )) {
          return _failure(
            pending,
            adapter,
            record,
            ToolResult(
              callId: pending.call.callId,
              name: pending.call.name,
              content:
                  'Skill source resolution returned no complete usable list.',
              isError: true,
              errorCode: 'skill_source_resolution_failed',
            ),
          );
        }
        failures = 0;
        backoffs = 0;
        await _end(
          pending,
          adapter,
          record,
          validated.result,
          evidence: validated.evidenceCandidate,
        );
        return null;
    }
  }

  Future<TaskSegmentResult?> _failure(
    TaskPendingCall pending,
    TaskToolAdapter adapter,
    ToolExecutionRecord record,
    ToolResult result, {
    ToolInvocationStatus status = ToolInvocationStatus.failed,
    bool reconciled = false,
  }) async {
    final permanent =
        adapter.definition.name == resolveSkillSourceToolName
            ? TaskReasonCode.skillSourceFailed
            : _permanentToolReason(result.errorCode);
    final canRetry =
        adapter.definition.riskLevel == ToolRiskLevel.readOnly ||
        adapter.guaranteesIdempotency ||
        reconciled;
    failures++;
    final retry =
        permanent == null &&
        canRetry &&
        pending.retryCount < limits.maxSameCallRetries &&
        failures < limits.maxConsecutiveToolFailures;
    calls.removeAt(0);
    if (retry) {
      calls.insert(
        0,
        pending.withAttempt(null, retries: pending.retryCount + 1),
      );
    } else if (permanent == null) {
      replan = true;
      calls.clear();
      phase = ConversationTaskPhase.planning;
    }
    await _end(
      pending,
      adapter,
      record,
      result,
      status: status,
      removeCall: false,
    );
    if (permanent != null) return _finishFinalization(permanent);
    if (!canRetry && adapter.definition.riskLevel != ToolRiskLevel.readOnly) {
      return _finishFinalization(
        TaskReasonCode.reconciliationRequired,
        unknown: true,
      );
    }
    if (retry) return _backoff();
    return null;
  }

  Future<void> _end(
    TaskPendingCall pending,
    TaskToolAdapter adapter,
    ToolExecutionRecord record,
    ToolResult result, {
    ToolInvocationStatus status = ToolInvocationStatus.succeeded,
    ToolEvidenceCandidate? evidence,
    bool removeCall = true,
    bool cleanup = false,
  }) async {
    if (removeCall) {
      calls.removeWhere((call) => call.attemptId == record.attemptId);
    }
    jobs.removeWhere((job) => job.attemptId == record.attemptId);
    phase = ConversationTaskPhase.observing;
    final summary = _toolResultSummary(result.content);
    ToolEvidenceRecord? fact;
    if (evidence != null) {
      // Evidence cannot be redacted after its digest has been established.
      final data = {
        'subject': evidence.subject,
        'scope': evidence.scope,
        'facts': [
          for (final f in evidence.structuredFacts)
            {'name': f.name, 'value': f.value},
        ],
      };
      if (jsonEncode(data) == jsonEncode(taskSafeObject(data))) {
        fact = ToolEvidenceRecord(
          evidenceId: ToolEvidenceRecord.evidenceIdForAttempt(record.attemptId),
          runId: record.runId,
          turnId: task.originTurnId,
          chatId: task.chatId,
          messageId: task.ackMessageId,
          invocationId: record.invocationId,
          attemptId: record.attemptId,
          providerCallId: record.providerCallId,
          toolName: record.name,
          toolVersion: evidence.toolVersion,
          source: record.source,
          capabilities: evidence.capabilities,
          terminalStatus: status,
          evidenceKind: evidence.evidenceKind,
          subject: evidence.subject,
          scope: evidence.scope,
          resultSummary: summary,
          argumentsDigest: evidence.argumentsDigest,
          resultDigest: evidence.resultDigest,
          structuredFacts: evidence.structuredFacts,
          observedAt: evidence.observedAt,
          validUntil: evidence.validUntil,
        );
      }
    }
    if (status == ToolInvocationStatus.succeeded) {
      duplicateCalls = 0;
      if (!retainsTaskFileRead(adapter.definition)) {
        final observation = prepareTaskToolObservation(
          attemptId: record.attemptId,
          result: result,
        );
        final retained = TaskToolObservation.retain([
          ...toolResults.where((item) => item.attemptId != record.attemptId),
          observation,
        ]);
        toolResults
          ..clear()
          ..addAll(retained);
      }
      if (retainsTaskFileRead(adapter.definition)) {
        final page = prepareTaskFileRead(
          call: pending.call,
          result: result,
          attemptId: record.attemptId,
          stepId: nextStep!,
        );
        final retained = TaskFileReadObservation.retain([...fileReads, page]);
        fileReads
          ..clear()
          ..addAll(retained);
      } else if (adapter.definition.riskLevel != ToolRiskLevel.readOnly) {
        // A successful mutation can invalidate any file observed in this step.
        fileReads.clear();
      }
    }
    await _save(
      status == ToolInvocationStatus.succeeded
          ? TaskEventKind.toolSucceeded
          : TaskEventKind.toolFailed,
      tool: _record(
        pending,
        adapter.definition,
        status,
        previous: record,
        summary: summary,
        detail: taskExecutionOutput(result.content),
        errorCode:
            status == ToolInvocationStatus.succeeded
                ? ''
                : _safeToolCode(result.errorCode),
      ),
      evidence: fact,
      cleanup: cleanup,
    );
  }

  ToolExecutionRecord _record(
    TaskPendingCall call,
    ToolDefinition definition,
    ToolInvocationStatus status, {
    ToolExecutionRecord? previous,
    String summary = '',
    String detail = '',
    String errorCode = '',
  }) {
    final terminal =
        !{
          ToolInvocationStatus.requested,
          ToolInvocationStatus.awaitingApproval,
          ToolInvocationStatus.running,
        }.contains(status);
    final at = now;
    final started = previous?.startedAt ?? at;
    return ToolExecutionRecord(
      executionId: call.attemptId!,
      invocationId: previous?.invocationId ?? call.idempotencyKey,
      attemptId: call.attemptId!,
      providerCallId: previous?.providerCallId ?? call.call.callId,
      runId: previous?.runId ?? segmentId,
      turnId: task.originTurnId,
      messageId: task.ackMessageId,
      chatId: task.chatId,
      botId: task.botId,
      callId: previous?.callId ?? call.call.callId,
      name: definition.name,
      title: definition.title,
      mcpServerName: definition.mcpServerName,
      source: definition.source,
      riskLevel: definition.riskLevel,
      status: status,
      argumentsSummary: taskExecutionArguments(jsonEncode(call.call.arguments)),
      detail: detail,
      approvalStatus: switch (snapshot.approvals
          .where((approval) => approval.attemptId == call.attemptId)
          .lastOrNull
          ?.decision) {
        TaskApprovalDecision.approved => 'allowOnce',
        TaskApprovalDecision.denied => 'deny',
        null => '',
      },
      resultSummary: summary,
      errorCode: errorCode,
      startedAt: started,
      completedAt: terminal ? at : null,
      durationMs: terminal ? at.difference(started).inMilliseconds : null,
      updatedAt: at,
    );
  }
}

String _toolResultSummary(String content) {
  // Redact while line boundaries still identify diagnostics, then meet the
  // evidence summary's single-line contract without changing the result digest.
  final safe = taskSafeText(content);
  final normalized = safe.replaceAll(RegExp(r'[\x00-\x1f\x7f\s]+'), ' ').trim();
  // Normalization can expose a leading JSON object or a credential assignment.
  return taskSafeText(
    normalized.isEmpty ? 'Tool attempt completed.' : normalized,
  );
}

String _safeToolCode(String code) =>
    RegExp(r'^[a-z][a-z0-9_]{0,127}$').hasMatch(code) ? code : 'tool_failed';
String? _permanentToolReason(String code) => switch (code) {
  'authentication_failed' ||
  'missing_credentials' ||
  'mcp_access_token_required' ||
  'mcp_environment_value_required' ||
  'unauthorized' => TaskReasonCode.missingCredentials,
  'permission_denied' ||
  'forbidden' ||
  'tool_denied' => TaskReasonCode.permissionDenied,
  'invalid_arguments' ||
  'invalid_tool_arguments' ||
  'invalid_skill_source' ||
  'invalid_mcp_server' ||
  'invalid_mcp_transport' ||
  'invalid_mcp_server_name' ||
  'invalid_mcp_connect_option' ||
  'mcp_configuration_unavailable' ||
  'mcp_configuration_mismatch' ||
  'mcp_unsupported_configuration' ||
  'mcp_unsupported_headers' ||
  'mcp_server_already_exists' ||
  'mcp_invalid_endpoint' ||
  'mcp_invalid_auth_type' ||
  'mcp_invalid_credential' ||
  'mcp_unexpected_credential' ||
  'mcp_transport_field_mismatch' ||
  'mcp_invalid_stdio_command' ||
  'mcp_invalid_stdio_arguments' ||
  'mcp_invalid_stdio_environment' ||
  'invalid_input' => TaskReasonCode.invalidPlan,
  'skill_install_rejected' => TaskReasonCode.skillInstallRejected,
  _ => null,
};
