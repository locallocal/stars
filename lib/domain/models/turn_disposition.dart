import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';

enum TurnDispositionKind { directReply, backgroundTaskPlan, taskStatusRequest }

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

/// A proposal only. It becomes accepted work after the repository transaction.
final class BackgroundTaskPlan extends TurnDisposition {
  BackgroundTaskPlan({
    required this.title,
    required this.objective,
    required List<TaskPlanStep> steps,
    required Set<String> allowedToolNames,
    required this.acknowledgementDraft,
  }) : steps = List.unmodifiable(steps),
       allowedToolNames = Set.unmodifiable(allowedToolNames) {
    if (title.trim().isEmpty ||
        title.length > 200 ||
        objective.trim().isEmpty ||
        objective.length > 16000 ||
        steps.isEmpty ||
        steps.length > 32 ||
        steps.map((step) => step.stepId).toSet().length != steps.length ||
        steps.any((step) => step.status != TaskPlanStepStatus.pending) ||
        allowedToolNames.length > 256 ||
        allowedToolNames.any(
          (name) => name.trim().isEmpty || name.length > 256,
        ) ||
        acknowledgementDraft.length > 2000) {
      throw ArgumentError('Invalid foreground task proposal.');
    }
  }
  final String title;
  final String objective;
  final List<TaskPlanStep> steps;
  final Set<String> allowedToolNames;
  final String acknowledgementDraft;
  @override
  TurnDispositionKind get kind => TurnDispositionKind.backgroundTaskPlan;
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
