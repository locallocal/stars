import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/features/chat/views/conversation_task_card.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';

import '../../../../support/widget_test_support.dart' show shadHarness;

void main() {
  for (final desktop in [true, false]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'task progress uses the normal selectable message bubble ($desktop, $brightness)',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(desktop ? 1000 : 360, 800);
          addTearDown(tester.view.reset);
          final controller = ScrollController();
          addTearDown(controller.dispose);
          final time = DateTime.utc(2026, 9, 20);
          final summary = ConversationTaskProgressSummary(
            taskId: 'task-internal-id',
            chatId: 'chat-1',
            title: '整理报告',
            status: ConversationTaskStatus.running,
            phase: ConversationTaskPhase.executing,
            planRevision: 1,
            summaryRevision: 3,
            updatedAt: time,
            progress: TaskProgress(
              totalSteps: 5,
              completedSteps: 3,
              currentStepSummary: '核验报告',
              lastMeaningfulProgressAt: time,
            ),
          );
          const reply = '资料已经整理好了，正在**核验报告**，目前还不能算全部完成。';
          await tester.pumpWidget(
            shadHarness(
              brightness: brightness,
              homeBuilder:
                  (_) => Scaffold(
                    body: Column(
                      children: [
                        MessageList(
                          messages: [
                            Message(
                              messageId: 'question:status',
                              turnId: 'question',
                              chatId: 'chat-1',
                              botId: 'bot-1',
                              senderId: 'bot-1',
                              content: reply,
                              taskId: summary.taskId,
                              summaryRevision: summary.summaryRevision,
                              taskMessageKind: TaskMessageKind.status,
                              taskStatusSummaries: [summary],
                              timestamp: time,
                            ),
                          ],
                          scrollController: controller,
                          isStreaming: false,
                          streamingResponse: '',
                          currentUserId: 'user',
                          isDesktop: desktop,
                          strictGroundingMode: true,
                        ),
                      ],
                    ),
                  ),
            ),
          );
          await tester.pumpAndSettle();

          final prose = find.byWidgetPredicate(
            (widget) => widget is MarkdownBody && widget.data == reply,
          );
          expect(prose, findsOneWidget);
          expect(tester.widget<MarkdownBody>(prose).selectable, isTrue);
          expect(find.byType(ConversationTaskCard), findsNothing);
          expect(find.textContaining('task-internal-id'), findsNothing);
          expect(find.textContaining('3/5'), findsNothing);
          expect(
            find.byKey(const ValueKey('message-trust-status')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('message-strict-grounding-notice')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
