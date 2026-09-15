# 会话任务的跨分段验证与终态回复

[文档导航](../README.md) | [调度与恢复](conversation-task-scheduling.md) | [目标规格](../specs/conversation-foreground-background-model.md)

本文描述已实现的任务终结流程。应用级调度器将持久候选交给终结用例，成功、失败和取消都通过
同一事务提交唯一的 `taskId:result`。新的前台发送入口与任务动作交互仍由后续会话交互阶段接入。

## 验证范围与冻结策略

[`TaskEvidenceScope`](../../lib/domain/services/task_evidence_scope.dart) 以任务为验证范围。证据必须同时匹配
任务的会话、原始请求、不可变 attempt/segment 关联和成功工具记录。跨任务、失败尝试、损坏摘要、
过期证据以及不合格的类型、能力、主体、范围和事实值都不能支撑声明。

[`taskVerificationRequirements`](../../lib/domain/services/task_verification_preparation.dart) 从持久证据创建
应用侧的声明要求，供合成与验证共同使用；模型不能通过改写声明 ID 或省略声明移除要求。
成功写回执保留动作与最终状态两个要求，即使原工具已不可用。最终状态只能由写成功事件之后才开始的
读取证明，比较持久事件序号，因此相同时间戳也不会让写前读取成为写后验证。

任务接受时的 `VerificationPolicySnapshot` 决定可信状态与严格模式。隐藏验证标签不会关闭证据验证。
关闭可靠性时仍保存声明验证事实，整体可信状态保守标记为未验证。消息读取通过任务关联恢复接受时的
严格模式和标签设置，运行中或重启后修改个人设置不会重写这个结果。

## 终结流程

[`FinalizeConversationTask`](../../lib/domain/use_cases/finalize_conversation_task.dart) 只处理数据库中
`phase=committing` 的检查点，不使用回调携带的旧草稿：

1. 重读任务并获取独立、受并发额度约束的执行 lease。
2. 确认不存在未对账的运行尝试或外部 job；否则进入对账等待。
3. 按任务作用域验证跨分段证据及声明。严格模式无法证明关键声明时，生成验证失败与可验证部分结果。
4. 失败/取消根据提交事实创建安全摘要并执行一次有时限的终态润色。
5. 重读 revision 与取消意图，保存验证结论，再以有效 lease 和 `expectedRevision` 原子提交终态。

模型调用在事务外。取消在成功草稿之后提交时，成功草稿失效，后续执行器先完成停止与对账；
`cancelRequested` 不产生“已取消”消息。lease 失效、存储失败或进程退出后，检查点仍可由调度器重新读取。
内存中的回调记录不代表结果已提交。调度器单独跟踪正在终结的任务，润色不会阻塞其他 worker 的续期扫描。

## 失败、取消与保留事实

[`TaskTerminalSummaryPolicy`](../../lib/domain/services/task_terminal_summary_policy.dart) 使用受控原因码、
已验证的结构化事实和工具执行状态建立 `TaskTerminalSummary`。异常堆栈、原始 Provider 输出、敏感路径、
工具参数和模型猜测不会进入摘要。保留结果通过 `evidence:<证据 ID>` 引用持久账本；这些引用不表示创建了
额外文件，也不暴露文件路径。

完成的写操作仍被视为生效，明确说明未回滚，并建议先核对影响。未确认副作用的任务保持对账等待，
不能通过终态润色推断成功、停止或回滚。没有验证依据时明确说明没有可验证的部分结果或已确认的产物。

[`NarrateConversationTaskTerminal`](../../lib/domain/use_cases/narrate_conversation_task_terminal.dart) 默认最多
等待 2 秒，只调用一次。Provider 只能看到安全摘要及应用允许的完整表达，不能调用工具，也不能读取原始
会话上下文。返回文本须符合 [`TaskTerminalNarrationPolicy`](../../lib/domain/services/task_terminal_narration_policy.dart)
的完整语法；虚构完成、回滚、保留内容、弱化失败或修改下一步均被拒绝。服务不可用、超时或协议违规时
立即采用任务语言的本地化兜底，不执行修复轮次。

回执、状态、等待审批属于操作信息，不参与回答可信度展示或严格事实抑制。失败和取消消息中的部分事实
仍逐条验证；取消确认等操作段落不需要外部证据。执行失败与事实可信度分离：失败任务可以包含部分已验证
事实，但不能被标记为整体成功或整体已验证。

## 原子提交、时间线与通知

终态事务保存任务状态、安全摘要、终态事件、进度投影、消息、token 记录与 `answer_claim_evidence`。
证据链接提交前再次检查任务归属、成功尝试和摘要完整性。任一写入失败会回滚终态和消息。
相同提交可以幂等复用；其他终态、过期 revision 或 lease 不能覆盖已提交事实。

终态消息时间戳在事务内推进到该会话最新消息之后，因此旧请求的迟到结果和相同毫秒内的提交都保持
提交顺序。预览与消息一起更新，事务提交后才通知消息/会话 repository，失效缓存并刷新打开的会话。
稳定消息 ID 用于去重；重新进入页面从数据库恢复同一个结果，不插回原请求旁，也不泄露中间候选。

## 指标与验证入口

[`TaskTerminalMetrics`](../../lib/domain/models/task_terminal_metrics.dart) 记录提交耗时、冲突、润色尝试、
失败与兜底、声明覆盖率以及严格模式抑制数量。指标不包含会话文本和参数。

自动化验证使用真实临时 SQLite、可控时钟、多个调度/终结实例及故障注入：

- [终结集成与竞争](../../test/domain/use_cases/finalize_conversation_task_test.dart)
- [终态恢复与失效边界](../../test/domain/use_cases/conversation_task_terminal_recovery_test.dart)
- [证据作用域与写后读取顺序](../../test/domain/services/task_evidence_scope_test.dart)
- [终态润色策略](../../test/domain/services/task_terminal_narration_policy_test.dart)
- [Provider 终态会话边界](../../test/data/services/ai/task_terminal_polisher_test.dart)
- [通知、预览、时间线与恢复](../../test/data/repositories/conversation_task_terminal_delivery_test.dart)
