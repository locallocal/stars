part of 'agent_run_coordinator.dart';

final RegExp _evidenceFooter = RegExp(
  r'<stars_evidence\s+call_ids="([^"]*)"\s*/>',
);

extension _AgentRunCoordinatorSupport on AgentRunCoordinator {
  Future<List<ToolResult>> _executeSequentially({
    required List<ToolCallRequest> calls,
    required String runId,
    required Set<String> exposedNames,
    required ToolPolicyContext policyContext,
    required AgentCancellationToken cancellationToken,
    required Map<String, _CompletedCall> completedCalls,
    required _InvocationIdentityRegistry invocationIdentities,
    required void Function(ToolInvocationRecord) observeInvocation,
  }) async {
    final results = <ToolResult>[];
    for (final call in calls) {
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
  }) {
    final completedAt = DateTime.now();
    return record.copyWith(
      status: status,
      resultSummary: _truncate(resultSummary, 512),
      errorCode: errorCode,
      approvalDecision:
          approvalDecision.isEmpty ? record.approvalDecision : approvalDecision,
      completedAt: completedAt,
      durationMs: completedAt.difference(record.startedAt).inMilliseconds,
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
        evidenceId: '${identity.attemptId}:evidence',
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

  _FinalAnswerValidation _validateFinalAnswer(
    String candidate, {
    required Map<String, _CompletedCall> completedCalls,
  }) {
    final normalized = candidate.trimRight();
    final footerMatches = _evidenceFooter.allMatches(normalized).toList();
    if (completedCalls.isEmpty) {
      if (footerMatches.isEmpty) {
        return _FinalAnswerValidation.valid(normalized);
      }
      if (footerMatches.length != 1) {
        return const _FinalAnswerValidation.invalid(
          'multiple_evidence_footers',
        );
      }
      final ids = _evidenceIds(footerMatches.single.group(1) ?? '');
      if (ids.isNotEmpty) {
        return const _FinalAnswerValidation.invalid('unknown_evidence_id');
      }
      return _FinalAnswerValidation.valid(
        normalized.substring(0, footerMatches.single.start).trimRight(),
      );
    }
    if (footerMatches.length != 1 ||
        footerMatches.single.end != normalized.length) {
      return const _FinalAnswerValidation.invalid('missing_evidence_footer');
    }
    final ids = _evidenceIds(footerMatches.single.group(1) ?? '');
    final usableIds = <String>{
      for (final entry in completedCalls.entries)
        if (_isUsableEvidence(entry.value.result)) entry.key,
    };
    if (ids.any((id) => !usableIds.contains(id))) {
      return const _FinalAnswerValidation.invalid('invalid_evidence_id');
    }
    if (usableIds.isNotEmpty && ids.isEmpty) {
      return const _FinalAnswerValidation.invalid('usable_evidence_not_cited');
    }
    if (usableIds.isEmpty && ids.isNotEmpty) {
      return const _FinalAnswerValidation.invalid('unusable_evidence_cited');
    }
    return _FinalAnswerValidation.valid(
      normalized.substring(0, footerMatches.single.start).trimRight(),
    );
  }

  List<String> _evidenceIds(String value) => value
      .split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList(growable: false);

  bool _isUsableEvidence(ToolResult result) =>
      !result.isError &&
      !result.truncated &&
      (result.content.trim().isNotEmpty || result.structuredContent != null);

  String _reliabilityFeedback(
    String reason,
    Map<String, _CompletedCall> completedCalls,
  ) {
    final ledger = [
      for (final entry in completedCalls.entries)
        {
          'evidence_id': entry.value.result.evidenceId,
          'provider_call_id': entry.key,
          'tool_name': entry.value.result.name,
          'status': entry.value.result.isError ? 'error' : 'success',
          'error_code': entry.value.result.errorCode,
          'truncated': entry.value.result.truncated,
          'usable': _isUsableEvidence(entry.value.result),
        },
    ];
    return '''
<stars_reliability_feedback>
The previous final answer was rejected by deterministic validation: $reason.
Rewrite the complete final answer using only the usable evidence listed below.
Do not claim success from error, empty, or truncated results. End with exactly
one <stars_evidence call_ids="..." /> footer. If no evidence is usable, explain
that the result cannot be verified and use an empty call_ids value.
Evidence ledger: ${jsonEncode(ledger)}
</stars_reliability_feedback>
'''.trim();
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

final class _FinalAnswerValidation {
  const _FinalAnswerValidation.valid(this.text) : isValid = true, reason = '';

  const _FinalAnswerValidation.invalid(this.reason)
    : isValid = false,
      text = '';

  final bool isValid;
  final String text;
  final String reason;
}

final class _AgentModelFailure implements Exception {
  const _AgentModelFailure(this.message, this.code);

  final String message;
  final String code;
}
