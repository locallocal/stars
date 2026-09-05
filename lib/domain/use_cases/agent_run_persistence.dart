part of 'agent_run_coordinator.dart';

typedef ToolInvocationPersister =
    Future<void> Function(ToolExecutionRecord record);

final class _RunToolPersistence {
  _RunToolPersistence({
    required AgentRunRequest request,
    required ToolInvocationPersister? persister,
  }) : _request = request,
       _persister = persister;

  static const int _maxAttempts = 2;

  final AgentRunRequest _request;
  final ToolInvocationPersister? _persister;
  final Map<String, int> _sequences = <String, int>{};
  Future<void> _queue = Future<void>.value();
  AppFailure? _failure;

  Future<void> record(ToolInvocationRecord invocation) {
    final persister = _persister;
    if (persister == null) return Future<void>.value();
    final sequence = (_sequences[invocation.attemptId] ?? 0) + 1;
    _sequences[invocation.attemptId] = sequence;
    final projection = _toolExecutionProjection(
      _request,
      invocation,
      sequence: sequence,
    );
    _queue = _queue
        .then((_) => _persistWithRetry(persister, projection))
        .then(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {
            _failure ??= AppFailure.storage(
              'tool_evidence_persist_failed',
              cause: error,
            );
          },
        );
    if (!_terminalInvocationStatuses.contains(invocation.status)) {
      return Future<void>.value();
    }
    return _awaitTerminal();
  }

  Future<void> _persistWithRetry(
    ToolInvocationPersister persister,
    ToolExecutionRecord projection,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < _maxAttempts; attempt += 1) {
      try {
        await persister(projection);
        return;
      } on Object catch (error) {
        lastError = error;
      }
    }
    throw AppFailure.storage('tool_evidence_persist_failed', cause: lastError);
  }

  Future<void> _awaitTerminal() async {
    await _queue;
    final failure = _failure;
    if (failure != null) throw failure;
  }
}

ToolExecutionRecord _toolExecutionProjection(
  AgentRunRequest request,
  ToolInvocationRecord invocation, {
  required int sequence,
}) {
  final detail =
      invocation.errorCode.isNotEmpty
          ? invocation.errorCode
          : invocation.resultSummary;
  final arguments =
      conversationHistoryToolNames.contains(invocation.name)
          ? jsonEncode(<String, Object?>{
            'query_hash': _digestAuditText(jsonEncode(invocation.arguments)),
          })
          : invocation.name == shellCommandToolName
          ? jsonEncode(_shellAuditArguments(invocation.arguments))
          : invocation.name == addMcpServerToolName
          ? jsonEncode(_addMcpServerAuditArguments(invocation.arguments))
          : jsonEncode(_redactAuditValue(invocation.arguments));
  return ToolExecutionRecord(
    executionId: invocation.executionId,
    invocationId: invocation.invocationId,
    attemptId: invocation.attemptId,
    providerCallId: invocation.providerCallId,
    runId: request.runId,
    turnId: request.turnId.isEmpty ? request.runId : request.turnId,
    messageId:
        request.messageId.isEmpty
            ? '${request.runId}:assistant'
            : request.messageId,
    chatId: request.chatId,
    botId: request.botId,
    callId: invocation.callId,
    name: invocation.name,
    title: invocation.title,
    mcpServerName: invocation.mcpServerName,
    source: invocation.source,
    riskLevel: invocation.riskLevel,
    status: invocation.status,
    detail: detail,
    argumentsSummary: _truncateAuditText(arguments),
    resultSummary: _truncateAuditText(invocation.resultSummary),
    approvalStatus: invocation.approvalDecision,
    errorCode: invocation.errorCode,
    durationMs: invocation.durationMs,
    startedAt: invocation.startedAt,
    completedAt: invocation.completedAt,
    updatedAt: DateTime.now(),
    eventSequence: sequence,
    evidenceCandidate: invocation.evidenceCandidate,
  );
}

const Set<ToolInvocationStatus> _terminalInvocationStatuses = {
  ToolInvocationStatus.succeeded,
  ToolInvocationStatus.failed,
  ToolInvocationStatus.denied,
  ToolInvocationStatus.cancelled,
  ToolInvocationStatus.timedOut,
  ToolInvocationStatus.interrupted,
  ToolInvocationStatus.duplicateReused,
  ToolInvocationStatus.duplicateConflict,
  ToolInvocationStatus.duplicate,
};

String _truncateAuditText(String value) {
  const maxCharacters = 512;
  if (value.runes.length <= maxCharacters) return value;
  return '${String.fromCharCodes(value.runes.take(maxCharacters - 1))}…';
}

Object? _redactAuditValue(Object? value, {String key = ''}) {
  final normalizedKey = key.toLowerCase();
  const sensitiveFragments = <String>{
    'authorization',
    'cookie',
    'password',
    'secret',
    'token',
    'api_key',
    'apikey',
  };
  if (sensitiveFragments.any(normalizedKey.contains)) return '[redacted]';
  if (value is Map) {
    return value.map(
      (itemKey, itemValue) => MapEntry(
        itemKey.toString(),
        _redactAuditValue(itemValue, key: itemKey.toString()),
      ),
    );
  }
  if (value is List) {
    return value.map(_redactAuditValue).toList(growable: false);
  }
  if (value is String && value.runes.length > 128) {
    return '[text:${value.runes.length} chars]';
  }
  return value;
}

Map<String, Object?> _shellAuditArguments(Map<String, Object?> arguments) {
  final command = arguments['command']?.toString() ?? '';
  final workingDirectory = arguments['working_directory']?.toString() ?? '';
  return <String, Object?>{
    'command_hash': _digestAuditText(command),
    'command_characters': command.runes.length,
    if (workingDirectory.isNotEmpty)
      'working_directory_hash': _digestAuditText(workingDirectory),
    if (arguments['timeout_seconds'] is int)
      'timeout_seconds': arguments['timeout_seconds'],
  };
}

Map<String, Object?> _addMcpServerAuditArguments(
  Map<String, Object?> arguments,
) {
  final endpoint = arguments['endpoint']?.toString() ?? '';
  final command = arguments['command']?.toString() ?? '';
  final commandArguments = arguments['arguments'];
  final environment = arguments['environment'];
  final accessToken = arguments['access_token']?.toString() ?? '';
  return <String, Object?>{
    'name': arguments['name']?.toString() ?? '',
    'transport_type': arguments['transport_type']?.toString() ?? '',
    if (endpoint.isNotEmpty) 'endpoint_hash': _digestAuditText(endpoint),
    'auth_type': arguments['auth_type']?.toString() ?? 'none',
    'credential_provided': accessToken.isNotEmpty,
    if (command.isNotEmpty) 'command_hash': _digestAuditText(command),
    'argument_count': commandArguments is List ? commandArguments.length : 0,
    'environment_variable_count': environment is Map ? environment.length : 0,
    'connect': arguments['connect'] is bool ? arguments['connect'] : true,
  };
}

String _digestAuditText(String value) =>
    sha256.convert(utf8.encode(value)).toString();
