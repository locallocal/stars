import 'package:stars/domain/models/message.dart';

enum TurnDispositionKind { directReply, backgroundTask, taskStatusRequest }

/// A decision made by the main reply turn, never by a separate classifier.
sealed class TurnDisposition {
  const TurnDisposition();
  TurnDispositionKind get kind;
}

final class DirectReply extends TurnDisposition {
  const DirectReply(
    this.text, {
    this.outcome = MessageTerminalOutcome.completed,
  });
  final String text;
  final MessageTerminalOutcome outcome;
  @override
  TurnDispositionKind get kind => TurnDispositionKind.directReply;
}

/// Task metadata only. Tool selection and planning happen after acceptance.
final class BackgroundTaskRequest extends TurnDisposition {
  BackgroundTaskRequest({
    required this.title,
    required this.objective,
    required this.acknowledgementDraft,
  }) {
    if (title.trim().isEmpty ||
        title.length > 200 ||
        objective.trim().isEmpty ||
        objective.length > 16000 ||
        acknowledgementDraft.length > 2000) {
      throw ArgumentError('Invalid foreground task proposal.');
    }
  }
  final String title;
  final String objective;
  final String acknowledgementDraft;
  @override
  TurnDispositionKind get kind => TurnDispositionKind.backgroundTask;
}

final class TaskStatusRequest extends TurnDisposition {
  const TaskStatusRequest({this.taskId});
  final String? taskId;
  @override
  TurnDispositionKind get kind => TurnDispositionKind.taskStatusRequest;
}

sealed class TurnRoutingEvent {
  const TurnRoutingEvent();
}

final class TurnDispositionStarted extends TurnRoutingEvent {
  const TurnDispositionStarted(this.kind);
  final TurnDispositionKind kind;
}

/// Display-only text. A failed/incomplete stream must be discarded by the UI.
final class DirectReplyDelta extends TurnRoutingEvent {
  const DirectReplyDelta(this.text);
  final String text;
}

final class TurnDispositionCompleted extends TurnRoutingEvent {
  const TurnDispositionCompleted(this.disposition);
  final TurnDisposition disposition;
}

final class TurnRoutingUsage extends TurnRoutingEvent {
  const TurnRoutingUsage(this.usage);
  final ModelTokenUsage usage;
}

/// Emitted at the transport boundary, separate from Skill/context preflight.
final class TurnRoutingCallStarted extends TurnRoutingEvent {
  const TurnRoutingCallStarted({this.providerSupportsAgentLoop = false});
  final bool providerSupportsAgentLoop;
}

enum TurnRoutingFailure {
  invalidProtocol,
  unsupportedProvider,
  providerFailed,
  incompleteResponse,
  timedOut,
  cancelled,
  forbiddenTool,
}

final class TurnRoutingFailed extends TurnRoutingEvent {
  const TurnRoutingFailed(this.reason);
  final TurnRoutingFailure reason;
}
