import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_scheduling.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/models/task_tool_protocol.dart';

import '../../support/task_scheduler_harness.dart';

void main() {
  late TaskSchedulerHarness h;
  setUp(() async {
    h = TaskSchedulerHarness();
    await h.open();
  });
  tearDown(() => h.close());

  test(
    'database scans recover a task whose enqueue notification was lost',
    () async {
      final scheduler = h.scheduler();
      await scheduler.start(periodic: false);
      await h.add('late');
      await scheduler.tick();
      await until(() => h.started.contains('late'));
      expect((await h.db.repository.getById('late'))!.lease, isNotNull);
    },
  );

  test(
    'one conversation is serialized while another provider uses a free slot',
    () async {
      await h.add('a', chat: 'shared');
      await h.add('b', chat: 'shared');
      await h.add('c', provider: 'provider-2');
      final scheduler = h.scheduler(
        limits: const TaskConcurrencyLimits(global: 2, perProvider: 1),
      );
      await scheduler.start(periodic: false);
      await until(() => h.started.length == 2);
      expect(h.started, ['a', 'c']);
      expect((await h.db.repository.getById('b'))!.lease, isNull);
      h.releases['a']!.complete();
      await until(() => scheduler.runningCount == 1);
      await scheduler.tick();
      await scheduler.tick();
      await until(() => h.started.contains('b'));
      expect(h.started.where((id) => id == 'a'), hasLength(1));
    },
  );

  test('provider and global caps are enforced across two schedulers', () async {
    for (final id in ['a', 'b', 'c']) {
      await h.add(id);
    }
    await h.add('d', provider: 'provider-2');
    await h.add('e', provider: 'provider-3');
    const limits = TaskConcurrencyLimits(global: 3, perProvider: 1);
    final a = h.scheduler(limits: limits), b = h.scheduler(limits: limits);
    await Future.wait([a.start(periodic: false), b.start(periodic: false)]);
    await until(() => h.started.length == 3);
    expect(h.started.toSet(), {'a', 'd', 'e'});
    final leases = (await h.db.repository.listRecoverable()).where(
      (task) => task.lease != null,
    );
    expect(leases, hasLength(3));
    expect(
      leases.map((task) => task.acceptance.providerId).toSet(),
      hasLength(3),
    );
  });

  test(
    'scans past a blocked page instead of starving another provider',
    () async {
      // More than the repository page size share one provider.
      for (var i = 0; i < 102; i++) {
        await h.add('a-${i.toString().padLeft(3, '0')}');
      }
      await h.add('z-free', provider: 'provider-2');
      final scheduler = h.scheduler(
        limits: const TaskConcurrencyLimits(global: 2, perProvider: 1),
      );
      await scheduler.start(periodic: false);
      await until(() => h.started.length == 2);
      expect(h.started, contains('z-free'));
    },
  );

  test(
    'renewal survives multiple lease durations without duplicating execution',
    () async {
      await h.add('a');
      final scheduler = h.scheduler();
      await scheduler.start(periodic: false);
      await until(() => h.started.length == 1);
      final first = (await h.db.repository.getById('a'))!;
      for (var i = 0; i < 4; i++) {
        h.clock.advance(const Duration(seconds: 6));
        await scheduler.tick();
        final task = (await h.db.repository.getById('a'))!;
        expect(task.lease!.token, first.lease!.token);
        expect(task.lease!.isValidAt(h.clock.now()), isTrue);
      }
      expect(h.started, ['a']);
      expect(scheduler.metrics.leaseExpirations, 0);
    },
  );

  test(
    'an immediately runnable task cannot starve the next task at capacity',
    () async {
      await h.add('a');
      await h.add('b');
      h.immediateYield.add('a');
      final scheduler = h.scheduler(
        limits: const TaskConcurrencyLimits(global: 1),
      );
      await scheduler.start(periodic: false);
      await until(() async {
        await scheduler.tick();
        return h.started.contains('b');
      });
      expect(h.started, ['a', 'b']);
    },
  );

  test(
    'a failed runtime-wait commit retains the task and schedules a retry',
    () async {
      await h.add('a');
      await h.db.failWrite(
        'conversation_task_events',
        when: "NEW.kind = 'waitingForUser'",
      );
      final scheduler = h.scheduler(
        resolve:
            (_) async =>
                throw const TaskRuntimeUnavailable(
                  TaskWaitingReason.authentication,
                  TaskReasonCode.missingCredentials,
                ),
      );
      await scheduler.start(periodic: false);
      await until(
        () async =>
            (await h.db.repository.getById('a'))!.nextRunAt != null &&
            scheduler.runningCount == 0,
      );
      final task = (await h.db.repository.getById('a'))!;
      expect(task.lease, isNull);
      expect(task.status.isTerminal, isFalse);
      expect(scheduler.metrics.failures, 1);
      await h.db.clearFailure();
      h.clock.time = task.nextRunAt!;
      await scheduler.tick();
      await scheduler.tick();
      await until(
        () async =>
            (await h.db.repository.getById('a'))!.status ==
            ConversationTaskStatus.waitingForUser,
      );
    },
  );

  test(
    'runtime preparation can be suspended without waiting for provider setup',
    () async {
      await h.add('a');
      final entered = Completer<void>();
      final scheduler = h.scheduler(
        resolve: (_) async {
          entered.complete();
          return Completer<Never>().future;
        },
      );
      await scheduler.start(periodic: false);
      await entered.future;
      await scheduler.stop();
      final task = (await h.db.repository.getById('a'))!;
      expect(task.cancelRequestedAt, isNull);
      expect(task.lease, isNull);
      expect(task.status.isTerminal, isFalse);
    },
  );

  test(
    'missing runtime waits durably and does not occupy the global slot',
    () async {
      await h.add('a');
      await h.add('b', provider: 'provider-2');
      final scheduler = h.scheduler(
        limits: const TaskConcurrencyLimits(global: 1),
        resolve: (task) async {
          if (task.taskId == 'a') {
            throw const TaskRuntimeUnavailable(
              TaskWaitingReason.authentication,
              TaskReasonCode.missingCredentials,
            );
          }
          return h.hold;
        },
      );
      await scheduler.start(periodic: false);
      await until(
        () async =>
            (await h.db.repository.getById('a'))!.status ==
            ConversationTaskStatus.waitingForUser,
      );
      await scheduler.tick();
      await scheduler.tick();
      await until(() => h.started.contains('b'));
      final task = (await h.db.repository.getById('a'))!;
      expect(task.waitingReason, TaskWaitingReason.authentication);
      expect(task.progress.reasonCode, TaskReasonCode.missingCredentials);
      expect(task.lease, isNull);
    },
  );

  test('heartbeat and real runner checkpoints share a write gate', () async {
    final runner = TaskRunnerHarness();
    await runner.open();
    addTearDown(runner.close);
    final entered = Completer<void>(), finish = Completer<void>();
    runner.models.tool();
    runner.tool.onStart = (call) async {
      entered.complete();
      await finish.future;
      return ToolCompleted(
        ToolResult(callId: call.callId, name: call.name, content: 'done'),
      );
    };
    runner.models.completeStep();
    runner.models.candidate();
    final real = createRunnerScheduler(runner);
    addTearDown(real.stop);
    await real.start(periodic: false);
    await entered.future;
    runner.clock.advance(const Duration(seconds: 6));
    await real.tick();
    finish.complete();
    await until(
      () async =>
          (await runner.db.task).phase == ConversationTaskPhase.committing &&
          real.runningCount == 0,
    );
    expect((await runner.db.task).progress.completedSteps, 1);
    expect(real.metrics.failures, 0);
    expect(runner.tool.starts, 1);
  });
}
