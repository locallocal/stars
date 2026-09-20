part of 'chat_generation_view_model.dart';

extension ChatForegroundDispatch on ChatGenerationViewModel {
  Future<bool> dispatchText({
    required Message userMessage,
    required String language,
    required VerificationPolicySnapshot verification,
    String? retryOfTaskId,
  }) {
    final input = ConversationTurnInput(
      bot: _bot,
      userMessage: userMessage,
      language: language,
      verification: verification,
      segmentLimits: TaskSegmentLimits(),
      retryOfTaskId: retryOfTaskId,
    );
    return _dispatchForeground(input);
  }

  Future<bool> retryDispatch() async {
    final status = _statusRetry;
    if (status != null) {
      return _dispatchForeground(status.context.input, status: status);
    }
    final retry = _dispatchRetry;
    if (retry == null) return false;
    return _dispatchForeground(retry.input, retry: retry);
  }

  Future<bool> _dispatchForeground(
    ConversationTurnInput input, {
    TurnDispatchRetry? retry,
    TurnTaskStatusRead? status,
  }) async {
    if (!_acceptsAsyncCallbacks || hasBlockingRun) return false;
    final router = dispatcher;
    final runId = _messageIdFactory('foreground');
    final token = AgentCancellationToken();
    _foregroundCancellation = token;
    _terminalCompleter = Completer<ChatRunLifecycle>();
    _dispatchRetry = null;
    _statusRetry = null;
    _snapshot = ChatGenerationSnapshot(
      chatId: chatId,
      runId: runId,
      turnId: input.userMessage.turnId,
      submittedUserMessage: input.userMessage,
      lifecycle: ChatRunLifecycle.submitting,
      supportsCancellation: true,
    );
    _notifyView();
    void update(TurnDispatchUpdate value) {
      if (!_acceptsAsyncCallbacks ||
          _snapshot.runId != runId ||
          token.isCancelled) {
        return;
      }
      _contextAssemblyReport = value.context.prepared?.contextAssemblyReport;
      final event = value.event;
      _snapshot = _snapshot.copyWith(
        lifecycle: ChatRunLifecycle.active,
        userPersisted: true,
        streamingResponse:
            event is DirectReplyDelta
                ? _snapshot.streamingResponse + event.text
                : _snapshot.streamingResponse,
      );
      _notifyView();
    }

    final result =
        status ??
        (retry == null
            ? await router.dispatch(
              input,
              onUpdate: update,
              cancellation: token,
            )
            : await router.retry(retry, onUpdate: update, cancellation: token));
    Message? saved;
    var statusFailed = false;
    if (result is TurnDirectReplySaved) saved = result.message;
    if (result is TurnTaskStatusRead) {
      try {
        final presenter = taskProgress;
        saved = await presenter(
          chatId: chatId,
          botId: input.bot.id,
          language: input.language,
          question: input.userMessage.content,
          turnId: input.userMessage.turnId,
          taskId: result.explicitTaskId,
          summaries: result.summaries,
          cancellation: token,
        );
      } on Object {
        if (_acceptsAsyncCallbacks && !token.isCancelled) {
          _statusRetry = result;
          statusFailed = true;
        }
      }
    }
    if (!_acceptsAsyncCallbacks || _snapshot.runId != runId) return false;
    _contextAssemblyReport = result.context.prepared?.contextAssemblyReport;
    _foregroundCancellation = null;
    final failed = result is TurnDispatchFailed;
    final cancelled =
        token.isCancelled ||
        failed && result.code == TurnDispatchFailureCode.cancelled;
    final lifecycle =
        cancelled
            ? ChatRunLifecycle.cancelled
            : failed || statusFailed || result is TurnDispatchBusy
            ? ChatRunLifecycle.failed
            : ChatRunLifecycle.completed;
    _dispatchRetry = failed && !cancelled ? result.retry : null;
    _snapshot = _snapshot.copyWith(
      lifecycle: lifecycle,
      userPersisted:
          failed ? result.userPersisted : result is! TurnDispatchBusy,
      terminalMessage: saved,
      tokenUsage: saved?.tokenUsage ?? ModelTokenUsage.empty,
      clearTerminalMessage: saved == null,
      streamingResponse: '',
      supportsCancellation: false,
      error:
          statusFailed
              ? 'foreground_statusQueryFailed'
              : failed && !cancelled
              ? 'foreground_${result.code.name}'
              : null,
      clearError: !statusFailed && (!failed || cancelled),
    );
    _completeTerminal(lifecycle);
    _applyPendingBot();
    _notifyView();
    return !cancelled &&
        !failed &&
        !statusFailed &&
        result is! TurnDispatchBusy;
  }
}
