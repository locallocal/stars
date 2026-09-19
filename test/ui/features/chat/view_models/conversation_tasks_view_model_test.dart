import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/models/conversation_task_record.dart';
import 'package:stars/data/models/local_records.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart'
    show ObserveConversationTasks;
import 'package:stars/domain/use_cases/prepare_conversation_task_retry.dart';
import 'package:stars/ui/features/chat/view_models/conversation_tasks_view_model.dart';
import '../../../../support/conversation_task_repository_harness.dart';
import '../../../../support/task_runner_harness.dart' show RunnerClock;
import '../../../../support/task_scheduler_harness.dart' show until;

void main() {
  late TaskRepositoryHarness h;
  late SqliteMessageRepository messages;
  late ConversationTasksViewModel vm;
  final clock = RunnerClock();
  final wakes = <String>[];
  ConversationTasksViewModel create({
    TaskRetryDispatcher? retry,
    bool Function()? available,
  }) => ConversationTasksViewModel(
    chatId: 'chat-1',
    botId: 'bot-1',
    observe: ObserveConversationTasks(h.repository, clock: clock),
    commands: ConversationTaskCommands(
      repository: h.repository,
      clock: clock,
      wake: wakes.add,
    ),
    prepareRetry: PrepareConversationTaskRetry(
      tasks: h.repository,
      messages: messages,
    ),
    dispatchRetry: retry,
    retryAvailable: available,
  );
  setUp(() async {
    h = TaskRepositoryHarness();
    await h.open();
    messages = SqliteMessageRepository(localDatabase: h.local);
    clock.time = taskTime;
    wakes.clear();
    vm = create();
    await vm.start();
    await until(() => !vm.state.loading);
  });
  tearDown(() async {
    vm.dispose();
    await messages.dispose();
    await h.close();
  });

  Future<_SnapshotTasks> watchSnapshots() async {
    vm.dispose();
    final repository = _SnapshotTasks();
    addTearDown(repository.events.close);
    vm = ConversationTasksViewModel(
      chatId: 'chat-1',
      botId: 'bot-1',
      observe: ObserveConversationTasks(repository, clock: clock),
      commands: ConversationTaskCommands(repository: repository, wake: (_) {}),
      prepareRetry: PrepareConversationTaskRetry(
        tasks: repository,
        messages: messages,
      ),
    );
    await vm.start();
    return repository;
  }

  test(
    'loads expanded tasks only and refreshes committed history after cancellation',
    () async {
      committed(await h.accept());
      await until(() => vm.state.summaries.isNotEmpty);
      expect(vm.executionFor('task-1').data, isNull);
      vm.setExpandedTasks(['task-1']);
      await until(() => vm.executionFor('task-1').data != null);
      final original = vm.executionFor('task-1').data!;
      expect(original.activities.single.event.kind, TaskEventKind.queued);
      vm.setExpandedTasks([]);
      await vm.cancel(vm.state.summaries.single);
      await until(
        () =>
            vm.state.summaries.single.status ==
            ConversationTaskStatus.cancelRequested,
      );
      expect(vm.executionFor('task-1').data, same(original));
      vm.setExpandedTasks(['task-1']);
      await until(
        () => vm.executionFor('task-1').data!.revision > original.revision,
      );
      expect(
        vm.executionFor('task-1').data!.activities.last.event.kind,
        TaskEventKind.cancellationRequested,
      );
      expect(
        () => vm.executionFor('task-1').data!.activities.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'coalesces live updates during a read and caches the newest revision',
    () async {
      committed(await h.accept());
      final before = (await h.repository.getExecutionSnapshot('task-1'))!;
      final repository = await watchSnapshots();
      final pending = Completer<TaskExecutionSnapshot?>();
      repository.onRead = (_) => pending.future;
      repository.events.add([
        (await h.repository.getProgressSummary('task-1'))!,
      ]);
      await until(() => !vm.state.loading);
      vm.setExpandedTasks(['task-1']);
      await until(() => repository.reads == 1);
      await vm.loadExecution('task-1');
      expect(repository.reads, 1);
      committed(
        await h.repository.requestCancellation(
          taskId: 'task-1',
          expectedRevision: 0,
          source: TaskCancellationSource.user,
          requestedAt: taskTime,
        ),
      );
      final latest = (await h.repository.getExecutionSnapshot('task-1'))!;
      repository.events.add([
        (await h.repository.getProgressSummary('task-1'))!,
      ]);
      await until(
        () => vm.state.summaries.single.summaryRevision == latest.task.revision,
      );
      repository.onRead = (_) async => latest;
      pending.complete(before);
      await until(
        () => vm.executionFor('task-1').data?.revision == latest.task.revision,
      );
      expect(repository.reads, 2);
      vm.setExpandedTasks([]);
      vm.setExpandedTasks(['task-1']);
      await vm.loadExecution('task-1');
      expect(repository.reads, 2);
    },
  );

  test(
    'detail loading errors are local and can be retried; disposal ignores late reads',
    () async {
      committed(await h.accept());
      final snapshot = (await h.repository.getExecutionSnapshot('task-1'))!;
      final repository = await watchSnapshots();
      repository.onRead = (_) async => throw StateError('storage unavailable');
      repository.events.add([
        (await h.repository.getProgressSummary('task-1'))!,
      ]);
      await until(() => !vm.state.loading);
      vm.setExpandedTasks(['task-1']);
      await until(() => vm.executionFor('task-1').error);
      expect(vm.state.error, isFalse);
      repository.onRead = (_) async => snapshot;
      await vm.loadExecution('task-1', force: true);
      expect(vm.executionFor('task-1').error, isFalse);
      final pending = Completer<TaskExecutionSnapshot?>();
      repository.onRead = (_) => pending.future;
      final loading = vm.loadExecution('task-1', force: true);
      vm.dispose();
      pending.complete(snapshot);
      await loading;
    },
  );

  test(
    'paginates sorted tasks in groups of 20 and resets for search and sort',
    () async {
      final repository = await watchSnapshots();
      repository.events.add(List.generate(41, _pageSummary));
      await until(() => !vm.state.loading);
      expect(vm.sort, ConversationTaskSort.newestFirst);
      expect(vm.currentPage, 1);
      expect(vm.totalPages, 3);
      expect(vm.filteredCount, 41);
      expect(vm.visibleSummaries, hasLength(20));
      expect(vm.visibleSummaries.first.taskId, 'task-40');
      expect(vm.visibleSummaries.last.taskId, 'task-21');
      expect(vm.firstVisibleItem, 1);
      expect(vm.lastVisibleItem, 20);
      expect(vm.hasPreviousPage, isFalse);
      vm.previousPage();
      expect(vm.currentPage, 1);

      vm.nextPage();
      expect(vm.currentPage, 2);
      expect(vm.visibleSummaries, hasLength(20));
      expect(vm.visibleSummaries.first.taskId, 'task-20');
      expect(vm.visibleSummaries.last.taskId, 'task-01');
      expect(vm.firstVisibleItem, 21);
      expect(vm.lastVisibleItem, 40);
      vm.nextPage();
      expect(vm.visibleSummaries.single.taskId, 'task-00');
      expect(vm.currentPage, 3);
      expect(vm.hasNextPage, isFalse);
      vm.nextPage();
      expect(vm.currentPage, 3);
      expect(vm.firstVisibleItem, 41);
      expect(vm.lastVisibleItem, 41);
      expect(() => vm.visibleSummaries.clear(), throwsUnsupportedError);

      vm.search('Report task-0');
      expect(vm.currentPage, 1);
      expect(vm.totalPages, 1);
      expect(vm.filteredCount, 10);
      expect(vm.visibleSummaries.first.taskId, 'task-09');
      vm.search('');
      vm.nextPage();
      vm.toggleSort();
      expect(vm.currentPage, 1);
      expect(vm.visibleSummaries.first.taskId, 'task-00');
      expect(vm.visibleSummaries.last.taskId, 'task-19');
      vm.search('missing');
      expect(vm.visibleSummaries, isEmpty);
      expect(vm.currentPage, 0);
      expect(vm.totalPages, 0);
      expect(vm.hasNextPage, isFalse);
      expect(vm.hasPreviousPage, isFalse);
    },
  );

  test(
    'live updates retain the page and clamp it when tasks disappear',
    () async {
      final repository = await watchSnapshots();
      repository.events.add(List.generate(41, _pageSummary));
      await until(() => !vm.state.loading);
      vm.nextPage();
      repository.events.add(List.generate(42, _pageSummary));
      await until(() => vm.filteredCount == 42);
      expect(vm.currentPage, 2);
      await vm.start();
      repository.events.add(List.generate(42, _pageSummary));
      await until(() => !vm.state.loading);
      expect(vm.currentPage, 2);
      vm.nextPage();
      repository.events.add(List.generate(21, _pageSummary));
      await until(() => vm.filteredCount == 21);
      expect(vm.currentPage, 2);
      expect(vm.visibleSummaries.single.taskId, 'task-00');
      repository.events.add([_pageSummary(0)]);
      await until(() => vm.filteredCount == 1);
      expect(vm.currentPage, 1);
      repository.events.add([]);
      await until(() => vm.filteredCount == 0);
      expect(vm.currentPage, 0);
      expect(vm.visibleSummaries, isEmpty);
      expect(vm.firstVisibleItem, 0);
      expect(vm.lastVisibleItem, 0);
    },
  );

  test(
    'reviewed retry revalidates the task, forwards current policy, and prevents duplicate submission',
    () async {
      await h.start();
      final write = await h.terminal(ConversationTaskStatus.failed);
      final row = ConversationTaskRecord.fromDomain(write.task).values;
      final terminal =
          jsonDecode(row['terminal_summary_json']! as String)
              as Map<String, Object?>;
      committed(
        await TaskTerminalWrite(
          task: changeTask(write.task, {
            'terminal_summary_json': jsonEncode({
              ...terminal,
              'sideEffectStatus': 'none',
            }),
          }),
          event: write.event,
          lease: write.lease,
          revision: write.revision,
        ).commit(h.repository),
      );
      final calls = <String>[];
      final gate = Completer<void>();
      final policy = VerificationPolicySnapshot(
        reliabilityEnabled: true,
        strictGroundingEnabled: false,
        showVerificationStatus: false,
      );
      var available = true;
      vm.dispose();
      vm = create(
        available: () => available,
        retry: (draft, input, language, verification) async {
          calls.add('${draft.taskId}/$input/$language');
          expect(verification, same(policy));
          await gate.future;
        },
      );
      await vm.start();
      await until(() => !vm.state.loading);
      final draft = await vm.retryDraft(vm.state.summaries.single);
      Future<void> submit([ConversationTaskRetryDraft? reviewed]) =>
          vm.retryReviewed(
            draft: reviewed ?? draft,
            input: 'Reviewed input',
            language: 'en',
            verification: policy,
          );
      final pending = submit();
      await until(() => calls.isNotEmpty);
      expect(vm.state.pendingCommands, {'task-1'});
      await submit();
      expect(calls, ['task-1/Reviewed input/en']);
      gate.complete();
      await pending;
      expect(vm.state.pendingCommands, isEmpty);
      expect(vm.state.error, isFalse);
      expect((await h.task).status, ConversationTaskStatus.failed);
      available = false;
      await submit();
      expect(vm.state.error, isTrue);
      available = true;
      await submit(
        const ConversationTaskRetryDraft(
          taskId: 'unknown',
          input: 'Wrong scope',
        ),
      );
      expect(calls, hasLength(1));
      expect(vm.state.error, isTrue);
    },
  );

  test(
    'search and creation-time sorting survive live updates and refresh',
    () async {
      Future<void> add(
        String id,
        String title,
        int minutes, {
        String chat = 'chat-1',
      }) async {
        final created = taskTime.add(Duration(minutes: minutes));
        committed(
          await h.accept(
            task: changeTask(taskFixture(id: id), {
              'title': title,
              'chat_id': chat,
              'created_at': created.microsecondsSinceEpoch,
              'updated_at': created.microsecondsSinceEpoch,
            }),
          ),
        );
      }

      await add('task-z', 'Alpha report', 0);
      await add('task-b', 'Beta report', 1);
      await add('task-a', 'Gamma notes', 1);
      await add('other-task', 'Other report', 0, chat: 'other-chat');
      await until(() => vm.state.summaries.length == 3);
      List<String> ids() => vm.visibleSummaries.map((s) => s.taskId).toList();
      expect(ids(), ['task-b', 'task-a', 'task-z']);
      expect(
        vm.visibleSummaries.first.createdAt,
        taskTime.add(const Duration(minutes: 1)),
      );
      expect(() => vm.visibleSummaries.clear(), throwsUnsupportedError);
      vm.search('  REPORT beta  ');
      expect(ids(), ['task-b']);
      vm.search('task-a');
      expect(ids(), ['task-a']);
      vm.search('missing');
      expect(ids(), isEmpty);
      vm.search('');
      vm.toggleSort();
      expect(ids(), ['task-z', 'task-a', 'task-b']);
      clock.advance(const Duration(hours: 1));
      await vm.cancel(vm.visibleSummaries.last);
      await until(
        () =>
            vm.visibleSummaries.last.status ==
            ConversationTaskStatus.cancelRequested,
      );
      expect(ids(), ['task-z', 'task-a', 'task-b']);
      expect(vm.visibleSummaries.last.updatedAt, clock.time);
      vm.search('report');
      await vm.start();
      await until(() => !vm.state.loading);
      expect(vm.query, 'report');
      expect(vm.sort, ConversationTaskSort.oldestFirst);
      expect(ids(), ['task-z', 'task-b']);
    },
  );

  test(
    'page disposal does not cancel; reentry restores the persisted progress',
    () async {
      committed(await h.accept());
      await until(() => vm.state.summaries.isNotEmpty);
      vm.dispose();
      expect((await h.task).cancelRequestedAt, isNull);
      expect(wakes, isEmpty);
      vm = create();
      await vm.start();
      await until(() => !vm.state.loading);
      expect(vm.state.summaries.single.taskId, 'task-1');
      expect(() => vm.state.summaries.clear(), throwsUnsupportedError);
    },
  );
  test(
    'reentry lists every historical terminal task and keeps conversation scope',
    () async {
      for (final id in ['old-success', 'old-failure', 'recent-success']) {
        final status =
            id == 'old-failure'
                ? ConversationTaskStatus.failed
                : ConversationTaskStatus.succeeded;
        committed(await h.accept(task: taskFixture(id: id)));
        final terminal = taskFixture(id: id, status: status);
        final values = ConversationTaskRecord.fromDomain(terminal).values;
        // Seed historical terminal rows; terminal transaction behavior has its own suite.
        await h.database.transaction((tx) async {
          await tx.insert(
            'messages',
            MessageRecord.fromDomain(taskMessage(terminal)).values,
          );
          await tx.update(
            'conversation_tasks',
            values,
            where: 'task_id = ?',
            whereArgs: [id],
          );
        });
      }
      vm.dispose();
      await messages.dispose();
      await h.reopen();
      messages = SqliteMessageRepository(localDatabase: h.local);
      vm = create();
      await vm.start();
      await until(() => !vm.state.loading);
      expect(
        vm.state.summaries.map((s) => s.taskId),
        unorderedEquals(['old-success', 'old-failure', 'recent-success']),
      );
      expect(vm.state.summaries.every((s) => s.status.isTerminal), isTrue);
      vm.search('old-');
      expect(vm.visibleSummaries, hasLength(2));
    },
  );
  test('cancel displays cancelRequested until terminal commit', () async {
    committed(await h.accept());
    await until(() => vm.state.summaries.isNotEmpty);
    await vm.cancel(vm.state.summaries.single);
    await until(
      () =>
          vm.state.summaries.single.status ==
          ConversationTaskStatus.cancelRequested,
    );
    expect((await h.task).completedAt, isNull);
    expect(wakes, ['task-1']);
    expect(vm.state.pendingCommands, isEmpty);
  });
  test('stale action reports a conflict without guessing a status', () async {
    committed(await h.accept());
    await until(() => vm.state.summaries.isNotEmpty);
    final stale = vm.state.summaries.single;
    committed(
      await h.repository.tryAcquireLease(
        taskId: 'task-1',
        expectedRevision: 0,
        lease: taskLease(),
        now: taskTime,
      ),
    );
    await vm.cancel(stale);
    expect(vm.state.error, isTrue);
    expect((await h.task).cancelRequestedAt, isNull);
    expect(wakes, isEmpty);
  });
  test(
    'approval survives a long wait and process restart and commits once',
    () async {
      await h.start();
      final task = await h.task;
      committed(
        await h.repository.appendProgress(
          await h.update(
            TaskEventKind.approvalRequested,
            status: ConversationTaskStatus.waitingForUser,
            waitingReason: TaskWaitingReason.approval,
            approval: TaskApprovalRecord(
              approvalId: 'approve',
              taskId: task.taskId,
              requestRevision: task.revision + 1,
              safeActionSummary: 'Allow read',
              requestedAt: h.nextTime,
            ),
          ),
        ),
      );
      vm.dispose();
      await messages.dispose();
      await h.reopen();
      messages = SqliteMessageRepository(localDatabase: h.local);
      clock.time = h.time.add(const Duration(days: 7));
      vm = create();
      await vm.start();
      await until(() => !vm.state.loading);
      final summary = vm.state.summaries.single;
      expect(summary.progress.pendingApprovalId, 'approve');
      await vm.decide(summary, TaskApprovalDecision.approved);
      final approval =
          (await h.repository.getExecutionSnapshot('task-1'))!.approvals.single;
      expect(approval.decision, TaskApprovalDecision.approved);
      expect(wakes, ['task-1']);
      await vm.decide(summary, TaskApprovalDecision.denied);
      expect(vm.state.error, isTrue);
      expect(wakes, ['task-1']);
      expect(
        (await h.repository.getExecutionSnapshot(
          'task-1',
        ))!.approvals.single.decision,
        TaskApprovalDecision.approved,
      );
    },
  );
  test(
    'explicit recheck resumes configuration wait without changing the objective',
    () async {
      committed(await h.accept());
      committed(
        await h.repository.waitForTaskInput(
          taskId: 'task-1',
          expectedRevision: 0,
          reason: TaskWaitingReason.authentication,
          reasonCode: TaskReasonCode.missingCredentials,
          now: clock.now(),
        ),
      );
      await until(
        () =>
            vm.state.summaries.isNotEmpty &&
            vm.state.summaries.single.waitingReason != null,
      );
      final objective = (await h.task).objective;
      await vm.resume(vm.state.summaries.single);
      expect((await h.task).status, ConversationTaskStatus.queued);
      expect((await h.task).objective, objective);
      expect(wakes, ['task-1']);
    },
  );
}

ConversationTaskProgressSummary _pageSummary(int index) {
  final time = taskTime.add(Duration(minutes: index));
  final number = index.toString().padLeft(2, '0');
  return ConversationTaskProgressSummary(
    taskId: 'task-$number',
    chatId: 'chat-1',
    title: 'Report $number',
    status: ConversationTaskStatus.queued,
    phase: ConversationTaskPhase.executing,
    planRevision: 1,
    summaryRevision: 0,
    progress: TaskProgress(totalSteps: 1, lastMeaningfulProgressAt: time),
    createdAt: time,
    updatedAt: time,
  );
}

final class _SnapshotTasks implements ConversationTaskRepository {
  int reads = 0;
  Future<TaskExecutionSnapshot?> Function(String)? onRead;
  @override
  Future<TaskExecutionSnapshot?> getExecutionSnapshot(String taskId) async {
    reads++;
    return onRead?.call(taskId);
  }

  final events =
      StreamController<List<ConversationTaskProgressSummary>>.broadcast();
  @override
  Stream<List<ConversationTaskProgressSummary>> watchForChat(String chatId) =>
      events.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
