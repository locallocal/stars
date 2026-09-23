import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/conversation_task_list_item.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/services/task_safe_data.dart';

/// Decodes only the columns selected for the task browser.
abstract final class ConversationTaskListRecord {
  static ConversationTaskListItem decode(Map<String, Object?> row) {
    DateTime time(String key) =>
        DateTime.fromMicrosecondsSinceEpoch(row[key]! as int, isUtc: true);
    return ConversationTaskListItem(
      taskId: row['task_id']! as String,
      chatId: row['chat_id']! as String,
      title: taskSafeText(row['title']! as String, maximum: 200),
      status: ConversationTaskStatus.values.byName(row['status']! as String),
      phase: ConversationTaskPhase.values.byName(row['phase']! as String),
      summaryRevision: row['revision']! as int,
      createdAt: time('created_at'),
      updatedAt: time('updated_at'),
      leaseExpiresAt:
          row['lease_expires_at'] == null ? null : time('lease_expires_at'),
      completedSteps: row['completed_steps'] as int?,
      totalSteps: row['total_steps'] as int?,
      currentStepSummary: row['current_step_summary'] as String? ?? '',
      latestToolName: row['latest_tool_name'] as String? ?? '',
      tokenUsage:
          row['input_tokens'] == null
              ? null
              : ModelTokenUsage(
                inputTokens: row['input_tokens']! as int,
                outputTokens: row['output_tokens']! as int,
                totalTokens: row['total_tokens']! as int,
              ),
    );
  }
}
