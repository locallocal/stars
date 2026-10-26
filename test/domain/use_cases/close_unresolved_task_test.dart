import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/use_cases/conversation_task_runner_contracts.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/services/strict_grounding_policy.dart';
import 'package:stars/domain/use_cases/conversation_task_commands.dart';
import 'package:stars/domain/use_cases/prepare_conversation_task_retry.dart';
import 'package:stars/data/repositories/sqlite_message_repository.dart';
import '../../support/task_runner_harness.dart';

void main() {
  late TaskRunnerHarness h;
  setUp(() => h = TaskRunnerHarness());
  tearDown(() => h.close());

  Future<ConversationTask> park({bool cancel = false}) async {
    await h.open();
    var task = await h.db.task;
    if (cancel) {
      task = committed(
        await h.db.repository.requestCancellation(
          taskId: task.taskId,
          expectedRevision: task.revision,
          source: TaskCancellationSource.user,
          requestedAt: h.clock.now(),
        ),
      );
    }
    return committed(
      await h.db.repository.waitForTaskInput(
        taskId: task.taskId,
        expectedRevision: task.revision,
        reason: TaskWaitingReason.reconciliation,
        reasonCode: TaskReasonCode.reconciliationRequired,
        now: h.clock.now(),
      ),
    );
  }

  Future<TaskWriteResult<ConversationTask>> close(
    ConversationTask task, {
    String note = 'Reviewed external state; outcome cannot be established.',
  }) => ConversationTaskCommands(
    repository: h.db.repository,
    wake: (_) => fail('Closure must not restart execution'),
    clock: h.clock,
  ).closeUnresolved(
    taskId: task.taskId,
    expectedRevision: task.revision,
    actorId: 'me',
    note: note,
  );

  test(
    'interrupted write can be closed without replaying or rewriting its attempt',
    () async {
      await h.open();
      h.tool = RunnerTool(risk: ToolRiskLevel.write);
      h.models.tool();
      await h.db.failWrite(
        'conversation_task_events',
        when: "NEW.kind = 'toolSucceeded'",
      );
      await expectLater(h.run(), throwsA(isA<Exception>()));
      await h.db.clearFailure();
      h.clock.advance(const Duration(days: 2));
      h.tool.onReconcile = () async => const ToolOutcomeUnknown();
      final result = await h.run() as TaskNeedsSafeFinalization;
      final parked = committed(
        await h.db.repository.waitForTaskInput(
          taskId: result.snapshot.task.taskId,
          expectedRevision: result.snapshot.task.revision,
          reason: TaskWaitingReason.reconciliation,
          reasonCode: TaskReasonCode.reconciliationRequired,
          now: h.clock.now(),
        ),
      );
      final attempts = (await h.snapshot).attempts;
      committed(await close(parked));
      await h.db.reopen();
      expect((await h.db.task).status, ConversationTaskStatus.failed);
      expect(
        (await h.snapshot).attempts.single.status,
        ToolInvocationStatus.running,
      );
      expect(
        (await h.snapshot).attempts.single.attemptId,
        attempts.single.attemptId,
      );
      expect(h.tool.starts, 1);
      expect(await h.db.repository.listDue(now: h.clock.now()), isEmpty);
    },
  );

  for (final cancel in [false, true]) {
    test(
      'manual closure retains unknown effects and blocks retry, cancel=$cancel',
      () async {
        final parked = await park(cancel: cancel);
        await h.db.reopen();
        final ended = committed(await close(parked));
        expect(ended.status, ConversationTaskStatus.failed);
        expect(
          ended.terminalSummary!.sideEffectStatus,
          TaskSideEffectStatus.unknown,
        );
        expect(ended.terminalSummary!.canRetry, isFalse);
        expect(ended.cancelRequestedAt, parked.cancelRequestedAt);
        expect(await h.db.repository.listActiveForChat(ended.chatId), isEmpty);
        final snapshot =
            (await h.db.repository.getExecutionSnapshot(ended.taskId))!;
        expect(
          snapshot.events.last.safeSummary,
          contains('actor=me; note=Reviewed'),
        );
        final messages = SqliteMessageRepository(localDatabase: h.db.local);
        addTearDown(messages.dispose);
        final results = (await messages.getMessages(
          ended.chatId,
        )).where((m) => m.taskMessageKind == TaskMessageKind.result);
        expect(results, hasLength(1));
        expect(results.single.terminalOutcome, MessageTerminalOutcome.failed);
        expect(results.single.content, contains('未知'));
        expect(
          const StrictGroundingPolicy().present(results.single).content,
          results.single.content,
        );
        expect(await close(parked), isA<TaskWriteConflict<ConversationTask>>());
        await expectLater(
          PrepareConversationTaskRetry(
            tasks: h.db.repository,
            messages: messages,
          )(chatId: ended.chatId, botId: ended.botId, taskId: ended.taskId),
          throwsA(isA<Exception>()),
        );
      },
    );
  }

  test('message failure rolls back closure and audit event', () async {
    final task = await park();
    final before = await h.snapshot;
    await h.db.failWrite('messages');
    await expectLater(close(task), throwsA(isA<Exception>()));
    expect((await h.db.task).revision, task.revision);
    expect((await h.snapshot).events.length, before.events.length);
    await h.db.clearFailure();
    expect(committed(await close(task)).status, ConversationTaskStatus.failed);
  });

  test(
    'stale review and sensitive or empty notes cannot close a task',
    () async {
      final task = await park();
      for (final note in ['', 'password=secret-value']) {
        await expectLater(close(task, note: note), throwsArgumentError);
      }
      committed(
        await h.db.repository.resumeTask(
          taskId: task.taskId,
          expectedRevision: task.revision,
          now: h.clock.now(),
        ),
      );
      expect(await close(task), isA<TaskWriteConflict<ConversationTask>>());
      expect((await h.db.task).status.isTerminal, isFalse);
    },
  );
}
