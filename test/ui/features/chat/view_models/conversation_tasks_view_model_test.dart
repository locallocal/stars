import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';
import 'package:stars/domain/use_cases/present_conversation_task_progress.dart';
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
  ConversationTasksViewModel create() => ConversationTasksViewModel(
    chatId: 'chat-1',
    botId: 'bot-1',
    observe: ObserveConversationTasks(h.repository, clock: clock),
    present: PresentConversationTaskProgress(
      repository: h.repository,
      newId: messages.createId,
    ),
    commands: ConversationTaskCommands(
      repository: h.repository,
      clock: clock,
      wake: wakes.add,
    ),
    prepareRetry: PrepareConversationTaskRetry(
      tasks: h.repository,
      messages: messages,
    ),
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
