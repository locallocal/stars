import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/generated/l10n.dart';
import 'package:stars/ui/core/view_models/token_usage_timeline.dart';
import 'package:stars/ui/core/widgets/token_usage_indicator.dart';
import 'package:stars/ui/features/bots/view_models/bot_token_usage_view_model.dart';
import 'package:stars/ui/features/chat/views/token_usage_chart.dart';
import 'package:stars/utils/theme.dart';

const double _tokenUsagePieSize = 148;

class BotTokenUsagePanel extends StatelessWidget {
  const BotTokenUsagePanel({
    super.key,
    required this.usage,
    required this.conversationUsages,
    this.dailyBuckets = const [],
    this.visibleBuckets = const [],
    this.granularity = TokenUsageGranularity.day,
    this.selectedDay,
    this.onShowDaily,
    this.onBucketSelected,
  });

  static const double _twoColumnMinWidth = 680;

  final ModelTokenUsage usage;
  final List<BotConversationTokenUsage> conversationUsages;
  final List<TokenUsageBucket> dailyBuckets;
  final List<TokenUsageBucket> visibleBuckets;
  final TokenUsageGranularity granularity;
  final DateTime? selectedDay;
  final VoidCallback? onShowDaily;
  final ValueChanged<TokenUsageBucket>? onBucketSelected;

  @override
  Widget build(BuildContext context) {
    final summary = KeyedSubtree(
      key: const ValueKey<String>('bot-token-usage-summary'),
      child: SizedBox(
        height: _tokenUsagePieSize,
        child: TokenUsageIndicator(
          usage: usage,
          showBreakdown: true,
          breakdownLayout: TokenUsageBreakdownLayout.inspector,
        ),
      ),
    );
    final chart = _ConversationTokenShare(
      conversationUsages: conversationUsages,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _twoColumnMinWidth) {
              return Row(
                key: const ValueKey<String>('bot-token-usage-two-columns'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: summary),
                  const SizedBox(width: 32),
                  Expanded(child: chart),
                ],
              );
            }
            return Column(
              key: const ValueKey<String>('bot-token-usage-stacked'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, const SizedBox(height: 24), chart],
            );
          },
        ),
        const Divider(
          key: ValueKey<String>('bot-token-usage-timeline-divider'),
          height: 32,
        ),
        TokenUsageTimelineSection(
          dailyBuckets: dailyBuckets,
          visibleBuckets: visibleBuckets,
          granularity: granularity,
          selectedDay: selectedDay,
          onShowDaily: onShowDaily ?? _noop,
          onBucketSelected: onBucketSelected,
          chartOrientation: TokenUsageChartOrientation.vertical,
        ),
      ],
    );
  }

  static void _noop() {}
}

class _ConversationTokenShare extends StatelessWidget {
  const _ConversationTokenShare({required this.conversationUsages});

  final List<BotConversationTokenUsage> conversationUsages;

  @override
  Widget build(BuildContext context) {
    final entries = conversationUsages
        .where((entry) => entry.usage.effectiveTotalTokens > 0)
        .toList(growable: false);
    final total = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.usage.effectiveTotalTokens,
    );
    final colorScheme = ShadTheme.of(context).colorScheme;
    final colors = [
      for (var index = 0; index < entries.length; index++)
        entries[index].isDeleted
            ? colorScheme.mutedForeground
            : colorScheme.chartColor(index),
    ];
    final labels = [
      for (var index = 0; index < entries.length; index++)
        _conversationLabel(context, entries[index], index),
    ];
    final semanticsLabel =
        entries.isEmpty
            ? '${S.of(context).conversationTokenShare}: '
                '${S.of(context).noTokenUsageRecorded}'
            : [
              S.of(context).conversationTokenShare,
              for (var index = 0; index < entries.length; index++)
                '${labels[index]} '
                    '${_formatPercentage(context, entries[index], total)}',
            ].join(', ');

    return Column(
      key: const ValueKey<String>('bot-conversation-token-share'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: semanticsLabel,
          child: ExcludeSemantics(
            child:
                entries.isEmpty
                    ? const _EmptyPieChart(size: _tokenUsagePieSize)
                    : LayoutBuilder(
                      builder: (context, constraints) {
                        final pie = SizedBox.square(
                          dimension: _tokenUsagePieSize,
                          child: CustomPaint(
                            key: const ValueKey<String>(
                              'bot-conversation-token-pie-chart',
                            ),
                            painter: _ConversationTokenPiePainter(
                              values: [
                                for (final entry in entries)
                                  entry.usage.effectiveTotalTokens,
                              ],
                              colors: colors,
                              separatorColor:
                                  StarsDesktopThemeSpec.raisedSurface(context),
                            ),
                          ),
                        );
                        final legend = _ConversationTokenLegend(
                          entries: entries,
                          labels: labels,
                          colors: colors,
                          total: total,
                        );
                        if (constraints.maxWidth >= 360) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              pie,
                              const SizedBox(width: 18),
                              Expanded(child: legend),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(child: pie),
                            const SizedBox(height: 16),
                            legend,
                          ],
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }
}

class _EmptyPieChart extends StatelessWidget {
  const _EmptyPieChart({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: size,
          child: CustomPaint(
            key: const ValueKey<String>('bot-conversation-token-pie-empty'),
            painter: _EmptyPiePainter(
              color: StarsDesktopThemeSpec.secondarySurface(context),
              separatorColor: StarsDesktopThemeSpec.divider(context),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            S.of(context).noTokenUsageRecorded,
            style: StarsDesktopThemeSpec.metaStyle(context),
          ),
        ),
      ],
    );
  }
}

class _ConversationTokenLegend extends StatelessWidget {
  const _ConversationTokenLegend({
    required this.entries,
    required this.labels,
    required this.colors,
    required this.total,
  });

  final List<BotConversationTokenUsage> entries;
  final List<String> labels;
  final List<Color> colors;
  final int total;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact(
      locale: Localizations.localeOf(context).toString(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < entries.length; index++)
          Padding(
            key: ValueKey<String>(
              'bot-token-usage-conversation-'
              '${entries[index].chatId ?? 'deleted'}',
            ),
            padding: EdgeInsets.only(
              bottom: index == entries.length - 1 ? 0 : 10,
            ),
            child: ShadTooltip(
              builder:
                  (context) => Text(
                    '${labels[index]} · '
                    '${numberFormat.format(entries[index].usage.effectiveTotalTokens)} · '
                    '${_formatPercentage(context, entries[index], total)}',
                  ),
              child: ShadGestureDetector(
                child: Row(
                  children: [
                    Container(
                      key: ValueKey<String>(
                        'bot-token-usage-color-'
                        '${entries[index].chatId ?? 'deleted'}',
                      ),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[index],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        labels[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: StarsDesktopThemeSpec.bodyStyle(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatPercentage(context, entries[index], total),
                      style: StarsDesktopThemeSpec.metaStyle(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _conversationLabel(
  BuildContext context,
  BotConversationTokenUsage entry,
  int index,
) {
  if (entry.isDeleted) return S.of(context).deletedConversations;
  final preview = entry.preview.replaceAll(RegExp(r'\s+'), ' ').trim();
  return preview.isEmpty ? '${S.of(context).chats} ${index + 1}' : preview;
}

String _formatPercentage(
  BuildContext context,
  BotConversationTokenUsage entry,
  int total,
) {
  final percentage =
      total == 0 ? 0.0 : entry.usage.effectiveTotalTokens / total;
  return NumberFormat.decimalPercentPattern(
    locale: Localizations.localeOf(context).toString(),
    decimalDigits: 1,
  ).format(percentage);
}

class _ConversationTokenPiePainter extends CustomPainter {
  const _ConversationTokenPiePainter({
    required this.values,
    required this.colors,
    required this.separatorColor,
  });

  final List<int> values;
  final List<Color> colors;
  final Color separatorColor;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (sum, value) => sum + value);
    if (total <= 0) return;

    final diameter = math.min(size.width, size.height);
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: diameter / 2,
    );
    if (values.length == 1) {
      canvas.drawCircle(
        rect.center,
        diameter / 2,
        Paint()..color = colors.first,
      );
      canvas.drawCircle(
        rect.center,
        diameter / 2 - 0.75,
        Paint()
          ..color = separatorColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      return;
    }

    var startAngle = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final sweepAngle = values[index] / total * math.pi * 2;
      final path =
          Path()
            ..moveTo(rect.center.dx, rect.center.dy)
            ..arcTo(rect, startAngle, sweepAngle, false)
            ..close();
      canvas.drawPath(path, Paint()..color = colors[index]);
      canvas.drawPath(
        path,
        Paint()
          ..color = separatorColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _ConversationTokenPiePainter oldDelegate) {
    return !listEquals(values, oldDelegate.values) ||
        !listEquals(colors, oldDelegate.colors) ||
        separatorColor != oldDelegate.separatorColor;
  }
}

class _EmptyPiePainter extends CustomPainter {
  const _EmptyPiePainter({required this.color, required this.separatorColor});

  final Color color;
  final Color separatorColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2;
    canvas.drawCircle(size.center(Offset.zero), radius, Paint()..color = color);
    canvas.drawCircle(
      size.center(Offset.zero),
      radius - 0.75,
      Paint()
        ..color = separatorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _EmptyPiePainter oldDelegate) {
    return color != oldDelegate.color ||
        separatorColor != oldDelegate.separatorColor;
  }
}
