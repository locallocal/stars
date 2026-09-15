import 'dart:convert';

import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/task_execution_state.dart';
import 'package:stars/domain/models/tool.dart';

part 'conversation_task_snapshot_record.dart';
part 'conversation_task_fact_records.dart';

/// Current-schema task DTO. Task timestamps use UTC microseconds throughout.
final class ConversationTaskRecord {
  ConversationTaskRecord(Map<String, Object?> values)
    : values = Map.unmodifiable(values);

  factory ConversationTaskRecord.fromDomain(ConversationTask task) =>
      ConversationTaskRecord({
        'task_id': task.taskId,
        'chat_id': task.chatId,
        'bot_id': task.botId,
        'origin_turn_id': task.originTurnId,
        'origin_user_message_id': task.originUserMessageId,
        'ack_message_id': task.ackMessageId,
        'result_message_id': task.resultMessageId,
        'title': task.title,
        'objective': task.objective,
        'status': task.status.name,
        'phase': task.phase.name,
        'plan_revision': task.planRevision,
        'revision': task.revision,
        'acceptance_json': jsonEncode(
          TaskAcceptanceRecord.encode(task.acceptance),
        ),
        'waiting_reason': task.waitingReason?.name,
        'terminal_summary_json':
            task.terminalSummary == null
                ? null
                : jsonEncode(_terminalToJson(task.terminalSummary!)),
        'lease_owner_id': task.lease?.ownerId,
        'lease_token': task.lease?.token,
        'lease_acquired_at': task.lease?.acquiredAt.microsecondsSinceEpoch,
        'lease_expires_at': task.lease?.expiresAt.microsecondsSinceEpoch,
        'next_run_at': task.nextRunAt?.microsecondsSinceEpoch,
        'cancellation_source': task.cancellationSource?.name,
        'cancel_requested_at': task.cancelRequestedAt?.microsecondsSinceEpoch,
        'created_at': task.createdAt.microsecondsSinceEpoch,
        'updated_at': task.updatedAt.microsecondsSinceEpoch,
        'completed_at': task.completedAt?.microsecondsSinceEpoch,
      });

  final Map<String, Object?> values;

  ConversationTask toDomain({required TaskProgress progress}) {
    final row = _TaskRow(values);
    final task = ConversationTask(
      taskId: row.text('task_id'),
      chatId: row.text('chat_id'),
      botId: row.text('bot_id'),
      originTurnId: row.text('origin_turn_id'),
      originUserMessageId: row.text('origin_user_message_id'),
      title: row.text('title'),
      objective: row.text('objective'),
      acceptance: TaskAcceptanceRecord.decode(row.json('acceptance_json')),
      progress: progress,
      status: row.enumeration('status', ConversationTaskStatus.values),
      phase: row.enumeration('phase', ConversationTaskPhase.values),
      planRevision: row.integer('plan_revision'),
      revision: row.integer('revision'),
      waitingReason: row.optionalEnum(
        'waiting_reason',
        TaskWaitingReason.values,
      ),
      terminalSummary:
          values['terminal_summary_json'] == null
              ? null
              : _terminalFromJson(row.json('terminal_summary_json')),
      lease:
          values['lease_token'] == null
              ? null
              : TaskLease(
                taskId: row.text('task_id'),
                ownerId: row.text('lease_owner_id'),
                token: row.text('lease_token'),
                acquiredAt: row.time('lease_acquired_at'),
                expiresAt: row.time('lease_expires_at'),
              ),
      nextRunAt: row.optionalTime('next_run_at'),
      cancellationSource: row.optionalEnum(
        'cancellation_source',
        TaskCancellationSource.values,
      ),
      cancelRequestedAt: row.optionalTime('cancel_requested_at'),
      createdAt: row.time('created_at'),
      updatedAt: row.time('updated_at'),
      completedAt: row.optionalTime('completed_at'),
    );
    if (task.ackMessageId != values['ack_message_id'] ||
        task.resultMessageId != values['result_message_id']) {
      throw const FormatException(
        'Persisted task message identity is inconsistent.',
      );
    }
    return task;
  }
}

final class TaskProgressRecord {
  TaskProgressRecord(Map<String, Object?> values)
    : values = Map.unmodifiable(values);
  factory TaskProgressRecord.fromDomain(
    String taskId,
    int revision,
    TaskProgress progress,
  ) => TaskProgressRecord({
    'task_id': taskId,
    'summary_revision': revision,
    'progress_json': jsonEncode(_progressToJson(progress)),
  });
  final Map<String, Object?> values;
  TaskProgress toDomain() =>
      _progressFromJson(_TaskRow(values).json('progress_json'));
}

Map<String, Object?> _progressToJson(TaskProgress value) => {
  'completedSteps': value.completedSteps,
  'totalSteps': value.totalSteps,
  'currentStepSummary': value.currentStepSummary,
  'lastMeaningfulProgressAt':
      value.lastMeaningfulProgressAt.microsecondsSinceEpoch,
  'modelTurns': value.modelTurns,
  'toolAttempts': value.toolAttempts,
  'recoveries': value.recoveries,
  'segments': value.segments,
  'noProgressSegments': value.noProgressSegments,
  'summaryHash': value.summaryHash,
  'latestTool':
      value.latestTool == null
          ? null
          : {
            'attemptId': value.latestTool!.attemptId,
            'name': value.latestTool!.name,
            'status': value.latestTool!.status.name,
            'safeSummary': value.latestTool!.safeSummary,
          },
  'pendingApprovalId': value.pendingApprovalId,
  'pendingApprovalSummary': value.pendingApprovalSummary,
  'approvalRequestedAt': value.approvalRequestedAt?.microsecondsSinceEpoch,
  'reasonCode': value.reasonCode,
  'verificationStatus': value.verificationStatus.name,
};

TaskProgress _progressFromJson(Map<String, Object?> value) {
  final row = _TaskRow(value);
  final tool =
      value['latestTool'] == null ? null : _TaskRow(row.object('latestTool'));
  return TaskProgress(
    completedSteps: row.integer('completedSteps'),
    totalSteps: row.integer('totalSteps'),
    currentStepSummary: row.text('currentStepSummary'),
    lastMeaningfulProgressAt: row.time('lastMeaningfulProgressAt'),
    modelTurns: row.integer('modelTurns'),
    toolAttempts: row.integer('toolAttempts'),
    recoveries: row.integer('recoveries'),
    segments: row.integer('segments'),
    noProgressSegments: row.integer('noProgressSegments'),
    summaryHash: row.text('summaryHash'),
    latestTool:
        tool == null
            ? null
            : TaskToolProgress(
              attemptId: tool.text('attemptId'),
              name: tool.text('name'),
              status: tool.enumeration('status', ToolInvocationStatus.values),
              safeSummary: tool.text('safeSummary'),
            ),
    pendingApprovalId: row.optionalText('pendingApprovalId'),
    pendingApprovalSummary: row.optionalText('pendingApprovalSummary'),
    approvalRequestedAt: row.optionalTime('approvalRequestedAt'),
    reasonCode: row.text('reasonCode'),
    verificationStatus: row.enumeration(
      'verificationStatus',
      TaskVerificationStatus.values,
    ),
  );
}

Map<String, Object?> _terminalToJson(TaskTerminalSummary value) => {
  'status': value.status.name,
  'reasonCode': value.reasonCode,
  'safeReason': value.safeReason,
  'completedWorkSummary': value.completedWorkSummary,
  'retainedArtifacts': value.retainedArtifacts,
  'sideEffectStatus': value.sideEffectStatus.name,
  'canRetry': value.canRetry,
  'suggestedNextActions': value.suggestedNextActions,
  'cancellationSource': value.cancellationSource?.name,
};

TaskTerminalSummary _terminalFromJson(Map<String, Object?> value) {
  final row = _TaskRow(value);
  return TaskTerminalSummary(
    status: row.enumeration('status', ConversationTaskStatus.values),
    reasonCode: row.text('reasonCode'),
    safeReason: row.text('safeReason'),
    completedWorkSummary: row.text('completedWorkSummary'),
    retainedArtifacts: row.strings('retainedArtifacts'),
    sideEffectStatus: row.enumeration(
      'sideEffectStatus',
      TaskSideEffectStatus.values,
    ),
    canRetry: row.boolean('canRetry'),
    suggestedNextActions: row.strings('suggestedNextActions'),
    cancellationSource: row.optionalEnum(
      'cancellationSource',
      TaskCancellationSource.values,
    ),
  );
}

final class _TaskRow {
  const _TaskRow(this.values);
  final Map<String, Object?> values;

  T require<T>(String key) {
    final value = values[key];
    if (value is T) return value;
    throw FormatException('Invalid task field: $key.');
  }

  String text(String key) => require<String>(key);
  String? optionalText(String key) => values[key] == null ? null : text(key);
  int integer(String key) => require<int>(key);
  bool boolean(String key) => require<bool>(key);
  DateTime time(String key) =>
      DateTime.fromMicrosecondsSinceEpoch(integer(key), isUtc: true);
  DateTime? optionalTime(String key) => values[key] == null ? null : time(key);
  Map<String, Object?> object(String key) => require<Map<String, Object?>>(key);
  Map<String, Object?> json(String key) {
    final decoded = jsonDecode(text(key));
    if (decoded is! Map<String, Object?>) {
      throw FormatException('Invalid task JSON: $key.');
    }
    return decoded;
  }

  List<String> strings(String key) =>
      require<List<Object?>>(key).map((value) {
        if (value is! String) {
          throw FormatException('Invalid task string list: $key.');
        }
        return value;
      }).toList();
  T enumeration<T extends Enum>(String key, List<T> values) {
    final name = text(key);
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('Unknown task enum: $key.');
  }

  T? optionalEnum<T extends Enum>(String key, List<T> values) =>
      this.values[key] == null ? null : enumeration(key, values);

  void only(Set<String> keys) {
    if (keys.length != values.length || !keys.containsAll(values.keys)) {
      throw const FormatException('Unexpected task snapshot fields.');
    }
  }
}
