import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/tool.dart';

/// A single database snapshot, including decisions committed between segments.
final class TaskExecutionSnapshot {
  TaskExecutionSnapshot({
    required this.task,
    required this.plan,
    required this.lastSequence,
    this.checkpoint,
    List<ToolExecutionRecord> attempts = const [],
    List<TaskToolAttemptLink> attemptLinks = const [],
    List<TaskApprovalRecord> approvals = const [],
    List<ToolEvidenceRecord> evidence = const [],
  }) : attempts = List.unmodifiable(attempts),
       attemptLinks = List.unmodifiable(attemptLinks),
       approvals = List.unmodifiable(approvals),
       evidence = List.unmodifiable(evidence);
  final ConversationTask task;
  final ConversationTaskPlan plan;
  final int lastSequence;
  final ConversationTaskCheckpoint? checkpoint;
  final List<ToolExecutionRecord> attempts;
  final List<TaskToolAttemptLink> attemptLinks;
  final List<TaskApprovalRecord> approvals;
  final List<ToolEvidenceRecord> evidence;
}
