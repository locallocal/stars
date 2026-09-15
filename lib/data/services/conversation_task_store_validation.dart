part of 'conversation_task_store.dart';

void _validateNext(
  ConversationTask old,
  ConversationTask next,
  ConversationTaskEvent event,
  DateTime now,
) {
  if (next.revision != old.revision + 1 ||
      event.taskId != next.taskId ||
      next.updatedAt.isBefore(old.updatedAt) ||
      next.updatedAt.isAfter(now) ||
      event.occurredAt != next.updatedAt ||
      event.planRevision != next.planRevision ||
      !_sameAcceptance(_taskValues(old), _taskValues(next)) ||
      next.createdAt != old.createdAt ||
      next.taskId != old.taskId ||
      (next.status != old.status && !old.status.canTransitionTo(next.status))) {
    throw ArgumentError('Invalid task transition, identity or event revision.');
  }
  _validateEventReferences(event);
  if (old.cancelRequestedAt != null &&
      {
        ConversationTaskStatus.running,
        ConversationTaskStatus.queued,
        ConversationTaskStatus.succeeded,
      }.contains(next.status)) {
    throw ArgumentError('Cancellation intent cannot be overwritten.');
  }
}

void _validateEventReferences(ConversationTaskEvent event) {
  if (({
            TaskEventKind.stepStarted,
            TaskEventKind.stepCompleted,
          }.contains(event.kind) &&
          event.stepId == null) ||
      ({
            TaskEventKind.toolQueued,
            TaskEventKind.toolStarted,
            TaskEventKind.toolSucceeded,
            TaskEventKind.toolFailed,
            TaskEventKind.toolRetry,
            TaskEventKind.externalJobUpdated,
          }.contains(event.kind) &&
          (event.attemptId == null || event.segmentId == null)) ||
      ({
            TaskEventKind.approvalRequested,
            TaskEventKind.approvalApproved,
            TaskEventKind.approvalDenied,
          }.contains(event.kind) &&
          event.approvalId == null) ||
      ({
            TaskEventKind.evidenceAccepted,
            TaskEventKind.evidenceRejected,
          }.contains(event.kind) &&
          event.evidenceId == null)) {
    throw ArgumentError('Event is missing its fact reference.');
  }
}

bool _sameLease(TaskLease? a, TaskLease? b) =>
    a == null
        ? b == null
        : b != null &&
            a.taskId == b.taskId &&
            a.ownerId == b.ownerId &&
            a.token == b.token &&
            a.acquiredAt == b.acquiredAt &&
            a.expiresAt == b.expiresAt;

bool _sameAcceptance(Map<String, Object?> a, Map<String, Object?> b) => [
  'chat_id',
  'bot_id',
  'origin_turn_id',
  'origin_user_message_id',
  'title',
  'objective',
  'acceptance_json',
].every((key) => a[key] == b[key]);

bool _sameMap(Map<String, Object?> a, Map<String, Object?> b) =>
    a.length == b.length && a.keys.every((key) => a[key] == b[key]);

bool _sameMessage(
  Map<String, Object?> a,
  Map<String, Object?> b, {
  bool ignoreIdentity = false,
}) {
  final ignored = {
    'timestamp',
    if (ignoreIdentity) ...['task_id', 'message_id', 'run_id'],
  };
  return b.keys
      .where((key) => !ignored.contains(key))
      .every((key) => a[key] == b[key]);
}

bool _sameJson(Object? a, Object? b) => jsonEncode(a) == jsonEncode(b);

Map<String, Object?> _taskValues(ConversationTask task) {
  final values = {...ConversationTaskRecord.fromDomain(task).values};
  values['title'] = _safeText(task.title, maximum: 200);
  values['objective'] = _safeText(
    task.objective,
    maximum: 16000,
    structured: true,
  );
  final acceptance = TaskAcceptanceRecord.encode(task.acceptance);
  acceptance['allowedToolNames'] =
      task.acceptance.allowedToolNames.toList()..sort();
  values['acceptance_json'] = jsonEncode(_safeObject(acceptance));
  if (values['terminal_summary_json'] case final String summary) {
    values['terminal_summary_json'] = jsonEncode(
      _safeObject(jsonDecode(summary)),
    );
  }
  return values;
}

Map<String, Object?> _planValues(ConversationTaskPlan plan) {
  final values = {...ConversationTaskPlanRecord.fromDomain(plan).values};
  final content =
      jsonDecode(values['plan_json']! as String) as Map<String, Object?>;
  content['allowedToolNames'] = plan.allowedToolNames.toList()..sort();
  values['plan_json'] = jsonEncode(_safeObject(content));
  return values;
}

Map<String, Object?> _eventValues(ConversationTaskEvent event) => {
  ...ConversationTaskEventRecord.fromDomain(event).values,
  'safe_summary': _safeText(event.safeSummary),
  'reason_code': event.reasonCode == null ? null : _safeCode(event.reasonCode!),
};

Map<String, Object?> _messageValues(
  ConversationTask task,
  Message message, {
  required bool terminal,
}) {
  final outcome = switch (task.status) {
    ConversationTaskStatus.succeeded => MessageTerminalOutcome.completed,
    ConversationTaskStatus.failed => MessageTerminalOutcome.failed,
    ConversationTaskStatus.cancelled => MessageTerminalOutcome.cancelled,
    _ => null,
  };
  if (message.taskId != task.taskId ||
      message.chatId != task.chatId ||
      message.botId != task.botId ||
      message.turnId != task.originTurnId ||
      !{task.botId, 'assistant'}.contains(message.senderId) ||
      message.taskMessageKind !=
          (terminal
              ? TaskMessageKind.result
              : TaskMessageKind.acknowledgement) ||
      message.messageId !=
          (terminal ? task.resultMessageId : task.ackMessageId) ||
      message.terminalOutcome != outcome ||
      message.hasPartialContent ||
      message.content.trim().isEmpty) {
    throw ArgumentError(
      'Task message identity or terminal outcome is inconsistent.',
    );
  }
  return MessageRecord.fromDomain(
    message.copyWith(
      content: _safeText(message.content, maximum: 128000, structured: true),
      reasoning: '',
      processInfo: const MessageProcessInfo(),
    ),
  ).values;
}

String _safeCode(String value) =>
    RegExp(r'^[a-zA-Z0-9_.-]{0,128}$').hasMatch(value)
        ? value
        : 'task_detail_redacted';

// Safety net for prepared summaries. It does not infer safe purposes from raw
// tool arguments: those are deliberately omitted by the tool write boundary.
String _safeText(String text, {int maximum = 2000, bool structured = false}) =>
    taskSafeText(text, maximum: maximum, structured: structured);
Object? _safeObject(Object? value, {String key = ''}) =>
    taskSafeObject(value, key: key);
