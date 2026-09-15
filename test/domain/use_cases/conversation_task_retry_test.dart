import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/models/conversation_task_record.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/use_cases/conversation_turn_dispatcher.dart';
import 'package:stars/domain/use_cases/prepare_conversation_task_retry.dart';
import '../../support/foreground_dispatch_harness.dart';

void main() {
  late ForegroundDispatchHarness h;
  setUp(() async {
    h = ForegroundDispatchHarness();
    await h.open();
    h.background();
  });
  tearDown(() => h.close());
  Future<ConversationTask> failed({
    TaskSideEffectStatus effects = TaskSideEffectStatus.none,
  }) async {
    await h.storage.start();
    final write = await h.storage.terminal(ConversationTaskStatus.failed);
    final row = ConversationTaskRecord.fromDomain(write.task).values;
    final terminal =
        jsonDecode(row['terminal_summary_json']! as String)
            as Map<String, Object?>;
    final next = changeTask(write.task, {
      'terminal_summary_json': jsonEncode({
        ...terminal,
        'sideEffectStatus': effects.name,
      }),
    });
    return committed(
      await TaskTerminalWrite(
        task: next,
        event: write.event,
        lease: write.lease,
        revision: write.revision,
      ).commit(h.storage.repository),
    );
  }

  ConversationTurnInput input(
    String original, {
    String content = 'Reviewed input',
  }) {
    final source = foregroundInput(turnId: 'retry-turn', content: content);
    return ConversationTurnInput(
      bot: source.bot,
      userMessage: source.userMessage,
      language: 'en',
      verification: VerificationPolicySnapshot(
        reliabilityEnabled: false,
        strictGroundingEnabled: false,
        showVerificationStatus: false,
      ),
      segmentLimits: TaskSegmentLimits(maxToolCalls: 2),
      retryOfTaskId: original,
    );
  }

  test(
    'reviewed retry creates new linked task with current input and policies',
    () async {
      final original = await failed();
      final prepare = PrepareConversationTaskRetry(
        tasks: h.storage.repository,
        messages: h.messages,
      );
      final draft = await prepare(
        chatId: 'chat-1',
        botId: 'bot-1',
        taskId: original.taskId,
      );
      expect(draft.input, original.objective);
      final result =
          await h.dispatcher.dispatch(input(draft.taskId)) as TurnTaskAccepted;
      expect(result.task.taskId, isNot(original.taskId));
      expect(result.task.retryOfTaskId, original.taskId);
      expect(result.task.verificationPolicy.strictGroundingEnabled, isFalse);
      expect(result.task.acceptance.segmentLimits.maxToolCalls, 2);
      expect(result.task.acceptance.context.last.content, 'Reviewed input');
      expect(result.task.progress.toolAttempts, 0);
      expect(
        (await h.storage.repository.getExecutionSnapshot(
          result.task.taskId,
        ))!.approvals,
        isEmpty,
      );
      expect(
        ConversationTaskRecord.fromDomain(
          (await h.storage.repository.getById(original.taskId))!,
        ).values,
        ConversationTaskRecord.fromDomain(original).values,
      );
      await h.storage.reopen();
      expect(
        (await h.storage.repository.getById(result.task.taskId))!.retryOfTaskId,
        original.taskId,
      );
    },
  );
  for (final effects in [
    TaskSideEffectStatus.irreversible,
    TaskSideEffectStatus.unknown,
    TaskSideEffectStatus.reconciled,
  ]) {
    test(
      'does not replay tasks with $effects effects even if a caller bypasses review',
      () async {
        final original = await failed(effects: effects);
        final prepare = PrepareConversationTaskRetry(
          tasks: h.storage.repository,
          messages: h.messages,
        );
        await expectLater(
          prepare(chatId: 'chat-1', botId: 'bot-1', taskId: original.taskId),
          throwsA(isA<Exception>()),
        );
        final result = await h.dispatcher.dispatch(input(original.taskId));
        expect(result, isA<TurnDispatchFailed>());
        expect(await h.count('conversation_tasks'), 1);
        expect(h.enqueuer.calls, isEmpty);
      },
    );
  }
  test(
    'retry scope checks conversation and bot before reading original input',
    () async {
      final original = await failed();
      final prepare = PrepareConversationTaskRetry(
        tasks: h.storage.repository,
        messages: h.messages,
      );
      await expectLater(
        prepare(chatId: 'other', botId: 'bot-1', taskId: original.taskId),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        prepare(chatId: 'chat-1', botId: 'other', taskId: original.taskId),
        throwsA(isA<Exception>()),
      );
    },
  );
  test('running task cannot be retried as a new task', () async {
    await h.storage.start();
    final result = await h.dispatcher.dispatch(input('task-1'));
    expect(result, isA<TurnDispatchFailed>());
    expect(await h.count('conversation_tasks'), 1);
  });
  test('lineage is immutable at the database boundary', () async {
    final original = await failed();
    final result =
        await h.dispatcher.dispatch(input(original.taskId)) as TurnTaskAccepted;
    await expectLater(
      h.storage.database.update(
        'conversation_tasks',
        {'retry_of_task_id': null},
        where: 'task_id = ?',
        whereArgs: [result.task.taskId],
      ),
      throwsA(isA<Exception>()),
    );
  });
}
