part of 'conversation_task_record.dart';

abstract final class TaskPreparationRecord {
  static Map<String, Object?> encode(TaskPreparationSnapshot value) => {
    'context': value.context.map(_contextToJson).toList(),
    'allowedToolNames': value.allowedToolNames.toList()..sort(),
    'approvalExemptToolNames': value.approvalExemptToolNames.toList()..sort(),
  };

  static TaskPreparationSnapshot decode(Map<String, Object?> values) {
    final row = _TaskRow(values)
      ..only({'context', 'allowedToolNames', 'approvalExemptToolNames'});
    return TaskPreparationSnapshot(
      context: _contexts(row.require<List<Object?>>('context')),
      allowedToolNames: row.strings('allowedToolNames').toSet(),
      approvalExemptToolNames: row.strings('approvalExemptToolNames').toSet(),
    );
  }
}
