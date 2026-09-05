import 'package:stars/data/services/local_database_service.dart';
import 'package:stars/domain/models/grounding_metrics.dart';
import 'package:stars/domain/repositories/grounding_metrics_repository.dart';

final class SqliteGroundingMetricsRepository
    implements GroundingMetricsRepository {
  const SqliteGroundingMetricsRepository({
    required LocalDatabaseService localDatabase,
  }) : _localDatabase = localDatabase;

  final LocalDatabaseService _localDatabase;

  @override
  Future<void> record(
    Iterable<GroundingMetricDelta> deltas, {
    String observationId = '',
  }) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return _localDatabase.incrementGroundingMetrics([
      for (final delta in deltas)
        <String, Object?>{
          'metric': delta.name.name,
          'category': delta.category,
          'count': delta.count,
          'updated_at': now,
        },
    ], observationId: observationId);
  }

  @override
  Future<GroundingMetricsSnapshot> snapshot() async {
    final rows = await _localDatabase.loadGroundingMetrics();
    final counters = <GroundingMetricName, Map<String, int>>{};
    for (final row in rows) {
      final name = _metricName(row['metric']);
      final category = row['category'];
      final count = row['count'];
      if (name == null || category is! String || count is! int || count < 0) {
        throw const FormatException('Stored grounding metric is invalid.');
      }
      (counters[name] ??= <String, int>{})[category] = count;
    }
    return GroundingMetricsSnapshot(counters);
  }

  GroundingMetricName? _metricName(Object? source) {
    for (final value in GroundingMetricName.values) {
      if (value.name == source) return value;
    }
    return null;
  }
}
