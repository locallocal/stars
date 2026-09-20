part of 'conversation_task_runner.dart';

extension _TaskSegmentPreparation on _TaskSegment {
  Future<TaskSegmentResult?> _prepareExecution() async {
    final prepare = runner.prepare;
    if (prepare == null || !task.acceptance.deferredPreparation) {
      return _finishFinalization(TaskReasonCode.invalidPlan);
    }
    phase = ConversationTaskPhase.planning;
    pendingModelUsage = null;
    TaskExecutionPreparation prepared;
    try {
      prepared = await _operation(
        (token) => prepare(task, token),
        limits.providerTimeout,
      );
    } on AgentRunCancelledException {
      rethrow;
    } on _TaskFenceLost {
      rethrow;
    } on ProviderFailure catch (error) {
      if (!error.retryable || backoffs >= limits.maxSameCallRetries) {
        return _finishFinalization(_providerReason(error));
      }
      return _backoff();
    } on Object {
      if (backoffs >= limits.maxSameCallRetries) {
        return _finishFinalization(TaskReasonCode.providerUnavailable);
      }
      return _backoff();
    }
    tools = Map.unmodifiable({
      for (final adapter in prepared.tools) adapter.definition.name: adapter,
    });
    if (!tools.keys.toSet().containsAll(prepared.snapshot.allowedToolNames)) {
      return _finishFinalization(TaskReasonCode.toolUnavailable);
    }
    pendingModelUsage = prepared.tokenUsage;
    final hasUsage = prepared.tokenUsage.effectiveTotalTokens > 0;
    backoffs = 0;
    replan = true;
    // Activation usage is committed before planning, and is never charged again
    // after a process restart or a failed planning request.
    await _save(
      TaskEventKind.planRevised,
      modelCount: hasUsage ? 1 : 0,
      plan: ConversationTaskPlan(
        taskId: task.taskId,
        revision: snapshot.plan.revision + 1,
        objective: task.objective,
        steps: const [],
        allowedToolNames: const {},
        isPending: true,
        preparation: prepared.snapshot,
        createdAt: now,
      ),
    );
    pendingModelUsage = null;
    return null;
  }
}
