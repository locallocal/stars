import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/ui/core/widgets/logo.dart';
import 'package:stars/utils/theme.dart';

/// Theme-aware colors shared by daily and hourly token usage charts.
@immutable
class TokenUsageChartPalette {
  const TokenUsageChartPalette({required this.input, required this.output});

  /// Creates a palette from the provider logo and its avatar background.
  ///
  /// Brand colors are adjusted only when needed to preserve non-text contrast
  /// against the shadcn chart card surface.
  factory TokenUsageChartPalette.fromProvider(
    BuildContext context,
    String provider,
  ) {
    final colorScheme = ShadTheme.of(context).colorScheme;
    final tokens = StarsDesktopTokens.of(context);
    final surface = colorScheme.secondary;
    final minimumContrast = tokens.highContrast ? 4.5 : 3.0;

    return TokenUsageChartPalette(
      input: _ensureContrast(
        getProviderLogoColor(provider, colorScheme.foreground),
        surface,
        colorScheme.foreground,
        minimumContrast,
      ),
      output: _ensureContrast(
        getProviderColor(provider, colorScheme.chartColor(1)),
        surface,
        colorScheme.foreground,
        minimumContrast,
      ),
    );
  }

  /// Color mapped to input-token bars and labels.
  final Color input;

  /// Color mapped to output-token bars and labels.
  final Color output;
}

Color _ensureContrast(
  Color source,
  Color surface,
  Color contrastTarget,
  double minimumContrast,
) {
  final opaqueSource = source.withValues(alpha: 1);
  if (_contrastRatio(opaqueSource, surface) >= minimumContrast) {
    return opaqueSource;
  }

  for (var step = 1; step <= 20; step++) {
    final candidate = Color.lerp(opaqueSource, contrastTarget, step / 20)!;
    if (_contrastRatio(candidate, surface) >= minimumContrast) {
      return candidate;
    }
  }
  return contrastTarget;
}

double _contrastRatio(Color first, Color second) {
  final lighter = first.computeLuminance();
  final darker = second.computeLuminance();
  final high = lighter > darker ? lighter : darker;
  final low = lighter > darker ? darker : lighter;
  return (high + 0.05) / (low + 0.05);
}
