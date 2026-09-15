import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/ui/core/dependency_injection/app_scope.dart';
import 'package:stars/ui/features/app/views/desktop_layout.dart';
import 'package:stars/ui/features/chat/views/conversation_task_card.dart';
import 'package:stars/ui/features/chat/views/conversation_tasks_page.dart';
import 'package:stars/ui/features/chat/views/message_input.dart';
import 'package:stars/ui/features/chat/views/message_list.dart';
import 'conversation_task_app_harness.dart';
import 'widget_test_support.dart' show shadHarness, withDesktopPlatform;

/// Shared acceptance scenario runs in both WidgetTester and a native desktop.
void conversationTaskAcceptanceTests({
  void Function(Map<String, num>)? record,
}) {
  late ConversationTaskAppHarness h;
  setUp(() async {
    h = ConversationTaskAppHarness();
    await h.open();
  });
  tearDown(() => h.close());

  testWidgets(
    'chat accepts, restores approval and job, remains usable, and shows one verified terminal after reentry',
    (tester) async {
      await withDesktopPlatform(() async {
        tester.view.physicalSize = const Size(1280, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Widget page() => AppScope(
          dependencies: h,
          child: shadHarness(
            brightness: Brightness.light,
            homeBuilder:
                (_) => Scaffold(
                  body: DesktopLayout(
                    currentIndex: 0,
                    onPageChanged: (_) {},
                    pages: const [SizedBox.shrink(), SizedBox.shrink()],
                    selectedChatId: 'chat-1',
                    selectedChatBot: h.bot,
                    onBotUpdated: (_) async {},
                    onBotDeleted: () async {},
                    strictGroundingMode: true,
                  ),
                ),
          ),
        );
        List<Message> messages() =>
            find.byType(MessageList, skipOffstage: false).evaluate().isEmpty
                ? const []
                : tester
                    .widget<MessageList>(
                      find.byType(MessageList, skipOffstage: false),
                    )
                    .messages;
        ConversationTaskCard? activeCard() =>
            tester
                .widgetList<ConversationTaskCard>(
                  find.byType(ConversationTaskCard),
                )
                .where((card) => !card.historical)
                .firstOrNull;
        bool inputReady() =>
            find
                .byType(MessageInput, skipOffstage: false)
                .evaluate()
                .isNotEmpty &&
            !tester
                .widget<MessageInput>(
                  find.byType(MessageInput, skipOffstage: false),
                )
                .requestInProgress;
        Future<void> send(String text) async {
          final input = find.descendant(
            of: find.byType(MessageInput),
            matching: find.byType(EditableText),
          );
          await tester.enterText(input, text);
          await tester.pump();
          await tester.tap(find.widgetWithText(ShadButton, '发送'));
        }

        Future<void> leave() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await driveTaskUi(tester);
        }

        Future<void> toggleTasks() async {
          await tester.tap(
            find.byKey(const ValueKey('desktop-toolbar-conversation-tasks')),
          );
          await driveTaskUi(tester);
        }

        await tester.pumpWidget(page());
        await driveTaskUi(tester);
        final clear = find.byKey(const ValueKey('desktop-toolbar-clear-chat'));
        final tasks = find.byKey(
          const ValueKey('desktop-toolbar-conversation-tasks'),
        );
        expect(
          tester.getCenter(tasks).dx,
          greaterThan(tester.getCenter(clear).dx),
        );
        expect(find.byType(ConversationTasksPage), findsNothing);
        expect(find.text('查看状态'), findsNothing);
        final firstCard = Stopwatch()..start();
        await send('读取报告并核验报告条目数');
        await driveTaskUi(
          tester,
          until:
              () => messages().any(
                (m) => m.taskMessageKind == TaskMessageKind.acknowledgement,
              ),
        );
        await toggleTasks();
        await driveTaskUi(
          tester,
          until:
              () =>
                  activeCard()?.summary.waitingReason ==
                      TaskWaitingReason.approval &&
                  inputReady(),
          diagnostic:
              () async => jsonEncode({
                'tasks': await h.database.query(
                  'conversation_tasks',
                  columns: ['status', 'waiting_reason'],
                ),
                'inputReady': inputReady(),
                'renderedMessages': messages().length,
              }),
        );
        record?.call({
          'ui.acceptanceToApprovalFrameUs': firstCard.elapsedMicroseconds,
        });
        final taskContent = tester.getRect(
          find.byKey(const ValueKey('conversation-tasks-content')),
        );
        await tester.tap(
          find.byKey(const ValueKey('desktop-toolbar-conversation-directory')),
        );
        await driveTaskUi(tester);
        final directoryContent = tester.getRect(
          find.byKey(const ValueKey('desktop-conversation-directory-content')),
        );
        expect(taskContent.left, directoryContent.left);
        expect(taskContent.width, directoryContent.width);
        expect(taskContent.top, directoryContent.top);
        await toggleTasks();
        expect(
          messages().where(
            (m) => m.taskMessageKind == TaskMessageKind.acknowledgement,
          ),
          hasLength(1),
        );
        final acceptedId = activeCard()!.summary.taskId;
        final acknowledgement =
            messages()
                .singleWhere(
                  (m) => m.taskMessageKind == TaskMessageKind.acknowledgement,
                )
                .content;
        record?.call(h.conversationTasks.telemetry.snapshot());
        await leave();
        await tester.runAsync(() => h.restart());
        await tester.pumpWidget(page());
        await driveTaskUi(tester);
        await toggleTasks();
        await driveTaskUi(
          tester,
          until: () => activeCard()?.summary.progress.pendingApprovalId != null,
        );
        expect(activeCard()!.summary.taskId, acceptedId);
        await tester.ensureVisible(find.text('批准'));
        await tester.tap(find.text('批准'));
        await driveTaskUi(
          tester,
          until:
              () =>
                  activeCard()?.summary.status ==
                      ConversationTaskStatus.paused &&
                  h.conversationTasks.scheduler.runningCount == 0,
        );
        expect(h.job.read()['starts'], 1);
        expect(inputReady(), isTrue);
        await toggleTasks();
        expect(find.byType(ConversationTasksPage), findsNothing);
        h.providers.route = 'directReply';
        await send('Hello');
        await driveTaskUi(
          tester,
          until:
              () =>
                  messages().any(
                    (m) => m.content == 'Hello while the report is running',
                  ) &&
                  inputReady(),
        );
        await toggleTasks();
        expect(activeCard()!.summary.taskId, acceptedId);
        await toggleTasks();
        h.providers.route = 'taskStatusRequest';
        h.providers.failNarration = true;
        final statusFrame = Stopwatch()..start();
        await send('现在进展如何');
        await driveTaskUi(
          tester,
          until:
              () =>
                  messages().any(
                    (m) => m.taskMessageKind == TaskMessageKind.status,
                  ) &&
                  inputReady(),
        );
        record?.call({
          'ui.statusRequestToFrameUs': statusFrame.elapsedMicroseconds,
        });
        await tester.runAsync(h.conversationTasks.progress.settle);
        final historical = messages().singleWhere(
          (m) => m.taskMessageKind == TaskMessageKind.status,
        );
        expect(historical.taskStatusSummaries.single.taskId, acceptedId);
        expect(historical.content, isNotEmpty);
        expect(
          h.conversationTasks.telemetry.snapshot()['progress.fallbackRatio'],
          1,
        );
        expect(h.job.read()['starts'], 1);
        record?.call(h.conversationTasks.telemetry.snapshot());
        await leave();
        await tester.runAsync(() async {
          await h.restart(startImmediately: false);
          h.job.ready();
          h.clock.advance(const Duration(hours: 2));
          await h.start();
        });
        await tester.pumpWidget(page());
        await driveTaskUi(
          tester,
          until:
              () => messages().any(
                (m) => m.taskMessageKind == TaskMessageKind.result,
              ),
          diagnostic:
              () async => jsonEncode({
                'tasks': await h.database.query(
                  'conversation_tasks',
                  columns: ['status', 'waiting_reason', 'next_run_at'],
                ),
                'messages': await h.database.query(
                  'messages',
                  columns: ['task_message_kind', 'timestamp'],
                ),
                'renderedKinds':
                    messages().map((m) => m.taskMessageKind?.name).toList(),
                'job': {
                  for (final key in ['starts', 'polls', 'lookups', 'ready'])
                    key: h.job.read()[key],
                },
                'telemetry': h.conversationTasks.telemetry.snapshot(),
              }),
        );
        final result = messages().singleWhere(
          (m) => m.taskMessageKind == TaskMessageKind.result,
        );
        expect(result.terminalOutcome, MessageTerminalOutcome.completed);
        expect(result.grounding.trustLevel, AnswerTrustLevel.verified);
        expect(result.content, '报告共 42 条。');
        expect(
          messages()
              .singleWhere(
                (m) => m.taskMessageKind == TaskMessageKind.acknowledgement,
              )
              .content,
          acknowledgement,
        );
        expect(
          messages()
              .singleWhere((m) => m.taskMessageKind == TaskMessageKind.status)
              .content,
          historical.content,
        );
        expect(inputReady(), isTrue);
        record?.call(h.conversationTasks.telemetry.snapshot());
        await leave();
        await tester.pumpWidget(page());
        await driveTaskUi(
          tester,
          until:
              () => messages().any(
                (m) => m.taskMessageKind == TaskMessageKind.result,
              ),
          diagnostic:
              () async => jsonEncode({
                'tasks': await h.database.query(
                  'conversation_tasks',
                  columns: ['status', 'waiting_reason', 'next_run_at'],
                ),
                'messages': await h.database.query(
                  'messages',
                  columns: ['task_message_kind', 'timestamp'],
                ),
                'renderedKinds':
                    messages().map((m) => m.taskMessageKind?.name).toList(),
                'job': {
                  for (final key in ['starts', 'polls', 'lookups', 'ready'])
                    key: h.job.read()[key],
                },
                'telemetry': h.conversationTasks.telemetry.snapshot(),
              }),
        );
        expect(
          messages().where((m) => m.taskMessageKind == TaskMessageKind.result),
          hasLength(1),
        );
        expect((await tester.runAsync(h.integrity))!.values, everyElement(0));
        expect(h.job.read()['starts'], 1);
        expect(tester.takeException(), isNull);
        await leave();
      });
    },
  );
}

// SQLite uses a real isolate; pump UI continuations and its completion queue.
Future<void> driveTaskUi(
  WidgetTester tester, {
  bool Function()? until,
  Future<String> Function()? diagnostic,
}) async {
  for (var i = 0; i < 600; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    if (until?.call() ?? i >= 15) {
      await tester.pump();
      return;
    }
  }
  fail(
    'Conversation UI did not reach the expected committed state: ${diagnostic == null ? '' : await tester.runAsync(diagnostic)}',
  );
}
