part of 'conversation_task_store.dart';

const _taskModelUsagePrefix = 'task-model:';

Future<void> _writeModelUsage(
  DatabaseExecutor tx,
  ConversationTaskProgressUpdate update,
) async {
  final usage = update.modelUsage;
  if (usage == null) return;
  await tx.insert('token_usage_records', {
    'message_id':
        '$_taskModelUsagePrefix${update.task.taskId}:${update.event.sequence}',
    'chat_id': update.task.chatId,
    'bot_id': update.task.botId,
    'operation_kind': 'task_model_turn',
    'token_model': usage.model,
    'input_token_count': usage.inputTokens,
    'output_token_count': usage.outputTokens,
    'total_token_count': usage.effectiveTotalTokens,
    'timestamp': update.event.occurredAt.millisecondsSinceEpoch,
  });
}

Future<ModelTokenUsage?> _taskTokenUsage(
  DatabaseExecutor tx,
  Map<String, Object?> task,
) async {
  // Join exact identities, not a task-ID prefix: sibling tasks and retries
  // have separate ledgers. Existing receipt/result records are counted once.
  final row =
      (await tx.rawQuery(
        '''
    SELECT COUNT(*) AS reports,
      COALESCE(SUM(input_token_count), 0) AS input_tokens,
      COALESCE(SUM(output_token_count), 0) AS output_tokens,
      COALESCE(SUM(CASE WHEN total_token_count > 0 THEN total_token_count
        ELSE input_token_count + output_token_count END), 0) AS total_tokens
    FROM (
      SELECT u.input_token_count, u.output_token_count, u.total_token_count
      FROM conversation_task_events e
      JOIN token_usage_records u
        ON u.message_id = ? || e.task_id || ':' || e.sequence
      WHERE e.task_id = ? AND u.operation_kind = 'task_model_turn'
        AND u.chat_id = ? AND u.bot_id = ?
      UNION ALL
      SELECT input_token_count, output_token_count, total_token_count
      FROM token_usage_records
      WHERE message_id IN (?, ?) AND chat_id = ? AND bot_id = ?
        AND (input_token_count > 0 OR output_token_count > 0 OR total_token_count > 0)
    )
  ''',
        [
          _taskModelUsagePrefix,
          task['task_id'],
          task['chat_id'],
          task['bot_id'],
          task['ack_message_id'],
          task['result_message_id'],
          task['chat_id'],
          task['bot_id'],
        ],
      )).single;
  if ((row['reports']! as int) == 0) return null;
  return ModelTokenUsage(
    inputTokens: row['input_tokens']! as int,
    outputTokens: row['output_tokens']! as int,
    totalTokens: row['total_tokens']! as int,
  );
}
