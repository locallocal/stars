import 'package:stars/domain/models/conversation_task.dart';

final taskTime = DateTime.utc(2026, 9, 14, 10, 0, 0, 0, 123);

TaskAcceptanceSnapshot taskAcceptance({
  TaskSegmentLimits? limits,
  Set<String> allowedToolNames = const {'read_file'},
  Set<String> approvalExemptToolNames = const {},
}) => TaskAcceptanceSnapshot(
  providerId: 'provider-1',
  modelId: 'model-1',
  configurationDigest: 'config-digest',
  language: 'zh-CN',
  context: [TaskContextMessage(role: TaskContextRole.user, content: '整理报告')],
  allowedToolNames: allowedToolNames,
  approvalExemptToolNames: approvalExemptToolNames,
  verification: VerificationPolicySnapshot(
    reliabilityEnabled: true,
    strictGroundingEnabled: true,
    showVerificationStatus: true,
  ),
  segmentLimits: limits ?? TaskSegmentLimits(),
);

TaskTerminalSummary taskTerminal(ConversationTaskStatus status) =>
    TaskTerminalSummary(
      status: status,
      reasonCode:
          status == ConversationTaskStatus.cancelled
              ? TaskReasonCode.cancelled
              : TaskReasonCode.noProgress,
      safeReason: '任务已停止',
      completedWorkSummary: '已读取资料',
      retainedArtifacts: ['artifact:report'],
      sideEffectStatus: TaskSideEffectStatus.reconciled,
      canRetry: true,
      suggestedNextActions: ['检查输入'],
      cancellationSource:
          status == ConversationTaskStatus.cancelled
              ? TaskCancellationSource.user
              : null,
    );

ConversationTask taskFixture({
  String id = 'task-1',
  ConversationTaskStatus status = ConversationTaskStatus.queued,
  TaskAcceptanceSnapshot? acceptance,
  TaskProgress? progress,
  TaskLease? lease,
}) => ConversationTask(
  taskId: id,
  chatId: 'chat-1',
  botId: 'bot-1',
  originTurnId: '$id:turn',
  originUserMessageId: '$id:user',
  title: '整理报告',
  objective: '读取资料并整理报告',
  acceptance: acceptance ?? taskAcceptance(),
  progress:
      progress ??
      TaskProgress(totalSteps: 2, lastMeaningfulProgressAt: taskTime),
  createdAt: taskTime,
  updatedAt: taskTime,
  status: status,
  waitingReason:
      status == ConversationTaskStatus.waitingForUser
          ? TaskWaitingReason.approval
          : null,
  completedAt: status.isTerminal ? taskTime : null,
  terminalSummary:
      {
            ConversationTaskStatus.failed,
            ConversationTaskStatus.cancelled,
          }.contains(status)
          ? taskTerminal(status)
          : null,
  cancellationSource:
      {
            ConversationTaskStatus.cancelRequested,
            ConversationTaskStatus.cancelled,
          }.contains(status)
          ? TaskCancellationSource.user
          : null,
  cancelRequestedAt:
      {
            ConversationTaskStatus.cancelRequested,
            ConversationTaskStatus.cancelled,
          }.contains(status)
          ? taskTime
          : null,
  lease:
      lease ??
      (status == ConversationTaskStatus.running ? taskLease(taskId: id) : null),
);

ConversationTaskPlan taskPlan(ConversationTask task) => ConversationTaskPlan(
  taskId: task.taskId,
  revision: 1,
  objective: task.objective,
  steps: [
    TaskPlanStep(stepId: 'read', summary: '读取资料'),
    TaskPlanStep(stepId: 'write', summary: '整理报告'),
  ],
  allowedToolNames: task.acceptance.allowedToolNames,
  createdAt: task.createdAt,
);

TaskLease taskLease({String taskId = 'task-1'}) => TaskLease(
  taskId: taskId,
  ownerId: 'runner-1',
  token: 'lease-1',
  acquiredAt: taskTime,
  expiresAt: taskTime.add(const Duration(minutes: 1)),
);
