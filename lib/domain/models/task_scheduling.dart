import 'package:stars/domain/models/conversation_task.dart';

/// Limits count live database leases, including workers in other processes.
final class TaskConcurrencyLimits {
  const TaskConcurrencyLimits({this.global = 4, this.perProvider = 2})
    : assert(global > 0),
      assert(perProvider > 0);
  final int global;
  final int perProvider;
}

/// A recoverable configuration obstacle. Never contains credentials or errors
/// received verbatim from a provider or tool.
final class TaskRuntimeUnavailable implements Exception {
  const TaskRuntimeUnavailable(this.reason, this.code);
  final TaskWaitingReason reason;
  final String code;
}

/// Content-free observations for an application scheduler's lifetime.
final class TaskSchedulingMetrics {
  int segments = 0, recoveries = 0, retries = 0, leaseExpirations = 0;
  int noProgress = 0, reconciliationFailures = 0, failures = 0;
  Duration queueTime = Duration.zero;
  Duration executionTime = Duration.zero;
  Duration waitingTime = Duration.zero;
}
