part of 'conversation_task_record.dart';

/// Frozen, safe presentation data saved alongside a status message.
abstract final class TaskSummaryRecord {
  static Map<String, Object?> encode(ConversationTaskProgressSummary value) => {
    'taskId': value.taskId,
    'chatId': value.chatId,
    'title': value.title,
    'status': value.status.name,
    'phase': value.phase.name,
    'planRevision': value.planRevision,
    'summaryRevision': value.summaryRevision,
    'progress': _progressToJson(value.progress),
    'updatedAt': value.updatedAt.microsecondsSinceEpoch,
    'createdAt': value.createdAt.microsecondsSinceEpoch,
    'waitingReason': value.waitingReason?.name,
    'terminalSummary':
        value.terminalSummary == null
            ? null
            : _terminalToJson(value.terminalSummary!),
    'leaseExpiresAt': value.leaseExpiresAt?.microsecondsSinceEpoch,
  };

  static List<ConversationTaskProgressSummary> decodeList(Object? raw) {
    if (raw is! String) {
      throw const FormatException(
        "Task summaries require current JSON storage.",
      );
    }
    final decoded = jsonDecode(raw) as List<Object?>;
    return [
      for (final entry in decoded) decode(entry! as Map<String, Object?>),
    ];
  }

  static ConversationTaskProgressSummary decode(Map<String, Object?> value) {
    final row = _TaskRow(value);
    return ConversationTaskProgressSummary(
      taskId: row.text('taskId'),
      chatId: row.text('chatId'),
      title: row.text('title'),
      status: row.enumeration('status', ConversationTaskStatus.values),
      phase: row.enumeration('phase', ConversationTaskPhase.values),
      planRevision: row.integer('planRevision'),
      summaryRevision: row.integer('summaryRevision'),
      progress: _progressFromJson(row.object('progress')),
      updatedAt: row.time('updatedAt'),
      createdAt: row.optionalTime('createdAt'),
      waitingReason: row.optionalEnum(
        'waitingReason',
        TaskWaitingReason.values,
      ),
      terminalSummary:
          value['terminalSummary'] == null
              ? null
              : _terminalFromJson(row.object('terminalSummary')),
      leaseExpiresAt: row.optionalTime('leaseExpiresAt'),
    );
  }
}
