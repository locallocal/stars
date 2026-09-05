import 'package:stars/domain/models/grounding_metrics.dart';

abstract interface class GroundingMetricsRepository {
  Future<void> record(
    Iterable<GroundingMetricDelta> deltas, {
    String observationId = '',
  });

  Future<GroundingMetricsSnapshot> snapshot();
}
