import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/message.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';
import 'package:stars/domain/use_cases/conversation_task_scheduler.dart';
import 'package:stars/domain/use_cases/conversation_task_runner_contracts.dart';

import '../../support/task_terminal_harness.dart';
import '../../support/task_scheduler_harness.dart' show until;

void main() {
  late TaskTerminalHarness h;
  setUp(() => h = TaskTerminalHarness());
  tearDown(() => h.close());

  test(
    'cancelled write preserves known effects and validated retained work',
    () async {
      await h.open(write: true);
      await h.observe();
      await h.cancel();
      await h.finalizer()('task-1');
      final task = await h.runner.db.task;
      expect(task.status, ConversationTaskStatus.cancelled);
      expect(
        task.terminalSummary!.sideEffectStatus,
        TaskSideEffectStatus.irreversible,
      );
      expect(task.terminalSummary!.retainedArtifacts, isNotEmpty);
      expect((await h.result()).content, contains('未作回滚'));
      expect(
        (await h.result()).grounding.trustLevel,
        AnswerTrustLevel.partiallyVerified,
      );
    },
  );

  test(
    'unknown external cancellation remains a wait without terminal narration',
    () async {
      await h.open(write: true);
      h.runner.tool.onStart =
          (_) async => ToolJobStarted(
            externalJobId: 'job-1',
            resumeHandle: 'handle:job-1',
            safeStatus: 'running',
            nextPollAt: h.runner.clock.now().add(const Duration(seconds: 10)),
          );
      h.runner.tool.onCancel = () async => const ToolOutcomeUnknown();
      await h.observe();
      await h.cancel();
      var narrations = 0;
      await h.finalizer(
        polish: (_, _) async {
          narrations++;
          return GroundedAnswerCandidate(nonFactualText: '已取消');
        },
      )('task-1');
      final task = await h.runner.db.task;
      expect(task.status, ConversationTaskStatus.waitingForUser);
      expect(task.waitingReason, TaskWaitingReason.reconciliation);
      expect(narrations, 0);
      expect(
        (await h.messages()).where(
          (m) => m.taskMessageKind == TaskMessageKind.result,
        ),
        isEmpty,
      );
    },
  );

  test(
    'expired finalizer cannot commit a late narrative; another lease completes it',
    () async {
      await h.open();
      await h.fail();
      final stale = h.finalizer(
        polish: (request, _) async {
          h.runner.clock.advance(const Duration(seconds: 31));
          return terminalTestReply(request);
        },
      );
      await stale('task-1');
      expect(stale.metrics.conflicts, 1);
      expect((await h.runner.db.task).status.isTerminal, isFalse);
      expect(
        (await h.messages()).where(
          (m) => m.taskMessageKind == TaskMessageKind.result,
        ),
        isEmpty,
      );
      await h.finalizer()('task-1');
      expect((await h.runner.db.task).status, ConversationTaskStatus.failed);
    },
  );

  test(
    'cancellation during failed-task narration invalidates the old summary',
    () async {
      await h.open();
      await h.fail();
      final entered = Completer<void>(), release = Completer<void>();
      final pending = h.finalizer(
        polish: (request, _) async {
          entered.complete();
          await release.future;
          return terminalTestReply(request);
        },
      )('task-1');
      await entered.future;
      final task = await h.runner.db.task;
      committed(
        await h.runner.db.repository.requestCancellation(
          taskId: 'task-1',
          expectedRevision: task.revision,
          source: TaskCancellationSource.conversationDeletion,
          requestedAt: h.runner.clock.now(),
        ),
      );
      release.complete();
      await pending;
      expect(
        (await h.messages()).where(
          (m) => m.taskMessageKind == TaskMessageKind.result,
        ),
        isEmpty,
      );
      await h.runner.run();
      await h.finalizer()('task-1');
      expect(
        (await h.result()).terminalOutcome,
        MessageTerminalOutcome.cancelled,
      );
      expect(
        (await h.runner.db.task).terminalSummary!.cancellationSource,
        TaskCancellationSource.conversationDeletion,
      );
    },
  );

  test(
    'evidence expiring during narration is omitted from the terminal reply',
    () async {
      await h.open();
      await h.observe();
      await h.fail();
      final finish = h.finalizer(
        polish: (request, _) async {
          // Keep the finalizer lease valid while crossing evidence expiry.
          h.runner.clock.advance(const Duration(seconds: 2));
          return terminalTestReply(request);
        },
      );
      h.runner.clock.advance(const Duration(minutes: 59, seconds: 59));
      await finish('task-1');
      expect((await h.runner.db.task).status, ConversationTaskStatus.failed);
      expect((await h.result()).grounding.evidenceIds, isEmpty);
      expect((await h.result()).content, isNot(contains('report.count: 42')));
    },
  );

  test(
    'slow terminal narration does not block another task heartbeat',
    () async {
      await h.open();
      await h.fail();
      final other = changeTask(taskFixture(id: 'other'), {
        'chat_id': 'other-chat',
      });
      committed(await h.runner.db.accept(task: other));
      final entered = Completer<void>(), release = Completer<void>();
      final finish = h.finalizer(
        polish: (request, _) async {
          entered.complete();
          await release.future;
          return terminalTestReply(request);
        },
      );
      var ids = 0;
      final scheduler = ConversationTaskScheduler(
        repository: h.runner.db.repository,
        resolve:
            (_) async => ({
              required input,
              required lease,
              required segmentId,
              writeGate,
              interruption,
            }) async {
              await interruption!.whenCancelled;
              return TaskContinueSegment(input);
            },
        ownerId: 'worker',
        newId: () => 'worker-${ids++}',
        clock: h.runner.clock,
        leaseDuration: const Duration(seconds: 10),
        onReady: finish.onReady,
      );
      addTearDown(scheduler.stop);
      await scheduler.start(periodic: false);
      await entered.future;
      await until(
        () async =>
            (await h.runner.db.repository.getById('other'))!.lease != null,
      );
      final expiry =
          (await h.runner.db.repository.getById('other'))!.lease!.expiresAt;
      h.runner.clock.advance(const Duration(seconds: 6));
      await scheduler.tick();
      expect(
        (await h.runner.db.repository.getById(
          'other',
        ))!.lease!.expiresAt.isAfter(expiry),
        isTrue,
      );
      release.complete();
      await until(() async => (await h.runner.db.task).status.isTerminal);
    },
  );
}
