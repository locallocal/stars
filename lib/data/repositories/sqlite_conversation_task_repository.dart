import 'package:stars/data/services/conversation_task_store.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/data/services/task_persistence_metrics.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';

/// Durable conversation tasks, shared with the message database boundary.
final class SqliteConversationTaskRepository
    implements ConversationTaskRepository {
  SqliteConversationTaskRepository({
    required LocalDatabaseService localDatabase,
  }) : _store = localDatabase.conversationTasks;

  final ConversationTaskStore _store;
  TaskPersistenceMetrics get metrics => _store.metrics;

  @override
  Future<TaskExecutionSnapshot?> getExecutionSnapshot(String taskId) =>
      _store.getExecutionSnapshot(taskId);

  @override
  Future<ConversationTask?> getById(String taskId) => _store.getById(taskId);
  @override
  Future<ConversationTask?> getByOriginTurnId(String originTurnId) =>
      _store.getByOriginTurnId(originTurnId);
  @override
  Future<List<ConversationTask>> listActiveForChat(String chatId) =>
      _store.listActiveForChat(chatId);
  @override
  Future<ConversationTask?> getLatestTerminalForChat(String chatId) =>
      _store.getLatestTerminalForChat(chatId);
  @override
  Future<ConversationTaskProgressSummary?> getProgressSummary(String taskId) =>
      _store.getProgressSummary(taskId);
  @override
  Stream<ConversationTaskProgressSummary> watchProgress(String taskId) =>
      _store.watchProgress(taskId);
  @override
  Future<ConversationTaskProgressSummary?> rebuildProgress(String taskId) =>
      _store.rebuildProgress(taskId);
  @override
  Future<ConversationTaskCheckpoint?> getCheckpoint(
    String taskId,
    int planRevision,
  ) => _store.getCheckpoint(taskId, planRevision);
  @override
  Future<List<ConversationTask>> listDue({
    required DateTime now,
    int limit = 100,
  }) => _store.listDue(now: now, limit: limit);
  @override
  Future<List<ConversationTask>> listRecoverable({
    String? afterTaskId,
    int limit = 100,
  }) => _store.listRecoverable(afterTaskId: afterTaskId, limit: limit);
  @override
  Future<TaskWriteResult<ConversationTask>> createWithAcknowledgement({
    required ConversationTask task,
    required ConversationTaskPlan plan,
    required ConversationTaskEvent initialEvent,
    required Message acknowledgement,
  }) => _store.createWithAcknowledgement(
    task: task,
    plan: plan,
    initialEvent: initialEvent,
    acknowledgement: acknowledgement,
  );
  @override
  Future<TaskWriteResult<TaskLease>> tryAcquireLease({
    required String taskId,
    required int expectedRevision,
    required TaskLease lease,
    required DateTime now,
  }) => _store.tryAcquireLease(
    taskId: taskId,
    expectedRevision: expectedRevision,
    lease: lease,
    now: now,
  );
  @override
  Future<TaskWriteResult<TaskLease>> renewLease({
    required TaskLease lease,
    required DateTime expiresAt,
    required int expectedRevision,
    required DateTime now,
  }) => _store.renewLease(
    lease: lease,
    expiresAt: expiresAt,
    expectedRevision: expectedRevision,
    now: now,
  );
  @override
  Future<TaskWriteResult<ConversationTask>> releaseLease({
    required TaskLease lease,
    required int expectedRevision,
    required DateTime now,
    DateTime? nextRunAt,
  }) => _store.releaseLease(
    lease: lease,
    expectedRevision: expectedRevision,
    now: now,
    nextRunAt: nextRunAt,
  );
  @override
  Future<TaskWriteResult<ConversationTask>> appendProgress(
    ConversationTaskProgressUpdate update,
  ) => _store.appendProgress(update);
  @override
  Future<TaskWriteResult<TaskApprovalRecord>> decideApproval({
    required String taskId,
    required String approvalId,
    required int expectedRevision,
    required TaskApprovalDecision decision,
    required String actorId,
    required DateTime decidedAt,
  }) => _store.decideApproval(
    taskId: taskId,
    approvalId: approvalId,
    expectedRevision: expectedRevision,
    decision: decision,
    actorId: actorId,
    decidedAt: decidedAt,
  );
  @override
  Future<TaskWriteResult<ConversationTask>> requestCancellation({
    required String taskId,
    required int expectedRevision,
    required TaskCancellationSource source,
    required DateTime requestedAt,
  }) => _store.requestCancellation(
    taskId: taskId,
    expectedRevision: expectedRevision,
    source: source,
    requestedAt: requestedAt,
  );
  @override
  Future<TaskWriteResult<ConversationTask>> commitTerminalMessage({
    required ConversationTask terminalTask,
    required ConversationTaskEvent event,
    required Message message,
    required int expectedRevision,
    required TaskLease lease,
    required DateTime now,
  }) => _store.commitTerminalMessage(
    terminalTask: terminalTask,
    event: event,
    message: message,
    expectedRevision: expectedRevision,
    lease: lease,
    now: now,
  );
}
