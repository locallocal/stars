import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/services/answer_trust_policy.dart';
import 'package:stars/domain/services/grounded_answer_validator.dart';
import 'package:stars/domain/use_cases/agent_run_coordinator.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

part 'chat_generation_events.dart';
part 'chat_generation_persistence.dart';
part 'chat_generation_registry.dart';
part 'chat_generation_state.dart';

int _identitySequence = 0;

String _defaultMessageIdFactory(String prefix) {
  _identitySequence = (_identitySequence + 1) & 0x7fffffff;
  return '$prefix:${DateTime.now().microsecondsSinceEpoch}:'
      '$_identitySequence';
}

/// Owns one chat's text generation independently from any [StatefulWidget].
///
/// A fresh AI provider session is created for every run. Its callbacks capture
/// the run id, so a late token from an older request cannot be reduced into a
/// newer run even if the user stops and sends again quickly.
class ChatGenerationViewModel extends DisposableChangeNotifier
    implements ToolApprovalHandler {
  static const Duration defaultPartialPersistenceInterval = Duration(
    milliseconds: 250,
  );

  ChatGenerationViewModel({
    required this.chatId,
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
        ),
  );

  Future<bool> startTextWithPreparation({
    required Message userMessage,
    required TextGenerationPreparer prepare,
  }) async {
    if (isDisposed || hasBlockingRun) return false;

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
    notifyListeners();

    late final PreparedTextGeneration prepared;
    try {
      prepared = await prepare(identifiedUser);
    } catch (error) {
      if (isDisposed) return false;
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
    if (isDisposed) return false;
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
    notifyListeners();

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
        notifyListeners();
      }
      return false;
    }

    if (!_isActiveRun(runId) || _snapshot.lifecycle.isTerminal) return false;
    _snapshot = _snapshot.copyWith(userPersisted: true, clearError: true);
    notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
    }
    return true;
  }

  Future<ChatRunLifecycle> cancel({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (isDisposed) return _snapshot.lifecycle;
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
    notifyListeners();
  }

  MessageGrounding _evaluateGrounding(
    MessageTerminalOutcome terminalOutcome, {
    String? failureReasonCode,
    bool? criticalPersistenceSucceeded,
  }) {
    return _answerTrustPolicy.evaluate(
      AnswerTrustPolicyInput(
        terminalOutcome: terminalOutcome,
        providerSupportsAgentLoop: _providerSupportsAgentLoop,
        reliabilityPolicyEnabled: _reliabilityPolicyEnabled,
        toolCalls: _snapshot.toolCalls,
        evidenceState: _answerEvidenceState,
        gateResult: _answerTrustGateResult,
        evidenceIds: _validatedEvidenceIds,
        claims: _validatedClaims,
        verificationUnavailableReason: _verificationUnavailableReason,
        criticalPersistenceSucceeded: criticalPersistenceSucceeded ?? true,
        failureReasonCode:
            failureReasonCode?.isNotEmpty ?? false ? failureReasonCode! : '',
      ),
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
