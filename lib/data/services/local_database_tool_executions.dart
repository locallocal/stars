part of 'local_database_service.dart';

extension LocalDatabaseToolExecutions on LocalDatabaseService {
  Future<void> upsertToolExecution(Map<String, Object?> values) async {
    final database = await _databaseProvider();
    await _upsertByPrimaryKey(
      database,
      'tool_execution_records',
      values,
      'execution_id',
    );
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
