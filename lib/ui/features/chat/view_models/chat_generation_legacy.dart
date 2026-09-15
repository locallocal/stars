part of 'chat_generation_view_model.dart';

// Isolated legacy entry points retained for phase 08 cleanup and its regression
// suite. Production text sends exclusively call dispatchText.
extension LegacyChatGeneration on ChatGenerationViewModel {
  Future<bool> startText({
    required Message userMessage,
    required List<ChatMessage> messages,
    List<ActivatedSkill> activatedSkills = const [],
    List<SkillActivationAttempt> activationAttempts = const [],
    List<MessageToolCall> skillToolCalls = const [],
    ModelTokenUsage preflightTokenUsage = ModelTokenUsage.empty,
    Set<String> requestedToolNames = const {},
    Set<String> verificationToolNames = const {},
    Set<String> approvalExemptToolNames = const {},
    String verificationUnavailableReason = '',
  }) => startTextWithPreparation(
    userMessage: userMessage,
    prepare:
        (identifiedUserMessage) async => PreparedTextGeneration(
          userMessage: identifiedUserMessage,
          messages: messages,
          activatedSkills: activatedSkills,
          activationAttempts: activationAttempts,
          skillToolCalls: skillToolCalls,
          preflightTokenUsage: preflightTokenUsage,
          requestedToolNames: requestedToolNames,
          verificationToolNames: verificationToolNames,
          approvalExemptToolNames: approvalExemptToolNames,
          verificationUnavailableReason: verificationUnavailableReason,
          maxModelTurns: _agentRunLimits.maxModelTurns,
        ),
  );

  Future<bool> startTextWithPreparation({
    required Message userMessage,
    required TextGenerationPreparer prepare,
  }) async {
    if (!_acceptsAsyncCallbacks || hasBlockingRun) return false;

    final runId = _messageIdFactory('run');
    final turnId =
        userMessage.turnId.isEmpty
            ? _messageIdFactory('turn')
            : userMessage.turnId;
    final identifiedUser = userMessage.copyWith(
      messageId:
          userMessage.messageId.isEmpty ? '$runId:user' : userMessage.messageId,
      turnId: turnId,
      runId: runId,
      clearTerminalOutcome: true,
      hasPartialContent: false,
    );

    final provider =
        _providerFactory(_bot)
          ..setWebSearch(_capabilityProvider.getWebSearch())
          ..setDeepThinking(_capabilityProvider.getDeepThinking());
    _runProvider = provider;
    _startedAt = DateTime.now();
    _preflightTokenUsage = ModelTokenUsage.empty;
    _agentTokenUsage = ModelTokenUsage.empty;
    _providerSupportsAgentLoop = provider.capabilities.supportsAgentLoop;
    _reliabilityPolicyEnabled = true;
    _answerEvidenceState = AnswerEvidenceState.none;
    _answerTrustGateResult = AnswerTrustGateResult.notRun;
    _validatedEvidenceIds = const [];
    _validatedClaims = const [];
    _verificationUnavailableReason = '';
    _terminalCompleter = Completer<ChatRunLifecycle>();
    _preparingRuns.add(runId);
    _snapshot = ChatGenerationSnapshot(
      chatId: chatId,
      runId: runId,
      turnId: turnId,
      lifecycle: ChatRunLifecycle.submitting,
      // Preparation can always be abandoned, even when the provider itself
      // cannot cancel an in-flight generation request.
      supportsCancellation: true,
      submittedUserMessage: identifiedUser,
    );
    _notifyView();

    late final PreparedTextGeneration prepared;
    try {
      prepared = await prepare(identifiedUser);
    } catch (error) {
      if (!_acceptsAsyncCallbacks) return false;
      _preparingRuns.remove(runId);
      if (_isActiveRun(runId) && !_snapshot.lifecycle.isTerminal) {
        await _finalizeRun(
          runId,
          ProviderTerminalType.failed,
          error: AppFailure.from(error, code: 'generation_prepare_failed').code,
        );
      }
      return false;
    }
    if (!_acceptsAsyncCallbacks) return false;
    _preparingRuns.remove(runId);

    if (!_isActiveRun(runId) || _snapshot.lifecycle.isTerminal) return false;
    final preparedUser = prepared.userMessage.copyWith(
      messageId: identifiedUser.messageId,
      turnId: turnId,
      runId: runId,
      clearTerminalOutcome: true,
      hasPartialContent: false,
    );
    _preflightTokenUsage = prepared.preflightTokenUsage;
    _contextAssemblyReport = prepared.contextAssemblyReport;
    _reliabilityPolicyEnabled = prepared.reliabilityPolicyEnabled;
    _verificationUnavailableReason = prepared.verificationUnavailableReason;
    _snapshot = _snapshot.copyWith(
      supportsCancellation: provider.supportsCancellation,
      tokenUsage: prepared.preflightTokenUsage,
      toolCalls: prepared.skillToolCalls,
      skillActivations: [
        for (final skill in prepared.activatedSkills)
          MessageSkillActivation(
            name: skill.name,
            contentDigest: skill.contentDigest,
            trigger: skill.trigger.name,
          ),
      ],
      submittedUserMessage: preparedUser,
    );
    _notifyView();

    try {
      await _messagePersister(preparedUser);
    } catch (error) {
      if (_isActiveRun(runId)) {
        _preflightCancellationRuns.remove(runId);
        _snapshot = _snapshot.copyWith(
          lifecycle: ChatRunLifecycle.failed,
          error: AppFailure.from(error, code: 'generation_start_failed').code,
          userPersisted: false,
        );
        _completeTerminal(ChatRunLifecycle.failed);
        _notifyView();
      }
      return false;
    }

    if (!_isActiveRun(runId) || _snapshot.lifecycle.isTerminal) return false;
    _snapshot = _snapshot.copyWith(userPersisted: true, clearError: true);
    _notifyView();
    await _persistSkillActivationsSafely(
      runId: runId,
      messageId: '$runId:assistant',
      activatedSkills: prepared.activatedSkills,
      activationAttempts: prepared.activationAttempts,
    );

    unawaited(_updateLastMessageSafely(preparedUser.content));

    if (!_isActiveRun(runId) || _snapshot.lifecycle.isTerminal) return false;
    if (_preflightCancellationRuns.remove(runId)) {
      await _finalizeRun(runId, ProviderTerminalType.cancelled);
      return false;
    }

    _snapshot = _snapshot.copyWith(
      lifecycle: ChatRunLifecycle.connecting,
      clearError: true,
    );
    _notifyView();
    if (_preflightCancellationRuns.remove(runId)) {
      await _finalizeRun(runId, ProviderTerminalType.cancelled);
      return false;
    }

    final runToolRegistry =
        prepared.runScopedTools.isEmpty
            ? _toolRegistry
            : OverlayToolRegistry(
              parent: _toolRegistry,
              overlayTools: prepared.runScopedTools,
            );
    final agentToolNames = <String>{
      ...prepared.requestedToolNames,
      ...prepared.verificationToolNames,
    };
    final agentTools =
        agentToolNames.isEmpty
            ? const <ToolDefinition>[]
            : runToolRegistry.list(allowedNames: agentToolNames);
    final usesNormalizedNativeTools =
        provider.getWebSearch() &&
        provider.capabilities.supportsNativeToolEvidence;
    if (provider.capabilities.supportsAgentLoop &&
        (agentTools.isNotEmpty || usesNormalizedNativeTools)) {
      return _startAgentRun(
        runId: runId,
        provider: provider,
        messages: prepared.messages,
        requestedToolNames: prepared.requestedToolNames,
        verificationToolNames: prepared.verificationToolNames,
        approvalExemptToolNames: prepared.approvalExemptToolNames,
        toolRegistry: runToolRegistry,
        maxModelTurns: prepared.maxModelTurns,
      );
    }

    provider.setCallbacks(
      onResponse: (text) => _onResponse(runId, text),
      onReasoningResponse: (text) => _onReasoning(runId, text),
      onToolCall: (toolCall) => _onToolCall(runId, toolCall),
      onCommandExecution: (execution) => _onCommandExecution(runId, execution),
      onTokenUsage: (usage) => _onTokenUsage(runId, usage),
      onComplete: () {},
      onError: (_) {},
      onTerminal: (event) => _onProviderTerminal(runId, event),
    );

    // Providers reset their cancellation state synchronously at the start of
    // generateText. Invoke it before publishing the cancellable active state
    // so an input event cannot be erased by that reset.
    late final Future<void> generation;
    try {
      generation = provider.generateText(prepared.messages);
    } catch (error) {
      if (error is ProviderFailure && !_hasGeneratedContent) {
        _recordProviderFailureSafely(error);
      }
      await _finalizeRun(
        runId,
        ProviderTerminalType.failed,
        error: AppFailure.from(error, code: 'generation_persist_failed').code,
      );
      return false;
    }

    unawaited(
      generation
          .then((_) {
            if (_isActiveRun(runId) && !_finalizingRuns.contains(runId)) {
              unawaited(_finalizeRun(runId, ProviderTerminalType.completed));
            }
          })
          .catchError((Object error, StackTrace stackTrace) {
            if (_isActiveRun(runId) && !_finalizingRuns.contains(runId)) {
              if (error is ProviderFailure && !_hasGeneratedContent) {
                _recordProviderFailureSafely(error);
              }
              unawaited(
                _finalizeRun(
                  runId,
                  provider.isCancelled
                      ? ProviderTerminalType.cancelled
                      : ProviderTerminalType.failed,
                  error:
                      AppFailure.from(
                        error,
                        code: 'generation_partial_persist_failed',
                      ).code,
                ),
              );
            }
          }),
    );
    if (!_isActiveRun(runId) || _snapshot.lifecycle.isTerminal) return false;
    if (!_finalizingRuns.contains(runId)) {
      _snapshot = _snapshot.copyWith(lifecycle: ChatRunLifecycle.active);
      _notifyView();
    }
    return true;
  }

  Future<void> _finalizeRun(
    String runId,
    ProviderTerminalType providerTerminal, {
    String? error,
  }) async {
    if (!_isActiveRun(runId) ||
        _snapshot.lifecycle.isTerminal ||
        !_finalizingRuns.add(runId)) {
      return;
    }

    _partialPersistenceTimer?.cancel();
    _partialPersistenceTimer = null;
    await _partialPersistenceQueue;
    if (!_isActiveRun(runId)) return;

    var lifecycle = switch (providerTerminal) {
      ProviderTerminalType.completed => ChatRunLifecycle.completed,
      ProviderTerminalType.cancelled => ChatRunLifecycle.cancelled,
      ProviderTerminalType.failed => ChatRunLifecycle.failed,
    };
    final hasGeneratedContent =
        _snapshot.streamingResponse.isNotEmpty ||
        _snapshot.reasoningResponse.isNotEmpty ||
        _snapshot.toolCalls.isNotEmpty ||
        _snapshot.commandExecutions.isNotEmpty ||
        _snapshot.skillActivations.isNotEmpty ||
        _snapshot.localFiles.isNotEmpty;
    if (lifecycle == ChatRunLifecycle.completed && !hasGeneratedContent) {
      lifecycle = ChatRunLifecycle.emptyResponse;
    }

    Message? terminalMessage;
    if (hasGeneratedContent || lifecycle == ChatRunLifecycle.emptyResponse) {
      final outcome = switch (lifecycle) {
        ChatRunLifecycle.completed => MessageTerminalOutcome.completed,
        ChatRunLifecycle.cancelled => MessageTerminalOutcome.cancelled,
        ChatRunLifecycle.failed => MessageTerminalOutcome.failed,
        ChatRunLifecycle.emptyResponse => MessageTerminalOutcome.emptyResponse,
        _ => throw StateError('A terminal run must have a terminal outcome.'),
      };
      final duration =
          _startedAt == null
              ? null
              : DateTime.now().difference(_startedAt!).inMilliseconds;
      final grounding = _evaluateGrounding(outcome, failureReasonCode: error);
      final terminalDraft = Message(
        messageId: '$runId:assistant',
        turnId: _snapshot.turnId ?? runId,
        runId: runId,
        chatId: chatId,
        botId: _bot.id,
        senderId: _bot.id,
        content: _snapshot.streamingResponse,
        reasoning: _snapshot.reasoningResponse,
        processInfo: MessageProcessInfo(
          reasoningStatus:
              _snapshot.reasoningResponse.isEmpty ? '' : outcome.name,
          durationMs: duration,
          toolCalls: List<MessageToolCall>.of(_snapshot.toolCalls),
          commandExecutions: List<MessageCommandExecution>.of(
            _snapshot.commandExecutions,
          ),
          skillActivations: List<MessageSkillActivation>.of(
            _snapshot.skillActivations,
          ),
        ),
        tokenUsage: _snapshot.tokenUsage,
        grounding: grounding,
        files: List<String>.of(_snapshot.localFiles),
        terminalOutcome: outcome,
        hasPartialContent:
            hasGeneratedContent &&
            (lifecycle == ChatRunLifecycle.cancelled ||
                lifecycle == ChatRunLifecycle.failed),
        timestamp: DateTime.now(),
      );
      var terminalPersisted = false;
      try {
        terminalMessage = await _persistGroundedTerminal(terminalDraft);
        terminalPersisted = true;
      } catch (persistenceError) {
        lifecycle = ChatRunLifecycle.failed;
        final failureCode =
            AppFailure.from(
              persistenceError,
              code: 'generation_response_persist_failed',
            ).code;
        error = failureCode;
        terminalMessage = terminalDraft.copyWith(
          grounding: _evaluateGrounding(
            MessageTerminalOutcome.failed,
            failureReasonCode: failureCode,
            criticalPersistenceSucceeded: false,
          ),
          terminalOutcome: MessageTerminalOutcome.failed,
          hasPartialContent: hasGeneratedContent,
        );
      }
      if (!_isActiveRun(runId)) return;
      if (terminalPersisted && terminalMessage.content.isNotEmpty) {
        try {
          final preview = await _assistantPreviewBuilder(terminalMessage);
          await _lastMessageUpdater(chatId, preview);
        } catch (lastMessageError) {
          debugPrint(
            'Failed to update chat preview for $chatId: $lastMessageError',
          );
        }
      }
      if (!_isActiveRun(runId)) return;
      final observer = _terminalMessageObserver;
      if (terminalPersisted && observer != null) {
        unawaited(
          observer(
            chatId,
            _bot,
            terminalMessage,
            _contextAssemblyReport,
          ).catchError((Object observerError, StackTrace stackTrace) {
            debugPrint(
              'Failed to run terminal conversation observer: $observerError',
            );
          }),
        );
      }
    }

    if (!_isActiveRun(runId)) return;
    _snapshot = _snapshot.copyWith(
      lifecycle: lifecycle,
      error: error,
      clearError: error == null,
      terminalMessage: terminalMessage,
    );
    _runProvider = null;
    _agentCancellationToken = null;
    final approvalCompleter = _toolApprovalCompleter;
    if (approvalCompleter != null && !approvalCompleter.isCompleted) {
      approvalCompleter.complete(ToolApprovalDecision.deny);
    }
    _toolApprovalCompleter = null;
    _snapshot = _snapshot.copyWith(clearPendingToolApproval: true);
    _completeTerminal(lifecycle);
    _applyPendingBot();
    _finalizingRuns.remove(runId);
    _notifyView();
  }
}
