import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';

import '../../../../support/widget_test_support.dart' show shadHarness;

void main() {
  for (final desktop in [true, false]) {
    for (final brightness in Brightness.values) {
      for (final (outcome, toolStatus) in [
        (MessageTerminalOutcome.completed, 'succeeded'),
        (MessageTerminalOutcome.failed, 'failed'),
        (MessageTerminalOutcome.cancelled, 'cancelled'),
      ]) {
        testWidgets(
          'task result execution follows the preference ($desktop, $brightness, $outcome)',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(desktop ? 1000 : 360, 1000);
            addTearDown(tester.view.reset);
            final scroll = ScrollController();
            addTearDown(scroll.dispose);
            final message = Message(
              messageId: 'task-1:result',
              taskId: 'task-1',
              taskMessageKind: TaskMessageKind.result,
              terminalOutcome: outcome,
              chatId: 'chat-1',
              botId: 'bot-1',
              senderId: 'bot-1',
              content: '后台任务报告',
              processInfo: MessageProcessInfo(
                durationMs: 1200,
                toolCalls: [
                  MessageToolCall(
                    name: 'read_file',
                    title: '读取报告',
                    status: toolStatus,
                    source: 'builtIn',
                    riskLevel: 'readOnly',
                  ),
                ],
              ),
              tokenUsage: const ModelTokenUsage(
                inputTokens: 120,
                outputTokens: 30,
              ),
              timestamp: DateTime(2026),
            );
            Widget page(bool showExecutionStatus) => shadHarness(
              brightness: brightness,
              homeBuilder:
                  (_) => Scaffold(
                    body: Column(
                      children: [
                        MessageList(
                          messages: [message],
                          taskTokenUsage: const {
                            'task-1:result': ModelTokenUsage(
                              inputTokens: 2400,
                              outputTokens: 360,
                            ),
                          },
                          scrollController: scroll,
                          isStreaming: false,
                          streamingResponse: '',
                          currentUserId: 'user',
                          isDesktop: desktop,
                          showReasoning: false,
                          showVerificationStatus: false,
                          showExecutionStatus: showExecutionStatus,
                        ),
                      ],
                    ),
                  ),
            );

            await tester.pumpWidget(page(true));
            await tester.pumpAndSettle();
            expect(find.byType(ProcessInfoSection), findsOneWidget);
            expect(find.text('执行状态'), findsOneWidget);
            expect(find.text('输入 Token 2400'), findsOneWidget);
            expect(find.text('输出 Token 360'), findsOneWidget);
            expect(find.text('输入 Token 120'), findsNothing);
            expect(find.text('输出 Token 30'), findsNothing);
            if (desktop) {
              expect(find.byType(ShadAccordion<String>), findsOneWidget);
              expect(find.text('read_file').hitTestable(), findsNothing);
              await tester.tap(find.text('执行状态'));
              await tester.pumpAndSettle();
            }
            expect(find.text('read_file').hitTestable(), findsOneWidget);
            expect(tester.takeException(), isNull);

            await tester.pumpWidget(page(false));
            await tester.pumpAndSettle();
            expect(find.byType(ProcessInfoSection), findsNothing);
            expect(find.text('输入 Token 2400'), findsNothing);
            expect(find.text('输出 Token 360'), findsNothing);
            expect(find.text('read_file'), findsNothing);
            final prose = find.byWidgetPredicate(
              (widget) =>
                  widget is MarkdownBody && widget.data == message.content,
            );
            expect(prose, findsOneWidget);
            expect(tester.widget<MarkdownBody>(prose).selectable, isTrue);

            await tester.pumpWidget(page(true));
            await tester.pumpAndSettle();
            expect(find.byType(ProcessInfoSection), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'task usage distinguishes unavailable, zero and late loaded totals',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      Widget page(ModelTokenUsage? usage) => shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (_) => Scaffold(
              body: Column(
                children: [
                  MessageList(
                    messages: [
                      Message(
                        messageId: 'task-1:result',
                        taskId: 'task-1',
                        taskMessageKind: TaskMessageKind.result,
                        terminalOutcome: MessageTerminalOutcome.completed,
                        chatId: 'chat-1',
                        botId: 'bot-1',
                        senderId: 'bot-1',
                        content: 'Report',
                        // A reply's own usage must not stand in for the task aggregate.
                        tokenUsage: const ModelTokenUsage(
                          inputTokens: 10,
                          outputTokens: 2,
                        ),
                        timestamp: DateTime(2026),
                      ),
                    ],
                    taskTokenUsage: {'task-1:result': usage},
                    scrollController: scroll,
                    isStreaming: false,
                    streamingResponse: '',
                    currentUserId: 'user',
                    showVerificationStatus: false,
                  ),
                ],
              ),
            ),
      );
      for (final (usage, input, output) in [
        (null, '—', '—'),
        (ModelTokenUsage.empty, '0', '0'),
        (
          const ModelTokenUsage(inputTokens: 450, outputTokens: 90),
          '450',
          '90',
        ),
      ]) {
        await tester.pumpWidget(page(usage));
        await tester.pumpAndSettle();
        expect(find.text('输入 Token $input'), findsOneWidget);
        expect(find.text('输出 Token $output'), findsOneWidget);
        expect(find.text('输入 Token 10'), findsNothing);
        expect(find.text('输出 Token 2'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
