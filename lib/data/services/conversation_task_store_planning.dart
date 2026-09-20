part of 'conversation_task_store.dart';

void _validatePlanScope(
  ConversationTask task,
  ConversationTaskPlan previous,
  ConversationTaskPlan next,
) {
  if (next.objective != task.objective ||
      (!previous.isPending && next.isPending)) {
    throw ArgumentError(
      'Planning cannot replace the objective or forget its steps.',
    );
  }
  if (!task.acceptance.deferredPreparation) {
    if (next.preparation != null ||
        next.isPending ||
        !task.acceptance.allowedToolNames.containsAll(next.allowedToolNames)) {
      throw ArgumentError('Legacy task scope is immutable.');
    }
    return;
  }
  final before = previous.preparation;
  final after = next.preparation;
  if (after == null ||
      (before == null && (!previous.isPending || !next.isPending)) ||
      (before != null &&
          !_sameJson(
            TaskPreparationRecord.encode(before),
            TaskPreparationRecord.encode(after),
          )) ||
      !after.allowedToolNames.containsAll(next.allowedToolNames)) {
    throw ArgumentError(
      'Background preparation must be committed once before planning.',
    );
  }
}
