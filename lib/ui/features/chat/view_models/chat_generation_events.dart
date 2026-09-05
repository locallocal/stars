part of 'chat_generation_view_model.dart';

extension _ChatGenerationEvents on ChatGenerationViewModel {
  void _onResponse(String runId, String text) {
    if (!_canReduceProviderEvent(runId)) return;
    _snapshot = _snapshot.copyWith(
      streamingResponse: '${_snapshot.streamingResponse}$text',
      lifecycle:
          _snapshot.lifecycle == ChatRunLifecycle.connecting
              ? ChatRunLifecycle.active
              : _snapshot.lifecycle,
    );
    _notifyView();
    _schedulePartialPersistence(runId);
  }

  void _onReasoning(String runId, String text) {
    if (!_canReduceProviderEvent(runId)) return;
    _snapshot = _snapshot.copyWith(
      reasoningResponse: '${_snapshot.reasoningResponse}$text',
    );
    _notifyView();
    _schedulePartialPersistence(runId);
  }

  void _onToolCall(String runId, MessageToolCall toolCall) {
    if (!_canReduceProviderEvent(runId)) return;
    _snapshot = _snapshot.copyWith(
      toolCalls: [..._snapshot.toolCalls, toolCall],
    );
    _notifyView();
    _schedulePartialPersistence(runId);
  }

  void _onCommandExecution(String runId, MessageCommandExecution execution) {
    if (!_canReduceProviderEvent(runId)) return;
    _snapshot = _snapshot.copyWith(
      commandExecutions: [..._snapshot.commandExecutions, execution],
    );
    _notifyView();
    _schedulePartialPersistence(runId);
  }

  void _onTokenUsage(String runId, ModelTokenUsage usage) {
    if (!_canReduceProviderEvent(runId)) return;
    final combined = _preflightTokenUsage + usage;
    _snapshot = _snapshot.copyWith(
      tokenUsage: ModelTokenUsage(
        model:
            usage.model.isNotEmpty ? usage.model : _preflightTokenUsage.model,
        inputTokens: combined.inputTokens,
        outputTokens: combined.outputTokens,
        totalTokens: combined.totalTokens,
      ),
    );
    _notifyView();
    _schedulePartialPersistence(runId);
  }

  Future<bool> _startAgentRun({
    required String runId,
    required AiProvider provider,
    required List<ChatMessage> messages,
    required Set<String> requestedToolNames,
    required Set<String> verificationToolNames,
    required Set<String> approvalExemptToolNames,
    required ToolRegistry toolRegistry,
  }) async {
    final cancellationToken = AgentCancellationToken();
    _agentCancellationToken = cancellationToken;
    _snapshot = _snapshot.copyWith(supportsCancellation: true);
    _notifyView();
    final coordinator = AgentRunCoordinator(
      toolRegistry: toolRegistry,
      toolPolicy: _toolPolicy,
      approvalHandler: this,
      limits: _agentRunLimits,
      toolInvocationPersister: _toolInvocationPersister,
      groundedAnswerValidator: _groundedAnswerValidator,
    );
    final generation = coordinator.run(
      provider: provider,
      request: AgentRunRequest(
        runId: runId,
        chatId: chatId,
        botId: _bot.id,
        turnId: _snapshot.turnId ?? runId,
        messageId: '$runId:assistant',
        messages: messages,
        requestedToolNames: requestedToolNames,
        verificationToolNames: verificationToolNames,
        approvalExemptToolNames: approvalExemptToolNames,
        verificationUnavailableReason: _verificationUnavailableReason,
        cancellationToken: cancellationToken,
      ),
      onModelEvent: (event) => _onAgentModelEvent(runId, event),
      onToolInvocation: (invocation) => _onToolInvocation(runId, invocation),
    );
    unawaited(
      generation
          .then((result) {
            if (!_isActiveRun(runId) || _finalizingRuns.contains(runId)) {
              return;
            }
            if (result.status == AgentRunStatus.completed) {
              _answerTrustGateResult = AnswerTrustGateResult.passed;
              final validation = result.groundedValidation;
              if (validation != null) {
                _validatedEvidenceIds = validation.evidenceIds;
                _validatedClaims = validation.toMessageGrounding().claims;
                _answerEvidenceState = switch (validation.trustLevel) {
                  AnswerTrustLevel.verified =>
                    AnswerEvidenceState.fullyValidated,
                  AnswerTrustLevel.partiallyVerified =>
                    AnswerEvidenceState.partiallyValidated,
                  AnswerTrustLevel.unverified => AnswerEvidenceState.none,
                  AnswerTrustLevel.failed => AnswerEvidenceState.invalid,
                };
              } else {
                _answerEvidenceState =
                    result.toolInvocations.isEmpty
                        ? AnswerEvidenceState.none
                        : result.groundedAnswer?.isLegacy ?? true
                        ? AnswerEvidenceState.legacyFormatOnly
                        : AnswerEvidenceState.structuredUnvalidated;
              }
            } else if (const <String>{
              'invalid_grounded_json',
              'invalid_grounded_answer',
              'invalid_grounded_answer_protocol',
              'invalid_grounded_provider_response',
              'evidence_id_out_of_range',
              'unknown_claim_kind',
              'duplicate_claim_id',
              'empty_claim_text',
            }.contains(result.error)) {
              _answerTrustGateResult = AnswerTrustGateResult.failed;
              _answerEvidenceState = AnswerEvidenceState.invalid;
            }
            final providerFailure = result.providerFailure;
            if (providerFailure != null && !_hasGeneratedContent) {
              _recordProviderFailureSafely(providerFailure);
            }
            final terminal = switch (result.status) {
              AgentRunStatus.completed => ProviderTerminalType.completed,
              AgentRunStatus.cancelled => ProviderTerminalType.cancelled,
              AgentRunStatus.failed ||
              AgentRunStatus.timedOut ||
              AgentRunStatus.limitExceeded => ProviderTerminalType.failed,
            };
            unawaited(
              _finalizeRun(
                runId,
                terminal,
                error: result.error.isEmpty ? null : result.error,
              ),
            );
          })
          .catchError((Object error, StackTrace stackTrace) {
            if (_isActiveRun(runId) && !_finalizingRuns.contains(runId)) {
              unawaited(
                _finalizeRun(
                  runId,
                  cancellationToken.isCancelled
                      ? ProviderTerminalType.cancelled
                      : ProviderTerminalType.failed,
                  error:
                      AppFailure.from(
                        error,
                        code: 'agent_generation_failed',
                      ).code,
                ),
              );
            }
          }),
    );
    if (!_isActiveRun(runId) || _snapshot.lifecycle.isTerminal) {
      return false;
    }
    _snapshot = _snapshot.copyWith(lifecycle: ChatRunLifecycle.active);
    _notifyView();
    return true;
  }

  void _onAgentModelEvent(String runId, ModelEvent event) {
    if (!_canReduceProviderEvent(runId)) return;
    switch (event) {
      case TextDelta():
        _onResponse(runId, event.text);
      case ReasoningDelta():
        _onReasoning(runId, event.text);
      case UsageReported():
        _agentTokenUsage = _agentTokenUsage + event.usage;
        _onTokenUsage(runId, _agentTokenUsage);
      case ToolCallStarted():
      case ToolCallArgumentsDelta():
      case ToolCallRequested():
      case ProviderNativeToolResult():
      case GroundedAnswerProduced():
      case ModelTurnCompleted():
      case ModelTurnFailed():
        break;
    }
  }

  void _onToolInvocation(String runId, ToolInvocationRecord invocation) {
    if (!_canReduceProviderEvent(runId)) return;
    final detail =
        invocation.errorCode.isNotEmpty
            ? invocation.errorCode
            : invocation.resultSummary;
    final arguments =
        conversationHistoryToolNames.contains(invocation.name)
            ? jsonEncode({
              'query_hash':
                  sha256
                      .convert(utf8.encode(jsonEncode(invocation.arguments)))
                      .toString(),
            })
            : invocation.name == shellCommandToolName
            ? jsonEncode(_shellAuditArguments(invocation.arguments))
            : invocation.name == addMcpServerToolName
            ? jsonEncode(_addMcpServerAuditArguments(invocation.arguments))
            : jsonEncode(_redactAuditValue(invocation.arguments));
    final item = MessageToolCall(
      executionId: invocation.executionId,
      invocationId: invocation.invocationId,
      attemptId: invocation.attemptId,
      providerCallId: invocation.providerCallId,
      callId: invocation.callId,
      name: invocation.name,
      title: invocation.title,
      mcpServerName: invocation.mcpServerName,
      status: invocation.status.name,
      detail: detail,
      source: invocation.source.name,
      riskLevel: invocation.riskLevel.name,
      argumentsSummary: _truncateAuditText(arguments),
      resultSummary: _truncateAuditText(invocation.resultSummary),
      approvalStatus: invocation.approvalDecision,
      errorCode: invocation.errorCode,
      durationMs: invocation.durationMs,
    );
    final calls = List<MessageToolCall>.of(_snapshot.toolCalls);
    final index = calls.indexWhere(
      (existing) => existing.attemptId == invocation.attemptId,
    );
    if (index < 0) {
      calls.add(item);
    } else {
      calls[index] = item;
    }
    final commandExecutions = List<MessageCommandExecution>.of(
      _snapshot.commandExecutions,
    );
    final commandExecution = _shellCommandExecution(invocation, detail: detail);
    if (commandExecution != null) {
      final commandIndex = commandExecutions.indexWhere(
        (existing) =>
            existing.callId.isNotEmpty &&
            existing.callId == commandExecution.callId,
      );
      if (commandIndex < 0) {
        commandExecutions.add(commandExecution);
      } else {
        commandExecutions[commandIndex] = commandExecution;
      }
    }
    final localFiles = List<String>.of(_snapshot.localFiles);
    final localFile = _successfulLocalFile(invocation);
    if (localFile != null && !localFiles.contains(localFile)) {
      localFiles.add(localFile);
    }
    _snapshot = _snapshot.copyWith(
      toolCalls: calls,
      commandExecutions: commandExecutions,
      localFiles: localFiles,
    );
    _notifyView();
    _schedulePartialPersistence(runId);
  }

  String? _successfulLocalFile(ToolInvocationRecord invocation) {
    if (invocation.status != ToolInvocationStatus.succeeded) return null;
    final argumentName = switch (invocation.name) {
      readLocalFileToolName || writeLocalFileToolName => 'path',
      copyLocalFileToolName || moveLocalFileToolName => 'destination_path',
      _ => null,
    };
    if (argumentName == null) return null;
    final path = invocation.arguments[argumentName];
    if (path is! String || path.trim().isEmpty) return null;
    return path.trim();
  }

  String _truncateAuditText(String value) {
    const maxCharacters = 512;
    if (value.runes.length <= maxCharacters) return value;
    return '${String.fromCharCodes(value.runes.take(maxCharacters - 1))}…';
  }

  MessageCommandExecution? _shellCommandExecution(
    ToolInvocationRecord invocation, {
    required String detail,
  }) {
    if (invocation.name != shellCommandToolName) return null;
    if (invocation.status == ToolInvocationStatus.duplicateReused ||
        invocation.status == ToolInvocationStatus.duplicateConflict) {
      return null;
    }
    final command = invocation.arguments['command'];
    if (command is! String || command.trim().isEmpty) return null;
    return MessageCommandExecution(
      callId: invocation.callId,
      command: command,
      status: invocation.status.name,
      detail: detail,
      durationMs: invocation.durationMs,
    );
  }

  Object? _redactAuditValue(Object? value, {String key = ''}) {
    final normalizedKey = key.toLowerCase();
    const sensitiveFragments = <String>[
      'authorization',
      'cookie',
      'password',
      'secret',
      'token',
      'api_key',
      'apikey',
    ];
    if (sensitiveFragments.any(normalizedKey.contains)) {
      return '[redacted]';
    }
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
    return {
      'command_hash': sha256.convert(utf8.encode(command)).toString(),
      'command_characters': command.runes.length,
      if (workingDirectory.isNotEmpty)
        'working_directory_hash':
            sha256.convert(utf8.encode(workingDirectory)).toString(),
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
    return {
      'name': arguments['name']?.toString() ?? '',
      'transport_type': arguments['transport_type']?.toString() ?? '',
      if (endpoint.isNotEmpty)
        'endpoint_hash': sha256.convert(utf8.encode(endpoint)).toString(),
      'auth_type': arguments['auth_type']?.toString() ?? 'none',
      'credential_provided': accessToken.isNotEmpty,
      if (command.isNotEmpty)
        'command_hash': sha256.convert(utf8.encode(command)).toString(),
      'argument_count': commandArguments is List ? commandArguments.length : 0,
      'environment_variable_count': environment is Map ? environment.length : 0,
      'connect': arguments['connect'] is bool ? arguments['connect'] : true,
    };
  }
}
