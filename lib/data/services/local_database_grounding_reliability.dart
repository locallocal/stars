part of 'local_database_service.dart';

extension LocalDatabaseGroundingReliability on LocalDatabaseService {
  Future<void> incrementGroundingMetrics(
    Iterable<Map<String, Object?>> deltas, {
    String observationId = '',
  }) async {
    final database = await _databaseProvider();
    await database.transaction((transaction) async {
      if (observationId.isNotEmpty) {
        final existing = await transaction.query(
          'grounding_metric_observations',
          columns: const ['observation_id'],
          where: 'observation_id = ?',
          whereArgs: [observationId],
          limit: 1,
        );
        if (existing.isNotEmpty) return;
        await transaction
            .insert('grounding_metric_observations', <String, Object?>{
              'observation_id': observationId,
              'recorded_at': DateTime.now().toUtc().millisecondsSinceEpoch,
            });
      }
      for (final delta in deltas) {
        await transaction.rawInsert(
          '''
          INSERT INTO grounding_metric_counters (
            metric, category, count, updated_at
          ) VALUES (?, ?, ?, ?)
          ON CONFLICT(metric, category) DO UPDATE SET
            count = count + excluded.count,
            updated_at = excluded.updated_at
          ''',
          [
            delta['metric'],
            delta['category'],
            delta['count'],
            delta['updated_at'],
          ],
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> loadGroundingMetrics() async {
    final database = await _databaseProvider();
    return database.query(
      'grounding_metric_counters',
      orderBy: 'metric ASC, category ASC',
    );
  }
}
