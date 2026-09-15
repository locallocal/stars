import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/ui/features/chat/views/conversation_task_card.dart';
import 'package:stars/ui/features/chat/views/conversation_task_retry_dialog.dart';
import 'package:stars/utils/theme.dart';
import '../../../../support/conversation_task_fixtures.dart';

ConversationTaskProgressSummary cardSummary(ConversationTaskStatus status) =>
    ConversationTaskProgressSummary(
      taskId: 'task:abc12345678',
      chatId: 'chat-1',
      title: 'Report',
      status: status,
      phase: ConversationTaskPhase.executing,
      planRevision: 1,
      summaryRevision: 4,
      updatedAt: taskTime,
      waitingReason:
          status == ConversationTaskStatus.waitingForUser
              ? TaskWaitingReason.approval
              : null,
      progress: TaskProgress(
        totalSteps: 5,
        completedSteps: 3,
        lastMeaningfulProgressAt: taskTime,
        currentStepSummary: 'Read notes',
        recoveries: 2,
        pendingApprovalId:
            status == ConversationTaskStatus.waitingForUser ? 'approval' : null,
        pendingApprovalSummary:
            status == ConversationTaskStatus.waitingForUser
                ? 'Save notes'
                : null,
        approvalRequestedAt:
            status == ConversationTaskStatus.waitingForUser ? taskTime : null,
      ),
      terminalSummary:
          {
                ConversationTaskStatus.failed,
                ConversationTaskStatus.cancelled,
              }.contains(status)
              ? taskTerminal(status)
              : null,
    );
Widget host(Widget child, {bool desktop = true}) {
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
        theme: buildStarsShadTheme(brightness: Brightness.light, fontSize: 14),
        appBuilder: (context) => app(context),
      )
      : app(null);
}

void main() {
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
                ),
                desktop: width != 320,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text('Steps: 3/5'), findsOneWidget);
            expect(find.textContaining('%'), findsNothing);
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
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('View status'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Cancel task'), findsNothing);
  });
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
