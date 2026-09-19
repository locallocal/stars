import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/ui/features/chat/views/conversation_task_card.dart';
import 'package:stars/ui/features/chat/views/conversation_task_retry_dialog.dart';
import 'package:stars/ui/features/chat/views/task_action_button.dart';
import 'package:stars/utils/theme.dart';
import '../../../../support/conversation_task_fixtures.dart';

ConversationTaskProgressSummary cardSummary(
  ConversationTaskStatus status, {
  TaskWaitingReason waitingReason = TaskWaitingReason.approval,
  String reasonCode = '',
  String approvalSummary = 'Save notes',
  ModelTokenUsage? tokenUsage,
}) => ConversationTaskProgressSummary(
  taskId: 'task:abc12345678',
  chatId: 'chat-1',
  title: 'Report',
  status: status,
  phase: ConversationTaskPhase.executing,
  planRevision: 1,
  summaryRevision: 4,
  updatedAt: taskTime,
  waitingReason:
      status == ConversationTaskStatus.waitingForUser ? waitingReason : null,
  progress: TaskProgress(
    tokenUsage: tokenUsage,
    reasonCode: reasonCode,
    totalSteps: 5,
    completedSteps: 3,
    lastMeaningfulProgressAt: taskTime,
    currentStepSummary: 'Read notes',
    recoveries: 2,
    pendingApprovalId:
        status == ConversationTaskStatus.waitingForUser &&
                waitingReason == TaskWaitingReason.approval
            ? 'approval'
            : null,
    pendingApprovalSummary:
        status == ConversationTaskStatus.waitingForUser &&
                waitingReason == TaskWaitingReason.approval
            ? approvalSummary
            : null,
    approvalRequestedAt:
        status == ConversationTaskStatus.waitingForUser &&
                waitingReason == TaskWaitingReason.approval
            ? taskTime
            : null,
  ),
  terminalSummary:
      {
            ConversationTaskStatus.failed,
            ConversationTaskStatus.cancelled,
          }.contains(status)
          ? taskTerminal(status)
          : null,
);
Widget host(
  Widget child, {
  bool desktop = true,
  Brightness brightness = Brightness.light,
}) {
  Widget app(BuildContext? shad) => MaterialApp(
    locale: const Locale('en'),
    theme:
        shad == null
            ? ThemeData()
            : buildShadMaterialBridgeTheme(context: shad, fontSize: 14),
    localizationsDelegates: const [
      GlobalShadLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: desktop ? (context, child) => ShadAppBuilder(child: child!) : null,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
  return desktop
      ? ShadApp.custom(
        theme: buildStarsShadTheme(brightness: brightness, fontSize: 14),
        appBuilder: (context) => app(context),
      )
      : app(null);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'collapsed token metrics update and fit narrow $brightness cards',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = ShadAccordionController<String>.multiple();
        addTearDown(controller.dispose);
        Future<void> show(ModelTokenUsage? usage) async {
          await tester.pumpWidget(
            host(
              MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
                child: ConversationTaskCard(
                  summary: cardSummary(
                    ConversationTaskStatus.paused,
                    tokenUsage: usage,
                  ),
                  expansionController: controller,
                  executionDetails: const Text('Execution details'),
                ),
              ),
              brightness: brightness,
            ),
          );
          await tester.pumpAndSettle();
        }

        await show(null);
        expect(find.text('Input tokens —'), findsOneWidget);
        expect(find.text('Output tokens —'), findsOneWidget);
        expect(find.text('Execution details'), findsNothing);
        await show(
          const ModelTokenUsage(inputTokens: 123456789, outputTokens: 0),
        );
        expect(find.text('Input tokens 123456789'), findsOneWidget);
        expect(find.text('Output tokens 0'), findsOneWidget);
        expect(find.byIcon(Icons.login_rounded), findsOneWidget);
        expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
        expect(find.text('Execution details'), findsNothing);
        expect(tester.takeException(), isNull);
        controller.value = ['task:abc12345678'];
        await tester.pumpAndSettle();
        expect(find.text('Input tokens 123456789'), findsOneWidget);
        expect(find.text('Execution details'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('collapsed task details can be toggled with the keyboard', (
    tester,
  ) async {
    final controller = ShadAccordionController<String>.multiple();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(
        ConversationTaskCard(
          summary: cardSummary(ConversationTaskStatus.waitingForUser),
          expansionController: controller,
          onAction: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Steps: 3/5'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Approve'), findsOneWidget);
    final heading = tester.widget<Semantics>(
      find.byKey(const ValueKey('task-heading-task:abc12345678')),
    );
    expect(heading.properties.expanded, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('Approve'), findsNothing);
    expect(controller.value, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('approval card retains the end of a long command', (
    tester,
  ) async {
    final summary = 'Approve run_shell_command: ${'x' * 3000} --final-option';
    await tester.pumpWidget(
      host(
        ConversationTaskCard(
          summary: cardSummary(
            ConversationTaskStatus.waitingForUser,
            approvalSummary: summary,
          ),
          onAction: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('--final-option'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final entry
      in {
        TaskReasonCode.toolUnavailableFor('run_shell_command'):
            'run_shell_command',
        TaskReasonCode.invalidPlan: 'The task plan is invalid',
        TaskReasonCode.missingCredentials:
            'Provider credentials are unavailable',
        TaskReasonCode.providerUnavailable: 'provider or model configuration',
        TaskReasonCode.botUnavailable: 'bot used by this task is unavailable',
        TaskReasonCode.reconciliationRequired: 'unknown outcome',
      }.entries) {
    testWidgets('card explains the persisted obstacle ${entry.key}', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          ConversationTaskCard(
            summary: cardSummary(
              ConversationTaskStatus.waitingForUser,
              waitingReason: TaskWaitingReason.requiredInput,
              reasonCode: entry.key,
            ),
            showStatusAction: false,
            onAction: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(entry.value), findsOneWidget);
      expect(
        find.textContaining(
          'Update the provider credentials or task configuration',
        ),
        findsNothing,
      );
      expect(find.text('Recheck and resume'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [320.0, 680.0, 1200.0]) {
    for (final status in ConversationTaskStatus.values) {
      testWidgets(
        'card $status fits width $width with semantic state and step counts',
        (tester) async {
          tester.view.physicalSize = Size(width, 950);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              host(
                ConversationTaskCard(
                  summary: cardSummary(status),
                  onAction: (_) {},
                  onRefresh: () {},
                ),
                desktop: width != 320,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text('Steps: 3/5'), findsOneWidget);
            expect(find.textContaining('%'), findsNothing);
            expect(
              find.text('Refresh tasks'),
              status.isTerminal ? findsNothing : findsOneWidget,
            );
            expect(
              find.bySemanticsLabel(RegExp('Tasks: Report.*abc12345')),
              findsWidgets,
            );
            if (status.isTerminal) {
              expect(find.text('Cancel task'), findsNothing);
            }
            if (status == ConversationTaskStatus.cancelRequested) {
              expect(find.text('Cancel task'), findsNothing);
            }
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
  testWidgets('keyboard activates status and approval actions', (tester) async {
    final actions = <TaskCardAction>[];
    await tester.pumpWidget(
      host(
        ConversationTaskCard(
          summary: cardSummary(ConversationTaskStatus.waitingForUser),
          onAction: actions.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(actions, [TaskCardAction.status]);
    await tester.tap(find.text('Approve'));
    await tester.pump();
    expect(actions.last, TaskCardAction.approve);
  });
  testWidgets('historical card only permits a fresh status query', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        ConversationTaskCard(
          summary: cardSummary(ConversationTaskStatus.waitingForUser),
          historical: true,
          onAction: (_) {},
          onRefresh: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('View status'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Cancel task'), findsNothing);
    expect(find.text('Refresh tasks'), findsNothing);
  });

  for (final width in [320.0, 680.0]) {
    testWidgets('refresh shares task action sizing and busy state at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var refreshes = 0;
      Widget card({bool busy = false}) => host(
        ConversationTaskCard(
          summary: cardSummary(
            ConversationTaskStatus.waitingForUser,
            waitingReason: TaskWaitingReason.requiredInput,
          ),
          showStatusAction: false,
          busy: busy,
          onAction: (_) {},
          onRefresh: () => refreshes++,
        ),
      );
      await tester.pumpWidget(card());
      await tester.pumpAndSettle();
      final refresh = find.byKey(
        const ValueKey('task-refresh-task:abc12345678'),
      );
      final refreshRect = tester.getRect(refresh);
      for (final element in find.byType(TaskActionButton).evaluate()) {
        final rect = tester.getRect(find.byWidget(element.widget));
        expect(rect.height, refreshRect.height);
        if (width > 600) expect(rect.top, refreshRect.top);
      }
      await tester.tap(refresh);
      expect(refreshes, 1);
      await tester.pumpWidget(card(busy: true));
      await tester.pumpAndSettle();
      await tester.tap(refresh);
      expect(refreshes, 1);
      expect(tester.takeException(), isNull);
    });
  }
  for (final desktop in [true, false]) {
    testWidgets(
      'retry dialog reviews input and policy before creating a task ($desktop)',
      (tester) async {
        String? submitted;
        await tester.pumpWidget(
          host(
            Builder(
              builder:
                  (context) => TextButton(
                    onPressed: () async {
                      submitted = await showConversationTaskRetryDialog(
                        context,
                        input: 'Reviewed report',
                        policyDescription: 'Strict verification',
                      );
                    },
                    child: const Text('open'),
                  ),
            ),
            desktop: desktop,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Strict verification'), findsOneWidget);
        expect(submitted, isNull);
        await tester.tap(find.text('Create new task'));
        await tester.pumpAndSettle();
        expect(submitted, 'Reviewed report');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
