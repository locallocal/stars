import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/task_message_kind.dart';
import 'package:stars/domain/services/task_safe_data.dart';
import 'package:stars/domain/use_cases/get_conversation_task_execution.dart';

/// Read-only execution metadata for task replies, separate from persisted text
/// and token accounting. Progress replies retain the facts they summarized.
final class GetTaskMessageExecution {
  const GetTaskMessageExecution(this.getExecution);

  final GetConversationTaskExecution Function() getExecution;

  Future<({MessageProcessInfo processInfo, ModelTokenUsage? tokenUsage})> call(
    Message message,
  ) async {
    final original = message.processInfo;
    final MessageProcessInfo? execution;
    final ModelTokenUsage? tokenUsage;
    switch (message.taskMessageKind) {
      case TaskMessageKind.result:
        final taskExecution = await getExecution()(
          taskId: message.taskId!,
          chatId: message.chatId,
          botId: message.botId,
        );
        execution = taskExecution?.processInfo;
        tokenUsage = taskExecution?.tokenUsage;
      case TaskMessageKind.status:
        final summaries = message.taskStatusSummaries;
        if (summaries.isEmpty) return (processInfo: original, tokenUsage: null);
        tokenUsage =
            summaries.every((summary) => summary.progress.tokenUsage != null)
                ? ModelTokenUsage.sum(
                  summaries.map((summary) => summary.progress.tokenUsage!),
                )
                : null;
        final summary = summaries.length == 1 ? summaries.single : null;
        execution = MessageProcessInfo(
          durationMs:
              summary?.updatedAt.difference(summary.createdAt).inMilliseconds,
          toolCalls: List.unmodifiable([
            for (final summary in summaries)
              if (summary.progress.latestTool case final tool?)
                MessageToolCall(
                  attemptId: tool.attemptId,
                  name: taskSafeText(tool.name),
                  status: tool.status.name,
                  resultSummary: taskSafeText(tool.safeSummary),
                ),
          ]),
        );
      case TaskMessageKind.acknowledgement:
      case TaskMessageKind.directReply:
      case null:
        return (processInfo: original, tokenUsage: null);
    }
    if (execution == null) {
      return (processInfo: original, tokenUsage: tokenUsage);
    }
    return (
      tokenUsage: tokenUsage,
      processInfo: MessageProcessInfo(
        reasoningStatus: original.reasoningStatus,
        durationMs: execution.durationMs ?? original.durationMs,
        toolCalls:
            execution.toolCalls.isEmpty
                ? original.toolCalls
                : execution.toolCalls,
        commandExecutions:
            execution.commandExecutions.isEmpty
                ? original.commandExecutions
                : execution.commandExecutions,
        fileEdits: original.fileEdits,
        skillActivations: original.skillActivations,
      ),
    );
  }
}
