# 01：领域模型与全新数据库

[总计划](README.md) | [下一阶段：事务持久化与进度事实](02-persistence-and-progress.md)

前置依赖：无。对应目标规格第 5、6、9、11、12 节。

目标：先建立可持久化、可恢复的任务契约，使后续前台、runner 和 UI 使用同一套身份与状态语义。

## 实现步骤

1. 定义任务及不可变值对象：`ConversationTask`、版本化计划、事件、检查点、`TaskProgress`、
   `ConversationTaskProgressSummary`、`TaskTerminalSummary`、审批记录和 `TaskLease`。
   集中定义生命周期、执行阶段、等待原因、取消来源、副作用状态和稳定原因码；列出合法变换，
   禁止终态回到执行状态。`timedOut` 只允许表示单次尝试结果，不属于任务终态。
2. 定义任务接受快照：原始 turn/用户消息、bot ID、冻结上下文、配置版本摘要、工具白名单、
   `VerificationPolicySnapshot` 和执行策略。检查点只保存恢复所需的结构化状态、下一步骤、
   计划版本与证据游标；凭据通过安全配置重新取得。
3. 定义独立 `TaskSegmentLimits`，按规格第 6.2 节落实默认值、正值校验和硬上限。
   分清分段计数、累计计数、单次请求超时与退避；配置覆盖值写入任务快照。
4. 扩展消息与证据身份：直接回复用 `turnId:assistant`，回执用 `taskId:ack`，所有终态共用
   `taskId:result`；状态消息保存 `taskId` 和 `summaryRevision`。明确领域消息枚举与
   `messages.task_message_kind` 的映射，工具执行/证据增加 `taskId`、`segmentId` 或等价不可变关联。
5. 定义 `ConversationTaskRepository` 及更新对象。除规格列出的创建、查询、进度、lease、取消、
   终态方法外，补齐调度所需的到期扫描、lease 续期/释放、审批决定与检查点访问契约。
   明确 `expectedRevision`、执行者身份、冲突结果和事务提交后通知语义，不向 Domain 暴露 SQLite。
6. 新建 schema 版本，创建 tasks、plans、events、progress、approvals、checkpoints 六类任务表，
   扩展消息与工具证据存储。设计 `(taskId, sequence)`、计划版本、稳定消息 ID、工具尝试幂等键
   等唯一约束，以及按会话、生命周期、调度到期时间查找的索引。
7. 明确同一 `originTurnId` 的重复创建识别方式，建议在单任务接受模型下设置唯一约束，
   避免重试生成新 `taskId` 绕过回执去重。为 lease 过期时间、退避到期时间、外部 job 句柄及
   最小恢复状态安排持久化位置。
8. 让新建数据库直接使用完整新 schema；旧版本不可直接继续使用。实施时以代码中的当前版本
   为基线递增，不在计划中固定版本号。开发测试使用新建数据库，不实现旧库升级或回填。

## 代码落点

| 类型 | 入口 |
| --- | --- |
| 新增领域对象与契约 | `lib/domain/models/conversation_task.dart`、`task_segment_limits.dart`；`lib/domain/repositories/conversation_task_repository.dart`，按职责拆分值对象 |
| 现有消息与证据 | [message.dart](../../../lib/domain/models/message.dart)、[tool_evidence.dart](../../../lib/domain/models/tool_evidence.dart) |
| 新 schema 与校验 | [database_service.dart](../../../lib/data/services/database_service.dart)、[database_schema_verifier.dart](../../../lib/data/services/database_schema_verifier.dart)，新任务 schema 按独立文件组织 |
| 执行预算参考 | [agent_run_models.dart](../../../lib/domain/use_cases/agent_run_models.dart)，只参考已有护栏含义，后台使用独立默认值 |

## 验证与退出条件

- [ ] Domain 测试覆盖合法/非法状态变换、终态不可逆、快照不可变及执行策略边界。
- [ ] 新建数据库包含全部目标表、约束、索引和消息/证据关联，schema 校验通过。
- [ ] 消息类型、状态类型和快照可无损映射；敏感配置不进入任务 DTO。
- [ ] Repository 契约能表达原子接受、原子进展、原子终态、取消与恢复所需的操作。
- [ ] Domain 无 Flutter、SQLite 或具体 Provider 依赖；没有引入历史兼容模型。

本阶段交付契约和 schema。实际事务行为在阶段 02 实现，状态机和策略测试随本阶段提交。
