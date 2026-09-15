part of 'chat_generation_view_model.dart';

enum ChatRunLifecycle {
  idle,
  submitting,
  active,
  stopping,
  completed,
  cancelled,
  failed;

  bool get isRunning =>
      this == submitting || this == active || this == stopping;

  bool get isTerminal =>
      this == completed || this == cancelled || this == failed;
}

@immutable
class ChatGenerationSnapshot {
  const ChatGenerationSnapshot({
    required this.chatId,
    this.runId,
    this.turnId,
    this.lifecycle = ChatRunLifecycle.idle,
    this.streamingResponse = '',
    this.tokenUsage = ModelTokenUsage.empty,
    this.supportsCancellation = false,
    this.userPersisted = false,
    this.submittedUserMessage,
    this.error,
    this.terminalMessage,
  });

  final String chatId;
  final String? runId;
  final String? turnId;
  final ChatRunLifecycle lifecycle;
  final String streamingResponse;
  final ModelTokenUsage tokenUsage;
  final bool supportsCancellation;
  final bool userPersisted;
  final Message? submittedUserMessage;
  final String? error;
  final Message? terminalMessage;

  bool get isRunning => lifecycle.isRunning;
  bool get contentStreaming => streamingResponse.isNotEmpty;
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
    ModelTokenUsage? tokenUsage,
    bool? supportsCancellation,
    bool? userPersisted,
    Message? submittedUserMessage,
    bool clearSubmittedUserMessage = false,
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
      tokenUsage: tokenUsage ?? this.tokenUsage,
      supportsCancellation: supportsCancellation ?? this.supportsCancellation,
      userPersisted: userPersisted ?? this.userPersisted,
      submittedUserMessage:
          clearSubmittedUserMessage
              ? null
              : submittedUserMessage ?? this.submittedUserMessage,
      error: clearError ? null : error ?? this.error,
      terminalMessage:
          clearTerminalMessage ? null : terminalMessage ?? this.terminalMessage,
    );
  }
}

typedef ProviderFactory = AiProvider Function(Bot bot);
typedef MessageIdFactory = String Function(String prefix);
