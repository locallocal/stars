import 'package:stars/domain/models/task_scheduling.dart';
import 'package:stars/domain/models/task_terminal_metrics.dart';
import 'package:stars/domain/use_cases/conversation_turn_dispatcher.dart';
import 'package:stars/domain/use_cases/narrate_conversation_task_progress.dart';

/// Bounded, content-free observations for one application lifetime. Durable
/// per-task counters remain in task events; this object never retains identities.
final class ConversationTaskTelemetry {
  final scheduling = TaskSchedulingMetrics();
  final progress = TaskProgressMetrics();
  final terminal = TaskTerminalMetrics();
  int _dispatches = 0, _mainCalls = 0, _firstCharacters = 0;
  int _directCompletions = 0, _acknowledgements = 0;
  int _routingFallbacks = 0, _acknowledgementFallbacks = 0;
  Duration _firstCharacterLatency = Duration.zero;
  Duration _directCompletionLatency = Duration.zero;
  Duration _acknowledgementLatency = Duration.zero;

  void recordDispatch(TurnDispatchMetrics metrics) {
    _dispatches++;
    _mainCalls += metrics.mainReplyCalls;
    _routingFallbacks += metrics.routingFallbacks;
    _acknowledgementFallbacks += metrics.acknowledgementFallbacks;
    if (metrics.directFirstCharacterLatency case final latency?) {
      _firstCharacters++;
      _firstCharacterLatency += latency;
    }
    if (metrics.directCompletionLatency case final latency?) {
      _directCompletions++;
      _directCompletionLatency += latency;
    }
    if (metrics.acknowledgementCommitLatency case final latency?) {
      _acknowledgements++;
      _acknowledgementLatency += latency;
    }
  }

  /// Fixed numeric keys only: safe to export without prompts, task IDs, provider
  /// configuration, tool arguments, reasoning, or an unbounded event buffer.
  Map<String, num> snapshot() => Map.unmodifiable({
    'foreground.dispatches': _dispatches,
    'foreground.mainCalls': _mainCalls,
    'foreground.firstCharacters': _firstCharacters,
    'foreground.firstCharacterUs': _firstCharacterLatency.inMicroseconds,
    'foreground.directCompletions': _directCompletions,
    'foreground.directCompletionUs': _directCompletionLatency.inMicroseconds,
    'foreground.acknowledgements': _acknowledgements,
    'foreground.acknowledgementUs': _acknowledgementLatency.inMicroseconds,
    'foreground.routingFallbacks': _routingFallbacks,
    'foreground.acknowledgementFallbacks': _acknowledgementFallbacks,
    'progress.cards': progress.cards,
    'progress.cardReadyUs': progress.cardLatency.inMicroseconds,
    'progress.narrationUs': progress.narrationLatency.inMicroseconds,
    'progress.narrationFailures': progress.failures,
    'progress.failureRatio': progress.failureRatio,
    'scheduling.queueUs': scheduling.queueTime.inMicroseconds,
    'scheduling.executionUs': scheduling.executionTime.inMicroseconds,
    'scheduling.waitingUs': scheduling.waitingTime.inMicroseconds,
    'scheduling.segments': scheduling.segments,
    'scheduling.recoveries': scheduling.recoveries,
    'scheduling.retries': scheduling.retries,
    'scheduling.leaseExpirations': scheduling.leaseExpirations,
    'scheduling.noProgressSegments': scheduling.noProgress,
    'scheduling.reconciliationFailures': scheduling.reconciliationFailures,
    'scheduling.failures': scheduling.failures,
    'terminal.committed': terminal.committed,
    'terminal.succeeded': terminal.succeeded,
    'terminal.failed': terminal.failed,
    'terminal.cancelled': terminal.cancelled,
    'terminal.noProgressFailures': terminal.noProgressFailures,
    'terminal.commitUs': terminal.commitLatency.inMicroseconds,
    'terminal.failureCommitUs': terminal.failureCommitLatency.inMicroseconds,
    'terminal.cancellationUs': terminal.cancellationLatency.inMicroseconds,
    'terminal.endToEndUs': terminal.endToEndLatency.inMicroseconds,
    'terminal.narrationFailures': terminal.narrationFailures,
    'terminal.fallbackRatio': terminal.fallbackRatio,
    'terminal.evidenceCoverage': terminal.evidenceCoverage,
    'terminal.suppressedClaims': terminal.suppressedClaims,
  });
}
