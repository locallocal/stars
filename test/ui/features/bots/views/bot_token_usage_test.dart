import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/core/view_models/token_usage_timeline.dart';
import 'package:stars/ui/features/bots/view_models/bot_token_usage_view_model.dart';
import 'package:stars/ui/features/bots/views/bot_token_usage.dart';

import '../../../../support/widget_test_support.dart';

void main() {
  testWidgets('desktop panel shows summary and conversation pie side by side', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const _Harness(
        width: 800,
        child: BotTokenUsagePanel(
          usage: ModelTokenUsage(
            inputTokens: 80,
            outputTokens: 20,
            totalTokens: 100,
          ),
          conversationUsages: [
            BotConversationTokenUsage(
              chatId: 'chat-large',
              preview: '第一段会话',
              usage: ModelTokenUsage(totalTokens: 75),
            ),
            BotConversationTokenUsage(
              chatId: 'chat-small',
              preview: '第二段会话',
              usage: ModelTokenUsage(totalTokens: 25),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final summary = find.byKey(
      const ValueKey<String>('bot-token-usage-summary'),
    );
    final chart = find.byKey(
      const ValueKey<String>('bot-conversation-token-share'),
    );
    expect(
      find.byKey(const ValueKey<String>('bot-token-usage-two-columns')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('bot-conversation-token-pie-chart')),
      findsOneWidget,
    );
    final pie = find.byKey(
      const ValueKey<String>('bot-conversation-token-pie-chart'),
    );
    final summaryRect = tester.getRect(summary);
    final pieRect = tester.getRect(pie);
    final firstMetricRect = tester.getRect(
      find.byKey(const ValueKey<String>('token-usage-total')),
    );
    final lastMetricRect = tester.getRect(
      find.byKey(const ValueKey<String>('token-usage-output')),
    );
    expect(summaryRect.top, closeTo(pieRect.top, 0.01));
    expect(summaryRect.bottom, closeTo(pieRect.bottom, 0.01));
    expect(summaryRect.center.dy, closeTo(pieRect.center.dy, 0.01));
    expect(firstMetricRect.top, closeTo(pieRect.top, 0.01));
    expect(lastMetricRect.bottom, closeTo(pieRect.bottom, 0.01));
    expect(
      tester.getTopLeft(summary).dx,
      lessThan(tester.getTopLeft(chart).dx),
    );
    expect(find.text('第一段会话'), findsOneWidget);
    expect(find.text('第二段会话'), findsOneWidget);
    expect(find.text('会话 Token 占比'), findsNothing);
    expect(find.text('75.0%'), findsOneWidget);
    expect(find.text('25.0%'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'会话 Token 占比, 第一段会话 75\.0%, 第二段会话 25\.0%')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('panel stacks when its parent is too narrow', (tester) async {
    await tester.pumpWidget(
      const _Harness(
        width: 600,
        child: BotTokenUsagePanel(
          usage: ModelTokenUsage(totalTokens: 10),
          conversationUsages: [
            BotConversationTokenUsage(
              chatId: 'chat-1',
              preview: '',
              usage: ModelTokenUsage(totalTokens: 10),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final summary = find.byKey(
      const ValueKey<String>('bot-token-usage-summary'),
    );
    final chart = find.byKey(
      const ValueKey<String>('bot-conversation-token-share'),
    );
    expect(
      find.byKey(const ValueKey<String>('bot-token-usage-stacked')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('bot-conversation-token-pie-chart')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(summary).dy,
      lessThan(tester.getTopLeft(chart).dy),
    );
    expect(find.text('聊天 1'), findsOneWidget);
    expect(find.text('100.0%'), findsOneWidget);
  });

  testWidgets('panel appends the shared daily usage bars', (tester) async {
    TokenUsageBucket? selectedBucket;
    final buckets = [
      TokenUsageBucket(
        start: DateTime(2026, 7, 24),
        usage: const ModelTokenUsage(
          inputTokens: 20,
          outputTokens: 5,
          totalTokens: 25,
        ),
      ),
      TokenUsageBucket(
        start: DateTime(2026, 7, 25),
        usage: const ModelTokenUsage(
          inputTokens: 45,
          outputTokens: 30,
          totalTokens: 75,
        ),
      ),
    ];

    await tester.pumpWidget(
      _Harness(
        width: 800,
        child: BotTokenUsagePanel(
          usage: const ModelTokenUsage(totalTokens: 100),
          conversationUsages: const [],
          dailyBuckets: buckets,
          visibleBuckets: buckets,
          onBucketSelected: (bucket) => selectedBucket = bucket,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('每日用量'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('bot-token-usage-timeline-divider')),
      findsOneWidget,
    );
    expect(find.byType(FilterChip), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('token-usage-toggle-input')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('token-usage-toggle-output')),
      findsNothing,
    );
    final inputSection = find.byKey(
      const ValueKey<String>('token-usage-input-section'),
    );
    final outputSection = find.byKey(
      const ValueKey<String>('token-usage-output-section'),
    );
    expect(inputSection, findsOneWidget);
    expect(outputSection, findsOneWidget);
    expect(
      tester.getTopLeft(inputSection).dy,
      lessThan(tester.getTopLeft(outputSection).dy),
    );
    expect(
      find.descendant(of: inputSection, matching: find.byType(ShadCard)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: outputSection, matching: find.byType(ShadCard)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: inputSection, matching: find.text('输入 Token')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: outputSection, matching: find.text('输出 Token')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: inputSection, matching: find.text('65')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: outputSection, matching: find.text('35')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('token-usage-input-chart-vertical')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('token-usage-output-chart-vertical')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('token-usage-input-bar-day-2026-07-25'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('token-usage-output-bar-day-2026-07-25'),
      ),
      findsOneWidget,
    );
    final tallestDailyBar = find.byKey(
      const ValueKey<String>('token-usage-input-bar-day-2026-07-25'),
    );
    expect(
      tester.getSize(tallestDailyBar).height,
      greaterThan(tester.getSize(tallestDailyBar).width),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('token-usage-input-bucket-day-2026-07-24'),
      ),
    );
    expect(selectedBucket?.start, DateTime(2026, 7, 24));
  });

  testWidgets('panel renders hourly usage as scrollable vertical bars', (
    tester,
  ) async {
    final hourlyBuckets = List<TokenUsageBucket>.generate(24, (hour) {
      return TokenUsageBucket(
        start: DateTime(2026, 7, 24, hour),
        usage: ModelTokenUsage(
          inputTokens: 24 - hour,
          outputTokens: hour + 1,
          totalTokens: 25,
        ),
      );
    });

    await tester.pumpWidget(
      _Harness(
        width: 600,
        child: BotTokenUsagePanel(
          usage: const ModelTokenUsage(totalTokens: 300),
          conversationUsages: const [],
          dailyBuckets: [
            TokenUsageBucket(
              start: DateTime(2026, 7, 24),
              usage: const ModelTokenUsage(
                inputTokens: 300,
                outputTokens: 24,
                totalTokens: 324,
              ),
            ),
          ],
          visibleBuckets: hourlyBuckets,
          granularity: TokenUsageGranularity.hour,
          selectedDay: DateTime(2026, 7, 24),
          onShowDaily: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('小时用量'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('token-usage-input-bar-hour-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('token-usage-output-bar-hour-0')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('token-usage-input-bar-hour-0')),
          )
          .height,
      greaterThan(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('token-usage-input-bar-hour-0'),
              ),
            )
            .width,
      ),
    );
    final inputSection = find.byKey(
      const ValueKey<String>('token-usage-input-section'),
    );
    final outputSection = find.byKey(
      const ValueKey<String>('token-usage-output-section'),
    );
    expect(
      tester.getTopLeft(inputSection).dy,
      lessThan(tester.getTopLeft(outputSection).dy),
    );
    final inputScrollable = find.descendant(
      of: find.byKey(
        const ValueKey<String>('token-usage-input-chart-vertical'),
      ),
      matching: find.byType(Scrollable),
    );
    final outputScrollable = find.descendant(
      of: find.byKey(
        const ValueKey<String>('token-usage-output-chart-vertical'),
      ),
      matching: find.byType(Scrollable),
    );
    expect(inputScrollable, findsOneWidget);
    expect(outputScrollable, findsOneWidget);
    expect(
      tester.state<ScrollableState>(inputScrollable).position.maxScrollExtent,
      greaterThan(0),
    );
    expect(
      tester.state<ScrollableState>(outputScrollable).position.maxScrollExtent,
      greaterThan(0),
    );
  });
}

class _Harness extends StatelessWidget {
  const _Harness({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return shadHarness(
      brightness: Brightness.light,
      homeBuilder:
          (context) => Scaffold(
            body: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: width, child: child),
              ),
            ),
          ),
    );
  }
}
