import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/turn_disposition.dart';
import 'package:stars/domain/use_cases/conversation_turn_dispatcher.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/services/answer_trust_policy.dart';
import 'package:stars/domain/services/grounded_answer_validator.dart';
import 'package:stars/domain/use_cases/agent_run_coordinator.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

part 'chat_generation_events.dart';
part 'chat_foreground_dispatch.dart';
part 'chat_generation_legacy.dart';
part 'chat_generation_persistence.dart';
part 'chat_generation_registry.dart';
part 'chat_generation_state.dart';

int _identitySequence = 0;

String _defaultMessageIdFactory(String prefix) {
  _identitySequence = (_identitySequence + 1) & 0x7fffffff;
  return '$prefix:${DateTime.now().microsecondsSinceEpoch}:'
      '$_identitySequence';
}

/// Coordinates foreground dispatch independently from the conversation route.
/// Background execution, recovery and finalization belong to the app scheduler.
class ChatGenerationViewModel extends DisposableChangeNotifier
    implements ToolApprovalHandler {
  static const Duration defaultPartialPersistenceInterval = Duration(
    milliseconds: 250,
  );

  ChatGenerationViewModel({
    required this.chatId,
    this.dispatcher,
    this.taskProgress,
    required Bot bot,
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
    TerminalMessageObserver? terminalMessageObserver,
    ProviderFailureObserver? providerFailureObserver,
    TerminalGroundingMetricsObserver? terminalGroundingMetricsObserver,
    ToolRegistry? toolRegistry,
    ToolPolicy toolPolicy = const DefaultToolPolicy(),
    AgentRunLimits agentRunLimits = const AgentRunLimits(),
    AnswerTrustPolicy answerTrustPolicy = const AnswerTrustPolicy(),
    GroundedAnswerValidator? groundedAnswerValidator,
    Duration partialPersistenceInterval = defaultPartialPersistenceInterval,
  }) : _bot = bot,
       _providerFactory = providerFactory,
       _messagePersister = messagePersister,
       _groundedMessagePersister = groundedMessagePersister ?? messagePersister,
       _hasDedicatedGroundedMessagePersister = groundedMessagePersister != null,
       _answerRecoveryCheckpointPersister = answerRecoveryCheckpointPersister,
       _answerRecoveryCheckpointClearer = answerRecoveryCheckpointClearer,
       _lastMessageUpdater = lastMessageUpdater,
       _assistantPreviewBuilder = assistantPreviewBuilder,
       _messageIdFactory = messageIdFactory,
       _skillActivationPersister = skillActivationPersister,
       _toolInvocationPersister = toolInvocationPersister,
       _terminalMessageObserver = terminalMessageObserver,
       _providerFailureObserver = providerFailureObserver,
       _terminalGroundingMetricsObserver = terminalGroundingMetricsObserver,
       _toolRegistry = toolRegistry ?? StaticToolRegistry(const []),
       _toolPolicy = toolPolicy,
       _agentRunLimits = agentRunLimits,
       _answerTrustPolicy = answerTrustPolicy,
       _groundedAnswerValidator = groundedAnswerValidator,
       _partialPersistenceInterval = partialPersistenceInterval,
       _capabilityProvider = providerFactory(bot),
       _snapshot = ChatGenerationSnapshot(chatId: chatId);

  final String chatId;
  final ConversationTurnDispatcher? dispatcher;
  final PresentConversationTaskProgress? taskProgress;
  TurnDispatchRetry? _dispatchRetry;
  TurnTaskStatusRead? _statusRetry;
  AgentCancellationToken? _foregroundCancellation;
  bool get canRetryDispatch =>
      (_dispatchRetry != null || _statusRetry != null) && !hasBlockingRun;

  final ProviderFactory _providerFactory;
  final MessagePersister _messagePersister;
  final GroundedMessagePersister _groundedMessagePersister;
  final bool _hasDedicatedGroundedMessagePersister;
  final AnswerRecoveryCheckpointPersister? _answerRecoveryCheckpointPersister;
  final AnswerRecoveryCheckpointClearer? _answerRecoveryCheckpointClearer;
  final LastMessageUpdater _lastMessageUpdater;
  final AssistantPreviewBuilder _assistantPreviewBuilder;
  final MessageIdFactory _messageIdFactory;
  final SkillActivationPersister? _skillActivationPersister;
  final ToolInvocationPersister? _toolInvocationPersister;
  final TerminalMessageObserver? _terminalMessageObserver;
  final ProviderFailureObserver? _providerFailureObserver;
  final TerminalGroundingMetricsObserver? _terminalGroundingMetricsObserver;
  final ToolRegistry _toolRegistry;
  final ToolPolicy _toolPolicy;
  final AgentRunLimits _agentRunLimits;
  final AnswerTrustPolicy _answerTrustPolicy;
  final GroundedAnswerValidator? _groundedAnswerValidator;
  final Duration _partialPersistenceInterval;

  Bot _bot;
  Bot? _pendingBot;
  AiProvider _capabilityProvider;
  AiProvider? _runProvider;
  ChatGenerationSnapshot _snapshot;
  Completer<ChatRunLifecycle>? _terminalCompleter;
  DateTime? _startedAt;
  ModelTokenUsage _preflightTokenUsage = ModelTokenUsage.empty;
  final Set<String> _finalizingRuns = <String>{};
  final Set<String> _preparingRuns = <String>{};
  final Set<String> _preflightCancellationRuns = <String>{};
  AgentCancellationToken? _agentCancellationToken;
  Completer<ToolApprovalDecision>? _toolApprovalCompleter;
  ModelTokenUsage _agentTokenUsage = ModelTokenUsage.empty;
  ContextAssemblyReport? _contextAssemblyReport;
  Timer? _partialPersistenceTimer;
  Future<void> _partialPersistenceQueue = Future<void>.value();
  bool _providerSupportsAgentLoop = false;
  bool _reliabilityPolicyEnabled = true;
  AnswerEvidenceState _answerEvidenceState = AnswerEvidenceState.none;
  AnswerTrustGateResult _answerTrustGateResult = AnswerTrustGateResult.notRun;
  List<String> _validatedEvidenceIds = const [];
  List<MessageClaimGrounding> _validatedClaims = const [];
  String _verificationUnavailableReason = '';

  ChatGenerationSnapshot get snapshot => _snapshot;
  ContextAssemblyReport? get contextAssemblyReport => _contextAssemblyReport;
  AiProvider get capabilityProvider => _capabilityProvider;
  bool get hasBlockingRun => _snapshot.lifecycle.isRunning;
  bool get _acceptsAsyncCallbacks => !isDisposed;

  void updateBot(Bot bot) {
    if (isDisposed) return;
    if (_bot == bot) return;
    if (hasBlockingRun) {
      _pendingBot = bot;
      return;
    }
    _replaceCapabilityProvider(bot);
  }

  Future<ChatRunLifecycle> cancel({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (isDisposed) return _snapshot.lifecycle;
    if (_foregroundCancellation != null && hasBlockingRun) {
      _foregroundCancellation!.cancel();
      return await _terminalCompleter!.future;
    }
    final runId = _snapshot.runId;
    final provider = _runProvider;
    final terminalFuture = _terminalCompleter?.future;
    if (runId == null || provider == null || !hasBlockingRun) {
      return _snapshot.lifecycle;
    }
    final isPreparing = _preparingRuns.contains(runId);
    if (!isPreparing && !provider.supportsCancellation) {
      return _snapshot.lifecycle;
    }

    if (isPreparing) {
      _preparingRuns.remove(runId);
      _snapshot = _snapshot.copyWith(
        lifecycle: ChatRunLifecycle.stopping,
        clearError: true,
      );
      notifyListeners();
      await _finalizeRun(runId, ProviderTerminalType.cancelled);
      return _snapshot.lifecycle;
    }

    final isPreflight =
        _snapshot.lifecycle == ChatRunLifecycle.submitting ||
        _snapshot.lifecycle == ChatRunLifecycle.connecting;
    if (isPreflight) {
      _preflightCancellationRuns.add(runId);
    }

    _snapshot = _snapshot.copyWith(
      lifecycle: ChatRunLifecycle.stopping,
      clearError: true,
    );
    notifyListeners();

    if (!isPreflight) {
      final agentCancellationToken = _agentCancellationToken;
      if (agentCancellationToken != null) {
        agentCancellationToken.cancel();
      } else {
        final result = await provider.cancelRequest();
        if (!result.accepted) {
          if (_isActiveRun(runId)) {
            _snapshot = _snapshot.copyWith(
              lifecycle: ChatRunLifecycle.active,
              error: 'provider_cancellation_not_supported',
            );
            notifyListeners();
          }
          return _snapshot.lifecycle;
        }
      }
    }

    if (terminalFuture == null) return _snapshot.lifecycle;
    try {
      return await terminalFuture.timeout(timeout);
    } on TimeoutException {
      if (_isActiveRun(runId) &&
          _snapshot.lifecycle == ChatRunLifecycle.stopping &&
          !isPreflight) {
        _snapshot = _snapshot.copyWith(
          lifecycle: ChatRunLifecycle.active,
          error: 'provider_cancellation_timeout',
        );
        notifyListeners();
      }
      return _snapshot.lifecycle;
    }
  }

  Future<bool> stopForNavigation() async {
    if (isDisposed) return true;
    if (!hasBlockingRun) return true;
    if (!_snapshot.supportsCancellation) return false;
    final result = await cancel();
    return result.isTerminal;
  }

  void acknowledgeTerminal() {
    if (isDisposed) return;
    if (!_snapshot.lifecycle.isTerminal) return;
    _snapshot = _snapshot.copyWith(
      lifecycle: ChatRunLifecycle.idle,
      clearRunId: true,
      clearTurnId: true,
      streamingResponse: '',
      reasoningResponse: '',
      toolCalls: const [],
      commandExecutions: const [],
      skillActivations: const [],
      localFiles: const [],
      clearPendingToolApproval: true,
      tokenUsage: ModelTokenUsage.empty,
      supportsCancellation: false,
      userPersisted: false,
      clearSubmittedUserMessage: true,
      clearError: true,
      clearTerminalMessage: true,
    );
    notifyListeners();
  }

  void _notifyView() => notifyListeners();

  @override
  Future<ToolApprovalDecision> requestApproval(
    ToolApprovalRequest request,
    AgentCancellationToken cancellationToken,
  ) async {
    if (!_isActiveRun(request.runId) || cancellationToken.isCancelled) {
      return ToolApprovalDecision.deny;
    }
    final previous = _toolApprovalCompleter;
    if (previous != null && !previous.isCompleted) {
      previous.complete(ToolApprovalDecision.deny);
    }
    final completer = Completer<ToolApprovalDecision>();
    _toolApprovalCompleter = completer;
    _snapshot = _snapshot.copyWith(pendingToolApproval: request);
    notifyListeners();
    try {
      return await Future.any<ToolApprovalDecision>([
        completer.future,
        cancellationToken.whenCancelled.then((_) => ToolApprovalDecision.deny),
      ]);
    } finally {
      if (_isActiveRun(request.runId) &&
          identical(_toolApprovalCompleter, completer)) {
        _toolApprovalCompleter = null;
        _snapshot = _snapshot.copyWith(clearPendingToolApproval: true);
        notifyListeners();
      }
    }
  }

  void resolveToolApproval(ToolApprovalDecision decision) {
    if (isDisposed) return;
    final completer = _toolApprovalCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete(decision);
  }

  void _onProviderTerminal(String runId, ProviderTerminalEvent event) {
    if (!_isActiveRun(runId) || _finalizingRuns.contains(runId)) return;
    final rawError = event.error;
    final error =
        rawError == null
            ? null
            : AppFailure.from(
              rawError,
              code: 'provider_generation_failed',
            ).code;
    unawaited(_finalizeRun(runId, event.type, error: error));
  }

  void _recordProviderFailureSafely(ProviderFailure failure) {
    final observer = _providerFailureObserver;
    if (observer == null) return;
    unawaited(
      observer(failure).catchError((Object error, StackTrace stackTrace) {
        debugPrint('Failed to record Provider failure metric: $error');
      }),
    );
  }

  void _completeTerminal(ChatRunLifecycle lifecycle) {
    final completer = _terminalCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(lifecycle);
    }
  }

  void _applyPendingBot() {
    final bot = _pendingBot;
    if (bot == null) return;
    _pendingBot = null;
    _replaceCapabilityProvider(bot);
  }

  void _replaceCapabilityProvider(Bot bot) {
    _bot = bot;
    _capabilityProvider = _providerFactory(bot);
  }

  @override
  void disposeResources() {
    _foregroundCancellation?.cancel();
    _partialPersistenceTimer?.cancel();
    _partialPersistenceTimer = null;
    _agentCancellationToken?.cancel();
    final approvalCompleter = _toolApprovalCompleter;
    if (approvalCompleter != null && !approvalCompleter.isCompleted) {
      approvalCompleter.complete(ToolApprovalDecision.deny);
    }
    _toolApprovalCompleter = null;
    final terminalCompleter = _terminalCompleter;
    if (terminalCompleter != null && !terminalCompleter.isCompleted) {
      terminalCompleter.complete(ChatRunLifecycle.cancelled);
    }
    _terminalCompleter = null;
    final provider = _runProvider;
    if (provider != null && provider.supportsCancellation) {
      unawaited(
        provider.cancelRequest().then<void>((_) {}).catchError((
          Object error,
          StackTrace stackTrace,
        ) {
          debugPrint('Failed to cancel disposed chat run: $error');
        }),
      );
    }
  }
}

Future<String> _defaultAssistantPreviewBuilder(Message message) async =>
    message.content;
