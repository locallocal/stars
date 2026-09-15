import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/grounded_answer_validator.dart';

/// Uses immutable task/attempt links from one committed database snapshot.
/// Segment IDs retain their audit identity; they are never rewritten as task IDs.
final class TaskEvidenceScope implements EvidenceValidationScope {
  const TaskEvidenceScope(this.snapshot);
  final TaskExecutionSnapshot snapshot;

  @override
  bool contains(ToolEvidenceRecord evidence, String scopeId) {
    final task = snapshot.task;
    if (scopeId != task.taskId ||
        evidence.chatId != task.chatId ||
        evidence.turnId != task.originTurnId ||
        !snapshot.evidence.any((e) => e.evidenceId == evidence.evidenceId)) {
      return false;
    }
    final link =
        snapshot.attemptLinks
            .where(
              (link) =>
                  link.taskId == task.taskId &&
                  link.attemptId == evidence.attemptId &&
                  link.segmentId == evidence.runId,
            )
            .firstOrNull;
    final attempt =
        snapshot.attempts
            .where((attempt) => attempt.attemptId == evidence.attemptId)
            .firstOrNull;
    return link != null &&
        attempt != null &&
        attempt.runId == evidence.runId &&
        attempt.chatId == task.chatId &&
        attempt.botId == task.botId &&
        attempt.turnId == task.originTurnId &&
        attempt.invocationId == evidence.invocationId &&
        attempt.name == evidence.toolName &&
        attempt.status == ToolInvocationStatus.succeeded &&
        evidence.terminalStatus == ToolInvocationStatus.succeeded &&
        attempt.completedAt != null;
  }
}
