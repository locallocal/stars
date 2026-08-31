import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/view_models/chat_token_usage_view_model.dart';
import 'package:stars/utils/theme.dart';

enum TokenUsageChartOrientation { horizontal, vertical }

enum TokenUsageSeries { input, output }

class ConversationTokenUsagePanel extends StatelessWidget {
  const ConversationTokenUsagePanel({super.key, required this.viewModel});

  final ChatTokenUsageViewModel viewModel;

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
            const Divider(height: 25),
            Text(
              key: const ValueKey<String>('token-usage-section-title'),
              S.of(context).tokenUsage,
              style: StarsDesktopThemeSpec.sectionTitleStyle(context),
            ),
            const SizedBox(height: 12),
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
                onShowDaily: viewModel.showDaily,
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
    this.onBucketSelected,
    this.chartOrientation = TokenUsageChartOrientation.horizontal,
  });

  final List<TokenUsageBucket> dailyBuckets;
  final List<TokenUsageBucket> visibleBuckets;
  final TokenUsageGranularity granularity;
  final DateTime? selectedDay;
  final VoidCallback onShowDaily;
  final ValueChanged<TokenUsageBucket>? onBucketSelected;
  final TokenUsageChartOrientation chartOrientation;

  @override
  Widget build(BuildContext context) {
    final hourly = granularity == TokenUsageGranularity.hour;
    final locale = Localizations.localeOf(context).toString();
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
          child: TokenUsageChart(
            buckets: visibleBuckets,
            granularity: granularity,
            series: TokenUsageSeries.input,
            onBucketSelected: onBucketSelected,
            orientation: chartOrientation,
          ),
        ),
        const SizedBox(height: 16),
        _TokenUsageSeriesCard(
          key: const ValueKey<String>('token-usage-output-section'),
          series: TokenUsageSeries.output,
          total: _seriesTotal(visibleBuckets, TokenUsageSeries.output),
          child: TokenUsageChart(
            buckets: visibleBuckets,
            granularity: granularity,
            series: TokenUsageSeries.output,
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
    required this.child,
  });

  final TokenUsageSeries series;
  final int total;
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
        backgroundColor: tokens.raisedSurface,
        radius: StarsDesktopThemeSpec.containerRadius,
        border: ShadBorder.all(color: tokens.separator, width: 1),
        columnCrossAxisAlignment: CrossAxisAlignment.stretch,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _seriesColor(context, series),
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
      child: ExcludeSemantics(
        child: Column(
          key: const ValueKey<String>('inspector-token-usage-summary'),
          children: [
            _InspectorTokenMetric(
              key: const ValueKey<String>('inspector-token-usage-total'),
              icon: Icons.data_usage_rounded,
              label: S.of(context).totalTokens,
              value: numberFormat.format(usage.effectiveTotalTokens),
            ),
            _InspectorTokenMetric(
              key: const ValueKey<String>('inspector-token-usage-input'),
              icon: Icons.login_rounded,
              label: S.of(context).inputTokens,
              value: numberFormat.format(usage.inputTokens),
            ),
            _InspectorTokenMetric(
              key: const ValueKey<String>('inspector-token-usage-output'),
              icon: Icons.logout_rounded,
              label: S.of(context).outputTokens,
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
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) =>
      StarsInspectorInfoRow(icon: icon, label: label, value: value);
}

class TokenUsageChart extends StatelessWidget {
  const TokenUsageChart({
    super.key,
    required this.buckets,
    required this.granularity,
    required this.series,
    this.onBucketSelected,
    this.orientation = TokenUsageChartOrientation.horizontal,
  });

  final List<TokenUsageBucket> buckets;
  final TokenUsageGranularity granularity;
  final TokenUsageSeries series;
  final ValueChanged<TokenUsageBucket>? onBucketSelected;
  final TokenUsageChartOrientation orientation;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return SizedBox(
        key: ValueKey<String>('token-usage-${series.name}-chart-empty'),
        height: 150,
        child: Center(child: Text(S.of(context).noTokenUsageRecorded)),
      );
    }

    final maximum = buckets.fold<int>(0, (value, bucket) {
      return math.max(value, _seriesValue(bucket.usage, series));
    });
    final locale = Localizations.localeOf(context).toString();
    final isDaily = granularity == TokenUsageGranularity.day;

    if (orientation == TokenUsageChartOrientation.vertical) {
      return _VerticalTokenUsageChart(
        buckets: buckets,
        maximum: maximum,
        granularity: granularity,
        series: series,
        onBucketSelected: onBucketSelected,
      );
    }

    if (isDaily) {
      return Column(
        key: ValueKey<String>('token-usage-${series.name}-chart'),
        children: [
          for (final bucket in buckets)
            _HorizontalTokenUsageBar(
              bucket: bucket,
              maximum: maximum,
              bucketKey:
                  'token-usage-${series.name}-bucket-day-'
                  '${_tokenUsageDateKey(bucket.start)}',
              barKey:
                  'token-usage-${series.name}-bar-day-'
                  '${_tokenUsageDateKey(bucket.start)}',
              label: DateFormat.Md(locale).format(bucket.start),
              series: series,
              onTap:
                  onBucketSelected == null
                      ? null
                      : () => onBucketSelected!(bucket),
            ),
        ],
      );
    }

    return Column(
      key: ValueKey<String>('token-usage-${series.name}-chart'),
      children: [
        for (final bucket in buckets)
          _HorizontalTokenUsageBar(
            bucket: bucket,
            maximum: maximum,
            bucketKey:
                'token-usage-${series.name}-bucket-hour-${bucket.start.hour}',
            barKey: 'token-usage-${series.name}-bar-hour-${bucket.start.hour}',
            label: '${bucket.start.hour.toString().padLeft(2, '0')}:00',
            series: series,
          ),
      ],
    );
  }
}

class _VerticalTokenUsageChart extends StatelessWidget {
  const _VerticalTokenUsageChart({
    required this.buckets,
    required this.maximum,
    required this.granularity,
    required this.series,
    required this.onBucketSelected,
  });

  final List<TokenUsageBucket> buckets;
  final int maximum;
  final TokenUsageGranularity granularity;
  final TokenUsageSeries series;
  final ValueChanged<TokenUsageBucket>? onBucketSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isDaily = granularity == TokenUsageGranularity.day;
    final minimumSlotWidth = isDaily ? 64.0 : 50.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.hasBoundedWidth
                ? constraints.maxWidth
                : minimumSlotWidth * buckets.length;
        final slotWidth = math.max(
          minimumSlotWidth,
          availableWidth / buckets.length,
        );
        return SizedBox(
          key: ValueKey<String>('token-usage-${series.name}-chart'),
          height: 176,
          child: ListView.builder(
            key: ValueKey<String>('token-usage-${series.name}-chart-vertical'),
            scrollDirection: Axis.horizontal,
            itemCount: buckets.length,
            itemExtent: slotWidth,
            itemBuilder: (context, index) {
              final bucket = buckets[index];
              final bucketKey =
                  isDaily
                      ? 'token-usage-${series.name}-bucket-day-'
                          '${_tokenUsageDateKey(bucket.start)}'
                      : 'token-usage-${series.name}-bucket-hour-'
                          '${bucket.start.hour}';
              final barKey =
                  isDaily
                      ? 'token-usage-${series.name}-bar-day-'
                          '${_tokenUsageDateKey(bucket.start)}'
                      : 'token-usage-${series.name}-bar-hour-'
                          '${bucket.start.hour}';
              final label =
                  isDaily
                      ? DateFormat.Md(locale).format(bucket.start)
                      : '${bucket.start.hour.toString().padLeft(2, '0')}:00';
              return _VerticalTokenUsageBar(
                bucket: bucket,
                maximum: maximum,
                bucketKey: bucketKey,
                barKey: barKey,
                label: label,
                series: series,
                onTap:
                    onBucketSelected == null
                        ? null
                        : () => onBucketSelected!(bucket),
              );
            },
          ),
        );
      },
    );
  }
}

class _VerticalTokenUsageBar extends StatelessWidget {
  const _VerticalTokenUsageBar({
    required this.bucket,
    required this.maximum,
    required this.bucketKey,
    required this.barKey,
    required this.label,
    required this.series,
    this.onTap,
  });

  final TokenUsageBucket bucket;
  final int maximum;
  final String bucketKey;
  final String barKey;
  final String label;
  final TokenUsageSeries series;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = _visibleUsageLabel(
      context,
      label: label,
      usage: bucket.usage,
      series: series,
    );
    final colors = Theme.of(context).colorScheme;
    final numberFormat = NumberFormat.compact(
      locale: Localizations.localeOf(context).toString(),
    );
    final value = _seriesValue(bucket.usage, series);
    final color = _seriesColor(context, series);

    return ShadTooltip(
      builder: (context) => Text(semanticsLabel),
      child: Semantics(
        button: onTap != null,
        label: semanticsLabel,
        child: GestureDetector(
          key: ValueKey<String>(bucketKey),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              children: [
                SizedBox(
                  height: 144,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final height =
                          value == 0 || maximum == 0
                              ? 2.0
                              : math.max(
                                6.0,
                                (constraints.maxHeight - 24) * value / maximum,
                              );
                      return Column(
                        children: [
                          SizedBox(
                            height: 20,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                numberFormat.format(value),
                                maxLines: 1,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                key: ValueKey<String>(barKey),
                                width: 18,
                                height: height,
                                decoration: BoxDecoration(
                                  color:
                                      value == 0
                                          ? colors.surfaceContainerHighest
                                          : color,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalTokenUsageBar extends StatelessWidget {
  const _HorizontalTokenUsageBar({
    required this.bucket,
    required this.maximum,
    required this.bucketKey,
    required this.barKey,
    required this.label,
    required this.series,
    this.onTap,
  });

  final TokenUsageBucket bucket;
  final int maximum;
  final String bucketKey;
  final String barKey;
  final String label;
  final TokenUsageSeries series;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semanticsLabel = _visibleUsageLabel(
      context,
      label: label,
      usage: bucket.usage,
      series: series,
    );
    final colors = Theme.of(context).colorScheme;
    final numberFormat = NumberFormat.compact(
      locale: Localizations.localeOf(context).toString(),
    );
    final value = _seriesValue(bucket.usage, series);
    final color = _seriesColor(context, series);

    return ShadTooltip(
      builder: (context) => Text(semanticsLabel),
      child: Semantics(
        button: onTap != null,
        label: semanticsLabel,
        child: GestureDetector(
          key: ValueKey<String>(bucketKey),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 38,
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  child: _HorizontalTokenUsageSeriesBar(
                    key: ValueKey<String>(barKey),
                    value: value,
                    maximum: maximum,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 42,
                  child: Text(
                    numberFormat.format(value),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalTokenUsageSeriesBar extends StatelessWidget {
  const _HorizontalTokenUsageSeriesBar({
    super.key,
    required this.value,
    required this.maximum,
    required this.color,
  });

  final int value;
  final int maximum;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 12,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              value == 0 || maximum == 0
                  ? 2.0
                  : math.max(4.0, constraints.maxWidth * value / maximum);
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: value == 0 ? colors.surfaceContainerHighest : color,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(4),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _visibleUsageLabel(
  BuildContext context, {
  required String label,
  required ModelTokenUsage usage,
  required TokenUsageSeries series,
}) {
  return '$label, ${_seriesLabel(context, series)} '
      '${_seriesValue(usage, series)}';
}

int _seriesTotal(Iterable<TokenUsageBucket> buckets, TokenUsageSeries series) {
  return buckets.fold<int>(
    0,
    (total, bucket) => total + _seriesValue(bucket.usage, series),
  );
}

int _seriesValue(ModelTokenUsage usage, TokenUsageSeries series) {
  return switch (series) {
    TokenUsageSeries.input => usage.inputTokens,
    TokenUsageSeries.output => usage.outputTokens,
  };
}

String _seriesLabel(BuildContext context, TokenUsageSeries series) {
  return switch (series) {
    TokenUsageSeries.input => S.of(context).inputTokens,
    TokenUsageSeries.output => S.of(context).outputTokens,
  };
}

Color _seriesColor(BuildContext context, TokenUsageSeries series) {
  return switch (series) {
    TokenUsageSeries.input => StarsDesktopThemeSpec.primaryActionColor(context),
    TokenUsageSeries.output => StarsDesktopTokens.of(context).secondaryText,
  };
}

String _tokenUsageDateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
