import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/tool.dart';

sealed class ToolStartResult {
  const ToolStartResult();
}

final class ToolCompleted extends ToolStartResult {
  const ToolCompleted(this.result);
  final ToolResult result;
}

/// Adapters keep credentials outside the checkpoint. The handle names a durable
/// adapter-owned resource, and must remain resolvable after process restart.
final class ToolJobStarted extends ToolStartResult {
  const ToolJobStarted({
    required this.externalJobId,
    required this.resumeHandle,
    required this.safeStatus,
    required this.nextPollAt,
  });
  final String externalJobId;
  final String resumeHandle;
  final String safeStatus;
  final DateTime nextPollAt;
}

sealed class ToolReconciliation {
  const ToolReconciliation();
}

final class ToolReconciled extends ToolReconciliation {
  const ToolReconciled(this.result);
  final ToolStartResult result;
}

/// Positive proof that the attempted operation never took effect.
final class ToolNotStarted extends ToolReconciliation {
  const ToolNotStarted();
}

final class ToolOutcomeUnknown extends ToolReconciliation {
  const ToolOutcomeUnknown();
}

abstract interface class TaskToolAdapter {
  ToolDefinition get definition;

  /// Audited non-sensitive fields needed to resume an invocation. Credentials,
  /// headers and large payloads must stay in adapter-owned storage; expose an
  /// opaque reference instead. The runner rejects undeclared fields.
  Set<String> get checkpointArgumentNames;

  /// True only when start enforces the supplied key at the side-effect boundary.
  /// ToolDefinition.isIdempotent alone is not a durable deduplication guarantee.
  bool get guaranteesIdempotency;
  Future<ToolStartResult> start(
    ToolCallRequest call,
    String idempotencyKey,
    AgentCancellationToken cancellation,
  );
  Future<ToolStartResult> poll(
    TaskExternalJob job,
    AgentCancellationToken cancellation,
  );
  Future<ToolReconciliation> cancel(
    TaskExternalJob job,
    AgentCancellationToken cancellation,
  );
  Future<ToolReconciliation> reconcile(
    ToolCallRequest call,
    String idempotencyKey,
    TaskExternalJob? job,
    AgentCancellationToken cancellation,
  );
}

/// Ordinary tools remain bounded attempts. Long jobs must supply an adapter.
final class SynchronousTaskToolAdapter implements TaskToolAdapter {
  SynchronousTaskToolAdapter(
    this.tool, {
    Set<String> checkpointArgumentNames = const {},
  }) : checkpointArgumentNames = Set.unmodifiable(checkpointArgumentNames);
  final ExecutableTool tool;
  @override
  final Set<String> checkpointArgumentNames;
  @override
  ToolDefinition get definition => tool.definition;
  @override
  bool get guaranteesIdempotency => false;
  @override
  Future<ToolStartResult> start(
    ToolCallRequest call,
    String idempotencyKey,
    AgentCancellationToken cancellation,
  ) async => ToolCompleted(await tool.execute(call, cancellation));
  @override
  Future<ToolStartResult> poll(
    TaskExternalJob job,
    AgentCancellationToken cancellation,
  ) => Future.error(StateError('Synchronous tools have no external job.'));
  @override
  Future<ToolReconciliation> cancel(
    TaskExternalJob job,
    AgentCancellationToken cancellation,
  ) async => const ToolOutcomeUnknown();
  @override
  Future<ToolReconciliation> reconcile(
    ToolCallRequest call,
    String idempotencyKey,
    TaskExternalJob? job,
    AgentCancellationToken cancellation,
  ) async => const ToolOutcomeUnknown();
}
