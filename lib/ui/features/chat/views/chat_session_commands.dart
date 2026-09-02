part of 'chat.dart';

extension ChatPageSessionCommands on ChatPageState {
  Future<void> requestBrowseConversationDirectory() async {
    final viewModel = AppScope.of(
      context,
    ).createConversationDirectoryViewModel(widget.id);
    await showConversationDirectoryDialog(
      context: context,
      viewModel: viewModel,
      actionViewModel: _chatViewModel.messageActions,
    );
  }

  Future<void> requestClearChat() async {
    final shouldClear = await showClearChatDialog(context, widget.bot.name);
    if (!mounted) return;
    if (shouldClear) {
      if (!await _confirmStopBeforeMutation()) return;
      if (!mounted) return;
      await _clearChatMessages();
    }
  }

  Future<void> _clearChatMessages() async {
    try {
      await _chatViewModel.clearHistory();
      if (!mounted) return;
      _updateState(() {
        _messages = [];
        _messageRevision += 1;
        _historyError = null;
        _composerFocusToken += 1;
      });
      _chatViewModel.notifyChatListChanged();
    } catch (error) {
      if (!mounted) return;
      _updateState(() {
        _generationError = desktopConversationText(
          context,
          S.of(context).clearChatFailed(safeFailureMessage(context, error)),
        );
      });
    }
  }

  Future<bool> _confirmStopBeforeMutation() async {
    if (!_chatViewModel.hasBlockingRun) return true;
    if (!_chatViewModel.supportsRunCancellation) {
      _updateState(() {
        _generationError = S.of(context).activeRequestCannotCancel;
      });
      return false;
    }

    final shouldStop = await showStopGenerationBeforeLeavingDialog(context);
    if (!shouldStop || !mounted) return false;

    final stopped = await _chatViewModel.stopActiveRun();
    if (!stopped && mounted) {
      _updateState(() {
        _generationError = S.of(context).activeRequestCannotCancel;
      });
    }
    return stopped;
  }

  Future<void> _cancelRequest() async {
    if (!_isCancellable) return;
    _updateState(() => _isStopping = true);
    final cancelled = await _chatViewModel.stopActiveRun();
    if (!mounted) return;
    if (cancelled) {
      showStarsNotice(context, S.of(context).replyCancelled);
    }
  }

  Future<bool> stopActiveRunForNavigation() => _chatViewModel.stopActiveRun();

  void _beginMediaRun(String _) {
    _updateState(() {
      _isTyping = true;
      _isCancellable = true;
      _isStopping = false;
    });
  }

  void _finishMediaRun(String _) {
    if (!mounted) return;
    _updateState(() {
      _isTyping = false;
      _isCancellable = false;
      _isStopping = false;
    });
  }
}
