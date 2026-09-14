import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/task_segment_limits.dart';

void main() {
  test('background defaults match the segment specification', () {
    final limits = TaskSegmentLimits();
    expect(
      [
        limits.maxModelTurns,
        limits.maxToolCalls,
        limits.maxSameCallRetries,
        limits.maxConsecutiveToolFailures,
        limits.maxReliabilityRepairs,
        limits.maxPlanRevisions,
        limits.maxNoProgressSegments,
      ],
      [32, 48, 4, 8, 3, 8, 8],
    );
    expect(limits.providerTimeout, const Duration(minutes: 15));
    expect(limits.toolTimeout, const Duration(minutes: 15));
    expect(limits.reconcileTimeout, const Duration(minutes: 15));
    expect(limits.pollTimeout, const Duration(minutes: 5));
    expect(limits.initialBackoff, const Duration(seconds: 15));
    expect(limits.maxBackoff, const Duration(minutes: 30));
  });
  final counters = <String, TaskSegmentLimits Function(int)>{
    'model turns': (n) => TaskSegmentLimits(maxModelTurns: n),
    'tool calls': (n) => TaskSegmentLimits(maxToolCalls: n),
    'same call retries': (n) => TaskSegmentLimits(maxSameCallRetries: n),
    'consecutive failures':
        (n) => TaskSegmentLimits(maxConsecutiveToolFailures: n),
    'repairs': (n) => TaskSegmentLimits(maxReliabilityRepairs: n),
    'revisions': (n) => TaskSegmentLimits(maxPlanRevisions: n),
    'no progress': (n) => TaskSegmentLimits(maxNoProgressSegments: n),
  };
  for (final entry in counters.entries) {
    test(
      '${entry.key} rejects nonpositive and excessive overrides at runtime',
      () {
        for (final value in [-1, 0, TaskSegmentLimits.countHardLimit + 1]) {
          expect(() => entry.value(value), throwsRangeError);
        }
        expect(() => entry.value(1), returnsNormally);
        expect(
          () => entry.value(TaskSegmentLimits.countHardLimit),
          returnsNormally,
        );
      },
    );
  }
  final timeouts = <String, TaskSegmentLimits Function(Duration)>{
    'provider': (d) => TaskSegmentLimits(providerTimeout: d),
    'tool': (d) => TaskSegmentLimits(toolTimeout: d),
    'poll': (d) => TaskSegmentLimits(pollTimeout: d),
    'reconcile': (d) => TaskSegmentLimits(reconcileTimeout: d),
    'initial backoff':
        (d) => TaskSegmentLimits(
          initialBackoff: d,
          maxBackoff: TaskSegmentLimits.durationHardLimit,
        ),
    'max backoff':
        (d) => TaskSegmentLimits(
          maxBackoff: d,
          initialBackoff: const Duration(microseconds: 1),
        ),
  };
  for (final entry in timeouts.entries) {
    test(
      '${entry.key} validates attempt bounds independently of task lifetime',
      () {
        expect(() => entry.value(Duration.zero), throwsRangeError);
        expect(
          () => entry.value(const Duration(microseconds: -1)),
          throwsRangeError,
        );
        expect(
          () => entry.value(
            TaskSegmentLimits.durationHardLimit +
                const Duration(microseconds: 1),
          ),
          throwsRangeError,
        );
        expect(
          () => entry.value(TaskSegmentLimits.durationHardLimit),
          returnsNormally,
        );
      },
    );
  }
  test('initial retry delay cannot exceed maximum delay', () {
    expect(
      () => TaskSegmentLimits(initialBackoff: const Duration(hours: 1)),
      throwsArgumentError,
    );
  });
}
