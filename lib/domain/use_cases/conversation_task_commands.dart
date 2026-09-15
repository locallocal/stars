import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_scheduling.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_runner_contracts.dart';

/// User intent is committed before a scheduler is notified.
final class ConversationTaskCommands {
  const ConversationTaskCommands({
    required this.repository,
    required this.wake,
    this.clock = const SystemTaskRunnerClock(),
    this.metrics,
  });
  final ConversationTaskRepository repository;
  final void Function(String taskId) wake;
  final TaskRunnerClock clock;
  final TaskSchedulingMetrics? metrics;

  Future<TaskWriteResult<ConversationTask>> cancel({
    required String taskId,
    required int expectedRevision,
    TaskCancellationSource source = TaskCancellationSource.user,
  }) async {
    final result = await repository.requestCancellation(
      taskId: taskId,
      expectedRevision: expectedRevision,
      source: source,
      requestedAt: clock.now(),
    );
    if (result is TaskWriteCommitted<ConversationTask>) wake(taskId);
    return result;
  }

  Future<TaskWriteResult<TaskApprovalRecord>> decide({
    required String taskId,
    required int expectedRevision,
    required String approvalId,
    required TaskApprovalDecision decision,
    required String actorId,
  }) async {
    final result = await repository.decideApproval(
      taskId: taskId,
      approvalId: approvalId,
      expectedRevision: expectedRevision,
      decision: decision,
      actorId: actorId,
      decidedAt: clock.now(),
    );
    if (result is TaskWriteCommitted<TaskApprovalRecord>) {
      metrics?.waitingTime += result.value.decidedAt!.difference(
        result.value.requestedAt,
      );
      wake(taskId);
    }
    return result;
  }

  Future<TaskWriteResult<ConversationTask>> resume({
    required String taskId,
    required int expectedRevision,
  }) async {
    final previous = metrics == null ? null : await repository.getById(taskId);
    final result = await repository.resumeTask(
      taskId: taskId,
      expectedRevision: expectedRevision,
      now: clock.now(),
    );
    if (result is TaskWriteCommitted<ConversationTask>) {
      if (previous != null && previous.revision == expectedRevision) {
        metrics?.waitingTime += result.value.updatedAt.difference(
          previous.updatedAt,
        );
      }
      wake(taskId);
    }
    return result;
  }
}
