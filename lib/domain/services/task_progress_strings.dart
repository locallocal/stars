import 'package:stars/domain/models/conversation_task.dart';

part 'task_progress_translations.dart';
part 'task_progress_copy.dart';

/// Application-owned status vocabulary for task controls and details.
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
  String get pageDescription => pick(
    'View progress and manage tasks in this conversation.',
    '查看当前会话的任务进度，管理审批和执行操作。',
  );
  String get searchTasks => pick('Search tasks', '搜索任务');
  String get noMatchingTasks => pick('No matching tasks', '未找到匹配的任务');
  String get oldestFirst => pick('Oldest first', '时间：从早到晚');
  String get newestFirst => pick('Newest first', '时间：从晚到早');
  String get created => pick('Created', '创建时间');
  String get inputTokens => pick('Input tokens', '输入 Token');
  String get outputTokens => pick('Output tokens', '输出 Token');
  String get tokenUsageHint => pick(
    'Recorded model usage for this task. Usage not reported or saved is not estimated; — means unavailable.',
    '此任务已记录的模型用量。未返回或未保存的用量不估算；— 表示暂无数据。',
  );
  String get executionArguments => pick('Arguments', '调用参数');
  String get executionResult => pick('Result', '执行结果');
  String get executionError => pick('Error', '错误信息');
  String get executionTimeline => pick('Execution history', '执行流程');
  String get executionCommand => pick('Command', '执行命令');
  String get executionDirectory => pick('Working directory', '工作目录');
  String get executionAttention => pick('Needs attention', '需关注');
  String get executionStopped => pick('Stopped', '已停止');
  String get executionMilestones => pick('Key progress', '关键进展');
  String get executionAllEvents => pick('All events', '全部记录');
  String get executionNewestFirst => pick('Latest first', '最近更新在前');
  String get executionEmpty =>
      pick('No tools have been called yet.', '尚未调用工具，执行后将在此显示。');
  String get executionNoMilestones => pick(
    'No key progress yet. View all events for the saved records.',
    '暂无关键进展，可切换「全部记录」查看已保存的活动。',
  );
  String get executionNoOutput =>
      pick('This call has no saved output.', '此调用没有已保存的输出。');
  String get executionPendingOutput => pick(
    'The result will appear when this call finishes.',
    '调用结束后，结果将显示在这里。',
  );
  String get executionCopy => pick('Copy', '复制');
  String get executionCopied => pick('Copied', '已复制');
  String get executionCopyFailed => pick('Copy failed', '复制失败');
  String executionCalls(int count) => pick('$count calls', '$count 次调用');
  String executionEvents(int count) => pick('$count events', '$count 条记录');
  String executionAttempt(int count) => pick('Attempt $count', '第 $count 次尝试');
  String get executionLoadFailed =>
      pick('Execution details could not be loaded.', '执行详情加载失败。');
  String event(TaskEventKind kind) => switch (kind) {
    TaskEventKind.queued => pick('Task queued', '任务已排队'),
    TaskEventKind.started => pick('Task started', '开始执行任务'),
    TaskEventKind.paused => pick('Task paused', '任务已暂停'),
    TaskEventKind.resumed => pick('Task resumed', '继续执行任务'),
    TaskEventKind.cancellationRequested => pick(
      'Cancellation requested',
      '已请求取消',
    ),
    TaskEventKind.terminal => pick('Task finished', '任务已结束'),
    TaskEventKind.planCreated => pick('Plan created', '已创建计划'),
    TaskEventKind.planRevised => pick('Plan revised', '已调整计划'),
    TaskEventKind.stepStarted => pick('Step started', '开始执行步骤'),
    TaskEventKind.stepCompleted => pick('Step completed', '步骤已完成'),
    TaskEventKind.toolQueued => pick('Tool queued', '工具调用已排队'),
    TaskEventKind.toolStarted => pick('Tool started', '开始调用工具'),
    TaskEventKind.toolSucceeded => pick('Tool completed', '工具调用已完成'),
    TaskEventKind.toolFailed => pick('Tool stopped', '工具调用未成功'),
    TaskEventKind.toolRetry => pick('Tool retried', '重试工具调用'),
    TaskEventKind.externalJobUpdated => pick('External job updated', '外部任务已更新'),
    TaskEventKind.approvalRequested => pick('Approval requested', '已请求审批'),
    TaskEventKind.waitingForUser => pick('Waiting for user', '等待用户处理'),
    TaskEventKind.approvalApproved => pick('Approval granted', '已批准执行'),
    TaskEventKind.approvalDenied => pick('Approval denied', '已拒绝执行'),
    TaskEventKind.verificationStarted => pick('Verification started', '开始验证结果'),
    TaskEventKind.evidenceAccepted => pick('Evidence accepted', '证据已接受'),
    TaskEventKind.evidenceRejected => pick('Evidence rejected', '证据未通过'),
    TaskEventKind.verificationCompleted => pick(
      'Verification completed',
      '结果验证已完成',
    ),
    TaskEventKind.resultCommitting => pick('Saving result', '保存执行结果'),
    TaskEventKind.leaseExpired => pick('Execution interrupted', '执行已中断'),
    TaskEventKind.processRecovered => pick('Execution recovered', '执行已恢复'),
    TaskEventKind.retryScheduled => pick('Retry scheduled', '已安排重试'),
    TaskEventKind.noProgress => pick('No new progress', '暂无新进展'),
    TaskEventKind.modelTurnCompleted => pick('Model turn completed', '模型处理已完成'),
    TaskEventKind.segmentCheckpoint => pick('Progress saved', '执行进度已保存'),
    TaskEventKind.segmentProgress => pick('Progress updated', '执行进度已更新'),
  };
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

  /// Describes a committed obstacle without exposing arbitrary diagnostic text.
  String waitingDescription(TaskWaitingReason reason, String code) {
    if (reason == TaskWaitingReason.approval) return wait(reason);
    if (TaskReasonCode.isToolUnavailable(code)) {
      final name = TaskReasonCode.unavailableTool(code);
      return name == null
          ? pick(
            'A required tool is unavailable for background execution. Enable or update the tool, then recheck.',
            '任务所需工具暂不支持后台执行。请启用或更新对应工具后重新检查。',
          )
          : pick(
            'The tool "$name" is unavailable for background execution. Enable or update it, then recheck.',
            '工具「$name」暂不支持后台执行。请启用或更新对应工具后重新检查。',
          );
    }
    return switch (code) {
      TaskReasonCode.invalidPlan => pick(
        'The task plan is invalid or a required tool is unavailable. Repair the plan or tool configuration before rechecking.',
        '任务计划无效，或计划所需工具尚未接入后台执行。请修复计划或工具配置后重新检查。',
      ),
      TaskReasonCode.missingCredentials => pick(
        'Provider credentials are unavailable. Update them, then recheck.',
        '供应商凭据不可用。请更新凭据后重新检查。',
      ),
      TaskReasonCode.providerUnavailable => pick(
        'The provider or model configuration no longer matches the accepted task. Restore it, or create a new task with the current settings.',
        '供应商或模型配置不可用，或与任务接受时的配置不一致。请恢复配置，或使用当前设置创建新任务。',
      ),
      TaskReasonCode.botUnavailable => pick(
        'The bot used by this task is unavailable. Restore it, then recheck.',
        '此任务使用的智能体不可用。请恢复智能体后重新检查。',
      ),
      TaskReasonCode.reconciliationRequired => pick(
        'An external operation has an unknown outcome. Check its effects before continuing; the command will not be automatically repeated.',
        '外部操作的结果尚未确定。请先核对实际执行结果；系统不会自动重复执行该命令。',
      ),
      _ => wait(reason),
    };
  }

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
