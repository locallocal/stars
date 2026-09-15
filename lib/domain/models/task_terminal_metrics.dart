/// Content-free counters; no prompts, tool arguments or Provider responses.
final class TaskTerminalMetrics {
  int committed = 0, conflicts = 0, narrationAttempts = 0;
  int narrationFailures = 0, narrationFallbacks = 0;
  int verifiedClaims = 0, factualClaims = 0, suppressedClaims = 0;
  Duration commitLatency = Duration.zero;

  double get fallbackRatio =>
      narrationAttempts == 0 ? 0 : narrationFallbacks / narrationAttempts;
  double get evidenceCoverage =>
      factualClaims == 0 ? 0 : verifiedClaims / factualClaims;
}
