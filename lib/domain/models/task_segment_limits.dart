/// Bounds one execution segment or attempt, never the lifetime of a task.
final class TaskSegmentLimits {
  TaskSegmentLimits({
    this.maxModelTurns = 32,
    this.maxToolCalls = 48,
    this.maxSameCallRetries = 4,
    this.maxConsecutiveToolFailures = 8,
    this.maxReliabilityRepairs = 3,
    this.maxPlanRevisions = 8,
    this.maxNoProgressSegments = 8,
    this.providerTimeout = const Duration(minutes: 15),
    this.toolTimeout = const Duration(minutes: 15),
    this.pollTimeout = const Duration(minutes: 5),
    this.reconcileTimeout = const Duration(minutes: 15),
    this.initialBackoff = const Duration(seconds: 15),
    this.maxBackoff = const Duration(minutes: 30),
  }) {
    for (final entry
        in <String, int>{
          'maxModelTurns': maxModelTurns,
          'maxToolCalls': maxToolCalls,
          'maxSameCallRetries': maxSameCallRetries,
          'maxConsecutiveToolFailures': maxConsecutiveToolFailures,
          'maxReliabilityRepairs': maxReliabilityRepairs,
          'maxPlanRevisions': maxPlanRevisions,
          'maxNoProgressSegments': maxNoProgressSegments,
        }.entries) {
      RangeError.checkValueInInterval(
        entry.value,
        1,
        countHardLimit,
        entry.key,
      );
    }
    for (final entry
        in <String, Duration>{
          'providerTimeout': providerTimeout,
          'toolTimeout': toolTimeout,
          'pollTimeout': pollTimeout,
          'reconcileTimeout': reconcileTimeout,
          'initialBackoff': initialBackoff,
          'maxBackoff': maxBackoff,
        }.entries) {
      RangeError.checkValueInInterval(
        entry.value.inMicroseconds,
        1,
        durationHardLimit.inMicroseconds,
        entry.key,
      );
    }
    if (initialBackoff > maxBackoff) {
      throw ArgumentError('Initial backoff must not exceed maximum backoff.');
    }
  }

  // Deliberately generous safety caps; neither is an aggregate task budget.
  static const countHardLimit = 4096;
  static const durationHardLimit = Duration(hours: 24);

  final int maxModelTurns;
  final int maxToolCalls;
  final int maxSameCallRetries;
  final int maxConsecutiveToolFailures;
  final int maxReliabilityRepairs;
  final int maxPlanRevisions;
  final int maxNoProgressSegments;
  final Duration providerTimeout;
  final Duration toolTimeout;
  final Duration pollTimeout;
  final Duration reconcileTimeout;
  final Duration initialBackoff;
  final Duration maxBackoff;
}
