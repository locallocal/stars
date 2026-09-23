import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/conversation_task_list_item.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/repositories/message_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart';
import 'package:stars/domain/use_cases/prepare_conversation_task_retry.dart';
import 'package:stars/ui/features/chat/view_models/conversation_tasks_view_model.dart';
import 'package:stars/ui/core/widgets/desktop_chat_primitives.dart';
import 'package:stars/ui/features/chat/views/conversation_task_card.dart';
import 'package:stars/ui/features/chat/views/conversation_tasks_page.dart';
import 'package:stars/ui/features/chat/views/conversation_task_execution_status.dart';
import 'package:stars/utils/theme.dart';

import '../../../../support/widget_test_support.dart'
    show shadHarness, withDesktopPlatform;
import '../../../../support/conversation_task_repository_harness.dart'
    show changeTask, taskFixture, taskPlan, taskTool, taskTime;
import 'conversation_task_card_test.dart' show cardSummary;

void main() {
  late _Tasks repository;
  late ConversationTasksViewModel vm;
  setUp(() {
    repository = _Tasks();
    vm = ConversationTasksViewModel(
      chatId: 'chat-1',
      botId: 'bot-1',
      observe: ObserveConversationTasks(repository),
      commands: ConversationTaskCommands(repository: repository, wake: (_) {}),
      prepareRetry: PrepareConversationTaskRetry(
        tasks: repository,
        messages: _Messages(),
      ),
    );
  });
  tearDown(() async {
    vm.dispose();
    await repository.events.close();
  });

  for (final width in [560.0, 1200.0]) {
    testWidgets('task scrollbar stays outside the centered cards at $width', (
      tester,
    ) async {
      await withDesktopPlatform(() async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await vm.start();
        await tester.pumpWidget(
          shadHarness(
            brightness: Brightness.light,
            homeBuilder:
                (_) => Scaffold(
                  body: ConversationTasksPage(
                    viewModel: vm,
                    onAction: (_, _) {},
                  ),
                ),
          ),
        );
        repository.events.add([
          for (var index = 0; index < 20; index++)
            _summary('task-$index', 'Report $index', index),
        ]);
        await tester.pumpAndSettle();
        final list = find.byKey(const ValueKey('conversation-tasks-list'));
        final controller = tester.widget<ListView>(list).controller!;
        final bar = find.byWidgetPredicate(
          (widget) => widget is Scrollbar && widget.controller == controller,
        );
        expect(bar, findsOneWidget);
        expect(tester.getRect(bar).right, width);
        expect(tester.getRect(bar).left, 0);
        final cardRect = tester.getRect(
          find.byType(ConversationTaskListCard).first,
        );
        final searchRect = tester.getRect(
          find.byKey(const ValueKey('conversation-tasks-search')),
        );
        expect(cardRect.left, closeTo(searchRect.left, .01));
        expect(
          cardRect.width,
          lessThanOrEqualTo(StarsDesktopThemeSpec.contentMaxWidth),
        );
        expect(width - cardRect.right, greaterThanOrEqualTo(32));
        await tester.drag(list, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(controller.offset, greaterThan(0));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    });
  }

  testWidgets(
    'task expansion loads persisted details and reopening uses the cache',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final task = changeTask(taskFixture(), {'revision': 4});
      repository.snapshot = TaskExecutionSnapshot(
        task: task,
        plan: taskPlan(task),
        lastSequence: 1,
        attempts: [taskTool(at: taskTime, arguments: '{"path":"report.md"}')],
      );
      await vm.start();
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (_) => Scaffold(
                body: ConversationTasksPage(viewModel: vm, onAction: (_, _) {}),
              ),
        ),
      );
      repository.events.add([_summary('task-1', 'Report', 0)]);
      await tester.pumpAndSettle();
      expect(repository.detailReads, 0);
      await _tapTaskHeading(tester, 'task-1');
      await tester.pumpAndSettle();
      expect(repository.detailReads, 1);
      expect(find.byType(ConversationTaskExecutionStatus), findsOneWidget);
      expect(find.textContaining('"path": "report.md"'), findsNothing);
      await tester.tap(find.text('read_file'));
      await tester.pumpAndSettle();
      expect(find.textContaining('"path": "report.md"'), findsOneWidget);
      final taskCard = find.byKey(const ValueKey('task-task-1'));
      expect(
        find.descendant(of: taskCard, matching: find.byType(Scrollbar)),
        findsNothing,
      );
      expect(
        find.descendant(of: taskCard, matching: find.byType(Scrollable)),
        findsNothing,
      );
      await _tapTaskHeading(tester, 'task-1');
      await tester.pumpAndSettle();
      expect(find.byType(ConversationTaskExecutionStatus), findsNothing);
      await _tapTaskHeading(tester, 'task-1');
      await tester.pumpAndSettle();
      expect(repository.detailReads, 1);
      expect(find.byType(ConversationTaskExecutionStatus), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'keyboard expansion loads approval details and retries failures locally',
    (tester) async {
      final pending = Completer<TaskExecutionSnapshot?>();
      repository.onRead = (_) => pending.future;
      await vm.start();
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (_) => Scaffold(
                body: ConversationTasksPage(viewModel: vm, onAction: (_, _) {}),
              ),
        ),
      );
      final summary = _summary('task-1', 'Review report', 0);
      repository.events.add([summary]);
      await tester.pumpAndSettle();
      expect(repository.detailReads, 0);
      expect(find.text('批准'), findsNothing);
      expect(find.byType(ConversationTaskCard), findsNothing);
      final heading = find.byKey(const ValueKey('task-heading-task-1'));
      final context = tester.element(heading);
      Focus.of(context).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(repository.detailReads, 1);
      expect(tester.widget<Semantics>(heading).properties.expanded, isTrue);
      expect(find.byType(ShadProgress), findsOneWidget);
      expect(find.text('批准'), findsNothing);
      pending.completeError(StateError('private detail read failure'));
      await tester.pumpAndSettle();
      expect(find.byType(ShadAlert), findsOneWidget);
      expect(find.textContaining('private detail read failure'), findsNothing);
      expect(vm.state.error, isFalse);
      repository.onRead = null;
      final retry = find.descendant(
        of: find.byType(ShadAlert),
        matching: find.byType(ShadButton),
      );
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(repository.detailReads, 2);
      expect(find.text('批准'), findsOneWidget);
      expect(find.byType(ShadAlert), findsNothing);
      await _tapTaskHeading(tester, 'task-1');
      await tester.pumpAndSettle();
      expect(find.byType(ConversationTaskCard), findsNothing);
      await _tapTaskHeading(tester, 'task-1');
      await tester.pumpAndSettle();
      expect(repository.detailReads, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final width in [320.0, 1200.0]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'task search, sorting and approval fit $width in $brightness',
        (tester) async {
          tester.view.physicalSize = Size(width, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final actions = <String>[];
          await vm.start();
          await tester.pumpWidget(
            shadHarness(
              brightness: brightness,
              homeBuilder:
                  (context) => Scaffold(
                    body: ConversationTasksPage(
                      viewModel: vm,
                      embedded: width > 600,
                      onAction:
                          (summary, action) =>
                              actions.add('${summary.taskId}/${action.name}'),
                    ),
                  ),
            ),
          );
          final older = _summary('old-task', 'Alpha report', 0);
          final newer = _summary('new-task', 'Beta report', 1);
          repository.events.add([newer, older]);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('查看状态'), findsNothing);
          expect(
            find.byKey(const ValueKey('conversation-tasks-refresh')),
            findsNothing,
          );
          final searchRect = tester.getRect(
            find.byKey(const ValueKey('conversation-tasks-search')),
          );
          final sortRect = tester.getRect(
            find.byKey(const ValueKey('conversation-tasks-sort')),
          );
          expect(sortRect.height, searchRect.height);
          expect(vm.visibleSummaries.first.taskId, 'new-task');
          if (width > 600) {
            expect(sortRect.top, searchRect.top);
            expect(sortRect.bottom, searchRect.bottom);
            expect(
              tester
                  .getSize(
                    find.byKey(const ValueKey('conversation-tasks-content')),
                  )
                  .width,
              lessThanOrEqualTo(StarsDesktopThemeSpec.contentMaxWidth),
            );
          }
          final search = find.descendant(
            of: find.byKey(const ValueKey('conversation-tasks-search')),
            matching: find.byType(EditableText),
          );
          await tester.enterText(search, '  BETA  ');
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('task-old-task')), findsNothing);
          expect(find.byKey(const ValueKey('task-new-task')), findsOneWidget);
          expect(find.text('批准'), findsNothing);
          await _tapTaskHeading(tester, 'new-task');
          await tester.pumpAndSettle();
          await tester.tap(find.text('批准'));
          await tester.pump();
          expect(actions, ['new-task/approve']);
          await tester.enterText(search, 'missing');
          await tester.pumpAndSettle();
          expect(find.text('未找到匹配的任务'), findsOneWidget);
          await tester.tap(
            find.byKey(const ValueKey('conversation-tasks-clear-search')),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('conversation-tasks-sort')),
          );
          await tester.pumpAndSettle();
          expect(vm.sort, ConversationTaskSort.oldestFirst);
          expect(
            tester
                .widgetList<ConversationTaskListCard>(
                  find.byType(ConversationTaskListCard),
                )
                .first
                .item
                .taskId,
            'old-task',
          );
          repository.events.add([older, newer]);
          await tester.pumpAndSettle();
          expect(vm.visibleSummaries.first.taskId, 'old-task');
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (final width in [320.0, 1200.0]) {
    testWidgets('pagination and expansion survive updates at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await vm.start();
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.dark,
          homeBuilder:
              (_) => Scaffold(
                body: ConversationTasksPage(
                  viewModel: vm,
                  embedded: width > 600,
                  onAction: (_, _) {},
                ),
              ),
        ),
      );
      final summaries = List.generate(
        41,
        (index) => _summary('task-$index', 'Report $index', index),
      );
      repository.events.add(summaries);
      await tester.pumpAndSettle();
      final previous = find.byKey(
        const ValueKey('conversation-tasks-previous-page'),
      );
      final next = find.byKey(const ValueKey('conversation-tasks-next-page'));
      final indicator = find.byKey(
        const ValueKey('conversation-tasks-page-indicator'),
      );
      final listFinder = find.byKey(const ValueKey('conversation-tasks-list'));
      expect(tester.widget<Text>(indicator).data, '1 / 3');
      expect(tester.widget<StarsDesktopIconAction>(previous).enabled, isFalse);
      expect(
        tester
            .widget<ListView>(listFinder)
            .childrenDelegate
            .estimatedChildCount,
        39,
      );
      expect(find.byKey(const ValueKey('task-task-40')), findsOneWidget);
      expect(find.byKey(const ValueKey('task-refresh-task-40')), findsNothing);
      await _tapTaskHeading(tester, 'task-40');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('task-refresh-task-40')),
        findsOneWidget,
      );
      repository.events.add(summaries.reversed.toList());
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('task-refresh-task-40')),
        findsOneWidget,
      );

      final scroll = tester.widget<ListView>(listFinder).controller!;
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(vm.visibleSummaries, hasLength(20));
      expect(tester.widget<Text>(indicator).data, '2 / 3');
      expect(scroll.offset, 0);
      expect(find.byKey(const ValueKey('task-task-20')), findsOneWidget);
      expect(find.byKey(const ValueKey('task-task-40')), findsNothing);
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(indicator).data, '3 / 3');
      expect(tester.widget<StarsDesktopIconAction>(next).enabled, isFalse);
      expect(find.byType(ConversationTaskListCard), findsOneWidget);
      expect(find.byKey(const ValueKey('task-task-0')), findsOneWidget);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('task-refresh-task-40')),
        findsOneWidget,
      );
      await _tapTaskHeading(tester, 'task-40');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('task-refresh-task-40')), findsNothing);

      await tester.tap(next);
      await tester.pumpAndSettle();
      final search = find.descendant(
        of: find.byKey(const ValueKey('conversation-tasks-search')),
        matching: find.byType(EditableText),
      );
      await tester.enterText(search, 'Report 40');
      await tester.pumpAndSettle();
      expect(vm.currentPage, 1);
      expect(tester.widget<Text>(indicator).data, '1 / 1');
      expect(tester.widget<StarsDesktopIconAction>(next).enabled, isFalse);
      expect(find.byKey(const ValueKey('task-task-40')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final status in [
    ConversationTaskStatus.succeeded,
    ConversationTaskStatus.failed,
  ]) {
    testWidgets('live $status task hides refresh while expanded', (
      tester,
    ) async {
      await vm.start();
      await tester.pumpWidget(
        shadHarness(
          brightness: Brightness.light,
          homeBuilder:
              (_) => Scaffold(
                body: ConversationTasksPage(viewModel: vm, onAction: (_, _) {}),
              ),
        ),
      );
      final active = cardSummary(ConversationTaskStatus.queued);
      repository.events.add([active]);
      await tester.pumpAndSettle();
      await _tapTaskHeading(tester, active.taskId);
      await tester.pumpAndSettle();
      final refresh = find.byKey(ValueKey('task-refresh-${active.taskId}'));
      expect(refresh, findsOneWidget);

      repository.events.add([cardSummary(status)]);
      await tester.pumpAndSettle();

      expect(refresh, findsNothing);
      expect(find.text('刷新任务'), findsNothing);
      final heading = tester.widget<Semantics>(
        find.byKey(ValueKey('task-heading-${active.taskId}')),
      );
      expect(heading.properties.expanded, isTrue);
      expect(repository.subscriptions, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('stream failure can refresh into an empty task list', (
    tester,
  ) async {
    await vm.start();
    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (_) => Scaffold(
              body: ConversationTasksPage(viewModel: vm, onAction: (_, _) {}),
            ),
      ),
    );
    repository.events.addError(StateError('private storage failure'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('conversation-tasks-error')),
      findsOneWidget,
    );
    expect(find.textContaining('private storage failure'), findsNothing);
    expect(vm.state.loading, isFalse);
    await tester.tap(
      find.byKey(const ValueKey('conversation-tasks-retry-load')),
    );
    // The controller is created in setUp, outside WidgetTester's fake clock.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(repository.subscriptions, 2);
    expect(vm.state.error, isFalse);
    expect(repository.refreshes, [false, true]);
    repository.events.add([]);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('conversation-tasks-error')),
      findsNothing,
    );
    expect(find.text('当前会话没有任务。'), findsOneWidget);
    expect(repository.subscriptions, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('card refresh restores progress and retains search and sorting', (
    tester,
  ) async {
    await vm.start();
    await tester.pumpWidget(
      shadHarness(
        brightness: Brightness.light,
        homeBuilder:
            (_) => Scaffold(
              body: ConversationTasksPage(viewModel: vm, onAction: (_, _) {}),
            ),
      ),
    );
    repository.events.add([_summary('task-1', 'Report', 0)]);
    await tester.pumpAndSettle();
    final search = find.descendant(
      of: find.byKey(const ValueKey('conversation-tasks-search')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(search, 'Report');
    await tester.tap(find.byKey(const ValueKey('conversation-tasks-sort')));
    repository.events.addError(StateError('storage unavailable'));
    await tester.pumpAndSettle();
    await _tapTaskHeading(tester, 'task-1');
    await tester.pumpAndSettle();
    final refresh = find.descendant(
      of: find.byKey(const ValueKey('task-task-1')),
      matching: find.byKey(const ValueKey('task-refresh-task-1')),
    );
    expect(refresh, findsOneWidget);
    expect(
      find.byKey(const ValueKey('conversation-tasks-retry-load')),
      findsNothing,
    );
    await tester.ensureVisible(refresh);
    await tester.pumpAndSettle();
    await tester.tap(refresh);
    await tester.pump();
    final button = find.descendant(
      of: refresh,
      matching: find.byType(ShadButton),
    );
    expect(tester.widget<ShadButton>(button).enabled, isFalse);
    expect(
      find.byKey(const ValueKey('conversation-tasks-refresh-progress')),
      findsOneWidget,
    );
    // Subscription cancellation runs outside WidgetTester's fake clock.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(repository.subscriptions, 2);
    expect(repository.refreshes, [false, true]);
    await tester.tap(refresh);
    await tester.pump();
    expect(repository.subscriptions, 2);
    expect(find.byKey(const ValueKey('task-task-1')), findsOneWidget);
    repository.events.add([_summary('task-1', 'Updated report', 0)]);
    await tester.pumpAndSettle();
    expect(vm.query, 'Report');
    expect(vm.sort, ConversationTaskSort.oldestFirst);
    expect(find.textContaining('Updated report'), findsOneWidget);
    expect(tester.widget<ShadButton>(button).enabled, isTrue);
    expect(
      find.byKey(const ValueKey('conversation-tasks-refresh-progress')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('conversation-tasks-error')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<void> _tapTaskHeading(WidgetTester tester, String taskId) => tester.tap(
  find
      .descendant(
        of: find.byKey(ValueKey('task-heading-$taskId')),
        matching: find.byType(Text),
      )
      .first,
);

ConversationTaskProgressSummary _summary(String id, String title, int minutes) {
  final source = cardSummary(ConversationTaskStatus.waitingForUser);
  return ConversationTaskProgressSummary(
    taskId: id,
    chatId: source.chatId,
    title: title,
    status: source.status,
    phase: source.phase,
    planRevision: source.planRevision,
    summaryRevision: source.summaryRevision,
    progress: source.progress,
    waitingReason: source.waitingReason,
    createdAt: source.createdAt.add(Duration(minutes: minutes)),
    updatedAt: source.updatedAt.add(const Duration(hours: 2)),
  );
}

final class _Tasks implements ConversationTaskRepository {
  TaskExecutionSnapshot? snapshot;
  Future<TaskExecutionSnapshot?> Function(String)? onRead;
  int detailReads = 0;
  final _summaries = <String, ConversationTaskProgressSummary>{};
  final _revisions = <String, int>{};
  @override
  Future<TaskExecutionSnapshot?> getExecutionSnapshot(String taskId) async {
    detailReads++;
    if (onRead case final read?) return read(taskId);
    if (snapshot != null) return snapshot;
    final summary = _summaries[taskId]!;
    final task = changeTask(
      taskFixture(
        id: taskId,
        status: summary.status,
        progress: summary.progress,
      ),
      {
        'revision': _revisions[taskId]!,
        'title': summary.title,
        'phase': summary.phase.name,
        'waiting_reason': summary.waitingReason?.name,
      },
    );
    return TaskExecutionSnapshot(
      task: task,
      plan: taskPlan(task),
      lastSequence: 0,
    );
  }

  final events =
      StreamController<List<ConversationTaskProgressSummary>>.broadcast();
  int subscriptions = 0;
  final refreshes = <bool>[];
  @override
  Stream<List<ConversationTaskListItem>> watchForChat(
    String chatId, {
    bool refresh = false,
  }) {
    subscriptions++;
    refreshes.add(refresh);
    return events.stream.map(
      (values) => [for (final summary in values) _item(summary)],
    );
  }

  ConversationTaskListItem _item(ConversationTaskProgressSummary summary) {
    final old = _summaries[summary.taskId];
    final revision =
        old != null && !identical(old, summary)
            ? _revisions[summary.taskId]! + 1
            : _revisions[summary.taskId] ?? summary.summaryRevision;
    _summaries[summary.taskId] = summary;
    _revisions[summary.taskId] = revision;
    final source = ConversationTaskListItem.fromSummary(summary);
    return ConversationTaskListItem(
      taskId: source.taskId,
      chatId: source.chatId,
      title: source.title,
      status: source.status,
      phase: source.phase,
      summaryRevision: revision,
      createdAt: source.createdAt,
      updatedAt: source.updatedAt,
      completedSteps: source.completedSteps,
      totalSteps: source.totalSteps,
      currentStepSummary: source.currentStepSummary,
      latestToolName: source.latestToolName,
      tokenUsage: source.tokenUsage,
      leaseExpiresAt: source.leaseExpiresAt,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Messages implements MessageRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
