import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/view_models/chat_token_usage_view_model.dart';
import 'package:stars/ui/features/chat/views/token_usage_chart_palette.dart';
import 'package:stars/utils/theme.dart';

export 'token_usage_chart_palette.dart';
part 'token_usage_chart_bars.dart';

enum TokenUsageChartOrientation { horizontal, vertical }

enum TokenUsageSeries { input, output }

class ConversationTokenUsagePanel extends StatelessWidget {
  const ConversationTokenUsagePanel({
    super.key,
    required this.viewModel,
    this.provider = '',
    this.showSectionHeader = true,
  });

  final ChatTokenUsageViewModel viewModel;
  final String provider;
  final bool showSectionHeader;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final hourly = viewModel.granularity == TokenUsageGranularity.hour;
        final selectedDay = viewModel.selectedDay;
        final populatedBuckets = viewModel.visibleBuckets
            .where((bucket) => bucket.usage.hasData)
            .toList(growable: false);
        return Column(
          key: const ValueKey<String>('conversation-token-usage-panel'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSectionHeader) ...[
              const Divider(height: 25),
              Text(
                key: const ValueKey<String>('token-usage-section-title'),
                S.of(context).tokenUsage,
                style: StarsDesktopThemeSpec.sectionTitleStyle(context),
              ),
              const SizedBox(height: 12),
            ],
            if (viewModel.isLoading && viewModel.dailyBuckets.isEmpty)
              const Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              _InspectorTokenUsageSummary(usage: viewModel.visibleTotalUsage),
              const Divider(
                key: ValueKey<String>('token-usage-section-divider'),
                height: 25,
              ),
              TokenUsageTimelineSection(
                dailyBuckets: viewModel.dailyBuckets,
                visibleBuckets: populatedBuckets,
                granularity: viewModel.granularity,
                selectedDay: selectedDay,
                palette: TokenUsageChartPalette.fromProvider(context, provider),
                onShowDaily: viewModel.showDaily,
                chartOrientation: TokenUsageChartOrientation.vertical,
                onBucketSelected:
                    hourly
                        ? null
                        : (bucket) => viewModel.selectDay(bucket.start),
              ),
            ],
          ],
        );
      },
    );
  }
}

class TokenUsageTimelineSection extends StatelessWidget {
  const TokenUsageTimelineSection({
    super.key,
    required this.dailyBuckets,
    required this.visibleBuckets,
    required this.granularity,
    required this.selectedDay,
    required this.onShowDaily,
    this.palette,
    this.onBucketSelected,
    this.chartOrientation = TokenUsageChartOrientation.horizontal,
  });

  final List<TokenUsageBucket> dailyBuckets;
  final List<TokenUsageBucket> visibleBuckets;
  final TokenUsageGranularity granularity;
  final DateTime? selectedDay;
  final VoidCallback onShowDaily;
  final TokenUsageChartPalette? palette;
  final ValueChanged<TokenUsageBucket>? onBucketSelected;
  final TokenUsageChartOrientation chartOrientation;

  @override
  Widget build(BuildContext context) {
    final hourly = granularity == TokenUsageGranularity.hour;
    final locale = Localizations.localeOf(context).toString();
    final resolvedPalette =
        palette ?? TokenUsageChartPalette.fromProvider(context, '');
    return Column(
      key: const ValueKey<String>('token-usage-timeline-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          key: const ValueKey<String>('token-usage-granularity-header'),
          children: [
            Expanded(
              child: Text(
                key: const ValueKey<String>('token-usage-granularity-title'),
                hourly
                    ? S.of(context).hourlyTokenUsage
                    : S.of(context).dailyTokenUsage,
                style: StarsDesktopThemeSpec.sectionTitleStyle(context),
              ),
            ),
            if (hourly)
              StarsDesktopIconAction(
                key: const ValueKey<String>('token-usage-back-to-daily'),
                icon: LucideIcons.arrowLeft,
                label: S.of(context).backToDailyUsage,
                onPressed: onShowDaily,
                iconSize: 18,
              ),
          ],
        ),
        if (selectedDay != null) ...[
          const SizedBox(height: 2),
          Text(
            DateFormat.yMMMd(locale).format(selectedDay!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else if (dailyBuckets.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            key: const ValueKey<String>('token-usage-drilldown-hint'),
            S.of(context).clickDayForHourlyUsage,
            style: StarsDesktopThemeSpec.metaStyle(context),
          ),
        ],
        const SizedBox(height: 16),
        _TokenUsageSeriesCard(
          key: const ValueKey<String>('token-usage-input-section'),
          series: TokenUsageSeries.input,
          total: _seriesTotal(visibleBuckets, TokenUsageSeries.input),
          color: resolvedPalette.input,
          child: TokenUsageChart(
            buckets: visibleBuckets,
            granularity: granularity,
            series: TokenUsageSeries.input,
            palette: resolvedPalette,
            onBucketSelected: onBucketSelected,
            orientation: chartOrientation,
          ),
        ),
        const SizedBox(height: 16),
        _TokenUsageSeriesCard(
          key: const ValueKey<String>('token-usage-output-section'),
          series: TokenUsageSeries.output,
          total: _seriesTotal(visibleBuckets, TokenUsageSeries.output),
          color: resolvedPalette.output,
          child: TokenUsageChart(
            buckets: visibleBuckets,
            granularity: granularity,
            series: TokenUsageSeries.output,
            palette: resolvedPalette,
            onBucketSelected: onBucketSelected,
            orientation: chartOrientation,
          ),
        ),
      ],
    );
  }
}

class _TokenUsageSeriesCard extends StatelessWidget {
  const _TokenUsageSeriesCard({
    super.key,
    required this.series,
    required this.total,
    required this.color,
    required this.child,
  });

  final TokenUsageSeries series;
  final int total;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.of(context);
    final tokens = StarsDesktopTokens.of(context);
    final numberFormat = NumberFormat.compact(
      locale: Localizations.localeOf(context).toString(),
    );
    final label = _seriesLabel(context, series);
    return Semantics(
      container: true,
      label: '$label ${numberFormat.format(total)}',
      child: ShadCard(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        backgroundColor: shadTheme.colorScheme.secondary,
        radius: StarsDesktopThemeSpec.containerRadius,
        border: ShadBorder.all(color: tokens.separator, width: 1),
        columnCrossAxisAlignment: CrossAxisAlignment.stretch,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  key: ValueKey<String>(
                    'token-usage-${series.name}-legend-swatch',
                  ),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    key: ValueKey<String>(
                      'token-usage-${series.name}-section-title',
                    ),
                    label,
                    style: shadTheme.textTheme.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  numberFormat.format(total),
                  style: shadTheme.textTheme.muted.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _InspectorTokenUsageSummary extends StatelessWidget {
  const _InspectorTokenUsageSummary({required this.usage});

  final ModelTokenUsage usage;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact(
      locale: Localizations.localeOf(context).toString(),
    );
    return Semantics(
      container: true,
      label:
          '${S.of(context).tokenUsage}: '
          '${S.of(context).totalTokens} ${usage.effectiveTotalTokens}, '
          '${S.of(context).inputTokens} ${usage.inputTokens}, '
          '${S.of(context).outputTokens} ${usage.outputTokens}',
      hint:
          '${S.of(context).totalTokensDescription} '
          '${S.of(context).inputTokensDescription} '
          '${S.of(context).outputTokensDescription}',
      child: ExcludeSemantics(
        child: StarsDesktopSettingsGroup(
          key: const ValueKey<String>('inspector-token-usage-summary'),
          children: [
            _InspectorTokenMetric(
              key: const ValueKey<String>('inspector-token-usage-total'),
              icon: Icons.data_usage_rounded,
              label: S.of(context).totalTokens,
              description: S.of(context).totalTokensDescription,
              value: numberFormat.format(usage.effectiveTotalTokens),
            ),
            _InspectorTokenMetric(
              key: const ValueKey<String>('inspector-token-usage-input'),
              icon: Icons.login_rounded,
              label: S.of(context).inputTokens,
              description: S.of(context).inputTokensDescription,
              value: numberFormat.format(usage.inputTokens),
            ),
            _InspectorTokenMetric(
              key: const ValueKey<String>('inspector-token-usage-output'),
              icon: Icons.logout_rounded,
              label: S.of(context).outputTokens,
              description: S.of(context).outputTokensDescription,
              value: numberFormat.format(usage.outputTokens),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectorTokenMetric extends StatelessWidget {
  const _InspectorTokenMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String description;
  final String value;

  @override
  Widget build(BuildContext context) => StarsInspectorInfoRow(
    icon: icon,
    label: label,
    description: description,
    value: value,
    layout: StarsInspectorInfoRowLayout.settings,
  );
}
