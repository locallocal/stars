import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/models/turn_disposition.dart';
import 'package:stars/domain/repositories/ai_provider_repository.dart';
import 'package:stars/domain/use_cases/conversation_turn_dispatcher.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart';
import 'package:stars/ui/core/view_models/disposable_change_notifier.dart';

part 'chat_foreground_dispatch.dart';
part 'chat_generation_registry.dart';
part 'chat_generation_state.dart';

int _identitySequence = 0;
String _defaultMessageIdFactory(String prefix) {
  _identitySequence = (_identitySequence + 1) & 0x7fffffff;
  return '$prefix:${DateTime.now().microsecondsSinceEpoch}:$_identitySequence';
}

/// Coordinates only foreground dispatch. Durable tasks belong to the app.
class ChatGenerationViewModel extends DisposableChangeNotifier {
  ChatGenerationViewModel({
    required this.chatId,
    required this.dispatcher,
    required this.taskProgress,
    required Bot bot,
    required ProviderFactory providerFactory,
    MessageIdFactory messageIdFactory = _defaultMessageIdFactory,
  }) : _bot = bot,
       _providerFactory = providerFactory,
       _messageIdFactory = messageIdFactory,
       _capabilityProvider = providerFactory(bot),
       _snapshot = ChatGenerationSnapshot(chatId: chatId);

  final String chatId;
  final ConversationTurnDispatcher dispatcher;
  final PresentConversationTaskProgress taskProgress;
  final ProviderFactory _providerFactory;
  final MessageIdFactory _messageIdFactory;
  TurnDispatchRetry? _dispatchRetry;
  TurnTaskStatusRead? _statusRetry;
  AgentCancellationToken? _foregroundCancellation;
  Bot _bot;
  Bot? _pendingBot;
  AiProvider _capabilityProvider;
  ChatGenerationSnapshot _snapshot;
  Completer<ChatRunLifecycle>? _terminalCompleter;
  ContextAssemblyReport? _contextAssemblyReport;

  bool get canRetryDispatch =>
      (_dispatchRetry != null || _statusRetry != null) && !hasBlockingRun;
  ChatGenerationSnapshot get snapshot => _snapshot;
  ContextAssemblyReport? get contextAssemblyReport => _contextAssemblyReport;
  AiProvider get capabilityProvider => _capabilityProvider;
  bool get hasBlockingRun => _snapshot.lifecycle.isRunning;
  bool get _acceptsAsyncCallbacks => !isDisposed;

  void updateBot(Bot bot) {
    if (isDisposed || _bot == bot) return;
    if (hasBlockingRun) {
      _pendingBot = bot;
    } else {
      _replaceCapabilityProvider(bot);
    }
  }

  Future<ChatRunLifecycle> cancel() async {
    if (isDisposed || !hasBlockingRun) return _snapshot.lifecycle;
    _snapshot = _snapshot.copyWith(lifecycle: ChatRunLifecycle.stopping);
    _notifyView();
    _foregroundCancellation?.cancel();
    return await _terminalCompleter!.future;
  }

  Future<bool> stopForNavigation() async =>
      isDisposed || !hasBlockingRun || (await cancel()).isTerminal;

  void acknowledgeTerminal() {
    if (isDisposed || !_snapshot.lifecycle.isTerminal) return;
    _snapshot = ChatGenerationSnapshot(chatId: chatId);
    _notifyView();
  }

  void _notifyView() => notifyListeners();
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
    _completeTerminal(ChatRunLifecycle.cancelled);
    _terminalCompleter = null;
  }
}
