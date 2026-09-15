import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/task_scheduling.dart';
import 'package:stars/domain/models/tool.dart';

/// Durable task operations. Implementations publish changes only after commit.
///
/// Execution writes fence on lease token, expiry and expected revision in the
/// same transaction. User commands fence on revision, without requiring a lease.
/// No method invokes a Provider or external tool while holding a transaction.
abstract interface class ConversationTaskRepository {
  Future<ConversationTask?> getById(String taskId);
  Future<TaskExecutionSnapshot?> getExecutionSnapshot(String taskId);
  Future<ConversationTask?> getByOriginTurnId(String originTurnId);
  Future<List<ConversationTask>> listActiveForChat(String chatId);
  Future<ConversationTask?> getLatestTerminalForChat(String chatId);

  /// One consistency snapshot of all committed task facts, not a live runner.
  Future<ConversationTaskProgressSummary?> getProgressSummary(String taskId);
  Stream<ConversationTaskProgressSummary> watchProgress(String taskId);

  /// Subscribes before reading an initial snapshot, including newly accepted tasks.
  /// Includes all terminal tasks in this conversation for history browsing.
  Stream<List<ConversationTaskProgressSummary>> watchForChat(String chatId);

  /// One immutable card snapshot per status message; repeat queries keep the
  /// original version. Narration updates only its text, with a revision fence.
  Future<Message> saveStatusMessage(Message message);
  Future<bool> updateStatusNarration(Message message);

  /// Repairs only the disposable projection from committed audit facts.
  Future<ConversationTaskProgressSummary?> rebuildProgress(String taskId);

  /// Saves task, plan, initial event/projection and acknowledgement atomically.
  /// A retry of the same origin turn returns its original task and acknowledgement;
  /// changed acceptance content for that turn is a duplicateIdentity conflict.
  /// Validate plan ownership/revision, its allowed-tool subset and message identity
  /// before writing. Deferred foreign-key failures must roll back the transaction.
  Future<TaskWriteResult<ConversationTask>> createWithAcknowledgement({
    required ConversationTask task,
    required ConversationTaskPlan plan,
    required ConversationTaskEvent initialEvent,
    required Message acknowledgement,
  });

  /// Due queued/paused/cancelRequested tasks, excluding committing candidates.
  Future<List<ConversationTask>> listDue({
    required DateTime now,
    int limit = 100,
    String? afterTaskId,
  });

  /// Includes all nonterminal tasks; recovery distinguishes waiting decisions,
  /// cancellation intent, backoff and expired leases using persisted facts.
  Future<List<ConversationTask>> listRecoverable({
    String? afterTaskId,
    int limit = 100,
  });
  Future<ConversationTaskCheckpoint?> getCheckpoint(
    String taskId,
    int planRevision,
  );

  Future<TaskWriteResult<TaskLease>> tryAcquireLease({
    required String taskId,
    required int expectedRevision,
    required TaskLease lease,
    required DateTime now,
    TaskConcurrencyLimits limits = const TaskConcurrencyLimits(),
  });

  /// Reclaims only an expired lease, preserving checkpoint, waits and backoff.
  Future<TaskWriteResult<ConversationTask>> recoverTask({
    required String taskId,
    required int expectedRevision,
    required DateTime now,
  });

  /// Parks a worker/result with an actionable reason. A live lease requires its
  /// owner token; after release the expected revision protects this command.
  Future<TaskWriteResult<ConversationTask>> waitForTaskInput({
    required String taskId,
    required int expectedRevision,
    required TaskWaitingReason reason,
    required String reasonCode,
    required DateTime now,
    TaskLease? lease,
  });

  /// Explicitly retry configuration/reconciliation after user intervention.
  /// Approval waits can only be resumed by decideApproval.
  Future<TaskWriteResult<ConversationTask>> resumeTask({
    required String taskId,
    required int expectedRevision,
    required DateTime now,
  });
  Future<TaskWriteResult<TaskLease>> renewLease({
    required TaskLease lease,
    required DateTime expiresAt,
    required int expectedRevision,
    required DateTime now,
  });
  Future<TaskWriteResult<ConversationTask>> releaseLease({
    required TaskLease lease,
    required int expectedRevision,
    required DateTime now,
    DateTime? nextRunAt,
  });

  /// Event, aggregate, projection and supplied auxiliary records are one write.
  /// The stored projection is derived from facts, not from caller counters.
  Future<TaskWriteResult<ConversationTask>> appendProgress(
    ConversationTaskProgressUpdate update,
  );

  /// Approval request + waiting status use appendProgress; a decision is durable
  /// before any scheduler wake-up. Repeated/conflicting decisions cannot overwrite.
  Future<TaskWriteResult<TaskApprovalRecord>> decideApproval({
    required String taskId,
    required String approvalId,
    required int expectedRevision,
    required TaskApprovalDecision decision,
    required String actorId,
    required DateTime decidedAt,
  });
  Future<TaskWriteResult<ConversationTask>> requestCancellation({
    required String taskId,
    required int expectedRevision,
    required TaskCancellationSource source,
    required DateTime requestedAt,
  });

  /// Saves terminal aggregate/summary/event/projection and taskId:result together.
  /// Identical repeated commits return the existing result; conflicting outcomes
  /// must never overwrite an already committed terminal state or cancellation.
  Future<TaskWriteResult<ConversationTask>> commitTerminalMessage({
    required ConversationTask terminalTask,
    required ConversationTaskEvent event,
    required Message message,
    required int expectedRevision,
    required TaskLease lease,
    required DateTime now,
  });
}

enum TaskWriteConflictReason {
  notFound,
  revisionMismatch,
  leaseUnavailable,
  leaseExpired,
  duplicateIdentity,
  alreadyTerminal,
  approvalAlreadyDecided,
}

sealed class TaskWriteResult<T> {
  const TaskWriteResult();
}

final class TaskWriteCommitted<T> extends TaskWriteResult<T> {
  const TaskWriteCommitted(
    this.value, {
    required this.revision,
    this.reused = false,
  });
  final T value;
  final int revision;
  final bool reused;
}

final class TaskWriteConflict<T> extends TaskWriteResult<T> {
  const TaskWriteConflict(this.reason, {this.actualRevision});
  final TaskWriteConflictReason reason;
  final int? actualRevision;
}

final class ConversationTaskProgressUpdate {
  ConversationTaskProgressUpdate({
    required this.task,
    required this.event,
    required this.expectedRevision,
    required this.lease,
    required this.now,
    this.plan,
    this.checkpoint,
    this.approval,
    this.toolExecution,
    this.toolAttemptLink,
    this.evidence,
    this.evidenceLink,
  }) {
    if (expectedRevision < 0 ||
        task.revision != expectedRevision + 1 ||
        task.status.isTerminal ||
        event.taskId != task.taskId ||
        lease.taskId != task.taskId ||
        [
          plan?.taskId,
          checkpoint?.taskId,
          approval?.taskId,
          toolAttemptLink?.taskId,
          evidenceLink?.taskId,
        ].any((id) => id != null && id != task.taskId)) {
      throw ArgumentError(
        'Progress updates must belong to one nonterminal task revision.',
      );
    }
    if ((plan != null &&
            (plan!.revision != task.planRevision ||
                !task.acceptance.allowedToolNames.containsAll(
                  plan!.allowedToolNames,
                ))) ||
        (checkpoint != null && checkpoint!.planRevision != task.planRevision) ||
        (toolExecution != null &&
            (toolExecution!.chatId != task.chatId ||
                toolExecution!.botId != task.botId ||
                toolExecution!.turnId != task.originTurnId)) ||
        (evidence != null &&
            (evidence!.chatId != task.chatId ||
                evidence!.turnId != task.originTurnId))) {
      throw ArgumentError(
        'Task progress cannot change scope or widen its accepted tools.',
      );
    }
  }

  final ConversationTask task;
  final ConversationTaskEvent event;
  final int expectedRevision;
  final TaskLease lease;
  final DateTime now;
  final ConversationTaskPlan? plan;
  final ConversationTaskCheckpoint? checkpoint;
  final TaskApprovalRecord? approval;
  final ToolExecutionRecord? toolExecution;
  final TaskToolAttemptLink? toolAttemptLink;
  final ToolEvidenceRecord? evidence;
  final TaskEvidenceLink? evidenceLink;
}
