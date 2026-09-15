/// Content-free counters; no prompts, tool arguments or Provider responses.
final class TaskTerminalMetrics {
  int committed = 0, conflicts = 0, narrationAttempts = 0;
  int narrationFailures = 0, narrationFallbacks = 0;
  int verifiedClaims = 0, factualClaims = 0, suppressedClaims = 0;
  int succeeded = 0, failed = 0, cancelled = 0, noProgressFailures = 0;
  Duration commitLatency = Duration.zero, failureCommitLatency = Duration.zero;
  Duration cancellationLatency = Duration.zero, endToEndLatency = Duration.zero;

  double get fallbackRatio =>
      narrationAttempts == 0 ? 0 : narrationFallbacks / narrationAttempts;
  double get evidenceCoverage =>
      factualClaims == 0 ? 0 : verifiedClaims / factualClaims;
}
