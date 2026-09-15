part of 'conversation_task_runner.dart';

extension _TaskSegmentRecovery on _TaskSegment {
  Future<TaskSegmentResult?> _reconcile(
    TaskPendingCall pending,
    TaskToolAdapter adapter,
    ToolExecutionRecord record,
    TaskExternalJob? job,
  ) async {
    toolCalls++;
    ToolReconciliation result;
    try {
      result = await _operation(
        (token) =>
            adapter.reconcile(pending.call, pending.idempotencyKey, job, token),
        limits.reconcileTimeout,
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
      return _backoff();
    }
    switch (result) {
      case ToolReconciled():
        return _acceptResult(pending, adapter, record, result.result);
      case ToolNotStarted():
        return _failure(
          pending,
          adapter,
          record,
          ToolResult(
            callId: pending.call.callId,
            name: pending.call.name,
            content: 'Reconciliation confirmed the operation did not start.',
            isError: true,
            errorCode: 'tool_not_started',
          ),
          reconciled: true,
        );
      case ToolOutcomeUnknown():
        if (adapter.guaranteesIdempotency ||
            adapter.definition.riskLevel == ToolRiskLevel.readOnly) {
          return _failure(
            pending,
            adapter,
            record,
            ToolResult(
              callId: pending.call.callId,
              name: pending.call.name,
              content: 'The previous attempt was interrupted.',
              isError: true,
              errorCode: 'tool_interrupted',
            ),
            status: ToolInvocationStatus.interrupted,
          );
        }
        return _finishFinalization(
          TaskReasonCode.reconciliationRequired,
          unknown: true,
        );
    }
  }

  Future<TaskSegmentResult> _cancel() async {
    var unknown = false;
    for (final pending in List<TaskPendingCall>.of(calls)) {
      final record =
          snapshot.attempts
              .where(
                (a) =>
                    a.attemptId == pending.attemptId && a.completedAt == null,
              )
              .firstOrNull;
      if (record == null) continue;
      final adapter = runner.tools[pending.call.name];
      final job =
          jobs.where((j) => j.attemptId == record.attemptId).firstOrNull;
      if (record.status == ToolInvocationStatus.running) {
        if (adapter == null) {
          unknown = true;
          continue;
        }
        ToolReconciliation result;
        try {
          result = await _operation(
            (token) =>
                job == null
                    ? adapter.reconcile(
                      pending.call,
                      pending.idempotencyKey,
                      null,
                      token,
                    )
                    : adapter.cancel(job, token),
            limits.reconcileTimeout,
            cleanup: true,
          );
        } on _TaskFenceLost {
          rethrow;
        } on Object {
          unknown = true;
          continue;
        }
        switch (result) {
          case ToolOutcomeUnknown():
            unknown = true;
            continue;
          case ToolReconciled(result: ToolJobStarted()):
            unknown = true;
            continue;
          case ToolReconciled(result: ToolCompleted(:final result)):
            if (result.callId != pending.call.callId ||
                result.name != pending.call.name) {
              unknown = true;
              continue;
            }
            final validated = const ToolResultValidator().validate(
              adapter.definition,
              pending.call,
              result,
            );
            if (validated.result.isError &&
                adapter.definition.riskLevel != ToolRiskLevel.readOnly) {
              unknown = true;
              continue;
            }
            await _end(
              pending,
              adapter,
              record,
              validated.result,
              status:
                  validated.result.isError
                      ? ToolInvocationStatus.failed
                      : ToolInvocationStatus.succeeded,
              evidence: validated.evidenceCandidate,
              cleanup: true,
            );
            continue;
          case ToolNotStarted():
            break;
        }
      }
      if (adapter != null) {
        await _end(
          pending,
          adapter,
          record,
          ToolResult(
            callId: pending.call.callId,
            name: pending.call.name,
            content: 'Task cancellation stopped this attempt.',
          ),
          status: ToolInvocationStatus.cancelled,
          cleanup: true,
        );
      }
    }
    return _finishFinalization(
      TaskReasonCode.cancelled,
      unknown: unknown,
      cleanup: true,
    );
  }
}
