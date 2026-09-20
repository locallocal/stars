part of 'conversation_turn_dispatcher.dart';

/// Construct once with CreateUserMessage, then retain this input for retries.
/// Bot configuration and attachment lists are copied before asynchronous work.
final class ConversationTurnInput {
  ConversationTurnInput({
    required Bot bot,
    required Message userMessage,
    required this.language,
    required this.verification,
    required this.segmentLimits,
    this.explicitTaskId,
    this.retryOfTaskId,
  }) : bot = _frozenBot(bot),
       userMessage = userMessage.copyWith(
         images: List.unmodifiable(userMessage.images),
         files: List.unmodifiable(userMessage.files),
       ) {
    for (final id in [
      userMessage.messageId,
      userMessage.turnId,
      userMessage.chatId,
      userMessage.botId,
      userMessage.senderId,
      language,
      if (explicitTaskId != null) explicitTaskId!,
    ]) {
      if (id.trim().isEmpty || id != id.trim() || id.length > 256) {
        throw ArgumentError('Foreground identity and language are required.');
      }
    }
    if (userMessage.botId != bot.id ||
        userMessage.messageId ==
            ConversationMessageIdentity.directReply(userMessage.turnId) ||
        userMessage.senderId == bot.id ||
        userMessage.senderId == 'assistant' ||
        userMessage.taskMessageKind != null ||
        userMessage.hasPartialContent ||
        userMessage.terminalOutcome != null) {
      throw ArgumentError(
        'Foreground dispatch requires the original user message.',
      );
    }
  }
  final Bot bot;
  final Message userMessage;
  final String language;
  final VerificationPolicySnapshot verification;
  final TaskSegmentLimits segmentLimits;
  final String? explicitTaskId;
  final String? retryOfTaskId;
  ConversationDraft get draft => ConversationDraft(
    text: userMessage.content,
    imagePaths: userMessage.images,
    filePaths: userMessage.files,
  );
}

final class ForegroundTurnGate {
  final Set<String> _active = {};
}

/// Present on updates and results, including errors before preparation.
final class TurnDispatchContext {
  const TurnDispatchContext({
    required this.input,
    this.prepared,
    this.acceptance,
  });
  final ConversationTurnInput input;
  final PreparedChatGeneration? prepared;
  final TaskAcceptanceSnapshot? acceptance;
  String get turnId => input.userMessage.turnId;
  String get userMessageId => input.userMessage.messageId;
  String get chatId => input.userMessage.chatId;
}

final class TurnDispatchUpdate {
  const TurnDispatchUpdate(this.context, this.event);
  final TurnDispatchContext context;

  /// Only started and direct text deltas. Task drafts are never published here.
  final TurnRoutingEvent event;
}

sealed class TurnDispatchResult {
  const TurnDispatchResult(this.context, this.metrics);
  final TurnDispatchContext context;
  final TurnDispatchMetrics metrics;
}

final class TurnDispatchBusy extends TurnDispatchResult {
  const TurnDispatchBusy(super.context, super.metrics);
}

final class TurnDirectReplySaved extends TurnDispatchResult {
  const TurnDirectReplySaved(
    super.context,
    super.metrics,
    this.message, {
    this.reused = false,
  });
  final Message message;
  final bool reused;
}

final class TurnTaskAccepted extends TurnDispatchResult {
  const TurnTaskAccepted(
    super.context,
    super.metrics,
    this.task, {
    required this.notificationDelivered,
    required this.reused,
  });
  final ConversationTask task;

  /// UI observes the committed acknowledgement by task.ackMessageId.
  final bool notificationDelivered;
  final bool reused;
}

final class TurnTaskStatusRead extends TurnDispatchResult {
  TurnTaskStatusRead(
    super.context,
    super.metrics, {
    required List<ConversationTaskProgressSummary> summaries,
    this.explicitTaskId,
  }) : summaries = List.unmodifiable(summaries);
  final List<ConversationTaskProgressSummary> summaries;
  final String? explicitTaskId;
  bool get needsSelection => summaries.length > 1;
}

enum TurnDispatchFailureCode {
  cancelled,
  userPersistenceFailed,
  preparationFailed,
  routingFailed,
  taskCreationFailed,
  replyPersistenceFailed,
  statusQueryFailed,
  identityConflict,
}

final class TurnDispatchFailed extends TurnDispatchResult {
  const TurnDispatchFailed(
    super.context,
    super.metrics, {
    required this.code,
    required this.userPersisted,
    required this.retry,
    this.routingFailure,
    this.draftToRestore,
    required this.draftRestored,
  });
  final TurnDispatchFailureCode code;
  final TurnRoutingFailure? routingFailure;
  final bool userPersisted;
  final TurnDispatchRetry? retry;
  final ConversationDraft? draftToRestore;
  final bool draftRestored;
}

/// Opaque in-memory retry material. Durable success is always checked first.
final class TurnDispatchRetry {
  const TurnDispatchRetry._(this._pending);
  final _PendingTurn _pending;
  ConversationTurnInput get input => _pending.input;
}

final class TurnDispatchMetrics {
  const TurnDispatchMetrics({
    required this.chatId,
    required this.turnId,
    required this.preparationCalls,
    required this.mainReplyCalls,
    required this.preflightUsage,
    required this.preparationDuration,
    required this.elapsed,
    required this.directFirstCharacterLatency,
    required this.directCompletionLatency,
    required this.acknowledgementCommitLatency,
    required this.routingFallbacks,
    required this.acknowledgementFallbacks,
  });
  final String chatId;
  final String turnId;

  /// Local context preparations; foreground preparation never activates Skills
  /// or invokes models for compaction.
  final int preparationCalls;
  final int mainReplyCalls;
  final ModelTokenUsage preflightUsage;
  final Duration preparationDuration;
  final Duration elapsed;
  final Duration? directFirstCharacterLatency;
  final Duration? directCompletionLatency;
  final Duration? acknowledgementCommitLatency;
  final int routingFallbacks;
  final int acknowledgementFallbacks;
}

final class _DispatchTiming {
  final clock = Stopwatch()..start();
  int preparationCalls = 0;
  int mainReplyCalls = 0;
  ModelTokenUsage preflightUsage = ModelTokenUsage.empty;
  Duration preparationDuration = Duration.zero;
  Duration? directFirstCharacterLatency;
  Duration? directCompletionLatency;
  Duration? acknowledgementCommitLatency;
  int routingFallbacks = 0;
  int acknowledgementFallbacks = 0;
  TurnDispatchMetrics snapshot(Message user) => TurnDispatchMetrics(
    chatId: user.chatId,
    turnId: user.turnId,
    preparationCalls: preparationCalls,
    mainReplyCalls: mainReplyCalls,
    preflightUsage: preflightUsage,
    preparationDuration: preparationDuration,
    elapsed: clock.elapsed,
    directFirstCharacterLatency: directFirstCharacterLatency,
    directCompletionLatency: directCompletionLatency,
    acknowledgementCommitLatency: acknowledgementCommitLatency,
    routingFallbacks: routingFallbacks,
    acknowledgementFallbacks: acknowledgementFallbacks,
  );
}

final class _PendingTurn {
  _PendingTurn(this.input, this.cancellation);
  AgentCancellationToken? cancellation;
  final ConversationTurnInput input;
  bool userPersisted = false;
  bool providerSupportsAgentLoop = false;
  PreparedChatGeneration? prepared;
  TaskAcceptanceSnapshot? acceptance;
  TurnDisposition? disposition;
  _AcceptanceWrite? acceptanceWrite;
  ModelTokenUsage usage = ModelTokenUsage.empty;
  TurnDispatchContext get context => TurnDispatchContext(
    input: input,
    prepared: prepared,
    acceptance: acceptance,
  );
}
