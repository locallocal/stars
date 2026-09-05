part of 'agent_run_coordinator.dart';

final class _ExtendableDeadline {
  _ExtendableDeadline(Duration initialDuration, this._onTimeout)
    : _budget = initialDuration {
    _arm(initialDuration);
  }

  final void Function() _onTimeout;
  final Stopwatch _stopwatch = Stopwatch();
  Duration _budget;
  Timer? _timer;
  bool _expired = false;

  void ensureRemaining(Duration minimumRemaining) {
    if (_expired) return;
    final remaining = _budget - _stopwatch.elapsed;
    if (remaining >= minimumRemaining) return;
    _arm(minimumRemaining);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
  }

  void _arm(Duration duration) {
    _timer?.cancel();
    _budget = duration;
    _stopwatch
      ..reset()
      ..start();
    _timer = Timer(duration, () {
      if (_expired) return;
      _expired = true;
      _stopwatch.stop();
      _onTimeout();
    });
  }
}

extension _AgentRunCoordinatorSupport on AgentRunCoordinator {
  Future<List<ToolResult>> _executeSequentially({
    required List<ToolCallRequest> calls,
    required String runId,
    required Set<String> exposedNames,
    required ToolPolicyContext policyContext,
    required AgentCancellationToken cancellationToken,
    required Map<String, _CompletedCall> completedCalls,
    required _InvocationIdentityRegistry invocationIdentities,
    required Future<void> Function(ToolInvocationRecord) observeInvocation,
    bool Function()? shouldContinue,
  }) async {
    final results = <ToolResult>[];
    for (final call in calls) {
      if (shouldContinue != null && !shouldContinue()) break;
      cancellationToken.throwIfCancelled();
      results.add(
        await _executeToolCall(
          call: call,
          runId: runId,
          exposedNames: exposedNames,
          policyContext: policyContext,
          cancellationToken: cancellationToken,
          completedCalls: completedCalls,
          invocationIdentities: invocationIdentities,
          observeInvocation: observeInvocation,
        ),
      );
    }
    return results;
  }

  bool _isParallelSafe(ToolCallRequest call) {
    final definition = _toolRegistry.find(call.name)?.definition;
    if (definition == null || definition.riskLevel != ToolRiskLevel.readOnly) {
      return false;
    }
    return definition.capabilities.isNotEmpty &&
        definition.capabilities.every(
          (capability) => capability == ToolCapability.compute,
        );
  }

  bool _isVerificationRetrySafe(ToolCallRequest call) {
    final definition = _toolRegistry.find(call.name)?.definition;
    if (definition == null || definition.riskLevel != ToolRiskLevel.readOnly) {
      return false;
    }
    return !definition.capabilities.any(
      const <ToolCapability>{
        ToolCapability.localWrite,
        ToolCapability.externalWrite,
        ToolCapability.process,
      }.contains,
    );
  }

  Future<void> _consumeEvents(
    Stream<ModelEvent> events,
    AgentCancellationToken cancellationToken,
    void Function(ModelEvent event) consume,
  ) async {
    final iterator = StreamIterator<ModelEvent>(events);
    try {
      while (await _raceCancellation(iterator.moveNext(), cancellationToken)) {
        consume(iterator.current);
      }
    } finally {
      await iterator.cancel();
    }
  }

  Future<T> _raceCancellation<T>(
    Future<T> operation,
    AgentCancellationToken cancellationToken,
  ) {
    cancellationToken.throwIfCancelled();
    return Future.any<T>([
      operation,
      cancellationToken.whenCancelled.then<T>(
        (_) => throw const AgentRunCancelledException(),
      ),
    ]);
  }

  ToolInvocationRecord _completeRecord(
    ToolInvocationRecord record, {
    required ToolInvocationStatus status,
    String resultSummary = '',
    String errorCode = '',
    String approvalDecision = '',
    ToolEvidenceCandidate? evidenceCandidate,
    DateTime? completedAt,
  }) {
    final effectiveCompletedAt = completedAt ?? DateTime.now();
    return record.copyWith(
      status: status,
      resultSummary: _truncate(resultSummary, 512),
      errorCode: errorCode,
      approvalDecision:
          approvalDecision.isEmpty ? record.approvalDecision : approvalDecision,
      completedAt: effectiveCompletedAt,
      durationMs:
          effectiveCompletedAt.difference(record.startedAt).inMilliseconds,
      evidenceCandidate: evidenceCandidate,
    );
  }

  ToolResult _truncateResult(ToolResult result) {
    if (result.content.runes.length <= _limits.maxToolOutputCharacters) {
      return result;
    }
    const suffix = '\n[tool output truncated]';
    final retained = _limits.maxToolOutputCharacters - suffix.runes.length;
    return result.copyWith(
      content:
          '${String.fromCharCodes(result.content.runes.take(retained))}$suffix',
      clearStructuredContent: true,
      truncated: true,
    );
  }

  ToolResult _identifyResult(ToolResult result, _AttemptIdentity identity) =>
      result.copyWith(
        invocationId: identity.invocationId,
        attemptId: identity.attemptId,
        evidenceId: ToolEvidenceRecord.evidenceIdForAttempt(identity.attemptId),
      );

  String _issuesSummary(List<JsonSchemaValidationIssue> issues) {
    return issues
        .take(3)
        .map((issue) => '${issue.path}:${issue.code}')
        .join(', ');
  }

  String _auditResultSummary(ToolDefinition definition, ToolResult result) {
    if (result.isError) {
      return result.errorCode.isEmpty ? 'tool_error' : result.errorCode;
    }
    if (conversationHistoryToolNames.contains(definition.name) &&
        result.structuredContent is Map) {
      final structured = result.structuredContent! as Map;
      return jsonEncode({
        'count': structured['count'],
        'truncated': structured['truncated'],
        'message_ids': structured['message_ids'],
      });
    }
    final isPureBuiltIn =
        definition.source == ToolSource.builtIn &&
        definition.capabilities.every(
          (capability) => capability == ToolCapability.compute,
        );
    return isPureBuiltIn ? result.content : 'completed';
  }

  String _fingerprint(ToolCallRequest call) {
    return '${call.name}:${_canonicalJson(call.arguments)}';
  }

  String _canonicalJson(Object? value) {
    if (value is Map) {
      final entries =
          value.entries.toList()
            ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));
      return '{${entries.map((entry) => '${jsonEncode(entry.key.toString())}:${_canonicalJson(entry.value)}').join(',')}}';
    }
    if (value is List) {
      return '[${value.map(_canonicalJson).join(',')}]';
    }
    return jsonEncode(value);
  }

  String _truncate(String value, int maxCharacters) {
    if (value.runes.length <= maxCharacters) return value;
    return '${String.fromCharCodes(value.runes.take(maxCharacters - 1))}…';
  }
}

AgentRunPhase _phaseForStatus(AgentRunStatus status) => switch (status) {
  AgentRunStatus.completed => AgentRunPhase.completed,
  AgentRunStatus.cancelled => AgentRunPhase.cancelled,
  AgentRunStatus.failed => AgentRunPhase.failed,
  AgentRunStatus.timedOut => AgentRunPhase.timedOut,
  AgentRunStatus.limitExceeded => AgentRunPhase.limitExceeded,
};

final class _CompletedCall {
  const _CompletedCall(this.result);

  final ToolResult result;
}

/// Allocates application-owned identities while retaining the provider call ID
/// only as the lookup needed to recognize a repeated provider request.
final class _InvocationIdentityRegistry {
  _InvocationIdentityRegistry(this._runId);

  final String _runId;
  final Map<String, _InvocationIdentity> _byProviderCallId = {};
  var _invocationSequence = 0;

  _AttemptIdentity startAttempt({
    required String providerCallId,
    required String fingerprint,
  }) {
    var invocation = _byProviderCallId[providerCallId];
    if (invocation == null) {
      _invocationSequence += 1;
      invocation = _InvocationIdentity(
        invocationId: '$_runId:invocation:$_invocationSequence',
        fingerprint: fingerprint,
      );
      _byProviderCallId[providerCallId] = invocation;
    }

    invocation.attemptSequence += 1;
    final hasFingerprintConflict = invocation.fingerprint != fingerprint;
    if (!hasFingerprintConflict) invocation.matchingAttempts += 1;
    return _AttemptIdentity(
      invocationId: invocation.invocationId,
      attemptId:
          '${invocation.invocationId}:attempt:${invocation.attemptSequence}',
      matchingAttemptNumber: invocation.matchingAttempts,
      hasFingerprintConflict: hasFingerprintConflict,
    );
  }
}

final class _InvocationIdentity {
  _InvocationIdentity({required this.invocationId, required this.fingerprint});

  final String invocationId;
  final String fingerprint;
  var attemptSequence = 0;
  var matchingAttempts = 0;
}

final class _AttemptIdentity {
  const _AttemptIdentity({
    required this.invocationId,
    required this.attemptId,
    required this.matchingAttemptNumber,
    required this.hasFingerprintConflict,
  });

  final String invocationId;
  final String attemptId;
  final int matchingAttemptNumber;
  final bool hasFingerprintConflict;
}

final class _AgentModelFailure implements Exception {
  const _AgentModelFailure(this.message, this.code, this.providerFailure);

  final String message;
  final String code;
  final ProviderFailure? providerFailure;
}
