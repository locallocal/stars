import 'package:stars/domain/models/conversation_task.dart';

part 'task_progress_translations.dart';
part 'task_progress_copy.dart';

/// Application-owned status vocabulary, shared by cards and narration.
final class TaskProgressStrings {
  TaskProgressStrings(String language)
    : language = language.replaceAll('_', '-'),
      chinese = language.toLowerCase().startsWith('zh');
  final bool chinese;
  final String language;
  String pick(String en, String zh) {
    final locale =
        language.toLowerCase().startsWith('zh-tw') ||
                language.toLowerCase().startsWith('zh-hant')
            ? 'zh-TW'
            : language.split('-').first.toLowerCase();
    return _taskProgressTranslations[locale]?[en] ??
        _taskProgressCopy[locale]?[en] ??
        (chinese
            ? zh
            : switch (en) {
              'queued' => 'Queued',
              'running' => 'Running',
              'waitingForUser' => 'Waiting for user',
              'paused' => 'Paused',
              'cancelRequested' => 'Cancelling',
              'succeeded' => 'Succeeded',
              'failed' => 'Failed',
              'cancelled' => 'Cancelled',
              'notStarted' => 'Not started',
              'verified' => 'Verified',
              'partial' => 'Partially verified',
              'waitingApproval' => 'Waiting for approval',
              _ => en,
            });
  }

  String get tasks => pick('Tasks', '任务');
  String get statusLabel => pick('Status', '状态');
  String get phaseLabel => pick('Phase', '阶段');
  String get steps => pick('Steps', '步骤');
  String get currentStep => pick('Current step', '当前步骤');
  String get latestTool => pick('Latest tool', '最近工具');
  String get approval => pick('Approval required', '待审批动作');
  String get updated => pick('Updated', '更新时间');
  String get waiting => pick('Waiting for', '等待原因');
  String get recoveries => pick('Recoveries', '恢复次数');
  String get verification => pick('Verification', '验证状态');
  String get viewStatus => pick('View status', '查看状态');
  String get cancel => pick('Cancel task', '取消任务');
  String get approve => pick('Approve', '批准');
  String get deny => pick('Deny', '拒绝');
  String get resume => pick('Recheck and resume', '重新检查并继续');
  String get retry => pick('Review and retry', '检查后重试');
  String get retrySend => pick('Create new task', '创建新任务');
  String get retryConfirmation => pick(
    'Review the input before creating a new task. Current provider, tools and verification settings will be checked again.',
    '请检查输入。新任务会重新检查当前供应商、工具和验证设置。',
  );
  String get noTasks =>
      pick('There are no tasks in this conversation.', '当前会话没有任务。');
  String get notFound =>
      pick('The task is not in this conversation.', '当前会话中未找到此任务。');
  String get choose =>
      pick('Select a task to view its status.', '请选择要查看状态的任务。');
  String get refresh => pick('Refresh tasks', '刷新任务');
  String get commandFailed => pick(
    'The task changed or the action could not be saved. Refresh and try again.',
    '任务已变化或操作未能保存，请刷新后重试。',
  );
  String get creationRetry => pick('Retry sending', '重试发送');
  String get deleteImpact => pick(
    'Active tasks will be asked to cancel. The conversation is kept until cancellation and any external effects are reconciled; delete it again afterwards.',
    '将请求取消活动任务。取消及外部操作对账完成前会保留会话，完成后请再次删除。',
  );
  String get botDeleteImpact => pick(
    'Bots with active tasks cannot be deleted. Finish or cancel their tasks first.',
    '有活动任务的机器人无法删除，请先完成或取消相关任务。',
  );
  String get dismiss => pick('Close', '关闭');
  String get configurationInput => pick(
    'Update the provider credentials or task configuration, then explicitly recheck. New chat messages do not change this task.',
    '请更新供应商凭据或任务配置，再显式重新检查。普通聊天消息不会修改此任务。',
  );
  String status(ConversationTaskStatus value) =>
      pick(value.name, switch (value) {
        ConversationTaskStatus.queued => '已排队',
        ConversationTaskStatus.running => '运行中',
        ConversationTaskStatus.waitingForUser => '等待用户',
        ConversationTaskStatus.paused => '已暂停',
        ConversationTaskStatus.cancelRequested => '正在取消',
        ConversationTaskStatus.succeeded => '已完成',
        ConversationTaskStatus.failed => '失败',
        ConversationTaskStatus.cancelled => '已取消',
      });
  String phase(ConversationTaskPhase value) => pick(value.name, switch (value) {
    ConversationTaskPhase.planning => '规划',
    ConversationTaskPhase.executing => '执行',
    ConversationTaskPhase.observing => '观察',
    ConversationTaskPhase.verifying => '验证',
    ConversationTaskPhase.synthesizing => '整理结果',
    ConversationTaskPhase.committing => '提交结果',
  });
  String wait(TaskWaitingReason value) => pick(
    switch (value) {
      TaskWaitingReason.approval => 'approval',
      TaskWaitingReason.authentication => 'credentials',
      TaskWaitingReason.requiredInput => 'configuration',
      TaskWaitingReason.reconciliation => 'external outcome reconciliation',
    },
    switch (value) {
      TaskWaitingReason.approval => '审批',
      TaskWaitingReason.authentication => '凭据',
      TaskWaitingReason.requiredInput => '配置输入',
      TaskWaitingReason.reconciliation => '外部操作对账',
    },
  );
  String verified(TaskVerificationStatus value) =>
      pick(value.name, switch (value) {
        TaskVerificationStatus.notStarted => '未开始',
        TaskVerificationStatus.verifying => '验证中',
        TaskVerificationStatus.verified => '验证通过',
        TaskVerificationStatus.partial => '部分验证通过',
        TaskVerificationStatus.failed => '验证未通过',
      });
  String toolStatus(String value) => pick(value, switch (value) {
    'queued' => '排队中',
    'running' => '执行中',
    'succeeded' => '成功',
    'failed' => '失败',
    'cancelled' => '已取消',
    'waitingApproval' => '等待审批',
    _ => value,
  });
}

String taskShortId(String id) => id
    .replaceFirst(RegExp(r'^task:'), '')
    .substring(0, id.replaceFirst(RegExp(r'^task:'), '').length.clamp(0, 8));
