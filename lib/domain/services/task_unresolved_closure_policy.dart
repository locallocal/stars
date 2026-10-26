import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/services/task_safe_data.dart';

/// Manual closure is a failed application outcome, never proof of an external
/// operation's success, termination or rollback. Original attempts stay intact.
final class TaskUnresolvedClosurePolicy {
  const TaskUnresolvedClosurePolicy();
  static const reasonCode = 'task_manually_closed_unresolved';

  ({TaskTerminalSummary summary, Message message, String audit}) build({
    required ConversationTask task,
    required String actorId,
    required String note,
    required DateTime now,
  }) {
    // Reject sensitive or altered notes rather than persisting different meaning.
    final audit = 'actor=$actorId; note=$note';
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(actorId) ||
        note.trim().isEmpty ||
        note != note.trim() ||
        note.length > 1000 ||
        taskSafeText(audit, maximum: 1200, structured: true) != audit) {
      throw ArgumentError('A bounded, non-sensitive review note is required.');
    }
    final chinese = task.acceptance.language.toLowerCase().startsWith('zh');
    final text =
        chinese
            ? '已由用户结束此任务。外部操作结果仍未知，操作可能仍在运行或已产生影响；请人工核对。未确认成功、停止或回滚，不能自动重试。'
            : 'The user closed this task. The external outcome remains unknown; the operation may still be running or have taken effect. Review it manually. Success, termination and rollback are unconfirmed; automatic retry is disabled.';

    final summary = TaskTerminalSummary(
      status: ConversationTaskStatus.failed,
      reasonCode: reasonCode,
      safeReason: text,
      completedWorkSummary: '',
      sideEffectStatus: TaskSideEffectStatus.unknown,
      canRetry: false,
      suggestedNextActions: [
        chinese ? '人工核对外部操作结果' : 'Review the external outcome manually',
      ],
      cancellationSource: task.cancellationSource,
    );
    final message = Message(
      messageId: ConversationMessageIdentity.result(task.taskId),
      taskId: task.taskId,
      taskMessageKind: TaskMessageKind.result,
      turnId: task.originTurnId,
      runId: task.taskId,
      chatId: task.chatId,
      botId: task.botId,
      senderId: 'assistant',
      content: text,
      grounding: MessageGrounding(reasonCode: 'no_verifiable_claims'),
      terminalOutcome: MessageTerminalOutcome.failed,
      timestamp: now,
      taskResultPolicy: TaskResultPresentationPolicy(
        strictGroundingEnabled: task.verificationPolicy.strictGroundingEnabled,
        showVerificationStatus: task.verificationPolicy.showVerificationStatus,
      ),
    );
    return (summary: summary, message: message, audit: audit);
  }
}
