import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/models.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/use_cases/conversation_turn_dispatcher.dart';
import '../../support/conversation_task_app_harness.dart';
import '../../support/foreground_turn_fixtures.dart';

void main() {
  late ConversationTaskAppHarness h;
  setUp(() async {
    h = ConversationTaskAppHarness();
    await h.open();
  });
  tearDown(() => h.close());

  Future<void> accept() async {
    final result = await h.conversationTasks.dispatcher.dispatch(
      foregroundInput(),
    );
    expect(result, isA<TurnTaskAccepted>());
    await untilTask(h, ConversationTaskStatus.waitingForUser);
    expect(h.job.read(), isEmpty);
    expect(
      (await h.task()).waitingReason,
      TaskWaitingReason.approval,
      reason: jsonEncode(await h.database.query('conversation_task_events')),
    );
  }

  Future<void> approve() async {
    final task = await h.task();
    final snapshot =
        (await h.conversationTasks.repository.getExecutionSnapshot(
          task.taskId,
        ))!;
    expect(
      await h.conversationTasks.commands.decide(
        taskId: task.taskId,
        expectedRevision: task.revision,
        approvalId: snapshot.approvals.single.approvalId,
        decision: TaskApprovalDecision.approved,
        actorId: 'user',
      ),
      isA<TaskWriteCommitted<TaskApprovalRecord>>(),
    );
  }

  test(
    'full composition restores approval and job, permits foreground chat, then publishes one verified result',
    () async {
      await accept();
      final original = await h.task();
      final oldProviders = h.providers;
      await h.restart();
      expect(identical(h.providers, oldProviders), isFalse);
      h.clock.advance(const Duration(days: 90));
      await h.conversationTasks.scheduler.tick();
      expect((await h.task()).status, ConversationTaskStatus.waitingForUser);
      expect(h.conversationTasks.scheduler.runningCount, 0);
      await approve();
      await untilTask(h, ConversationTaskStatus.paused);
      final waiting =
          (await h.conversationTasks.repository.getExecutionSnapshot(
            original.taskId,
          ))!;
      expect(
        waiting.checkpoint!.externalJobs.single.externalJobId,
        'report-job',
      );
      expect(h.job.read()['created'], 1);
      h.providers.route = 'directReply';
      expect(
        await h.conversationTasks.dispatcher.dispatch(
          foregroundInput(turnId: 'hello', content: 'Hello'),
        ),
        isA<TurnDirectReplySaved>(),
      );
      h.providers.route = 'taskStatusRequest';
      final status = await h.conversationTasks.dispatcher.dispatch(
        foregroundInput(turnId: 'status', content: '进展如何'),
      );
      expect(status, isA<TurnTaskStatusRead>());
      expect((await h.task()).objective, original.objective);
      expect((await h.task()).cancelRequestedAt, isNull);
      expect(
        h.conversationTasks.telemetry
            .snapshot()['foreground.directCompletions'],
        1,
      );
      await h.restart(startImmediately: false);
      h.job.ready();
      h.clock.advance(const Duration(hours: 2));
      await h.start();
      await untilTask(h, ConversationTaskStatus.succeeded);
      final messages = await h.messageRepository.getMessages('chat-1');
      final result = messages.singleWhere(
        (m) => m.taskMessageKind == TaskMessageKind.result,
      );
      expect(result.content, '报告共 42 条。');
      expect(result.grounding.trustLevel, AnswerTrustLevel.verified);
      expect(
        messages.where(
          (m) => m.taskMessageKind == TaskMessageKind.acknowledgement,
        ),
        hasLength(1),
      );
      expect(h.job.read()['starts'], 1);
      expect(
        h.conversationTasks.telemetry.snapshot()['terminal.evidenceCoverage'],
        1,
      );
      expect(h.conversationTasks.telemetry.snapshot()['terminal.committed'], 1);
      await h.restart();
      await h.conversationTasks.scheduler.tick();
      expect((await h.task()).taskId, original.taskId);
      expect(await h.integrity(), everyPairZero);
      expect(
        (await h.messageRepository.getMessages(
          'chat-1',
        )).where((m) => m.taskMessageKind == TaskMessageKind.result),
        hasLength(1),
      );
      final durable = jsonEncode({
        for (final table in [
          'conversation_tasks',
          'conversation_task_events',
          'conversation_task_checkpoints',
          'conversation_task_tool_attempts',
          'tool_evidence_records',
          'messages',
        ])
          table: await h.database.query(table),
        'telemetry': h.conversationTasks.telemetry.snapshot(),
      });
      for (final secret in [
        foregroundBot().apiKey,
        'private acceptance reasoning',
        'private acceptance draft',
      ]) {
        expect(durable, isNot(contains(secret)));
      }
    },
  );

  test(
    'lost job creation response is recovered by idempotency key after rebuilding application',
    () async {
      await accept();
      await h.database.execute(
        "CREATE TRIGGER lose_job_handle BEFORE INSERT ON conversation_task_events WHEN NEW.kind='externalJobUpdated' BEGIN SELECT RAISE(ABORT, 'injected handle commit failure'); END",
      );
      await approve();
      for (var i = 0; i < 500; i++) {
        if (h.job.read().isNotEmpty &&
            h.conversationTasks.scheduler.runningCount == 0) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(h.job.read()['starts'], 1);
      expect(
        (await h.conversationTasks.repository.getExecutionSnapshot(
          (await h.task()).taskId,
        ))!.checkpoint!.externalJobs,
        isEmpty,
      );
      await h.database.execute('DROP TRIGGER lose_job_handle');
      await h.restart(startImmediately: false);
      h.job.ready();
      h.clock.advance(const Duration(days: 1));
      await h.start();
      await untilTask(h, ConversationTaskStatus.succeeded);
      expect(h.job.read()['starts'], 1);
      expect(h.job.read()['lookups'], greaterThanOrEqualTo(1));
      expect(await h.integrity(), everyPairZero);
    },
  );

  test(
    'durable cancellation survives stopped scheduler and creates one result after reconciliation',
    () async {
      await accept();
      await approve();
      await untilTask(h, ConversationTaskStatus.paused);
      await h.conversationTasks.setSuspended(true);
      final waiting = await h.task();
      expect(
        await h.conversationTasks.commands.cancel(
          taskId: waiting.taskId,
          expectedRevision: waiting.revision,
        ),
        isA<TaskWriteCommitted<ConversationTask>>(),
      );
      expect((await h.task()).status, ConversationTaskStatus.cancelRequested);
      expect(
        (await h.messageRepository.getMessages(
          'chat-1',
        )).where((m) => m.taskMessageKind == TaskMessageKind.result),
        isEmpty,
      );
      h.clock.advance(const Duration(seconds: 7));
      await h.restart();
      await untilTask(h, ConversationTaskStatus.cancelled);
      expect(h.job.read()['cancelled'], isTrue);
      final metrics = h.conversationTasks.telemetry.snapshot();
      expect(metrics['terminal.cancelled'], 1);
      expect(
        metrics['terminal.cancellationUs'],
        const Duration(seconds: 7).inMicroseconds,
      );
      await h.restart();
      expect(await h.integrity(), everyPairZero);
      expect(h.job.read()['starts'], 1);
    },
  );

  test(
    'strict verification suppresses unsupported action and terminal narration failure falls back',
    () async {
      await accept();
      await approve();
      await untilTask(h, ConversationTaskStatus.paused);
      await h.restart(startImmediately: false);
      h.providers.unsupportedClaim = true;
      h.providers.failNarration = true;
      h.job.ready();
      h.clock.advance(const Duration(hours: 2));
      await h.start();
      await untilTask(h, ConversationTaskStatus.failed);
      final result = (await h.messageRepository.getMessages(
        'chat-1',
      )).singleWhere((m) => m.taskMessageKind == TaskMessageKind.result);
      expect(result.content, contains('42'));
      expect(result.content, isNot(contains('未经验证的文件已删除')));
      final metrics = h.conversationTasks.telemetry.snapshot();
      expect(metrics['terminal.failed'], 1);
      expect(
        metrics['terminal.suppressedClaims'],
        1,
        reason: 'result=${result.grounding} / ${result.content} / $metrics',
      );
      expect(metrics['terminal.evidenceCoverage'], 0.5);
      expect(metrics['terminal.fallbackRatio'], 1);
      expect(await h.integrity(), everyPairZero);
    },
  );
}

final everyPairZero = predicate<Map<String, int>>(
  (values) => values.length == 3 && values.values.every((v) => v == 0),
  'no orphan acknowledgement, duplicate result or missing terminal result',
);

Future<void> untilTask(
  ConversationTaskAppHarness h,
  ConversationTaskStatus status,
) async {
  for (var i = 0; i < 500; i++) {
    final task = await h.task();
    if (task.status == status &&
        h.conversationTasks.scheduler.runningCount == 0 &&
        (status != ConversationTaskStatus.paused ||
            (task.nextRunAt?.isAfter(h.clock.now()) ?? false))) {
      return;
    }
    if (task.status.isTerminal && task.status != status) {
      fail(
        'Expected $status; got ${task.status}/${task.terminalSummary?.reasonCode}',
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  final task = await h.task();
  fail(
    'Expected $status; got ${task.status}/${task.waitingReason}, metrics=${h.conversationTasks.telemetry.snapshot()}',
  );
}
