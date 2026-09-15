part of 'chat_generation_view_model.dart';

/// Tracks foreground text and media interactions, never durable task ownership.
class ChatGenerationRegistry {
  ChatGenerationRegistry({
    required this.dispatcher,
    required this.taskProgress,
    required ProviderFactory providerFactory,
    MessageIdFactory messageIdFactory = _defaultMessageIdFactory,
  }) : _providerFactory = providerFactory,
       _messageIdFactory = messageIdFactory;

  final ConversationTurnDispatcher dispatcher;
  final PresentConversationTaskProgress taskProgress;
  final ProviderFactory _providerFactory;
  final MessageIdFactory _messageIdFactory;
  final Map<String, ChatGenerationViewModel> _viewModels = {};
  final Set<String> _nonCancellableRuns = {};
  final Map<String, Future<bool> Function()> _externalRunCancellers = {};

  ChatGenerationViewModel viewModelFor(String chatId, Bot bot) {
    final viewModel = _viewModels.putIfAbsent(
      chatId,
      () => ChatGenerationViewModel(
        chatId: chatId,
        dispatcher: dispatcher,
        taskProgress: taskProgress,
        bot: bot,
        providerFactory: _providerFactory,
        messageIdFactory: _messageIdFactory,
      ),
    );
    viewModel.updateBot(bot);
    return viewModel;
  }

  ChatGenerationViewModel? maybeViewModel(String? chatId) {
    if (chatId == null) return null;
    return _viewModels[chatId];
  }

  bool hasBlockingRun(String? chatId) =>
      chatId != null &&
      (_nonCancellableRuns.contains(chatId) ||
          _externalRunCancellers.containsKey(chatId) ||
          (maybeViewModel(chatId)?.hasBlockingRun ?? false));

  bool supportsCancellationForRun(String? chatId) =>
      chatId != null &&
      !_nonCancellableRuns.contains(chatId) &&
      (_externalRunCancellers.containsKey(chatId) ||
          (maybeViewModel(chatId)?.snapshot.supportsCancellation ?? false));

  Future<bool> stopForNavigation(String? chatId) async {
    if (chatId != null && _nonCancellableRuns.contains(chatId)) return false;
    final externalCanceller =
        chatId == null ? null : _externalRunCancellers[chatId];
    if (externalCanceller != null) return externalCanceller();
    return await maybeViewModel(chatId)?.stopForNavigation() ?? true;
  }

  void setCancellableExternalRun(
    String chatId,
    Future<bool> Function()? canceller,
  ) {
    if (canceller == null) {
      _externalRunCancellers.remove(chatId);
    } else {
      _externalRunCancellers[chatId] = canceller;
    }
  }

  void setNonCancellableRunActive(String chatId, bool active) {
    if (active) {
      _nonCancellableRuns.add(chatId);
    } else {
      _nonCancellableRuns.remove(chatId);
    }
  }

  void remove(String chatId) {
    final viewModel = _viewModels[chatId];
    if (_nonCancellableRuns.contains(chatId) ||
        _externalRunCancellers.containsKey(chatId) ||
        viewModel == null ||
        viewModel.hasBlockingRun) {
      return;
    }
    _viewModels.remove(chatId)?.dispose();
  }

  @visibleForTesting
  void clear() {
    for (final viewModel in _viewModels.values) {
      viewModel.dispose();
    }
    _viewModels.clear();
    _nonCancellableRuns.clear();
    _externalRunCancellers.clear();
  }
}
