part of 'local_database_service.dart';

extension LocalDatabaseToolExecutions on LocalDatabaseService {
  Future<void> upsertToolExecution(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await database.transaction((tx) async {
      final taskLinks = await tx.query(
        'conversation_task_tool_attempts',
        columns: ['task_id'],
        where: 'attempt_id = ?',
        whereArgs: [values['attempt_id']],
      );
      if (taskLinks.isNotEmpty) {
        throw StateError(
          'Task tools must be updated with their progress transaction.',
        );
      }
      await _upsertByPrimaryKey(
        tx,
        'tool_execution_records',
        values,
        'execution_id',
      );
    });
  }

  Future<List<Map<String, Object?>>> loadToolExecutionsForRun(
    String runId,
  ) async {
    final database = await _databaseProvider();
    return database.query(
      'tool_execution_records',
      where: 'run_id = ?',
      whereArgs: [runId],
      orderBy: 'started_at ASC, execution_id ASC',
    );
  }

  Future<List<Map<String, Object?>>> loadToolExecutionsForChat(
    String chatId, {
    required int limit,
  }) async {
    final database = await _databaseProvider();
    return database.query(
      'tool_execution_records',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'started_at DESC, execution_id DESC',
      limit: limit,
    );
  }

  Future<void> deleteToolExecutionsForChat(String chatId) async {
    final database = await _databaseProvider();
    await database.delete(
      'tool_execution_records',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
  }
}
