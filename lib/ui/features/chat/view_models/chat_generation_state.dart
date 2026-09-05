part of 'chat_generation_view_model.dart';

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
    this.skillActivations = const [],
    this.localFiles = const [],
    this.pendingToolApproval,
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
  final String reasoningResponse;
  final List<MessageToolCall> toolCalls;
  final List<MessageCommandExecution> commandExecutions;
  final List<MessageSkillActivation> skillActivations;
  final List<String> localFiles;
  final ToolApprovalRequest? pendingToolApproval;
  final ModelTokenUsage tokenUsage;
  final bool supportsCancellation;
  final bool userPersisted;
  final Message? submittedUserMessage;
  final String? error;
  final Message? terminalMessage;

  bool get isRunning => lifecycle.isRunning;
  bool get contentStreaming => streamingResponse.isNotEmpty;
  bool get reasoningActive =>
      isRunning && (reasoningResponse.isNotEmpty || contentStreaming);
  bool get toolingActive =>
      isRunning &&
      (toolCalls.isNotEmpty ||
          commandExecutions.isNotEmpty ||
          skillActivations.isNotEmpty);
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
    List<MessageSkillActivation>? skillActivations,
    List<String>? localFiles,
    ToolApprovalRequest? pendingToolApproval,
    bool clearPendingToolApproval = false,
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
      reasoningResponse: reasoningResponse ?? this.reasoningResponse,
      toolCalls: toolCalls ?? this.toolCalls,
      commandExecutions: commandExecutions ?? this.commandExecutions,
      skillActivations: skillActivations ?? this.skillActivations,
      localFiles: localFiles ?? this.localFiles,
      pendingToolApproval:
          clearPendingToolApproval
              ? null
              : pendingToolApproval ?? this.pendingToolApproval,
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

typedef MessagePersister = Future<Message> Function(Message message);
typedef GroundedMessagePersister = Future<Message> Function(Message message);
typedef AnswerRecoveryCheckpointPersister =
    Future<void> Function(Message message);
typedef AnswerRecoveryCheckpointClearer = Future<void> Function(String runId);
typedef LastMessageUpdater =
    Future<void> Function(String chatId, String content);
typedef AssistantPreviewBuilder = Future<String> Function(Message message);
typedef ProviderFactory = AiProvider Function(Bot bot);
typedef MessageIdFactory = String Function(String prefix);
typedef SkillActivationPersister =
    Future<void> Function(Iterable<SkillActivationRecord> records);
typedef TerminalMessageObserver =
    Future<void> Function(
      String chatId,
      Bot bot,
      Message message,
      ContextAssemblyReport? report,
    );
typedef ProviderFailureObserver =
    Future<void> Function(ProviderFailure failure);
typedef TerminalGroundingMetricsObserver =
    Future<void> Function(Message message);
typedef TextGenerationPreparer =
    Future<PreparedTextGeneration> Function(Message identifiedUserMessage);

@immutable
class PreparedTextGeneration {
  const PreparedTextGeneration({
    required this.userMessage,
    required this.messages,
    this.activatedSkills = const [],
    this.activationAttempts = const [],
    this.skillToolCalls = const [],
    this.preflightTokenUsage = ModelTokenUsage.empty,
    this.requestedToolNames = const {},
    this.verificationToolNames = const {},
    this.approvalExemptToolNames = const {},
    this.runScopedTools = const [],
    this.contextAssemblyReport,
    this.reliabilityPolicyEnabled = true,
    this.verificationUnavailableReason = '',
  });

  final Message userMessage;
  final List<ChatMessage> messages;
  final List<ActivatedSkill> activatedSkills;
  final List<SkillActivationAttempt> activationAttempts;
  final List<MessageToolCall> skillToolCalls;
  final ModelTokenUsage preflightTokenUsage;
  final Set<String> requestedToolNames;
  final Set<String> verificationToolNames;
  final Set<String> approvalExemptToolNames;
  final List<ExecutableTool> runScopedTools;
  final ContextAssemblyReport? contextAssemblyReport;
  final bool reliabilityPolicyEnabled;
  final String verificationUnavailableReason;
}
