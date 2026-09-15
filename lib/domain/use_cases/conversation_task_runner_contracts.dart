import 'dart:async';

import 'package:stars/domain/models/ai_models.dart';
import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/grounded_answer.dart';
import 'package:stars/domain/models/task_execution_snapshot.dart';

/// Resolves the accepted provider/model configuration and current credentials.
/// Implementations must reject an unavailable or mismatched configuration.
typedef TaskModelSessionFactory =
    AgentModelSession Function(
      TaskAcceptanceSnapshot acceptance,
      ModelRequest request,
    );

abstract interface class TaskRunnerClock {
  DateTime now();
  Future<T> timeout<T>(Future<T> work, Duration limit);
}

final class SystemTaskRunnerClock implements TaskRunnerClock {
  const SystemTaskRunnerClock();
  @override
  DateTime now() => DateTime.now().toUtc();
  @override
  Future<T> timeout<T>(Future<T> work, Duration limit) => work.timeout(limit);
}

sealed class TaskSegmentResult {
  const TaskSegmentResult(this.snapshot);
  final TaskExecutionSnapshot snapshot;
}

final class TaskCompletionCandidate extends TaskSegmentResult {
  const TaskCompletionCandidate(super.snapshot, this.candidate);
  final GroundedAnswerCandidate candidate;
}

final class TaskApprovalWait extends TaskSegmentResult {
  const TaskApprovalWait(super.snapshot, this.approvalId);
  final String approvalId;
}

final class TaskExternalJobWait extends TaskSegmentResult {
  const TaskExternalJobWait(super.snapshot, this.nextPollAt);
  final DateTime nextPollAt;
}

final class TaskBackoff extends TaskSegmentResult {
  const TaskBackoff(super.snapshot, this.nextRunAt);
  final DateTime nextRunAt;
}

final class TaskContinueSegment extends TaskSegmentResult {
  const TaskContinueSegment(super.snapshot);
}

/// Stage 06 owns verification and terminal message commit.
final class TaskNeedsSafeFinalization extends TaskSegmentResult {
  const TaskNeedsSafeFinalization(
    super.snapshot,
    this.reasonCode, {
    this.sideEffectsUnknown = false,
  });
  final String reasonCode;
  final bool sideEffectsUnknown;
}

/// A fenced worker must stop without changing facts owned by another worker.
final class TaskLeaseLost extends TaskSegmentResult {
  const TaskLeaseLost(super.snapshot);
}

final class TaskModelProtocolException implements Exception {
  const TaskModelProtocolException();
}
