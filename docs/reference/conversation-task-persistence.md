# 会话任务持久化与进度查询

[文档导航](../README.md) | [目标规格](../specs/conversation-foreground-background-model.md) |
[验收与观测](conversation-task-verification.md)

会话任务的事务存储和查询已实现，[前台分流与接受](conversation-turn-dispatch.md)也已完成。
[分段执行](conversation-task-runner.md)与[调度恢复](conversation-task-scheduling.md)已实现；
[终态验证](conversation-task-terminal-results.md)和[生产会话交互](conversation-task-chat-ui.md)已连通。

## 入口与职责

- [ConversationTaskRepository](../../lib/domain/repositories/conversation_task_repository.dart)
  定义接受、进度、用户命令、lease、终态提交和查询契约。
- [SqliteConversationTaskRepository](../../lib/data/repositories/sqlite_conversation_task_repository.dart)
  通过构造函数接收现有 `LocalDatabaseService`，与消息使用同一个数据库。
- [ConversationTaskStore](../../lib/data/services/conversation_task_store.dart)封装 SQLite 事务；写入、
  命令、关联事实、校验和投影计算分别位于同目录的 part 文件。事务中不调用模型或外部工具。
- [GetConversationTaskProgress](../../lib/domain/use_cases/get_conversation_task_progress.dart)
  按明确的任务 ID 查询并验证会话归属；不存在或属于其他会话时返回 `null`。

## 领域模型与存储单位

[ConversationTask](../../lib/domain/models/conversation_task.dart)及其 part 文件定义不可变任务、
状态、接受快照、计划、进度和审计对象。终态不可逆；`timedOut` 只用于单次尝试。
直接回复用 `turnId:assistant`，回执用 `taskId:ack`，所有终态共享 `taskId:result`；
状态消息固定任务 ID 和摘要 revision，多任务查询不虚构单一任务归属。

任务、事件、lease、检查点及其 JSON 时间统一为 UTC 微秒，执行策略 Duration 同样使用微秒；
既有消息和工具记录使用各自的毫秒约定，不能混用。
[Data 映射](../../lib/data/models/conversation_task_record.dart)是存储单位的事实来源。
[分段预算](../../lib/domain/models/task_segment_limits.dart)校验正值和硬上限，完整配置随接受快照保存；
累计执行没有任务级时长或次数上限。

六类任务表保存 tasks、plans、events、progress、approvals、checkpoints；
`conversation_task_tool_attempts` 与 `conversation_task_evidence_links` 保存不可变任务/分段关联。
逻辑幂等键跨重试不变，递增 attempt number 区分审计尝试，已有关联不能跨任务或分段重绑。

## 事务边界

### 接受任务

用户消息必须先保存。`createWithAcknowledgement` 验证消息、会话、bot 和原始 turn 的关联，
同事务写入任务、接受快照、初始计划、首个事件、进度投影、`taskId:ack`、消息用量及会话预览。
接受事务不创建用户消息。

同一原始输入再次接受时，比较冻结的任务内容、初始计划和回执；内容相同则返回原任务及其稳定
回执身份，即使调用方重新生成了 task ID。内容改变或身份被占用时返回 `duplicateIdentity`，
不替换既有记录。

### 推进任务

`appendProgress` 比较 `expectedRevision`、当前 lease 的 owner/token/获取时间及有效期。
事件序号必须是该任务已保存最大序号加一；任务 revision 与事件序号是两个独立序列。
同事务保存事件、任务状态、投影及事件涉及的计划、工具、审批、证据和检查点。

调用方传入的 `TaskProgress` 不作为计数事实直接保存。存储层从已保存事实计算投影，防止调用方
只修改计数就宣称完成工作。计划修订必须追加下一版本及 `planRevised` 事件，不能扩大接受时的
工具白名单。事件保存所属计划版本、此次新增的模型回合数和验证完成事件的明确结论。

工具调用必须先保存尝试、调用 ID、逻辑幂等键及安全用途，再执行外部操作。结束时保存状态、
耗时和净化摘要，证据及不可变归属关联可在同一事务提交。失败后的重试使用同一逻辑幂等键、
递增的尝试编号和新的 attempt ID。已经结束的尝试不能覆盖。通用工具 repository 禁止单独
修改任务所属的执行记录，防止绕过事件和投影事务。

工具尝试保留最初的任务与分段归属，后续分段可以观察其结果，不重新绑定该尝试。外部 job
的本地 `handle:` 引用、下次轮询时间及恢复所需结构化信息随检查点保存。

### 审批、取消和终态

审批请求与 `waitingForUser` 同事务。`decideApproval` 保存决定、操作者和时间，并撤销当前
lease，再使任务可被调度器重新评估。拒绝仍保留拒绝事实；runner 必须据此选择后续安全步骤。
重复决定不能覆盖原决定。未决审批禁止普通执行恢复。

`requestCancellation` 先保存 `cancelRequested`、来源、时间和事件。重复命令保留首次取消
意图，审批随后通过也不能恢复普通执行。命令推进 revision，使先前构造的执行更新失效。

`commitTerminalMessage` 验证有效 lease、revision 和消息身份，将终态、可选终态摘要、事件、
投影和唯一 `taskId:result` 原子提交。相同终态重复提交返回既有结果，改变结果不能覆盖终态。
成功验证和最终文案策略由终态用例负责，存储层不调用模型生成文案。

所有写事务在返回 sqflite 回调前检查延迟外键。外键失败在回调内抛出，触发回滚，避免将
错误留到 sqflite 的 COMMIT 后才发现。消息 revision 与 watch 通知均只在事务成功返回后发布。

## 查询、重建与调度存储

`getProgressSummary` 在一个 SQLite 一致性快照内读取任务、当前计划、事件、工具、审批、
检查点和证据，验证证据摘要后生成安全摘要。查询不依赖 runner 或 ViewModel。

- `summaryRevision` 使用任务 revision；相同事实返回相同的 revision 和摘要哈希。
- 步骤数量来自当前计划及该版本的步骤事件和检查点；工具次数来自独立尝试记录。
- 模型回合、恢复、分段、无进展和验证状态来自持久事件。
- 待审批内容来自未决审批记录，终态不再显示待处理审批。
- 摘要不包含接受上下文、原始工具参数或完整证据载荷。

`watchProgress` 先注册提交事件监听，再读取初始快照，按 revision 去重，避免订阅与写入竞争
时丢失更新。共享同一 Database 实例的 repository 可以收到彼此提交后的通知。应用重开后
重新订阅即可从数据库取得快照；跨进程或通过其他数据库连接直接执行 SQL 不发布内存通知。

正常写入、查询和 `rebuildProgress` 使用同一投影计算函数。投影缺失或内容损坏时仍可查询；
重建仅修复可丢弃的投影，不增加任务 revision，也不生成新的进度事实。

`listActiveForChat` 返回会话的非终态任务；`getLatestTerminalForChat` 按完成时间选择最近终态。
`listDue` 按任务 ID 分页扫描已到期、无有效 lease 的 queued/paused/cancelRequested 任务；
普通任务的未决审批阻止执行，取消协调仍可运行，committing 候选由终态处理器接收；
`listRecoverable` 按任务 ID 分页列出所有非终态，包括等待和取消任务。

lease 获取、续期和释放均比较 revision。续期只能延长有效 lease；释放 running 任务会将其
保存为 paused，且可保存下次运行时间。过期持有者不能继续写入；重新获取使用新的 token。
获取 lease 的事务还检查同会话、全局和 Provider 并发上限；等待恢复和副作用对账见
[调度实现参考](conversation-task-scheduling.md)。

## 净化、指标与数据库版本

接受上下文、步骤与工具用途应由上游提供受控内容；存储层再进行有界净化，移除常见凭据、
堆栈和原始参数。任务消息不保存 reasoning 或过程轨迹。已经计算摘要的证据包含不安全内容
时拒绝写入，避免净化后悄悄改变证据含义。

[TaskPersistenceMetrics](../../lib/data/services/task_persistence_metrics.dart)提供存储服务生命周期内
的接受、接受失败、写失败、进度更新、幂等复用、冲突原因和提交耗时统计，不记录用户内容。
回执与任务的原子提交保证孤立回执计数为零。应用级遥测接入可读取这些计数。

新建 schema 的事件事实字段用于独立重建，分段扩展见[执行参考](conversation-task-runner.md)。当前版本以
[DatabaseService](../../lib/data/services/database_service.dart)为准。旧版本按[正式运行边界](conversation-task-cutover.md)要求重建，
不迁移、不回填，也不自动删除用户数据库。

## 验证入口

- [接受、冲突和 watch](../../test/data/repositories/sqlite_conversation_task_repository_test.dart)
- [lease、审批、取消与扫描](../../test/data/repositories/sqlite_conversation_task_commands_test.dart)
- [工具、证据、检查点、净化与投影重建](../../test/data/repositories/sqlite_conversation_task_progress_test.dart)
- [终态、重复提交和回滚](../../test/data/repositories/sqlite_conversation_task_terminal_test.dart)
- [会话归属查询](../../test/domain/use_cases/get_conversation_task_progress_test.dart)
- [schema](../../test/data/services/conversation_task_schema_test.dart)与
  [DTO 映射](../../test/data/models/conversation_task_record_test.dart)
