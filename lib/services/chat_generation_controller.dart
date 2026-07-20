import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stars/model/model.dart';
import 'package:stars/services/chat_service.dart';
import 'package:stars/services/message_service.dart';
import 'package:stars/services/providers/providers.dart';

enum ChatRunLifecycle {
  idle,
  submitting,
  connecting,
  active,
  stopping,
  completed,
  cancelled,
  failed,
  emptyResponse;

  bool get isRunning =>
      this == submitting ||
      this == connecting ||
      this == active ||
      this == stopping;

  bool get isTerminal =>
      this == completed ||
      this == cancelled ||
      this == failed ||
      this == emptyResponse;
}

@immutable
class ChatGenerationSnapshot {
  const ChatGenerationSnapshot({
    required this.chatId,
    this.runId,
    this.turnId,
    this.lifecycle = ChatRunLifecycle.idle,
    this.streamingResponse = '',
    this.reasoningResponse = '',
    this.toolCalls = const [],
    this.commandExecutions = const [],
    this.supportsCancellation = false,
    this.userPersisted = false,
    this.error,
    this.terminalMessage,
  });

  final String chatId;
  final String? runId;
  final String? turnId;
  final ChatRunLifecycle lifecycle;
  final String streamingResponse;
  final String reasoningResponse;
  final List<MessageToolCall> toolCalls;
  final List<MessageCommandExecution> commandExecutions;
  final bool supportsCancellation;
  final bool userPersisted;
  final String? error;
  final Message? terminalMessage;

  bool get isRunning => lifecycle.isRunning;
  bool get contentStreaming => streamingResponse.isNotEmpty;
  bool get reasoningActive =>
      isRunning && (reasoningResponse.isNotEmpty || contentStreaming);
  bool get toolingActive =>
      isRunning && (toolCalls.isNotEmpty || commandExecutions.isNotEmpty);
  bool get canCancel =>
      supportsCancellation &&
      lifecycle.isRunning &&
      lifecycle != ChatRunLifecycle.stopping;

  ChatGenerationSnapshot copyWith({
    String? runId,
    bool clearRunId = false,
    String? turnId,
    bool clearTurnId = false,
    ChatRunLifecycle? lifecycle,
    String? streamingResponse,
    String? reasoningResponse,
    List<MessageToolCall>? toolCalls,
    List<MessageCommandExecution>? commandExecutions,
    bool? supportsCancellation,
    bool? userPersisted,
    String? error,
    bool clearError = false,
    Message? terminalMessage,
    bool clearTerminalMessage = false,
  }) {
    return ChatGenerationSnapshot(
      chatId: chatId,
      runId: clearRunId ? null : runId ?? this.runId,
      turnId: clearTurnId ? null : turnId ?? this.turnId,
      lifecycle: lifecycle ?? this.lifecycle,
      streamingResponse: streamingResponse ?? this.streamingResponse,
      reasoningResponse: reasoningResponse ?? this.reasoningResponse,
      toolCalls: toolCalls ?? this.toolCalls,
      commandExecutions: commandExecutions ?? this.commandExecutions,
      supportsCancellation: supportsCancellation ?? this.supportsCancellation,
      userPersisted: userPersisted ?? this.userPersisted,
      error: clearError ? null : error ?? this.error,
      terminalMessage:
          clearTerminalMessage ? null : terminalMessage ?? this.terminalMessage,
    );
  }
}

typedef MessagePersister = Future<Message> Function(Message message);
typedef LastMessageUpdater =
    Future<void> Function(String chatId, String content);
typedef ProviderFactory = Provider Function(Bot bot);
typedef MessageIdFactory = String Function(String prefix);

/// Owns one chat's text generation independently from any [StatefulWidget].
///
/// A fresh Provider instance is created for every run. Its callbacks capture
/// the run id, so a late token from an older request cannot be reduced into a
/// newer run even if the user stops and sends again quickly.
class ChatGenerationController extends ChangeNotifier {
  ChatGenerationController({
    required this.chatId,
    required Bot bot,
    ProviderFactory providerFactory = Provider.create,
    MessagePersister messagePersister = MessageService.upsertMessage,
    LastMessageUpdater lastMessageUpdater = ChatService.updateLastMessage,
    MessageIdFactory messageIdFactory = MessageService.createId,
  }) : _bot = bot,
       _providerFactory = providerFactory,
       _messagePersister = messagePersister,
       _lastMessageUpdater = lastMessageUpdater,
       _messageIdFactory = messageIdFactory,
       _capabilityProvider = providerFactory(bot),
       _snapshot = ChatGenerationSnapshot(chatId: chatId);

  final String chatId;
  final ProviderFactory _providerFactory;
  final MessagePersister _messagePersister;
  final LastMessageUpdater _lastMessageUpdater;
  final MessageIdFactory _messageIdFactory;

  Bot _bot;
  Bot? _pendingBot;
  Provider _capabilityProvider;
  Provider? _runProvider;
  ChatGenerationSnapshot _snapshot;
  Completer<ChatRunLifecycle>? _terminalCompleter;
  DateTime? _startedAt;
  final Set<String> _finalizingRuns = <String>{};
  final Set<String> _preflightCancellationRuns = <String>{};

  ChatGenerationSnapshot get snapshot => _snapshot;
  Provider get capabilityProvider => _capabilityProvider;
  bool get hasBlockingRun => _snapshot.lifecycle.isRunning;

  void updateBot(Bot bot) {
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
  }) async {
    if (hasBlockingRun) return false;

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
    _terminalCompleter = Completer<ChatRunLifecycle>();
    _snapshot = ChatGenerationSnapshot(
      chatId: chatId,
      runId: runId,
      turnId: turnId,
      lifecycle: ChatRunLifecycle.submitting,
      supportsCancellation: provider.supportsCancellation,
    );
    notifyListeners();

    try {
      await _messagePersister(identifiedUser);
    } catch (error) {
      if (_isActiveRun(runId)) {
        _preflightCancellationRuns.remove(runId);
        _snapshot = _snapshot.copyWith(
          lifecycle: ChatRunLifecycle.failed,
          error: error.toString(),
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

    unawaited(_updateLastMessageSafely(identifiedUser.content));

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

    provider.setCallbacks(
      onResponse: (text) => _onResponse(runId, text),
      onReasoningResponse: (text) => _onReasoning(runId, text),
      onToolCall: (toolCall) => _onToolCall(runId, toolCall),
      onCommandExecution: (execution) => _onCommandExecution(runId, execution),
      onComplete: () {},
      onError: (_) {},
      onTerminal: (event) => _onProviderTerminal(runId, event),
    );

    // Providers reset their cancellation state synchronously at the start of
    // generateText. Invoke it before publishing the cancellable active state
    // so an input event cannot be erased by that reset.
    late final Future<void> generation;
    try {
      generation = provider.generateText(messages);
    } catch (error) {
      await _finalizeRun(
        runId,
        ProviderTerminalType.failed,
        error: error.toString(),
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
              unawaited(
                _finalizeRun(
                  runId,
                  provider.isCancelled
                      ? ProviderTerminalType.cancelled
                      : ProviderTerminalType.failed,
                  error: error.toString(),
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
    final runId = _snapshot.runId;
    final provider = _runProvider;
    if (runId == null || provider == null || !hasBlockingRun) {
      return _snapshot.lifecycle;
    }
    if (!provider.supportsCancellation) return _snapshot.lifecycle;

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
      final result = await provider.cancelRequest();
      if (!result.accepted) {
        if (_isActiveRun(runId)) {
          _snapshot = _snapshot.copyWith(
            lifecycle: ChatRunLifecycle.active,
            error: 'Cancellation is not supported by this provider.',
          );
          notifyListeners();
        }
        return _snapshot.lifecycle;
      }
    }

    try {
      return await _terminalCompleter!.future.timeout(timeout);
    } on TimeoutException {
      if (_isActiveRun(runId) &&
          _snapshot.lifecycle == ChatRunLifecycle.stopping &&
          !isPreflight) {
        _snapshot = _snapshot.copyWith(
          lifecycle: ChatRunLifecycle.active,
          error: 'Cancellation timed out; the request may still be active.',
        );
        notifyListeners();
      }
      return _snapshot.lifecycle;
    }
  }

  Future<bool> stopForNavigation() async {
    if (!hasBlockingRun) return true;
    if (!_snapshot.supportsCancellation) return false;
    final result = await cancel();
    return result.isTerminal;
  }

  void acknowledgeTerminal() {
    if (!_snapshot.lifecycle.isTerminal) return;
    _snapshot = _snapshot.copyWith(
      lifecycle: ChatRunLifecycle.idle,
      clearRunId: true,
      clearTurnId: true,
      streamingResponse: '',
      reasoningResponse: '',
      toolCalls: const [],
      commandExecutions: const [],
      supportsCancellation: false,
      userPersisted: false,
      clearError: true,
      clearTerminalMessage: true,
    );
    notifyListeners();
  }

  void _onResponse(String runId, String text) {
    if (!_canReduceProviderEvent(runId)) return;
    _snapshot = _snapshot.copyWith(
      streamingResponse: '${_snapshot.streamingResponse}$text',
      lifecycle:
          _snapshot.lifecycle == ChatRunLifecycle.connecting
              ? ChatRunLifecycle.active
              : _snapshot.lifecycle,
    );
    notifyListeners();
  }

  void _onReasoning(String runId, String text) {
    if (!_canReduceProviderEvent(runId)) return;
    _snapshot = _snapshot.copyWith(
      reasoningResponse: '${_snapshot.reasoningResponse}$text',
    );
    notifyListeners();
  }

  void _onToolCall(String runId, MessageToolCall toolCall) {
    if (!_canReduceProviderEvent(runId)) return;
    _snapshot = _snapshot.copyWith(
      toolCalls: [..._snapshot.toolCalls, toolCall],
    );
    notifyListeners();
  }

  void _onCommandExecution(String runId, MessageCommandExecution execution) {
    if (!_canReduceProviderEvent(runId)) return;
    _snapshot = _snapshot.copyWith(
      commandExecutions: [..._snapshot.commandExecutions, execution],
    );
    notifyListeners();
  }

  void _onProviderTerminal(String runId, ProviderTerminalEvent event) {
    if (!_isActiveRun(runId) || _finalizingRuns.contains(runId)) return;
    unawaited(_finalizeRun(runId, event.type, error: event.error));
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

    var lifecycle = switch (providerTerminal) {
      ProviderTerminalType.completed => ChatRunLifecycle.completed,
      ProviderTerminalType.cancelled => ChatRunLifecycle.cancelled,
      ProviderTerminalType.failed => ChatRunLifecycle.failed,
    };
    final hasGeneratedContent =
        _snapshot.streamingResponse.isNotEmpty ||
        _snapshot.reasoningResponse.isNotEmpty ||
        _snapshot.toolCalls.isNotEmpty ||
        _snapshot.commandExecutions.isNotEmpty;
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
        ),
        terminalOutcome: outcome,
        hasPartialContent:
            hasGeneratedContent &&
            (lifecycle == ChatRunLifecycle.cancelled ||
                lifecycle == ChatRunLifecycle.failed),
        timestamp: DateTime.now(),
      );
      var terminalPersisted = false;
      try {
        terminalMessage = await _messagePersister(terminalDraft);
        terminalPersisted = true;
      } catch (persistenceError) {
        lifecycle = ChatRunLifecycle.failed;
        error = 'Failed to save the generated response: $persistenceError';
        terminalMessage = terminalDraft.copyWith(
          terminalOutcome: MessageTerminalOutcome.failed,
          hasPartialContent: hasGeneratedContent,
        );
      }
      if (terminalPersisted && terminalMessage.content.isNotEmpty) {
        try {
          await _lastMessageUpdater(chatId, terminalMessage.content);
        } catch (lastMessageError) {
          debugPrint(
            'Failed to update chat preview for $chatId: $lastMessageError',
          );
        }
      }
    }

    if (!_isActiveRun(runId)) {
      _finalizingRuns.remove(runId);
      return;
    }
    _snapshot = _snapshot.copyWith(
      lifecycle: lifecycle,
      error: error,
      clearError: error == null,
      terminalMessage: terminalMessage,
    );
    _runProvider = null;
    _completeTerminal(lifecycle);
    _applyPendingBot();
    _finalizingRuns.remove(runId);
    notifyListeners();
  }

  bool _isActiveRun(String runId) => _snapshot.runId == runId;

  bool _canReduceProviderEvent(String runId) =>
      _isActiveRun(runId) &&
      !_snapshot.lifecycle.isTerminal &&
      !_finalizingRuns.contains(runId);

  Future<void> _updateLastMessageSafely(String content) async {
    try {
      await _lastMessageUpdater(chatId, content);
    } catch (error) {
      debugPrint('Failed to update chat preview for $chatId: $error');
    }
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
}

class ChatGenerationRegistry {
  ChatGenerationRegistry({
    MessagePersister messagePersister = MessageService.upsertMessage,
    LastMessageUpdater lastMessageUpdater = ChatService.updateLastMessage,
    MessageIdFactory messageIdFactory = MessageService.createId,
  }) : _messagePersister = messagePersister,
       _lastMessageUpdater = lastMessageUpdater,
       _messageIdFactory = messageIdFactory;

  static final ChatGenerationRegistry instance = ChatGenerationRegistry();

  final Map<String, ChatGenerationController> _controllers = {};
  final Set<String> _nonCancellableRuns = {};
  final MessagePersister _messagePersister;
  final LastMessageUpdater _lastMessageUpdater;
  final MessageIdFactory _messageIdFactory;

  ChatGenerationController controllerFor(String chatId, Bot bot) {
    final controller = _controllers.putIfAbsent(
      chatId,
      () => ChatGenerationController(
        chatId: chatId,
        bot: bot,
        messagePersister: _messagePersister,
        lastMessageUpdater: _lastMessageUpdater,
        messageIdFactory: _messageIdFactory,
      ),
    );
    controller.updateBot(bot);
    return controller;
  }

  ChatGenerationController? maybeController(String? chatId) {
    if (chatId == null) return null;
    return _controllers[chatId];
  }

  bool hasBlockingRun(String? chatId) =>
      chatId != null &&
      (_nonCancellableRuns.contains(chatId) ||
          (maybeController(chatId)?.hasBlockingRun ?? false));

  bool supportsCancellationForRun(String? chatId) =>
      chatId != null &&
      !_nonCancellableRuns.contains(chatId) &&
      (maybeController(chatId)?.snapshot.supportsCancellation ?? false);

  Future<bool> stopForNavigation(String? chatId) async {
    if (chatId != null && _nonCancellableRuns.contains(chatId)) return false;
    return await maybeController(chatId)?.stopForNavigation() ?? true;
  }

  void setNonCancellableRunActive(String chatId, bool active) {
    if (active) {
      _nonCancellableRuns.add(chatId);
    } else {
      _nonCancellableRuns.remove(chatId);
    }
  }

  void remove(String chatId) {
    final controller = _controllers[chatId];
    if (_nonCancellableRuns.contains(chatId) ||
        controller == null ||
        controller.hasBlockingRun) {
      return;
    }
    _controllers.remove(chatId)?.dispose();
  }

  @visibleForTesting
  void clear() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _nonCancellableRuns.clear();
  }
}
