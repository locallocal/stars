import 'package:stars/domain/models/conversation_task.dart';
import 'package:stars/domain/models/message.dart';

/// Metadata for browsing tasks, without approval, result or execution payloads.
final class ConversationTaskListItem {
  const ConversationTaskListItem({
    required this.taskId,
    required this.chatId,
    required this.title,
    required this.status,
    required this.phase,
    required this.summaryRevision,
    required this.createdAt,
    required this.updatedAt,
    this.completedSteps,
    this.totalSteps,
    this.currentStepSummary = '',
    this.latestToolName = '',
    this.tokenUsage,
    this.leaseExpiresAt,
  });

  factory ConversationTaskListItem.fromSummary(
    ConversationTaskProgressSummary summary,
  ) => ConversationTaskListItem(
    taskId: summary.taskId,
    chatId: summary.chatId,
    title: summary.title,
    status: summary.status,
    phase: summary.phase,
    summaryRevision: summary.summaryRevision,
    createdAt: summary.createdAt,
    updatedAt: summary.updatedAt,
    completedSteps: summary.progress.completedSteps,
    totalSteps: summary.progress.totalSteps,
    currentStepSummary: summary.progress.currentStepSummary,
    latestToolName: summary.progress.latestTool?.name ?? '',
    tokenUsage: summary.progress.tokenUsage,
    leaseExpiresAt: summary.leaseExpiresAt,
  );

  final String taskId, chatId, title;
  final ConversationTaskStatus status;
  final ConversationTaskPhase phase;
  final int summaryRevision;
  final DateTime createdAt, updatedAt;

  /// Null when the disposable progress projection needs to be rebuilt.
  final int? completedSteps, totalSteps;
  final String currentStepSummary, latestToolName;
  final ModelTokenUsage? tokenUsage;
  final DateTime? leaseExpiresAt;

  ConversationTaskListItem observedAt(DateTime now) {
    if (status != ConversationTaskStatus.running ||
        (leaseExpiresAt?.isAfter(now) ?? false)) {
      return this;
    }
    return ConversationTaskListItem(
      taskId: taskId,
      chatId: chatId,
      title: title,
      status: ConversationTaskStatus.paused,
      phase: phase,
      summaryRevision: summaryRevision,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedSteps: completedSteps,
      totalSteps: totalSteps,
      currentStepSummary: currentStepSummary,
      latestToolName: latestToolName,
      tokenUsage: tokenUsage,
      leaseExpiresAt: leaseExpiresAt,
    );
  }
}
