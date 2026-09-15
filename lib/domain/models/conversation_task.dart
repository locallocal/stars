import 'package:stars/domain/models/task_execution_state.dart';
import 'package:stars/domain/models/task_message_kind.dart';
import 'package:stars/domain/models/task_segment_limits.dart';
import 'package:stars/domain/models/tool.dart';

export 'task_message_kind.dart';
export 'task_segment_limits.dart';

part 'conversation_task_state.dart';
part 'conversation_task_snapshot.dart';
part 'conversation_task_progress.dart';
part 'conversation_task_records.dart';

/// The durable aggregate identity and current projection of an accepted task.
final class ConversationTask {
  ConversationTask({
    required this.taskId,
    required this.chatId,
    required this.botId,
    required this.originTurnId,
    required this.originUserMessageId,
    required this.title,
    required this.objective,
    required this.acceptance,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.status = ConversationTaskStatus.queued,
    this.phase = ConversationTaskPhase.planning,
    this.planRevision = 1,
    this.revision = 0,
    this.waitingReason,
    this.terminalSummary,
    this.completedAt,
    this.lease,
    this.nextRunAt,
    this.cancellationSource,
    this.cancelRequestedAt,
    this.retryOfTaskId,
  }) {
    for (final id in [
      taskId,
      chatId,
      botId,
      originTurnId,
      originUserMessageId,
    ]) {
      _taskText(id, 'identity', maximum: 256);
    }
    if (retryOfTaskId != null) {
      _taskText(retryOfTaskId!, 'retryOfTaskId', maximum: 256);
      if (retryOfTaskId == taskId) {
        throw ArgumentError('A task cannot retry itself.');
      }
    }
    _taskText(title, 'title', maximum: 200);
    _taskText(objective, 'objective');
    _taskCount(planRevision, 'planRevision', minimum: 1);
    _taskCount(revision, 'revision');
    if (updatedAt.isBefore(createdAt) ||
        (completedAt != null &&
            (completedAt!.isBefore(createdAt) ||
                completedAt!.isAfter(updatedAt))) ||
        (cancelRequestedAt != null &&
            (cancelRequestedAt!.isBefore(createdAt) ||
                cancelRequestedAt!.isAfter(updatedAt)))) {
      throw ArgumentError('Task timestamps must be chronological.');
    }
    if (status.isTerminal != (completedAt != null)) {
      throw ArgumentError('Only terminal tasks have a completion time.');
    }
    if ((status == ConversationTaskStatus.waitingForUser) !=
        (waitingReason != null)) {
      throw ArgumentError('Waiting tasks require an explicit waiting reason.');
    }
    if ((cancellationSource == null) != (cancelRequestedAt == null) ||
        ((status == ConversationTaskStatus.cancelRequested ||
                status == ConversationTaskStatus.cancelled) &&
            cancellationSource == null)) {
      throw ArgumentError('Cancellation requires a durable source and time.');
    }
    if (lease != null && lease!.taskId != taskId) {
      throw ArgumentError('Lease belongs to another task.');
    }
    if (status == ConversationTaskStatus.running && lease == null) {
      throw ArgumentError('Running tasks require an execution lease.');
    }
    if (status.isTerminal && lease != null) {
      throw ArgumentError('Terminal tasks cannot retain an execution lease.');
    }
    if ((status.isTerminal && nextRunAt != null) ||
        (cancellationSource != null &&
            {
              ConversationTaskStatus.queued,
              ConversationTaskStatus.running,
              ConversationTaskStatus.succeeded,
            }.contains(status))) {
      throw ArgumentError(
        'Terminal or cancelling tasks cannot resume normal work.',
      );
    }
    final needsSummary =
        status == ConversationTaskStatus.failed ||
        status == ConversationTaskStatus.cancelled;
    if (needsSummary != (terminalSummary != null) ||
        (terminalSummary != null && terminalSummary!.status != status) ||
        (status == ConversationTaskStatus.cancelled &&
            terminalSummary?.cancellationSource != cancellationSource)) {
      throw ArgumentError(
        'Failure and cancellation require matching summaries.',
      );
    }
  }

  final String taskId;
  final String chatId;
  final String botId;
  final String originTurnId;
  final String originUserMessageId;
  final String? retryOfTaskId;
  final String title;
  final String objective;
  final TaskAcceptanceSnapshot acceptance;
  final TaskProgress progress;
  final ConversationTaskStatus status;
  final ConversationTaskPhase phase;
  final int planRevision;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final TaskWaitingReason? waitingReason;
  final TaskTerminalSummary? terminalSummary;
  final TaskLease? lease;
  final DateTime? nextRunAt;
  final TaskCancellationSource? cancellationSource;
  final DateTime? cancelRequestedAt;

  String get ackMessageId =>
      ConversationMessageIdentity.acknowledgement(taskId);
  String? get resultMessageId =>
      status.isTerminal ? ConversationMessageIdentity.result(taskId) : null;
  VerificationPolicySnapshot get verificationPolicy => acceptance.verification;

  /// Builds the next aggregate; persistence must still compare revision/lease.
  ConversationTask transitionTo(
    ConversationTaskStatus next, {
    required DateTime at,
    ConversationTaskPhase? phase,
    TaskProgress? progress,
    TaskWaitingReason? waitingReason,
    TaskTerminalSummary? terminalSummary,
    TaskLease? lease,
    DateTime? nextRunAt,
    TaskCancellationSource? cancellationSource,
  }) {
    if (!status.canTransitionTo(next) ||
        at.isBefore(updatedAt) ||
        (cancelRequestedAt != null &&
            {
              ConversationTaskStatus.queued,
              ConversationTaskStatus.running,
              ConversationTaskStatus.succeeded,
            }.contains(next))) {
      throw StateError('Illegal or stale task transition: $status -> $next.');
    }
    return ConversationTask(
      taskId: taskId,
      chatId: chatId,
      botId: botId,
      originTurnId: originTurnId,
      originUserMessageId: originUserMessageId,
      retryOfTaskId: retryOfTaskId,
      title: title,
      objective: objective,
      acceptance: acceptance,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      updatedAt: at,
      status: next,
      phase: phase ?? this.phase,
      planRevision: planRevision,
      revision: revision + 1,
      waitingReason: waitingReason,
      terminalSummary: terminalSummary,
      completedAt: next.isTerminal ? at : null,
      lease: next.isTerminal ? null : lease,
      nextRunAt: next.isTerminal ? null : nextRunAt,
      cancellationSource: this.cancellationSource ?? cancellationSource,
      cancelRequestedAt:
          cancelRequestedAt ??
          (next == ConversationTaskStatus.cancelRequested ? at : null),
    );
  }
}

void _taskText(String value, String name, {int maximum = 16000}) {
  if (value.isEmpty || value.trim() != value || value.length > maximum) {
    throw ArgumentError('Invalid bounded, normalized task field: $name.');
  }
}

void _taskCount(int value, String name, {int minimum = 0}) {
  if (value < minimum) throw ArgumentError('Invalid task counter: $name.');
}

List<String> _taskStrings(Iterable<String> values, String name) {
  final copy = List<String>.unmodifiable(values);
  for (final value in copy) {
    _taskText(value, name);
  }
  return copy;
}
