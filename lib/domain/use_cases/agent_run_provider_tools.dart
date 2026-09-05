part of 'agent_run_coordinator.dart';

extension _AgentRunProviderTools on AgentRunCoordinator {
  Future<void> _recordProviderNativeToolResult({
    required String runId,
    required ProviderNativeToolResult event,
    required Map<String, _CompletedCall> completedCalls,
    required _InvocationIdentityRegistry invocationIdentities,
    required Future<void> Function(ToolInvocationRecord) observeInvocation,
  }) async {
    final definition = event.definition;
    final call = event.call;
    final identity = invocationIdentities.startAttempt(
      providerCallId: call.callId,
      fingerprint: _fingerprint(call),
    );
    final previous = completedCalls[call.callId];
    if (identity.hasFingerprintConflict) {
      await observeInvocation(
        _providerNativeTerminalRecord(
          event,
          identity,
          runId: runId,
          status: ToolInvocationStatus.duplicateConflict,
          resultSummary: 'duplicate_call_id_conflict',
          errorCode: 'duplicate_call_id_conflict',
        ),
      );
      return;
    }
    if (previous != null) {
      await observeInvocation(
        _providerNativeTerminalRecord(
          event,
          identity,
          runId: runId,
          status: ToolInvocationStatus.duplicateReused,
          resultSummary: 'duplicate_call_reused',
        ),
      );
      return;
    }

    var record = ToolInvocationRecord(
      runId: runId,
      invocationId: identity.invocationId,
      attemptId: identity.attemptId,
      providerCallId: call.callId,
      name: definition.name,
      title: definition.title,
      source: definition.source,
      riskLevel: definition.riskLevel,
      status: ToolInvocationStatus.requested,
      arguments: call.arguments,
      startedAt: event.reportedAt,
    );
    await observeInvocation(record);
    record = record.copyWith(status: ToolInvocationStatus.running);
    await observeInvocation(record);

    final sourceResult = event.result.copyWith(source: definition.source);
    final validated = _validateToolResultContract(
      definition,
      call,
      sourceResult,
    );
    final result = _identifyResult(_truncateResult(validated.result), identity);
    record = _completeRecord(
      record,
      status:
          result.isError
              ? ToolInvocationStatus.failed
              : ToolInvocationStatus.succeeded,
      errorCode: result.errorCode,
      resultSummary: _auditResultSummary(definition, result),
      evidenceCandidate: result.truncated ? null : validated.evidenceCandidate,
      completedAt: event.reportedAt,
    );
    await observeInvocation(record);
    completedCalls[call.callId] = _CompletedCall(result);
  }

  ToolInvocationRecord _providerNativeTerminalRecord(
    ProviderNativeToolResult event,
    _AttemptIdentity identity, {
    required String runId,
    required ToolInvocationStatus status,
    required String resultSummary,
    String errorCode = '',
  }) => ToolInvocationRecord(
    runId: runId,
    invocationId: identity.invocationId,
    attemptId: identity.attemptId,
    providerCallId: event.call.callId,
    name: event.definition.name,
    title: event.definition.title,
    source: event.definition.source,
    riskLevel: event.definition.riskLevel,
    status: status,
    arguments: event.call.arguments,
    resultSummary: resultSummary,
    errorCode: errorCode,
    startedAt: event.reportedAt,
    completedAt: event.reportedAt,
    durationMs: 0,
  );
}
