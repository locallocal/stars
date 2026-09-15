part of 'token_usage_chart.dart';

class TokenUsageChart extends StatelessWidget {
  const TokenUsageChart({
    super.key,
    required this.buckets,
    required this.granularity,
    required this.series,
    this.palette,
    this.onBucketSelected,
    this.orientation = TokenUsageChartOrientation.horizontal,
  });

  final List<TokenUsageBucket> buckets;
  final TokenUsageGranularity granularity;
  final TokenUsageSeries series;
  final TokenUsageChartPalette? palette;
  final ValueChanged<TokenUsageBucket>? onBucketSelected;
  final TokenUsageChartOrientation orientation;

  @override
  Widget build(BuildContext context) {
    final resolvedPalette =
        palette ?? TokenUsageChartPalette.fromProvider(context, '');
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
        color: _seriesColor(resolvedPalette, series),
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
              color: _seriesColor(resolvedPalette, series),
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
            color: _seriesColor(resolvedPalette, series),
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
    required this.color,
    required this.onBucketSelected,
  });

  final List<TokenUsageBucket> buckets;
  final int maximum;
  final TokenUsageGranularity granularity;
  final TokenUsageSeries series;
  final Color color;
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
                color: color,
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
    required this.color,
    this.onTap,
  });

  final TokenUsageBucket bucket;
  final int maximum;
  final String bucketKey;
  final String barKey;
  final String label;
  final TokenUsageSeries series;
  final Color color;
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
    required this.color,
    this.onTap,
  });

  final TokenUsageBucket bucket;
  final int maximum;
  final String bucketKey;
  final String barKey;
  final String label;
  final TokenUsageSeries series;
  final Color color;
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

Color _seriesColor(TokenUsageChartPalette palette, TokenUsageSeries series) {
  return switch (series) {
    TokenUsageSeries.input => palette.input,
    TokenUsageSeries.output => palette.output,
  };
}

String _tokenUsageDateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
