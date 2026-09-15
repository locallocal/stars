# 会话任务调度、恢复与副作用对账

[文档导航](../README.md) | [目标规格](../specs/conversation-foreground-background-model.md) |
[分段执行](conversation-task-runner.md) | [后续阶段](../plans/conversation-foreground-background-model/README.md)

应用级调度、lease 续期、重启恢复、审批/取消命令和删除保护已实现。[生产会话交互](conversation-task-chat-ui.md)和[候选验证与唯一终态消息提交](conversation-task-terminal-results.md)已接入完整流程。

## 队列与执行所有权

[ConversationTaskScheduler](../../lib/domain/use_cases/conversation_task_scheduler.dart) 的
`enqueue` 只唤醒扫描。到期时间、等待原因、取消意图和检查点均由 SQLite 保存；默认每秒扫描，
丢失内存通知不会遗失任务。按任务 ID 分页循环扫描，受限 Provider 和持续产生新分段的任务
不会阻止后面的任务获得执行机会。

- 默认最多 4 个执行 lease、每个接受快照中的 `providerId` 最多 2 个，每会话最多 1 个。
  所有调度实例使用相同的并发配置；限制在获取 lease 的数据库事务内检查，包括其他进程的有效 lease。
- 先获取 lease，再解析运行配置和创建 runner；已获取但尚未进入 running 的 lease 也占槽。
- 默认 lease 为 30 秒，剩余一半时续期。续期与当前分段的检查点写入共用
  [TaskExecutionGate](../../lib/domain/services/task_execution_gate.dart)，外部调用期间不持锁。
- 所有执行写入仍检查 revision、owner、token、取得时间和有效期。过期或接管后的迟到结果
  不能改变新持有者的事实。前台 `ForegroundTurnGate` 与后台 lease 独立。
- 审批、退避、轮询间隔及已持久化的结果候选释放执行槽。`nextRunAt` 在重启后仍生效。

## 恢复与结果候选

[RecoverConversationTasks](../../lib/domain/use_cases/recover_conversation_tasks.dart) 分页检查所有
非终态任务。有效 lease 保留所有权；过期 lease 记录 `leaseExpired`、`processRecovered`，
清除所有权并把旧 running 转成 paused，不直接判失败，也不改写检查点。

queued/paused 和 cancelRequested 到期后可执行；有未决审批的普通任务保持等待。审批决定与
重新入队在同一事务提交。普通配置等待和副作用未知的等待需要显式 `resumeTask`，审批等待
只能通过审批决定恢复。恢复使用原任务、原目标、原接受策略和已提交事实，创建新的模型 session。

`phase=committing` 的候选不进入执行队列。调度器通过 `onReady` 交给终态用例；用例使用
自己的 lease/revision 事务提交终态，不能依赖进程内通知去重。未提交回调会重新投递，正在润色的
终态任务不阻塞其他 worker 的续期扫描。即使进程在候选落库后退出，
恢复器仍能重新提供候选。缺少配置的候选转成明确等待，副作用未知的候选转成对账等待。

## 工具与取消恢复

| 已知事实 | 行为 |
| --- | --- |
| 成功结果已提交 | 复用结果和证据 |
| 调用意图已提交、调用尚未发出 | 执行已记录的调用 |
| 只读或适配器真正保证幂等的调用中断 | 使用同一逻辑 key，记录新的尝试 |
| 写调用可能已发出 | 先 reconcile；确认未执行才允许重试 |
| job 句柄已保存 | 查询原 job，保留下一次轮询时间 |
| job 已创建但响应或句柄落库丢失 | 使用原 key 查询；不能再次盲目 start |
| 对账超时 | 持久退避；保留调用和 job |
| 副作用仍不明确 | waitingForUser / reconciliation，保留取消来源和待核对尝试 |

[ConversationTaskCommands](../../lib/domain/use_cases/conversation_task_commands.dart) 先提交取消或
审批决定，再唤醒调度。冲突/过期 revision 和重复审批不会覆盖现有决定。runner 监听已提交
取消意图，停止新调用并通知 job；写工具返回错误也不能自动证明没有副作用。对账未完成时保留
running 尝试，只有确认停止或结果后才提供取消候选；调度层不提前写 cancelled。

[TaskRuntimeFactory](../../lib/data/services/task_runtime_factory.dart) 每个分段刷新 bot 配置与密钥，
校验冻结的 Provider/model/configuration digest。缺少 bot、凭据、Provider 能力或可用工具时，
持久化安全原因码并释放槽位。取消无需调用模型，缺少模型凭据不阻止已排队任务的取消。

[工具适配器](../../lib/data/services/task_tool_adapters.dart) 对可保存参数使用明确的字段白名单。
普通同步写工具无法证明结果时进入对账等待；动态工具需注册经过审核的适配器。
`JobTaskToolAdapter` 把 start/poll/cancel/lookup 交给运行时 `TaskJobClient`，lookup 使用稳定 key；
不会从工具的声明元数据推断真实幂等保证。密钥、Provider session、原始异常和完整推理不进入任务记录。

历史查询工具从同一任务已提交的成功结果元数据恢复可访问引用和分页游标；新模型参数和历史正文
不能授予访问权限。每个分段重建工具 session，不依赖上一个分段的内存缓存。

## 应用启动、暂停与删除

[AppConversationTasks](../../lib/ui/core/dependency_injection/app_dependencies_tasks.dart) 由应用组合根
创建。数据库就绪后先运行与新任务隔离的旧恢复器，再恢复并启动任务 scheduler，最后发布启动完成。
旧恢复查询和迟到中断写入均排除新任务关联记录，避免旧逻辑把新任务证据误判为孤立回复。

任务不属于页面 ViewModel。平台 paused/detached 时停止调度并取消当前 I/O，已提交的调用意图
可在 resumed 后重新对账；这不是用户取消，不生成取消终态。进程被系统终止后的持续计算不在支持范围内。

`GetConversationTaskProgress` 用查询时间解释 lease；过期 running 对外表现为 paused，保留原
summaryRevision。直接使用 repository 的事实快照时，可调用摘要的 `observedAt(now)` 获得同样的展示语义。

[DeleteConversation](../../lib/domain/use_cases/delete_conversation.dart) 先请求取消，有非终态任务
时保留会话及证据；完成终态后才能删除。bot 删除在存在非终态任务时被阻止。repository 在暂存
文件前检查，数据库事务在删除前再次检查，覆盖直接调用和并发接受。终态任务聚合及关联事实先删除，
再删除消息/会话；清空历史同样受保护。

## 指标与测试

`TaskSchedulingMetrics` 记录当前调度实例的排队、执行、定时等待时长，以及恢复、重试、lease
失效、无进展、对账等待和内部失败次数。通过命令用例结束的审批/配置等待也累计等待时长。
指标不包含用户内容；持久恢复次数和分段进度仍以事件账本及 `TaskProgress` 为准。

自动化测试使用真实临时 SQLite、可控时钟、独立调度实例和工具故障注入，覆盖并发限流与公平性、
lease 接管与迟到提交、审批长等待、取消重启、job 创建/句柄保存边界、对账重试、配置缺失、旧恢复隔离、
删除保护和应用启动/暂停顺序。入口见：

- [调度测试](../../test/domain/use_cases/conversation_task_scheduler_test.dart)
- [恢复集成测试](../../test/domain/use_cases/conversation_task_scheduling_recovery_test.dart)
- [数据库及删除保护](../../test/data/repositories/conversation_task_scheduling_guards_test.dart)
- [旧恢复隔离](../../test/data/repositories/conversation_task_legacy_recovery_test.dart)
- [运行配置与 job 适配器](../../test/data/services/task_runtime_factory_test.dart)
- [启动与平台生命周期](../../test/ui/features/app/view_models/conversation_task_startup_test.dart)
