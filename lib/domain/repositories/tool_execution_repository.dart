import 'package:stars/domain/models/models.dart';

abstract interface class ToolExecutionRepository {
  Future<void> upsert(ToolExecutionRecord record);

  Future<List<ToolExecutionRecord>> getForRun(String runId);

  Future<List<ToolExecutionRecord>> getForChat(
    String chatId, {
    int limit = 100,
  });
}
