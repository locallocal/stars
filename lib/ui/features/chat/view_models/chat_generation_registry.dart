part of 'chat_generation_view_model.dart';

class ChatGenerationRegistry {
  ChatGenerationRegistry({
    required MessagePersister messagePersister,
    GroundedMessagePersister? groundedMessagePersister,
    AnswerRecoveryCheckpointPersister? answerRecoveryCheckpointPersister,
    AnswerRecoveryCheckpointClearer? answerRecoveryCheckpointClearer,
    required LastMessageUpdater lastMessageUpdater,
    AssistantPreviewBuilder assistantPreviewBuilder =
        _defaultAssistantPreviewBuilder,
    required ProviderFactory providerFactory,
    MessageIdFactory messageIdFactory = _defaultMessageIdFactory,
    SkillActivationPersister? skillActivationPersister,
    ToolInvocationPersister? toolInvocationPersister,
    GroundedAnswerValidator? groundedAnswerValidator,
    TerminalMessageObserver? terminalMessageObserver,
    ProviderFailureObserver? providerFailureObserver,
    TerminalGroundingMetricsObserver? terminalGroundingMetricsObserver,
    ToolRegistry? toolRegistry,
    ToolPolicy toolPolicy = const DefaultToolPolicy(),
    AgentRunLimits agentRunLimits = const AgentRunLimits(),
    Duration partialPersistenceInterval =
        ChatGenerationViewModel.defaultPartialPersistenceInterval,
  }) : _messagePersister = messagePersister,
       _groundedMessagePersister = groundedMessagePersister,
       _answerRecoveryCheckpointPersister = answerRecoveryCheckpointPersister,
       _answerRecoveryCheckpointClearer = answerRecoveryCheckpointClearer,
       _lastMessageUpdater = lastMessageUpdater,
       _assistantPreviewBuilder = assistantPreviewBuilder,
       _providerFactory = providerFactory,
       _messageIdFactory = messageIdFactory,
       _skillActivationPersister = skillActivationPersister,
       _toolInvocationPersister = toolInvocationPersister,
       _groundedAnswerValidator = groundedAnswerValidator,
       _terminalMessageObserver = terminalMessageObserver,
       _providerFailureObserver = providerFailureObserver,
       _terminalGroundingMetricsObserver = terminalGroundingMetricsObserver,
       _toolRegistry = toolRegistry ?? StaticToolRegistry(const []),
       _toolPolicy = toolPolicy,
       _agentRunLimits = agentRunLimits,
       _partialPersistenceInterval = partialPersistenceInterval;

  final Map<String, ChatGenerationViewModel> _viewModels = {};
  final Set<String> _nonCancellableRuns = {};
  final Map<String, Future<bool> Function()> _externalRunCancellers = {};
  final MessagePersister _messagePersister;
  final GroundedMessagePersister? _groundedMessagePersister;
  final AnswerRecoveryCheckpointPersister? _answerRecoveryCheckpointPersister;
  final AnswerRecoveryCheckpointClearer? _answerRecoveryCheckpointClearer;
  final LastMessageUpdater _lastMessageUpdater;
  final AssistantPreviewBuilder _assistantPreviewBuilder;
  final ProviderFactory _providerFactory;
  final MessageIdFactory _messageIdFactory;
  final SkillActivationPersister? _skillActivationPersister;
  final ToolInvocationPersister? _toolInvocationPersister;
  final GroundedAnswerValidator? _groundedAnswerValidator;
  final TerminalMessageObserver? _terminalMessageObserver;
  final ProviderFailureObserver? _providerFailureObserver;
  final TerminalGroundingMetricsObserver? _terminalGroundingMetricsObserver;
  final ToolRegistry _toolRegistry;
  final ToolPolicy _toolPolicy;
  final AgentRunLimits _agentRunLimits;
  final Duration _partialPersistenceInterval;

  ChatGenerationViewModel viewModelFor(String chatId, Bot bot) {
    final viewModel = _viewModels.putIfAbsent(
      chatId,
      () => ChatGenerationViewModel(
        chatId: chatId,
        bot: bot,
        messagePersister: _messagePersister,
        groundedMessagePersister: _groundedMessagePersister,
        answerRecoveryCheckpointPersister: _answerRecoveryCheckpointPersister,
        answerRecoveryCheckpointClearer: _answerRecoveryCheckpointClearer,
        lastMessageUpdater: _lastMessageUpdater,
        assistantPreviewBuilder: _assistantPreviewBuilder,
        providerFactory: _providerFactory,
        messageIdFactory: _messageIdFactory,
        skillActivationPersister: _skillActivationPersister,
        toolInvocationPersister: _toolInvocationPersister,
        groundedAnswerValidator: _groundedAnswerValidator,
        terminalMessageObserver: _terminalMessageObserver,
        providerFailureObserver: _providerFailureObserver,
        terminalGroundingMetricsObserver: _terminalGroundingMetricsObserver,
        toolRegistry: _toolRegistry,
        toolPolicy: _toolPolicy,
        agentRunLimits: _agentRunLimits,
        partialPersistenceInterval: _partialPersistenceInterval,
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
