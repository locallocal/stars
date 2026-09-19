import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/conversation_task_execution.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/ui/features/chat/view_models/conversation_tasks_view_model.dart';
import 'package:stars/ui/features/chat/views/conversation_task_card.dart';
import 'package:stars/ui/features/chat/views/conversation_task_execution_section.dart';
import 'package:stars/ui/features/chat/views/conversation_task_execution_status.dart';

import '../../../../support/widget_test_support.dart' show shadHarness;
import 'conversation_task_card_test.dart' show cardSummary;

void main() {
  final output =
      'exit_code: 1\nstdout:\n${List.generate(80, (i) => 'Result line $i').join('\n')}\nstderr: test failed';
  final execution = ConversationTaskExecution(
    revision: 4,
    processInfo: MessageProcessInfo(
      toolCalls: [
        MessageToolCall(
          attemptId: 'attempt-1',
          name: 'run_shell_command',
          status: 'failed',
          argumentsSummary:
              '{"command":"flutter test","working_directory":"/workspace/project","timeout_seconds":7}',
          resultSummary: output,
          errorCode: 'shell_command_failed',
          durationMs: 1200,
        ),
      ],
      commandExecutions: const [
        MessageCommandExecution(command: 'flutter test', status: 'failed'),
      ],
    ),
    activities: [
      for (var i = 0; i < 20; i++)
        TaskExecutionActivity(
          event: ConversationTaskEvent(
            taskId: 'task:abc12345678',
            sequence: i + 1,
            kind:
                i == 19
                    ? TaskEventKind.toolFailed
                    : i == 18
                    ? TaskEventKind.segmentCheckpoint
                    : TaskEventKind.toolStarted,
            occurredAt: DateTime(2026, 9, 19, 12, i),
            safeSummary: 'Tool execution',
          ),
          subject: 'run_shell_command',
        ),
    ],
  );

  for (final width in [320.0, 1000.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'task details share the outer scroll and collapse independently at $width / $brightness',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final controller = ShadAccordionController<String>.multiple();
          addTearDown(controller.dispose);
          final scrollController = ScrollController();
          addTearDown(scrollController.dispose);
          await tester.pumpWidget(
            shadHarness(
              brightness: brightness,
              homeBuilder:
                  (_) => Scaffold(
                    body: Scrollbar(
                      controller: scrollController,
                      child: ListView(
                        key: const ValueKey('outer-task-list'),
                        controller: scrollController,
                        children: [
                          ConversationTaskCard(
                            summary: cardSummary(
                              ConversationTaskStatus.succeeded,
                            ),
                            expansionController: controller,
                            executionDetails: ConversationTaskExecutionSection(
                              state: ConversationTaskExecutionState(
                                data: execution,
                              ),
                              onRetry: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(ConversationTaskExecutionStatus), findsNothing);
          await tester.tap(find.textContaining('Report').first);
          await tester.pumpAndSettle();
          expect(find.byType(ConversationTaskExecutionStatus), findsOneWidget);
          expect(find.text('执行状态'), findsOneWidget);
          expect(find.text(output), findsNothing);
          expect(find.text('1 需关注'), findsOneWidget);
          await tester.tap(find.text('命令执行'));
          await tester.pumpAndSettle();
          expect(find.text('调用参数'), findsOneWidget);
          expect(find.text('执行结果'), findsOneWidget);
          expect(find.text('shell_command_failed'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(SelectionArea),
              matching: find.text(output),
            ),
            findsOneWidget,
          );
          expect(find.byType(Scrollbar), findsOneWidget);
          expect(find.byType(Scrollable), findsOneWidget);
          expect(find.byType(ShadCard), findsOneWidget);
          expect(
            find.byKey(const ValueKey('execution-details-scroll')),
            findsNothing,
          );
          expect(tester.getSize(find.text(output)).height, greaterThan(180));
          final left = tester.getTopLeft(find.textContaining('阶段:')).dx;
          for (final label in ['执行状态', '调用参数', '执行结果', '执行流程']) {
            expect(tester.getTopLeft(find.text(label)).dx, closeTo(left, 0.1));
          }
          await tester.drag(
            find.byKey(const ValueKey('outer-task-list')),
            const Offset(0, -600),
          );
          await tester.pumpAndSettle();
          expect(scrollController.offset, greaterThan(0));
          await tester.ensureVisible(find.text('工具调用未成功'));
          await tester.pumpAndSettle();
          expect(find.text('工具调用未成功').hitTestable(), findsOneWidget);
          expect(find.byKey(const ValueKey('task-event-19')), findsNothing);
          await tester.ensureVisible(
            find.byKey(const ValueKey('task-events-all')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('task-events-all')));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('task-event-19')), findsOneWidget);
          await tester.ensureVisible(find.text('执行流程'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('执行流程'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('task-execution-timeline')),
            findsNothing,
          );
          expect(find.text('调用参数'), findsOneWidget);
          await tester.ensureVisible(find.text('执行状态'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('执行状态'));
          await tester.pumpAndSettle();
          expect(find.text('调用参数').hitTestable(), findsNothing);
          expect(find.text('执行流程'), findsOneWidget);
          await tester.tap(find.text('执行状态'));
          await tester.pumpAndSettle();
          expect(find.text('调用参数'), findsOneWidget);
          expect(
            find.byKey(const ValueKey('task-execution-timeline')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
          controller.toggle('task:abc12345678');
          await tester.pumpAndSettle();
          expect(find.byType(ConversationTaskExecutionStatus), findsNothing);
        },
      );
    }
  }

  testWidgets('detail error keeps the saved results and offers retry', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (_) => Scaffold(
              body: SingleChildScrollView(
                child: ConversationTaskExecutionSection(
                  state: ConversationTaskExecutionState(
                    data: execution,
                    error: true,
                  ),
                  onRetry: () => retries++,
                ),
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('执行详情加载失败。'), findsOneWidget);
    expect(find.byType(ConversationTaskExecutionStatus), findsOneWidget);
    await tester.tap(find.widgetWithText(ShadButton, '重试'));
    expect(retries, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh retains expanded attempts and the timeline filter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = ValueNotifier(
      ConversationTaskExecutionState(data: execution),
    );
    addTearDown(state.dispose);
    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (_) => Scaffold(
              body: SingleChildScrollView(
                child: ValueListenableBuilder(
                  valueListenable: state,
                  builder:
                      (_, value, _) => ConversationTaskExecutionSection(
                        state: value,
                        onRetry: () {},
                      ),
                ),
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-events-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('命令执行'));
    await tester.pumpAndSettle();
    state.value = ConversationTaskExecutionState(
      data: execution,
      loading: true,
    );
    await tester.pumpAndSettle();
    expect(find.text('调用参数'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-event-19')), findsOneWidget);
    state.value = ConversationTaskExecutionState(
      data: ConversationTaskExecution(
        revision: 5,
        processInfo: execution.processInfo,
        activities: execution.activities,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('调用参数'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-event-19')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard opens a call and collapsed details leave semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (_) => Scaffold(
              body: ConversationTaskExecutionSection(
                state: ConversationTaskExecutionState(
                  data: ConversationTaskExecution(
                    revision: 1,
                    processInfo: const MessageProcessInfo(
                      toolCalls: [
                        MessageToolCall(
                          attemptId: 'read',
                          name: 'read_file',
                          status: 'succeeded',
                          resultSummary: 'Project loaded',
                        ),
                      ],
                    ),
                    activities: const [],
                  ),
                ),
                onRetry: () {},
              ),
            ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Project loaded').hitTestable(), findsOneWidget);
    expect(find.semantics.byLabel('Project loaded'), findsOne);
    await tester.tap(find.text('执行状态'));
    await tester.pumpAndSettle();
    expect(find.text('Project loaded').hitTestable(), findsNothing);
    expect(find.semantics.byLabel('Project loaded'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
