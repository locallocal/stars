import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stars/data/models/conversation_task_record.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/task_scheduling.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/services/task_execution_gate.dart';
import 'package:stars/domain/use_cases/conversation_task_scheduler.dart';
import 'package:stars/domain/use_cases/conversation_task_runner.dart';

import 'task_runner_harness.dart';

export 'task_runner_harness.dart';

final class TaskSchedulerHarness {
  final db = TaskRepositoryHarness();
  final clock = RunnerClock();
  final schedulers = <ConversationTaskScheduler>[];
  final started = <String>[];
  final releases = <String, Completer<void>>{};
  final immediateYield = <String>{};
  final ready = <TaskSegmentResult>[];
  int ids = 0;

  Future<void> open() => db.open();
  Future<void> close() async {
    for (final scheduler in schedulers) {
      await scheduler.stop();
    }
    await db.close();
  }

  ConversationTaskScheduler scheduler({
    TaskConcurrencyLimits limits = const TaskConcurrencyLimits(),
    TaskRuntimeResolver? resolve,
  }) {
    final scheduler = ConversationTaskScheduler(
      repository: db.repository,
      resolve: resolve ?? (_) async => hold,
      ownerId: 'worker-${ids++}',
      newId: () => 'identity-${ids++}',
      clock: clock,
      limits: limits,
      leaseDuration: const Duration(seconds: 10),
      onReady: (result) async {
        ready.add(result);
      },
    );
    schedulers.add(scheduler);
    return scheduler;
  }

  Future<void> add(
    String id, {
    String? chat,
    String provider = 'provider-1',
  }) async {
    final task = changeTask(taskFixture(id: id), {
      'chat_id': chat ?? 'chat-$id',
      'acceptance_json': jsonEncode({
        ...TaskAcceptanceRecord.encode(taskAcceptance()),
        'providerId': provider,
      }),
    });
    committed(await db.accept(task: task));
  }

  Future<TaskSegmentResult> hold({
    required TaskExecutionSnapshot input,
    required TaskLease lease,
    required String segmentId,
    TaskExecutionGate? writeGate,
    AgentCancellationToken? interruption,
  }) async {
    started.add(input.task.taskId);
    final release = releases.putIfAbsent(
      input.task.taskId,
      Completer<void>.new,
    );
    if (!immediateYield.contains(input.task.taskId)) {
      await Future.any([
        release.future,
        if (interruption != null) interruption.whenCancelled,
      ]);
    }
    final gate = writeGate ?? TaskExecutionGate();
    await gate.run(() async {
      final task = (await db.repository.getById(input.task.taskId))!;
      if (task.lease?.token == lease.token &&
          task.lease!.isValidAt(clock.now())) {
        committed(
          await db.repository.releaseLease(
            lease: lease,
            expectedRevision: task.revision,
            now: clock.now(),
            nextRunAt:
                immediateYield.contains(input.task.taskId)
                    ? null
                    : clock.now().add(const Duration(hours: 1)),
          ),
        );
      }
    });
    return TaskBackoff(
      (await db.repository.getExecutionSnapshot(input.task.taskId))!,
      clock.now().add(const Duration(hours: 1)),
    );
  }
}

/// Waits on observable state, with a bounded failure instead of test-suite hangs.
Future<void> until(FutureOr<bool> Function() condition) async {
  for (var i = 0; i < 1000; i++) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail('The expected task state was not reached.');
}

ConversationTaskScheduler createRunnerScheduler(
  TaskRunnerHarness runner, {
  Future<void> Function(TaskSegmentResult)? onReady,
  TaskRuntimeResolver? resolve,
  String owner = 'runner-scheduler',
}) {
  var ids = 0;
  return ConversationTaskScheduler(
    repository: runner.db.repository,
    resolve: resolve ?? (_) async => runner.runner.run,
    ownerId: owner,
    newId: () => '$owner-${ids++}',
    clock: runner.clock,
    leaseDuration: const Duration(seconds: 10),
    onReady: onReady,
  );
}
