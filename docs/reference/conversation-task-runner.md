# 会话任务分段执行与长工具协议

[文档导航](../README.md) | [目标规格](../specs/conversation-foreground-background-model.md) | [阶段计划](../plans/conversation-foreground-background-model/README.md)

`ConversationTaskRunner` 推进一个已接受任务的有界分段。任务、计划、工具尝试、审批、证据和
检查点来自数据库；模型 session 只在一次模型请求期间存在。[应用调度与恢复](conversation-task-scheduling.md)
已接入组合根；最终验证和唯一结果消息提交属于阶段 06，会话交互接入属于阶段 07。

## 调用与返回

调用方先取得 lease，再读取 `getExecutionSnapshot(taskId)`，把快照、lease 和新的 `segmentId`
传给 `run`。runner 重新读取权威事实，在每次外部操作前后和每次写入时检查所有权与取消意图。
正常返回前保存检查点并释放 lease；数据库故障向调用方传播，过期或被替换的 lease 返回
`TaskLeaseLost`，旧 worker 不再更新任务。

| 返回类型 | 已持久化内容与后续动作 |
| --- | --- |
| `TaskContinueSegment` | 预算边界的下一步骤、待执行调用和证据游标；调度下一分段 |
| `TaskApprovalWait` | 审批请求与 `waitingForUser` 同事务提交；等待数据库中的审批决定 |
| `TaskExternalJobWait` | 外部 job ID、安全恢复句柄、状态和下次轮询时间；到期轮询 |
| `TaskBackoff` | 重试状态与 `nextRunAt`；到期恢复，无内存 sleep |
| `TaskCompletionCandidate` | 受控声明、证据引用和候选已写入检查点；交给最终验证流程 |
| `TaskNeedsSafeFinalization` | 稳定原因码及副作用是否未知；交给安全终结流程 |
| `TaskLeaseLost` | 已失去执行权限；由调度器根据当前持久化所有权处理 |

runner 不提交聊天消息，也不把步骤说明、工具观察、reasoning 或普通模型草稿追加到时间线。
候选通过结构化答案协议解析，引用只能来自本任务已提交的证据；候选本身不表示验证通过或任务成功。

## 模型、计划与预算

每个模型回合从接受时冻结的上下文、当前计划和已提交观察重建 session。模型没有读取后来聊天
目标的接口。`TaskProviderSessionFactory` 校验接受时的配置摘要、Provider 和模型身份；运行时凭据
仍由 bot/Provider 持有。配置摘要与任务接受共用实现，参数键顺序不影响摘要。

模型通过 `stars_revise_task_plan` 修订剩余步骤。应用保留已完成步骤及原目标和工具白名单，追加
新的计划版本。普通回合结束且没有工具调用时完成当前步骤；全部步骤完成后记录验证开始并请求
结构化合成。合成准备复用写后验证策略，从已提交 action receipt 重建完成动作及最终状态要求。

预算来自接受快照中的 `TaskSegmentLimits`，模型回合、工具调用、可信性修复和计划修订计数在
每个分段重新开始；进度中的模型回合、工具尝试、分段和恢复累计值保留。默认值由
[`TaskSegmentLimits`](../../lib/domain/models/task_segment_limits.dart) 定义：

| 限制 | 默认值 |
| --- | --- |
| 分段模型回合 / 工具调用 | 32 / 48 |
| 同一逻辑调用额外重试 / 连续工具失败 | 4 / 8 |
| 分段可信性修复 / 计划修订 | 3 / 8 |
| 连续无进展分段 | 8 |
| Provider / 普通工具 / 对账单次超时 | 各 15 分钟 |
| 外部 job 单次轮询超时 | 5 分钟 |
| 指数退避 | 初始 15 秒，上限 30 分钟，带随机抖动 |

没有任务总时长、总分段数、总恢复次数或额外的合成总超时。OpenAI Chat Completions、Responses、
Anthropic 和 Moonshot 会把任务单次超时传入 HTTP 层，合成使用相同 Provider 请求预算。

无进展判断比较计划内容、已完成步骤、已记录调用意图、成功操作、证据、外部 job 状态和审批
决定；修订号、时间戳、重复失败和下次轮询时间不能单独表示进展。预算边界保存 `noProgress` 或
`segmentProgress` 事实，达到冻结阈值才产生 `task_no_progress`。正常审批、轮询和退避等待不增加
无进展计数；这些等待前发生的实际进展可以清除此前的连续无进展计数。

## 工具与恢复

[`TaskToolAdapter`](../../lib/domain/models/task_tool_protocol.dart) 提供 `start`、`poll`、`cancel` 和
`reconcile`。普通工具可通过 `SynchronousTaskToolAdapter` 接入；超过普通单次预算的操作必须使用
job 协议。

- `ToolCompleted` 返回普通 `ToolResult`。输出 schema 与证据契约校验和旧 Agent Loop 共用
  `ToolResultValidator`；成功尝试、证据及检查点在同一事务提交。
- `ToolJobStarted` 返回外部 job ID、`handle:...` 形式的不透明句柄、安全状态和下次轮询时间。
  适配器负责句柄在重启后仍可解析；凭据保存在适配器配置中。轮询失败保留原 job，不能据此判断
  外部操作失败或重新创建 job。
- 对账返回 `ToolReconciled`、`ToolNotStarted` 或 `ToolOutcomeUnknown`。明确确认未开始后可重试；
  未知的非幂等写操作交给安全终结流程，保留其待对账事实，不声称已经回滚或取消。

每次外部执行前先提交稳定幂等键和工具尝试，再提交 running 状态。幂等键由任务、工具、参数
以及只读调用的步骤身份生成，不依赖 Provider call ID；成功的同一调用被再次提出时复用已有事实。
写操作跨计划修订保持逻辑键。新增尝试保留相同键和递增尝试号，达到重试或连续失败阈值后请求
重规划，不能因此直接把整个任务标为 failed。

写操作只有适配器明确保证 `guaranteesIdempotency`，或对账确认未开始，才允许自动重试。
`ToolDefinition.isIdempotent` 本身不足以证明外部幂等。未知写入超时保留 running 尝试及对账标志；
下个分段先对账。进程在工具完成后、完成事务提交前退出，同样通过原幂等键对账。

审批请求结束当前分段，不挂起长期 Future。用户审批后从检查点恢复同一组参数，经过策略检查
才执行；拒绝审批不会启动工具。等待没有自动失败时限。取消先要求已有持久化取消意图，再停止
新调用，并对正在运行的工具/job 执行取消或对账，最后返回带副作用不确定信息的终结候选。

## 存储与安全边界

schema 版本 26 增加分段事件类型约束。`getExecutionSnapshot` 在一个读事务中返回任务、当前
计划、检查点、事件序号、尝试归属、审批和证据，供执行与恢复使用。进度仍由已提交事实重建。

检查点的 `TaskExecutionState` 保存待执行调用、工具版本、重试及对账状态、步骤状态和候选。
参数只保留适配器显式声明的 `checkpointArgumentNames` 非敏感字段，深度冻结、限制长度，并须原样通过持久化安全检查；包含凭据或 reasoning 等字段的调用
在执行前拒绝，不能把被净化后语义不同的参数用于审批恢复。普通工具包装器默认不允许任何参数进入检查点；接入时须审查可恢复字段，大载荷使用适配器管理的引用。工具审计摘要继续省略参数原文。
恢复句柄、调用参数和结构化候选采用不同字段；完整 Provider session 和普通观察原文不序列化。

## 代码与验证入口

| 入口 | 职责 |
| --- | --- |
| [ConversationTaskRunner](../../lib/domain/use_cases/conversation_task_runner.dart) | 分段协调、计划与模型预算 |
| [ConversationTaskModelTurn](../../lib/domain/use_cases/conversation_task_model_turn.dart) | 冻结上下文、模型协议和 session 生命周期 |
| [工具执行](../../lib/domain/use_cases/conversation_task_runner_tools.dart) | 工具策略、审批、尝试和证据 |
| [恢复与取消](../../lib/domain/use_cases/conversation_task_runner_recovery.dart) | 对账、取消及未知副作用 |
| [持久化与让出](../../lib/domain/use_cases/conversation_task_runner_persistence.dart) | lease 检查、检查点、进度、退避和释放 |
| [Provider factory](../../lib/data/services/ai/task_model_session_factory.dart) | 接受配置校验和运行时 Provider 创建 |
| [分段测试](../../test/domain/use_cases/conversation_task_runner_test.dart) | 超过旧预算、审批、job、重规划和无进展 |
| [恢复故障测试](../../test/domain/use_cases/conversation_task_runner_recovery_test.dart) | fake clock、提交失败、lease、取消与幂等 |
| [证据测试](../../test/domain/use_cases/conversation_task_runner_evidence_test.dart) | 证据原子性、重启合成、修复与动态计划 |
| [Provider 超时测试](../../test/data/services/ai/task_provider_timeout_test.dart) | 无网络的实际 HTTP 适配器超时验证 |

数据库测试使用真实 SQLite，并通过失败 trigger 验证外部调用前后的事务边界；时钟、Provider
session、工具适配器及 lease 冲突使用可控替身，不需要在线模型或真实长时间等待。
