import 'package:stars/data/models/tool_execution_record.dart';
import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/tool_execution_repository.dart';

final class SqliteToolExecutionRepository implements ToolExecutionRepository {
  const SqliteToolExecutionRepository({
    required LocalDatabaseService localDatabase,
  }) : _localDatabase = localDatabase;

  final LocalDatabaseService _localDatabase;

  @override
  Future<void> upsert(ToolExecutionRecord record) {
    return _localDatabase.upsertToolExecution(
      ToolExecutionDbRecord.fromDomain(record).values,
    );
  }

  @override
  Future<List<ToolExecutionRecord>> getForRun(String runId) async {
    final records = await _localDatabase.loadToolExecutionsForRun(runId);
    return List<ToolExecutionRecord>.unmodifiable(
      records.map((record) => ToolExecutionDbRecord(record).toDomain()),
    );
  }

  @override
  Future<List<ToolExecutionRecord>> getForChat(
    String chatId, {
    int limit = 100,
  }) async {
    if (limit < 1 || limit > 1000) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 1000.');
    }
    final records = await _localDatabase.loadToolExecutionsForChat(
      chatId,
      limit: limit,
    );
    return List<ToolExecutionRecord>.unmodifiable(
      records.map((record) => ToolExecutionDbRecord(record).toDomain()),
    );
  }
}
