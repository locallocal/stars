import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:stars/domain/models/bot.dart';
import 'package:stars/domain/models/conversation_draft.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/models/turn_disposition.dart';
import 'package:stars/domain/repositories/conversation_draft_repository.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/repositories/conversation_turn_router.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/services/answer_trust_policy.dart';
import 'package:stars/domain/services/task_acknowledgement_policy.dart';
import 'package:stars/domain/services/task_provider_configuration.dart';
import 'package:stars/domain/use_cases/get_conversation_task_progress.dart';
import 'package:stars/domain/use_cases/prepare_text_generation.dart';

part 'conversation_turn_dispatch_contracts.dart';
part 'conversation_turn_acceptance.dart';

/// Foreground only. Production composition waits for the scheduler and runner.
/// Share one instance (or one gate) for all foreground entry points.
final class ConversationTurnDispatcher {
  ConversationTurnDispatcher({
    required PrepareTextGeneration prepare,
    required ConversationTurnRouter router,
    required MessageRepository messages,
    required ConversationDraftRepository drafts,
    required ConversationTaskRepository tasks,
    required ConversationTaskEnqueuer enqueuer,
    required ToolRegistry toolRegistry,
    ForegroundTurnGate? gate,
    DateTime Function()? now,
    this.enqueueTimeout = const Duration(seconds: 1),
    this.onMetrics,
  }) : _prepare = prepare,
       _router = router,
       _messages = messages,
       _drafts = drafts,
       _tasks = tasks,
       _enqueuer = enqueuer,
       _tools = toolRegistry,
       _gate = gate ?? ForegroundTurnGate(),
       _now = now ?? DateTime.now;

  final PrepareTextGeneration _prepare;
  final ConversationTurnRouter _router;
  final MessageRepository _messages;
  final ConversationDraftRepository _drafts;
  final ConversationTaskRepository _tasks;
  final ConversationTaskEnqueuer _enqueuer;
  final ToolRegistry _tools;
  final ForegroundTurnGate _gate;
  final DateTime Function() _now;
  final Duration enqueueTimeout;
  final void Function(TurnDispatchMetrics)? onMetrics;

  bool isAccepting(String chatId) => _gate._active.contains(chatId);

  Future<TurnDispatchResult> dispatch(
    ConversationTurnInput input, {
    void Function(TurnDispatchUpdate)? onUpdate,
  }) => _run(_PendingTurn(input), onUpdate);

  /// Reuses prepared context, the validated disposition, and original identities.
  /// No second routing call is needed after an acceptance/persistence failure.
  Future<TurnDispatchResult> retry(
    TurnDispatchRetry retry, {
    void Function(TurnDispatchUpdate)? onUpdate,
  }) => _run(retry._pending, onUpdate);

  Future<TurnDispatchResult> _run(
    _PendingTurn pending,
    void Function(TurnDispatchUpdate)? onUpdate,
  ) async {
    final input = pending.input;
    final user = input.userMessage;
    final metrics = _DispatchTiming();
    if (!_gate._active.add(user.chatId)) {
      return TurnDispatchBusy(pending.context, metrics.snapshot(user));
    }
    try {
      final history = await _messages.getMessages(user.chatId);
      final originals = history.where(
        (message) =>
            message.messageId == user.messageId ||
            (message.turnId == user.turnId &&
                message.senderId == user.senderId),
      );
      if (originals.isNotEmpty &&
          (originals.length != 1 || !_sameUser(originals.single, user))) {
        throw const _DispatchProblem(TurnDispatchFailureCode.identityConflict);
      }
      if (originals.isEmpty) await _messages.upsertMessage(user);
      pending.userPersisted = true;
      await _clearMatchingDraft(input);

      // Reconcile durable success first, including an ambiguous commit response.
      final accepted = await _tasks.getByOriginTurnId(user.turnId);
      if (accepted != null) {
        if (accepted.chatId != user.chatId ||
            accepted.botId != user.botId ||
            accepted.originUserMessageId != user.messageId) {
          throw const _DispatchProblem(
            TurnDispatchFailureCode.identityConflict,
          );
        }
        return await _accepted(pending, accepted, metrics, reused: true);
      }
      final replies = history.where(
        (message) =>
            message.messageId ==
            ConversationMessageIdentity.directReply(user.turnId),
      );
      if (replies.isNotEmpty) {
        final reply = replies.single;
        if (reply.botId != user.botId ||
            reply.turnId != user.turnId ||
            reply.taskMessageKind != TaskMessageKind.directReply ||
            reply.hasPartialContent) {
          throw const _DispatchProblem(
            TurnDispatchFailureCode.identityConflict,
          );
        }
        return TurnDirectReplySaved(
          pending.context,
          metrics.snapshot(user),
          reply,
          reused: true,
        );
      }
      final explicitTaskId = input.explicitTaskId;
      if (explicitTaskId != null) {
        return await _status(
          pending,
          TaskStatusRequest(taskId: explicitTaskId),
          metrics,
        );
      }
      if (pending.prepared == null) {
        metrics.preparationCalls++;
        final started = metrics.clock.elapsed;
        pending.prepared = await _prepare(
          chatId: user.chatId,
          bot: input.bot,
          history:
              history
                  .where((message) => message.messageId != user.messageId)
                  .toList(),
          userMessage: user,
          currentUserId: user.senderId,
        );
        metrics.preparationDuration = metrics.clock.elapsed - started;
        if (!_sameUser(pending.prepared!.userMessage, user)) {
          throw const _DispatchProblem(
            TurnDispatchFailureCode.identityConflict,
          );
        }
      }
      final prepared = pending.prepared!;
      metrics.preflightUsage = prepared.preflightTokenUsage;
      pending.acceptance ??= _freezeAcceptance(input, prepared, _tools);
      if (pending.disposition == null) {
        await _route(pending, metrics, onUpdate);
      }
      final disposition = pending.disposition!;
      switch (disposition) {
        case DirectReply():
          return await _direct(pending, disposition, metrics);
        case BackgroundTaskPlan():
          if (!pending.acceptance!.allowedToolNames.containsAll(
            disposition.allowedToolNames,
          )) {
            pending.disposition = null;
            throw const _DispatchProblem(
              TurnDispatchFailureCode.routingFailed,
              routing: TurnRoutingFailure.invalidProtocol,
            );
          }
          if (pending.acceptanceWrite == null) {
            pending.acceptanceWrite = _createAcceptance(
              pending,
              disposition,
              _now(),
            );
            if (pending.acceptanceWrite!.ackFallback) {
              metrics.acknowledgementFallbacks++;
            }
          }
          final write = pending.acceptanceWrite!;
          final result = await _tasks.createWithAcknowledgement(
            task: write.task,
            plan: write.plan,
            initialEvent: write.event,
            acknowledgement: write.acknowledgement,
          );
          switch (result) {
            case TaskWriteCommitted<ConversationTask>():
              metrics.acknowledgementCommitLatency = metrics.clock.elapsed;
              return await _accepted(
                pending,
                result.value,
                metrics,
                reused: result.reused,
              );
            case TaskWriteConflict<ConversationTask>():
              throw const _DispatchProblem(
                TurnDispatchFailureCode.taskCreationFailed,
              );
          }
        case TaskStatusRequest():
          return await _status(pending, disposition, metrics);
      }
    } on Object catch (error) {
      var restored = false;
      if (!pending.userPersisted) {
        try {
          await _drafts.write(user.chatId, input.draft);
          restored = true;
        } on Object {
          /* The returned draft still lets the UI restore it. */
        }
      }
      final problem = error is _DispatchProblem ? error : null;
      final code =
          problem?.code ??
          (!pending.userPersisted
              ? TurnDispatchFailureCode.userPersistenceFailed
              : pending.acceptanceWrite != null
              ? TurnDispatchFailureCode.taskCreationFailed
              : pending.disposition is DirectReply
              ? TurnDispatchFailureCode.replyPersistenceFailed
              : input.explicitTaskId != null ||
                  pending.disposition is TaskStatusRequest
              ? TurnDispatchFailureCode.statusQueryFailed
              : TurnDispatchFailureCode.preparationFailed);
      return TurnDispatchFailed(
        pending.context,
        metrics.snapshot(user),
        code: code,
        routingFailure: problem?.routing,
        retry:
            code == TurnDispatchFailureCode.identityConflict
                ? null
                : TurnDispatchRetry._(pending),
        userPersisted: pending.userPersisted,
        draftToRestore: pending.userPersisted ? null : input.draft,
        draftRestored: restored,
      );
    } finally {
      _gate._active.remove(user.chatId);
      _observe(() => onMetrics?.call(metrics.snapshot(user)));
    }
  }

  Future<void> _route(
    _PendingTurn pending,
    _DispatchTiming metrics,
    void Function(TurnDispatchUpdate)? onUpdate,
  ) async {
    TurnDispositionKind? kind;
    TurnDisposition? completed;
    final displayed = StringBuffer();
    final request = TurnRoutingRequest(
      bot: pending.input.bot,
      userMessage: pending.input.userMessage,
      language: pending.input.language,
      messages: pending.prepared!.messages,
      allowedToolNames: pending.acceptance!.allowedToolNames,
    );
    void invalid() =>
        throw const _DispatchProblem(
          TurnDispatchFailureCode.routingFailed,
          routing: TurnRoutingFailure.invalidProtocol,
        );
    try {
      await for (final event in _router.route(request)) {
        switch (event) {
          case TurnRoutingCallStarted(:final providerSupportsAgentLoop):
            if (++metrics.mainReplyCalls > 1) invalid();
            pending.providerSupportsAgentLoop = providerSupportsAgentLoop;
          case TurnDispositionStarted():
            if (kind != null || completed != null) invalid();
            kind = event.kind;
            _observe(
              () => onUpdate?.call(TurnDispatchUpdate(pending.context, event)),
            );
          case DirectReplyDelta(:final text):
            if (kind != TurnDispositionKind.directReply || completed != null) {
              invalid();
            }
            if (text.isNotEmpty) {
              metrics.directFirstCharacterLatency ??= metrics.clock.elapsed;
            }
            displayed.write(text);
            if (displayed.length > 128000) invalid();
            _observe(
              () => onUpdate?.call(TurnDispatchUpdate(pending.context, event)),
            );
          case TurnRoutingUsage(:final usage):
            pending.usage = pending.usage.merge(usage);
          case TurnDispositionCompleted(:final disposition):
            if (kind != disposition.kind || completed != null) invalid();
            if (disposition is DirectReply &&
                displayed.isNotEmpty &&
                displayed.toString() != disposition.text) {
              invalid();
            }
            completed = disposition;
          case TurnRoutingFailed(:final reason):
            throw _DispatchProblem(
              TurnDispatchFailureCode.routingFailed,
              routing: reason,
            );
        }
      }
      if (completed == null || metrics.mainReplyCalls != 1) invalid();
      pending.disposition = completed;
    } on Object catch (error) {
      metrics.routingFallbacks++;
      pending.usage = ModelTokenUsage.empty;
      if (error is _DispatchProblem) rethrow;
      throw const _DispatchProblem(
        TurnDispatchFailureCode.routingFailed,
        routing: TurnRoutingFailure.providerFailed,
      );
    }
  }

  Future<TurnDirectReplySaved> _direct(
    _PendingTurn pending,
    DirectReply reply,
    _DispatchTiming metrics,
  ) async {
    final user = pending.input.userMessage;
    final outcome =
        reply.outcome == MessageTerminalOutcome.completed &&
                reply.text.trim().isEmpty
            ? MessageTerminalOutcome.emptyResponse
            : reply.outcome;
    final message = Message(
      messageId: ConversationMessageIdentity.directReply(user.turnId),
      turnId: user.turnId,
      chatId: user.chatId,
      botId: user.botId,
      senderId: user.botId,
      content: outcome == MessageTerminalOutcome.completed ? reply.text : '',
      taskMessageKind: TaskMessageKind.directReply,
      terminalOutcome: outcome,
      timestamp: _now(),
      tokenUsage: pending.prepared!.preflightTokenUsage + pending.usage,
      grounding: const AnswerTrustPolicy().evaluate(
        AnswerTrustPolicyInput(
          terminalOutcome: outcome,
          providerSupportsAgentLoop: pending.providerSupportsAgentLoop,
          reliabilityPolicyEnabled:
              pending.acceptance!.verification.reliabilityEnabled,
          verificationUnavailableReason:
              pending.prepared!.verificationUnavailableReason,
        ),
      ),
    );
    final saved = await _messages.upsertMessage(message);
    metrics.directCompletionLatency = metrics.clock.elapsed;
    return TurnDirectReplySaved(pending.context, metrics.snapshot(user), saved);
  }

  Future<TurnTaskAccepted> _accepted(
    _PendingTurn pending,
    ConversationTask task,
    _DispatchTiming metrics, {
    required bool reused,
  }) async {
    var notified = false;
    if (!task.status.isTerminal) {
      try {
        await _enqueuer.enqueue(task.taskId).timeout(enqueueTimeout);
        notified = true;
      } on Object {
        /* Queued facts survive a lost scheduling notification. */
      }
    }
    return TurnTaskAccepted(
      pending.context,
      metrics.snapshot(pending.input.userMessage),
      task,
      notificationDelivered: notified,
      reused: reused,
    );
  }

  Future<TurnTaskStatusRead> _status(
    _PendingTurn pending,
    TaskStatusRequest request,
    _DispatchTiming metrics,
  ) async {
    final chatId = pending.input.userMessage.chatId;
    final query = GetConversationTaskProgress(repository: _tasks);
    final summaries = <ConversationTaskProgressSummary>[];
    if (request.taskId != null) {
      final summary = await query(chatId: chatId, taskId: request.taskId!);
      if (summary != null) summaries.add(summary);
    } else {
      final active = await _tasks.listActiveForChat(chatId);
      final latest =
          active.isEmpty ? await _tasks.getLatestTerminalForChat(chatId) : null;
      for (final task in [...active, if (latest != null) latest]) {
        final summary = await query(chatId: chatId, taskId: task.taskId);
        if (summary != null) summaries.add(summary);
      }
    }
    return TurnTaskStatusRead(
      pending.context,
      metrics.snapshot(pending.input.userMessage),
      summaries: summaries,
      explicitTaskId: request.taskId,
    );
  }

  Future<void> _clearMatchingDraft(ConversationTurnInput input) async {
    try {
      final draft = await _drafts.read(input.userMessage.chatId);
      if (draft != null &&
          jsonEncode([draft.text, draft.imagePaths, draft.filePaths]) ==
              jsonEncode([
                input.draft.text,
                input.draft.imagePaths,
                input.draft.filePaths,
              ])) {
        await _drafts.delete(input.userMessage.chatId);
      }
    } on Object {
      /* Draft cleanup must not undo a committed user message. */
    }
  }
}

bool _sameUser(Message a, Message b) =>
    a.messageId == b.messageId &&
    a.turnId == b.turnId &&
    a.chatId == b.chatId &&
    a.botId == b.botId &&
    a.senderId == b.senderId &&
    a.content == b.content &&
    a.taskMessageKind == null &&
    b.taskMessageKind == null &&
    jsonEncode([a.images, a.files]) == jsonEncode([b.images, b.files]);

void _observe(void Function() callback) {
  try {
    callback();
  } on Object {
    /* Observers cannot affect committed work. */
  }
}

final class _DispatchProblem implements Exception {
  const _DispatchProblem(this.code, {this.routing});
  final TurnDispatchFailureCode code;
  final TurnRoutingFailure? routing;
}
