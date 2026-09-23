import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';

/// Read-only presentation of committed execution facts; never a continuation.
final class ConversationTaskExecution {
  ConversationTaskExecution({
    required this.revision,
    required this.processInfo,
    required List<TaskExecutionActivity> activities,
    this.tokenUsage,
    this.summary,
  }) : activities = List.unmodifiable(activities);

  final int revision;

  /// Full card details from the same read as the execution history.
  final ConversationTaskProgressSummary? summary;
  final MessageProcessInfo processInfo;

  /// Cumulative task usage; null means no usage report is available.
  final ModelTokenUsage? tokenUsage;
  final List<TaskExecutionActivity> activities;
}

final class TaskExecutionActivity {
  const TaskExecutionActivity({
    required this.event,
    this.subject = '',
    this.terminalStatus,
  });

  final ConversationTaskEvent event;
  final String subject;

  /// The committed outcome for a terminal event; absent on earlier events.
  final ConversationTaskStatus? terminalStatus;
}
