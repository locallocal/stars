import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/chat_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/ui/features/chat/view_models/chat_token_usage_view_model.dart';
import 'package:stars/ui/features/chat/views/token_usage_chart.dart';
import 'package:stars/utils/theme.dart';

import '../../../../support/widget_test_support.dart';

void main() {
  testWidgets('selecting a day drills into hours and back restores days', (
    tester,
  ) async {
    final viewModel = ChatTokenUsageViewModel(
      chatId: 'chat-1',
      messageRepository: _FakeMessageRepository([
        _message(DateTime(2026, 7, 24, 10), 120, 30),
        _message(DateTime(2026, 7, 24, 15), 40, 10),
        _message(DateTime(2026, 7, 26, 8), 80, 20),
      ]),
      chatRepository: _FakeChatRepository(),
      now: () => DateTime(2026, 7, 26, 8, 30),
    );
    addTearDown(viewModel.dispose);
    await viewModel.load();

    await tester.pumpWidget(_Harness(viewModel: viewModel));
    await tester.pumpAndSettle();

    final summary = find.byKey(
      const ValueKey<String>('inspector-token-usage-summary'),
    );
    final totalMetric = find.byKey(
      const ValueKey<String>('inspector-token-usage-total'),
    );
    final inputMetric = find.byKey(
      const ValueKey<String>('inspector-token-usage-input'),
    );
    final outputMetric = find.byKey(
      const ValueKey<String>('inspector-token-usage-output'),
    );
    final totalRect = tester.getRect(totalMetric);
    final inputRect = tester.getRect(inputMetric);
    final outputRect = tester.getRect(outputMetric);

    expect(summary, findsOneWidget);
    expect(
      find.descendant(of: summary, matching: find.byType(DecoratedBox)),
      findsNothing,
    );
    expect(totalRect.left, closeTo(inputRect.left, 0.01));
    expect(totalRect.left, closeTo(outputRect.left, 0.01));
    expect(totalRect.width, closeTo(inputRect.width, 0.01));
    expect(totalRect.width, closeTo(outputRect.width, 0.01));
    expect(inputRect.top, greaterThan(totalRect.top));
    expect(outputRect.top, greaterThan(inputRect.top));

    final metricFinders = [totalMetric, inputMetric, outputMetric];
    final labelLefts = <double>[];
    for (final metric in metricFinders) {
      final label = find.descendant(of: metric, matching: find.byType(Text));
      final value = find.descendant(
        of: metric,
        matching: find.byType(SelectableText),
      );
      expect(tester.widget<SelectableText>(value).textAlign, TextAlign.right);
      labelLefts.add(tester.getRect(label).left);
      expect(
        tester.getRect(value).right,
        closeTo(tester.getRect(metric).right, 0.01),
      );
    }
    expect(labelLefts[1], closeTo(labelLefts[0], 0.01));
    expect(labelLefts[2], closeTo(labelLefts[0], 0.01));

    final totalLabel = tester.widget<Text>(find.text('Token 总量'));
    final inputLabel = tester.widget<Text>(
      find.descendant(of: inputMetric, matching: find.text('输入 Token')),
    );
    final outputLabel = tester.widget<Text>(
      find.descendant(of: outputMetric, matching: find.text('输出 Token')),
    );
    expect(totalLabel.style, inputLabel.style);
    expect(totalLabel.style, outputLabel.style);
    expect(
      totalLabel.style?.fontSize,
      Theme.of(
        tester.element(find.text('Token 总量')),
      ).textTheme.bodyMedium?.fontSize,
    );

    final tokenUsageTitleFinder = find.byKey(
      const ValueKey<String>('token-usage-section-title'),
    );
    final dailyUsageTitleFinder = find.byKey(
      const ValueKey<String>('token-usage-granularity-title'),
    );
    final sectionDividerFinder = find.byKey(
      const ValueKey<String>('token-usage-section-divider'),
    );
    final drilldownHintFinder = find.byKey(
      const ValueKey<String>('token-usage-drilldown-hint'),
    );
    final tokenUsageTitle = tester.widget<Text>(tokenUsageTitleFinder);
    final dailyUsageTitle = tester.widget<Text>(dailyUsageTitleFinder);
    final drilldownHint = tester.widget<Text>(drilldownHintFinder);
    expect(find.byIcon(Icons.query_stats_rounded), findsNothing);
    expect(sectionDividerFinder, findsOneWidget);
    expect(
      tokenUsageTitle.style,
      StarsDesktopThemeSpec.sectionTitleStyle(
        tester.element(tokenUsageTitleFinder),
      ),
    );
    expect(dailyUsageTitle.style, tokenUsageTitle.style);
    expect(
      tester.getTopLeft(dailyUsageTitleFinder).dx,
      closeTo(tester.getTopLeft(tokenUsageTitleFinder).dx, 0.01),
    );
    expect(
      tester.getCenter(sectionDividerFinder).dy,
      allOf(
        greaterThan(tester.getBottomLeft(summary).dy),
        lessThan(tester.getTopLeft(dailyUsageTitleFinder).dy),
      ),
    );
    expect(
      drilldownHint.style,
      StarsDesktopThemeSpec.metaStyle(tester.element(drilldownHintFinder)),
    );
    expect(
      tester.getTopLeft(drilldownHintFinder).dx,
      closeTo(tester.getTopLeft(dailyUsageTitleFinder).dx, 0.01),
    );

    expect(find.text('每日用量'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('token-usage-back-to-daily')),
      findsNothing,
    );
    final firstDailyBar = find.byKey(
      const ValueKey<String>('token-usage-input-bar-day-2026-07-24'),
    );
    expect(firstDailyBar, findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('token-usage-output-bar-day-2026-07-24'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(firstDailyBar).width,
      greaterThan(tester.getSize(firstDailyBar).height),
    );
    final firstDailyBucket = find.byKey(
      const ValueKey<String>('token-usage-input-bucket-day-2026-07-24'),
    );
    final firstDailyValue = find.descendant(
      of: firstDailyBucket,
      matching: find.text('160'),
    );
    expect(firstDailyValue, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('token-usage-output-bucket-day-2026-07-24'),
        ),
        matching: find.text('40'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('token-usage-input-bucket-day-2026-07-25'),
      ),
      findsNothing,
    );
    expect(
      tester.getRect(firstDailyBucket).right -
          tester.getRect(firstDailyValue).right,
      closeTo(0, 0.01),
    );

    await tester.tap(firstDailyBucket);
    await tester.pump();

    expect(find.text('小时用量'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('token-usage-input-bucket-hour-10')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('token-usage-input-bucket-hour-11')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('token-usage-input-bucket-hour-15')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('token-usage-input-bucket-hour-23')),
      findsNothing,
    );
    final firstHourlyBar = find.byKey(
      const ValueKey<String>('token-usage-input-bar-hour-10'),
    );
    expect(firstHourlyBar, findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('token-usage-output-bar-hour-10')),
      findsOneWidget,
    );
    expect(
      tester.getSize(firstHourlyBar).width,
      greaterThan(tester.getSize(firstHourlyBar).height),
    );
    final firstHourlyBucket = find.byKey(
      const ValueKey<String>('token-usage-input-bucket-hour-10'),
    );
    final firstHourlyValue = find.descendant(
      of: firstHourlyBucket,
      matching: find.text('120'),
    );
    expect(firstHourlyValue, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('token-usage-output-bucket-hour-10'),
        ),
        matching: find.text('30'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getRect(firstHourlyBucket).right -
          tester.getRect(firstHourlyValue).right,
      closeTo(0, 0.01),
    );
    expect(
      find.byKey(const ValueKey<String>('token-usage-back-to-daily')),
      findsOneWidget,
    );
    final hourlyHeader = find.byKey(
      const ValueKey<String>('token-usage-granularity-header'),
    );
    final backButton = find.byKey(
      const ValueKey<String>('token-usage-back-to-daily'),
    );
    expect(
      find.descendant(of: hourlyHeader, matching: backButton),
      findsOneWidget,
    );
    expect(
      tester.getCenter(backButton).dx,
      greaterThan(tester.getCenter(dailyUsageTitleFinder).dx),
    );

    await tester.tap(backButton);
    await tester.pump();

    expect(find.text('每日用量'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('token-usage-input-bucket-day-2026-07-26'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('token-usage-input-bucket-day-2026-07-26'),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('token-usage-input-bucket-hour-8')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('token-usage-input-bucket-hour-9')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('token-usage-input-bucket-hour-23')),
      findsNothing,
    );
  });
}

Message _message(DateTime timestamp, int input, int output) {
  return Message(
    messageId: 'message-${timestamp.microsecondsSinceEpoch}',
    turnId: 'turn-${timestamp.microsecondsSinceEpoch}',
    chatId: 'chat-1',
    botId: 'bot-1',
    senderId: 'bot-1',
    content: 'response',
    tokenUsage: ModelTokenUsage(
      inputTokens: input,
      outputTokens: output,
      totalTokens: input + output,
    ),
    timestamp: timestamp,
  );
}

class _Harness extends StatelessWidget {
  const _Harness({required this.viewModel});

  final ChatTokenUsageViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return shadHarness(
      brightness: Brightness.light,
      homeBuilder:
          (context) => Scaffold(
            body: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: ConversationTokenUsagePanel(viewModel: viewModel),
              ),
            ),
          ),
    );
  }
}

class _FakeMessageRepository implements MessageRepository {
  _FakeMessageRepository(this.messages);

  final List<Message> messages;

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<List<Message>> getMessages(String chatId) async => messages;

  @override
  Future<List<ModelTokenUsageRecord>> getTokenUsageRecordsForChat(
    String chatId,
  ) async {
    return [
      for (final message in messages)
        ModelTokenUsageRecord(
          messageId: message.messageId,
          chatId: message.chatId,
          botId: message.botId,
          timestamp: message.timestamp,
          usage: message.tokenUsage,
        ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChatRepository implements ChatRepository {
  @override
  Stream<List<Chat>> get changes => const Stream<List<Chat>>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
