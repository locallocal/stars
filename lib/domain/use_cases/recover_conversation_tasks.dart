import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_scheduling.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_runner_contracts.dart';

/// Recovers ownership, never guesses the outcome of an external operation.
/// The segment runner reconstructs sessions and reconciles persisted intents.
final class RecoverConversationTasks {
  RecoverConversationTasks({
    required this.repository,
    this.clock = const SystemTaskRunnerClock(),
    TaskSchedulingMetrics? metrics,
  }) : metrics = metrics ?? TaskSchedulingMetrics();
  final ConversationTaskRepository repository;
  final TaskRunnerClock clock;
  final TaskSchedulingMetrics metrics;

  /// Returns durable candidates for stage 06, including a crash after the
  /// committing checkpoint but before the scheduler received the result.
  Future<List<TaskSegmentResult>> call() async {
    final ready = <TaskSegmentResult>[];
    String? cursor;
    do {
      final tasks = await repository.listRecoverable(afterTaskId: cursor);
      if (tasks.isEmpty) break;
      cursor = tasks.last.taskId;
      for (var task in tasks) {
        if (task.lease?.isValidAt(clock.now()) == true) continue;
        if (task.lease != null) {
          final recovered = await repository.recoverTask(
            taskId: task.taskId,
            expectedRevision: task.revision,
            now: clock.now(),
          );
          if (recovered is! TaskWriteCommitted<ConversationTask>) continue;
          task = recovered.value;
          if (!recovered.reused) {
            metrics.recoveries++;
            metrics.leaseExpirations++;
          }
        }
        if (task.phase != ConversationTaskPhase.committing ||
            task.status == ConversationTaskStatus.waitingForUser) {
          continue;
        }
        final snapshot = await repository.getExecutionSnapshot(task.taskId);
        if (snapshot == null || snapshot.task.revision != task.revision) {
          continue;
        }
        final state = snapshot.checkpoint?.execution;
        if (state?.sideEffectsUnknown == true) {
          final wait = await repository.waitForTaskInput(
            taskId: task.taskId,
            expectedRevision: task.revision,
            reason: TaskWaitingReason.reconciliation,
            reasonCode: TaskReasonCode.reconciliationRequired,
            now: clock.now(),
          );
          if (wait is TaskWriteCommitted<ConversationTask>) {
            metrics.reconciliationFailures++;
          }
        } else if (state?.finalizationReason case final reason?) {
          if ({
            TaskReasonCode.missingCredentials,
            TaskReasonCode.providerUnavailable,
            TaskReasonCode.botUnavailable,
          }.contains(reason)) {
            await repository.waitForTaskInput(
              taskId: task.taskId,
              expectedRevision: task.revision,
              reason:
                  reason == TaskReasonCode.missingCredentials
                      ? TaskWaitingReason.authentication
                      : TaskWaitingReason.requiredInput,
              reasonCode: reason,
              now: clock.now(),
            );
          } else {
            ready.add(TaskNeedsSafeFinalization(snapshot, reason));
          }
        } else if (state?.candidate case final candidate?) {
          ready.add(TaskCompletionCandidate(snapshot, candidate));
        }
      }
    } while (true);
    return ready;
  }
}
