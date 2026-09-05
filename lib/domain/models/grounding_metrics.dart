/// Redacted counters used to monitor the conversation grounding protocol.
enum GroundingMetricName {
  unsupportedClaimPass,
  evidenceReferenceTotal,
  evidenceReferenceResolved,
  verifiedEvidenceRequired,
  verifiedEvidencePersisted,
  duplicateSideEffect,
  gateRejection,
  providerFailure,
}

/// One aggregate counter update. Categories are application-owned codes only.
final class GroundingMetricDelta {
  GroundingMetricDelta({
    required this.name,
    this.category = '',
    this.count = 1,
  }) {
    if (count < 1) {
      throw ArgumentError.value(
        count,
        'count',
        'Metric counts must be positive.',
      );
    }
    if (category.isNotEmpty &&
        !RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(category)) {
      throw ArgumentError.value(
        category,
        'category',
        'Metric categories must be redacted application identifiers.',
      );
    }
  }

  final GroundingMetricName name;
  final String category;
  final int count;
}

/// Immutable aggregate values read by diagnostics and release gates.
final class GroundingMetricsSnapshot {
  GroundingMetricsSnapshot(Map<GroundingMetricName, Map<String, int>> counters)
    : counters = Map<GroundingMetricName, Map<String, int>>.unmodifiable({
        for (final entry in counters.entries)
          entry.key: Map<String, int>.unmodifiable(entry.value),
      });

  GroundingMetricsSnapshot.empty()
    : counters = const <GroundingMetricName, Map<String, int>>{};

  final Map<GroundingMetricName, Map<String, int>> counters;

  int total(GroundingMetricName name) {
    final values = counters[name]?.values;
    if (values == null) return 0;
    return values.fold<int>(0, (sum, value) => sum + value);
  }

  double get evidenceReferenceResolutionRate => _rate(
    total(GroundingMetricName.evidenceReferenceResolved),
    total(GroundingMetricName.evidenceReferenceTotal),
  );

  double get verifiedEvidencePersistenceRate => _rate(
    total(GroundingMetricName.verifiedEvidencePersisted),
    total(GroundingMetricName.verifiedEvidenceRequired),
  );

  static double _rate(int numerator, int denominator) =>
      denominator == 0 ? 1 : numerator / denominator;
}

enum GroundingReleaseInvariant {
  unsupportedClaimPasses,
  verifiedEvidencePersistence,
  duplicateSideEffects,
}

final class GroundingReleaseGateResult {
  GroundingReleaseGateResult(Iterable<GroundingReleaseInvariant> violations)
    : violations = List<GroundingReleaseInvariant>.unmodifiable(violations);

  final List<GroundingReleaseInvariant> violations;

  bool get passes => violations.isEmpty;

  void requirePass() {
    if (!passes) {
      throw StateError(
        'Grounding release gate failed: '
        '${violations.map((item) => item.name).join(', ')}',
      );
    }
  }
}

/// The three non-negotiable reliability invariants for a release.
final class GroundingReleaseGate {
  const GroundingReleaseGate();

  GroundingReleaseGateResult evaluate(GroundingMetricsSnapshot snapshot) {
    return GroundingReleaseGateResult([
      if (snapshot.total(GroundingMetricName.unsupportedClaimPass) != 0)
        GroundingReleaseInvariant.unsupportedClaimPasses,
      if (snapshot.total(GroundingMetricName.verifiedEvidenceRequired) !=
          snapshot.total(GroundingMetricName.verifiedEvidencePersisted))
        GroundingReleaseInvariant.verifiedEvidencePersistence,
      if (snapshot.total(GroundingMetricName.duplicateSideEffect) != 0)
        GroundingReleaseInvariant.duplicateSideEffects,
    ]);
  }
}
