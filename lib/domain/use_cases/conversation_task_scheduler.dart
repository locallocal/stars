import 'dart:async';

import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';
import 'package:stars/domain/models/task_scheduling.dart';
import 'package:stars/domain/models/tool.dart';
import 'package:stars/domain/repositories/conversation_task_repository.dart';
import 'package:stars/domain/services/task_execution_gate.dart';
import 'package:stars/domain/use_cases/conversation_task_runner_contracts.dart';
import 'package:stars/domain/use_cases/recover_conversation_tasks.dart';

typedef TaskSegmentExecutor =
    Future<TaskSegmentResult> Function({
      required TaskExecutionSnapshot input,
      required TaskLease lease,
      required String segmentId,
      TaskExecutionGate? writeGate,
      AgentCancellationToken? interruption,
    });
typedef TaskRuntimeResolver =
    Future<TaskSegmentExecutor> Function(ConversationTask task);

/// Application-owned durable queue. Notifications reduce latency; periodic
/// database scans recover lost notifications and abandoned workers.
final class ConversationTaskScheduler {
  ConversationTaskScheduler({
    required this.repository,
    required this.resolve,
    required this.ownerId,
    required this.newId,
    this.clock = const SystemTaskRunnerClock(),
    this.limits = const TaskConcurrencyLimits(),
    this.leaseDuration = const Duration(seconds: 30),
    this.scanInterval = const Duration(seconds: 1),
    this.onReady,
    TaskSchedulingMetrics? metrics,
  }) : metrics = metrics ?? TaskSchedulingMetrics() {
    if (ownerId.isEmpty ||
        limits.global < 1 ||
        limits.perProvider < 1 ||
        scanInterval <= Duration.zero ||
        leaseDuration <= scanInterval * 2) {
      throw ArgumentError('Invalid scheduler configuration.');
    }
    recovery = RecoverConversationTasks(
      repository: repository,
      clock: clock,
      metrics: this.metrics,
    );
  }
  final ConversationTaskRepository repository;
  final TaskRuntimeResolver resolve;
  final String ownerId;
  final String Function() newId;
  final TaskRunnerClock clock;
  final TaskConcurrencyLimits limits;
  final Duration leaseDuration, scanInterval;
  final Future<void> Function(TaskSegmentResult)? onReady;
  final TaskSchedulingMetrics metrics;
  late final RecoverConversationTasks recovery;
  final _workers = <String, _TaskWorker>{};
  final _finalizers = <String, Future<void>>{};
  Timer? _timer;
  Future<void>? _scanning;
  bool _enabled = false;
  String? _cursor;

  int get runningCount => _workers.length;
  bool get isStarted => _enabled;

  /// Startup waits for recovery and the first scan, not for external execution.
  Future<void> start({bool periodic = true}) async {
    if (_enabled) return;
    _enabled = true;
    try {
      await tick();
      if (_enabled && periodic) {
        _timer = Timer.periodic(scanInterval, (_) => _wake());
      }
    } on Object {
      _enabled = false;
      rethrow;
    }
  }

  /// Deliberately does not hold a task in memory or perform acceptance writes.
  void enqueue(String taskId) => _wake();
  void _wake() {
    if (_enabled) {
      unawaited(
        tick().catchError((Object _) {
          metrics.failures++;
        }),
      );
    }
  }

  /// A deterministic scheduling/heartbeat boundary for fake-clock tests.
  Future<void> tick() {
    if (!_enabled) return Future<void>.value();
    return _scanning ??= _scan().whenComplete(() {
      _scanning = null;
    });
  }

  Future<void> _scan() async {
    for (final worker in _workers.values.toList()) {
      await worker.gate.run(() async {
        final task = await repository.getById(worker.lease.taskId);
        if (task?.lease?.token != worker.lease.token ||
            task?.lease?.isValidAt(clock.now()) != true) {
          worker.interruption.cancel();
          return;
        }
        if (task!.lease!.expiresAt.difference(clock.now()) >
            leaseDuration ~/ 2) {
          return;
        }
        final renewed = await repository.renewLease(
          lease: worker.lease,
          expiresAt: clock.now().add(leaseDuration),
          expectedRevision: task.revision,
          now: clock.now(),
        );
        if (renewed is TaskWriteCommitted<TaskLease>) {
          worker.lease = renewed.value;
        } else if (renewed is TaskWriteConflict<TaskLease> &&
            renewed.reason != TaskWriteConflictReason.revisionMismatch) {
          worker.interruption.cancel();
        }
      });
    }
    for (final result in await recovery()) {
      await _deliver(result);
    }
    if (!_enabled || _workers.length >= limits.global) return;
    // Resume after the last examined ID so a busy provider/chat cannot starve
    // tasks past a page boundary. A full wrap is performed on the next scan.
    while (_enabled && _workers.length < limits.global) {
      final tasks = await repository.listDue(
        now: clock.now(),
        afterTaskId: _cursor,
      );
      if (tasks.isEmpty) {
        _cursor = null;
        break;
      }
      for (final task in tasks) {
        if (!_enabled || _workers.length >= limits.global) return;
        _cursor = task.taskId;
        if (_workers.containsKey(task.taskId)) continue;
        final now = clock.now();
        final lease = TaskLease(
          taskId: task.taskId,
          ownerId: ownerId,
          token: newId(),
          acquiredAt: now,
          expiresAt: now.add(leaseDuration),
        );
        final claim = await repository.tryAcquireLease(
          taskId: task.taskId,
          expectedRevision: task.revision,
          lease: lease,
          now: now,
          limits: limits,
        );
        if (claim is! TaskWriteCommitted<TaskLease>) continue;
        final worker = _TaskWorker(lease);
        _workers[task.taskId] = worker;
        final delay = now.difference(task.nextRunAt ?? task.updatedAt);
        if (!delay.isNegative) metrics.queueTime += delay;
        if (task.nextRunAt case final due? when due.isAfter(task.updatedAt)) {
          metrics.waitingTime += due.difference(task.updatedAt);
        }
        worker.done = _execute(task, worker);
      }
    }
  }

  Future<void> _execute(ConversationTask queued, _TaskWorker worker) async {
    final started = clock.now();
    try {
      final execute = await clock.timeout(
        Future.any([
          resolve(queued),
          worker.interruption.whenCancelled.then<TaskSegmentExecutor>(
            (_) => throw const AgentRunCancelledException(),
          ),
        ]),
        leaseDuration,
      );
      if (worker.interruption.isCancelled || !_enabled) return;
      final snapshot = await repository.getExecutionSnapshot(queued.taskId);
      if (snapshot == null ||
          snapshot.task.lease?.token != worker.lease.token) {
        return;
      }
      metrics.segments++;
      final result = await execute(
        input: snapshot,
        lease: worker.lease,
        segmentId: newId(),
        writeGate: worker.gate,
        interruption: worker.interruption,
      );
      if (result is TaskLeaseLost) return;
      final progress = result.snapshot.task.progress;
      metrics.noProgress += (progress.noProgressSegments -
              queued.progress.noProgressSegments)
          .clamp(0, 1);
      metrics.retries +=
          result.snapshot.attemptLinks
              .where((link) => link.attemptNumber > 1)
              .length -
          snapshot.attemptLinks.where((link) => link.attemptNumber > 1).length;
      if (result case TaskNeedsSafeFinalization(sideEffectsUnknown: true)) {
        final wait = await repository.waitForTaskInput(
          taskId: queued.taskId,
          expectedRevision: result.snapshot.task.revision,
          reason: TaskWaitingReason.reconciliation,
          reasonCode: TaskReasonCode.reconciliationRequired,
          now: clock.now(),
        );
        if (wait is TaskWriteCommitted<ConversationTask>) {
          metrics.reconciliationFailures++;
        }
      } else if (result is TaskNeedsSafeFinalization &&
          {
            TaskReasonCode.missingCredentials,
            TaskReasonCode.providerUnavailable,
            TaskReasonCode.botUnavailable,
          }.contains(result.reasonCode)) {
        await repository.waitForTaskInput(
          taskId: queued.taskId,
          expectedRevision: result.snapshot.task.revision,
          reason:
              result.reasonCode == TaskReasonCode.missingCredentials
                  ? TaskWaitingReason.authentication
                  : TaskWaitingReason.requiredInput,
          reasonCode: result.reasonCode,
          now: clock.now(),
        );
      } else if (result is TaskCompletionCandidate ||
          result is TaskNeedsSafeFinalization) {
        await _deliver(result);
      }
    } on TaskRuntimeUnavailable catch (error) {
      try {
        await worker.gate.run(() async {
          final task = await repository.getById(queued.taskId);
          if (task?.lease?.token != worker.lease.token) return;
          if (task!.cancelRequestedAt != null &&
              queued.cancelRequestedAt == null) {
            // Cancellation raced configuration loading. Let the cancellation
            // segment run without requiring the missing model credentials.
            return;
          }
          await repository.waitForTaskInput(
            taskId: queued.taskId,
            expectedRevision: task.revision,
            reason: error.reason,
            reasonCode: error.code,
            now: clock.now(),
            lease: worker.lease,
          );
        });
      } on Object {
        metrics.failures++;
      }
    } on AgentRunCancelledException {
      // Application suspension during runtime preparation has no user intent.
    } on Object {
      // Storage/runtime failures keep the durable intent. Release with backoff
      // when possible; otherwise recovery takes over after lease expiration.
      metrics.failures++;
    } finally {
      try {
        await worker.gate.run(() async {
          final task = await repository.getById(queued.taskId);
          if (task?.lease?.token == worker.lease.token &&
              task!.lease!.isValidAt(clock.now())) {
            await repository.releaseLease(
              lease: worker.lease,
              expectedRevision: task.revision,
              now: clock.now(),
              nextRunAt: clock.now().add(scanInterval),
            );
          }
        });
      } on Object {
        metrics.failures++;
      }
      metrics.executionTime += clock.now().difference(started);
      _workers.remove(queued.taskId);
      // Timer handles missed wakeups; this microtask accelerates a freed slot.
      scheduleMicrotask(_wake);
    }
  }

  Future<void> _deliver(TaskSegmentResult result) async {
    // A callback can lose a lease/capacity race. Only a committed terminal row
    // acknowledges delivery; the durable scan retries every unfinished result.
    final id = result.snapshot.task.taskId;
    if (!_enabled || onReady == null || _finalizers.containsKey(id)) return;
    // Narration cannot block heartbeat scans for unrelated executing tasks.
    _finalizers[id] = Future<void>.sync(() => onReady!(result))
        .catchError((Object _) {
          metrics.failures++;
        })
        .whenComplete(() {
          _finalizers.remove(id);
        });
  }

  /// Cooperatively stops I/O; committed intents survive application suspension.
  /// This never persists user cancellation or assumes a write was rolled back.
  Future<void> stop() async {
    _enabled = false;
    _timer?.cancel();
    _timer = null;
    for (final worker in _workers.values.toList()) {
      worker.interruption.cancel();
    }
    await _scanning;
    for (final worker in _workers.values.toList()) {
      worker.interruption.cancel();
    }
    await Future.wait(_workers.values.map((worker) => worker.done));
    await Future.wait(_finalizers.values.toList());
  }
}

final class _TaskWorker {
  _TaskWorker(this.lease);
  TaskLease lease;
  final gate = TaskExecutionGate();
  final interruption = AgentCancellationToken();
  Future<void> done = Future<void>.value();
}
