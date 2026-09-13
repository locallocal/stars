# 会话前台响应与后台任务模型

[返回文档导航](../README.md) |
[现有消息流转](../reference/user-message-agent-response-flow.md) |
[事实依据与防幻觉协议](../reference/conversation-loop-grounding.md)

本文定义 Stars 会话内用户与智能体交互的目标模型，以及基于现有实现进行调整的落地规范。
它是待实现的长期设计，不代表当前代码已经具备后台恢复能力。

规范使用以下关键词：

- **必须**：实现不可省略的正确性或安全要求；
- **应该**：默认实现方式，只有明确理由时才能偏离；
- **可以**：不影响核心语义的扩展项。

## 1. 目标与边界

### 1.1 需求映射

| 编号 | 用户体验目标 | 设计约束 |
| --- | --- | --- |
| 1 | 智能体尽快响应 | 每条输入先走轻量前台分流；首个模型调用同时完成“直接回答或创建任务”的判断，避免额外分类调用 |
| 2 | 简单问候和可直接回答的问题立即结束 | 生成一个完整助手消息，不创建后台任务，不进入工具循环 |
| 3 | 工具型、长时间任务后台运行 | 先原子保存任务与受控回执，再由脱离页面生命周期的任务调度器执行；完成后一次性发送整体结果 |
| 4 | 用户可询问任务状态 | 状态回答读取持久化任务事实，不要求运行中的模型记住状态，也不猜测进度 |
| 5 | 长任务可使用现有验证模式且无整体超时 | 复用证据和可信性门禁；取消任务级墙钟超时，但保留单次操作超时、重试上限、无进展检测与用户取消 |
| 6 | 按现有实现调整且不兼容历史数据 | 延续现有分层、工具与证据模型；采用新数据库结构，不迁移、不回填、不双读旧运行数据 |

### 1.2 非目标

- 不让模型在聊天文本中模拟任务进度或完成状态；
- 不把完整思维链、密钥、原始工具参数或无限增长的工具输出写入任务状态；
- 不承诺移动操作系统终止或长期挂起应用进程后仍能持续占用 CPU/网络；
- 不让后续普通聊天隐式修改已经接受的后台任务目标；
- 不为旧的 `runId`、partial 助手消息或未完成 Agent Run 提供迁移适配。

这里的“后台运行”指任务不依赖 `ChatPage`、当前路由或某个
`ChatGenerationViewModel` 的存活。应用进程可运行时任务持续执行；进程被操作系统停止后，任务
保持可恢复状态，并在应用恢复或平台后台执行窗口可用时继续。平台不允许执行期间，不虚构“仍在
运行”。

## 2. 当前实现与目标差异

现有路径详见[现有消息流转](../reference/user-message-agent-response-flow.md)。需要替换的关键边界如下：

| 当前实现 | 目标实现 |
| --- | --- |
| 会话有可用工具时倾向进入 Agent Loop | 首个前台模型回合明确返回“直接回复”或“后台任务计划” |
| 一个 `ChatGenerationViewModel` 管理会话内唯一阻塞 run | 前台回复与后台任务分别管理；后台任务不占用会话输入锁 |
| Agent Loop 规划文本暂存，最终只形成一个助手消息 | 直接回复仍是一个消息；长任务先有受控回执，完成后再有一个整体结果消息 |
| 总运行默认受 15 分钟 deadline 限制 | 后台任务不设置整体墙钟超时 |
| 工具审批超时会结束等待 | 审批进入持久化 `waitingForUser`，等待本身没有任务级超时 |
| 恢复逻辑把非终态调用标为中断并安全失败 | 任务从检查点恢复；副作用调用先对账，禁止盲目重放 |
| 运行期间 `_isTyping` 阻止用户继续发送 | 只阻止同一前台分流重复提交，后台任务运行时仍可聊天和询问状态 |
| 可信状态围绕单次 run 的最终消息计算 | 验证策略在任务创建时快照，并对跨阶段证据进行统一验证 |

本次调整不应把更多职责堆入现有 `ChatGenerationViewModel`。它应收缩为前台交互协调器，后台
生命周期由独立的 Domain 用例与持久化调度器承担。

## 3. 总体模型

```text
用户输入
  |
  v
前台 ConversationTurnDispatcher
  |-- DirectReply ----------------------> 保存完整助手回复 -> 本轮结束
  |
  |-- BackgroundTaskPlan
  |      -> 原子保存任务 + 回执消息
  |      -> ConversationTaskScheduler.enqueue
  |      -> 立即释放输入框
  |             |
  |             v
  |        后台 ConversationTaskRunner
  |          规划 -> 工具 -> 证据 -> 验证 -> 合成
  |             |
  |             `-----------------------> 一次性保存整体结果
  |
  `-- TaskStatusRequest
         -> 从 ConversationTaskRepository 读取事实
         -> 生成确定性的状态回复或状态卡片
```

该模型有三条互斥的前台处置结果：

```dart
/// 目标接口示意，不是当前代码。
sealed class TurnDisposition {
  const TurnDisposition();
}

final class DirectReply extends TurnDisposition {
  const DirectReply({required this.content});
  final String content;
}

final class BackgroundTaskPlan extends TurnDisposition {
  const BackgroundTaskPlan({
    required this.title,
    required this.objective,
    required this.steps,
    required this.allowedToolNames,
    required this.requiresVerification,
  });

  final String title;
  final String objective;
  final List<TaskPlanStep> steps;
  final Set<String> allowedToolNames;
  final bool requiresVerification;
}

final class TaskStatusRequest extends TurnDisposition {
  const TaskStatusRequest({this.taskId});
  final String? taskId;
}
```

Provider 不支持结构化输出时，Data 层适配器仍必须把结果解析为相同的密封类型；解析失败应回退到
普通直接回复或可恢复错误，不得凭不完整 JSON 启动工具任务。

## 4. 前台快速分流

### 4.1 一次调用同时分类与回答

为了缩短首条可见响应的延迟，不增加一个“先分类、再回答”的模型往返。`PrepareTextGeneration`
仍负责上下文、Token 预算、Skill、MCP 与工具白名单；随后由
`ConversationTurnDispatcher` 发起一个受约束的模型回合：

- 能直接回答时返回 `DirectReply.content`；
- 确实需要工具、审批、等待外部系统或多阶段验证时返回 `BackgroundTaskPlan`；
- 用户询问已有任务时返回 `TaskStatusRequest`；
- 返回的工具名必须是本轮准备结果中白名单的子集；
- 路由 JSON 必须经过 schema、长度和枚举校验；
- 路由模型无权声称工具已经执行或任务已经完成。

简单问候、闲聊、无需外部事实的解释、基于当前上下文即可完成的改写等应走直接回复。工具“存在”
不等于工具“需要调用”，因此不能再用“本轮工具列表非空”作为进入 Agent Loop 的充分条件。

推荐让 Provider 适配器先发出 `TurnDispositionStarted(kind)` 结构事件：`directReply` 后的文本 delta
可立即展示；`backgroundTask` 则继续收集并校验完整计划后再保存回执。UI 在收到 kind 前不展示模型
草稿，避免先显示半段回答又改成后台任务。Provider 不支持这种结构化流时，适配器缓冲并校验完整
响应；它仍然只进行一次模型调用，只是无法获得相同的首字符延迟。

### 4.2 直接回复时序

```text
保存用户消息
  -> 准备上下文
  -> 首个模型回合返回 DirectReply
  -> 应用现有回答终态与可信状态规则
  -> 保存一个完整助手消息
  -> 释放前台运行状态
```

直接回复不写 `conversation_tasks`，不创建回执消息，也不启动调度器。首个模型回合完成即为本轮
终态。仍可向 UI 流式显示直接回复，但持久化语义保持一个助手消息。

### 4.3 后台任务回执

模型只提供经过净化的任务标题和计划摘要，回执文本由应用本地化模板生成，例如：

> 已将“整理项目依赖并验证结果”转为后台任务。你可以继续聊天；完成后我会发送完整结果。

回执必须满足：

- 任务记录、初始事件和回执消息在同一数据库事务中写入；
- 事务提交后才能调用 `enqueue`；
- 不包含“已经完成”“验证通过”等执行性声明；
- 不包含工具原始参数、密钥或模型 reasoning；
- 使用稳定消息 ID `taskId:ack`，重复派发不能产生第二条回执；
- 回执保存成功后立即释放输入框，不等待第一个工具调用。

若事务失败，前台必须报告创建任务失败；不得显示一个实际不存在的后台任务。用户消息尚未持久化时
恢复草稿；用户消息已经持久化时，在原消息上提供“重新创建任务”动作，不得重复写入用户消息。

## 5. 后台任务状态机

任务生命周期和执行阶段分开保存，避免用一个不断膨胀的枚举表达两个维度。

### 5.1 生命周期

```text
queued -> running <-> waitingForUser
             |
             +------> paused
             |
             +------> succeeded
             +------> failed
             `------> cancelled

任意非终态 --用户取消--> cancelRequested --> cancelled
```

| 状态 | 含义 | 是否终态 |
| --- | --- | --- |
| `queued` | 已持久化，等待调度资源 | 否 |
| `running` | 某个 runner 持有有效租约并推进任务 | 否 |
| `waitingForUser` | 等待审批、补充认证或必要输入 | 否 |
| `paused` | 应用/平台暂时不能执行，检查点完整 | 否 |
| `cancelRequested` | 已收到取消请求，正在停止或对账 | 否 |
| `succeeded` | 整体结果已原子提交 | 是 |
| `failed` | 确认不可恢复或无进展后提交失败结果 | 是 |
| `cancelled` | 已安全停止并提交取消状态 | 是 |

`timedOut` 不再是任务终态。单次网络或工具调用超时是一次尝试的结果，任务可以重试、重规划、
暂停或请求用户处理。

### 5.2 执行阶段

沿用现有 Agent Loop 的语义，任务保存以下阶段：

`planning -> executing -> observing -> verifying -> synthesizing -> committing`

`waitingForUser` 是生命周期，审批原因另存为 `waitingReason`。阶段和生命周期的组合使状态查询可以
准确表达“等待用户批准执行阶段的写操作”，而不是只返回模糊的“处理中”。

### 5.3 任务进度

进度是业务事实，不使用虚假的时间百分比。每次检查点最多保存：

- 已完成步骤数与计划步骤总数；
- 当前步骤的安全摘要；
- 最近一次有意义进展时间；
- 累计模型回合、工具尝试和恢复次数；
- 等待原因、失败代码或验证阶段；
- 最近进展内容的摘要哈希，用于无进展检测。

当计划动态调整时增加 `planRevision`，并同时更新总步骤数。UI 应优先显示“3/5 个步骤”和当前
阶段，不能把不稳定的步骤比值渲染成精确剩余时间。

## 6. 无整体超时与有界执行

“整体无超时时间”只取消任务墙钟 deadline，不等于允许不可取消、无限循环或无限成本的单次
操作。

### 6.1 必须移除

- 从后台路径移除 `AgentRunLimits.totalTimeout`；
- 不使用 `synthesisTimeout` 作为整个任务剩余时间的延伸；
- 用户审批等待不再因 `approvalTimeout` 自动失败；
- 导航、页面销毁和布局切换不得取消后台任务。

### 6.2 必须保留的护栏

- Provider 单次请求、工具单次连接和轮询请求仍有技术超时；
- 单个执行分段仍限制模型回合数、工具调用数、相同参数重试数和连续失败数；
- 分段达到上限但确有进展时，保存检查点并排入下一分段，而不是结束整个任务；
- 连续多个分段的进展摘要哈希相同，且没有新证据、外部 job 状态或用户输入时，以
  `task_no_progress` 安全失败；
- 用户取消、权限永久拒绝、无效计划、缺少必需密钥等可以成为明确终态；
- 每次重试采用有上限的指数退避，等待期间不占用 runner 并发槽。

默认分段限制可以复用当前 `AgentRunLimits` 中除整体时间之外的数值，但它们应重命名为
`TaskSegmentLimits`，明确只是单段预算。限制值仍由代码与测试作为事实来源，文档不复制易变默认值。

### 6.3 长时间工具协议

一个可能运行数小时的外部任务不能由单个永不返回的 `Future` 表示。工具执行结果需要区分：

```dart
/// 目标接口示意，不是当前代码。
sealed class ToolStartResult {
  const ToolStartResult();
}

final class ToolCompleted extends ToolStartResult {
  const ToolCompleted(this.output);
  final ToolOutput output;
}

final class ToolJobStarted extends ToolStartResult {
  const ToolJobStarted({
    required this.externalJobId,
    required this.resumeToken,
  });

  final String externalJobId;
  final String resumeToken;
}
```

支持长任务的工具必须提供查询、取消和必要时的对账能力。`resumeToken` 应是可撤销的引用或安全句柄，
不能直接保存访问密钥。轮询结果成为任务事件；两次轮询之间 runner 释放资源。

## 7. 任务状态询问

### 7.1 解析规则

状态请求可在后台任务运行时正常发送。前台分流识别为 `TaskStatusRequest` 后：

1. 显式提到任务 ID 时读取该任务；
2. 没有 ID 且只有一个非终态任务时选择该任务；
3. 有多个候选任务时返回任务列表，由用户选择；
4. 没有活动任务时说明最近任务终态或当前没有运行任务；
5. 不启动 Agent Loop，不让模型根据聊天上下文猜测进度。

自然语言意图识别可以由首个模型回合完成，但状态内容必须由应用根据 repository 数据生成。可以
用确定性模板或状态卡片呈现，不再进行第二次模型润色，以同时保证速度和真实性。
用户点击任务卡片的“查看状态”或发送带稳定任务引用的结构化命令时，应直接查询 repository，跳过
模型意图识别。

### 7.2 用户可见信息

状态回复可以包含：任务标题、稳定短 ID、生命周期、当前阶段、已完成/总步骤、最近更新时间、
等待原因、恢复次数和验证状态。

状态回复不得包含：模型思维链、未净化工具输出、完整文件内容、密钥、访问令牌、原始请求头、
敏感工具参数或未经确认的完成百分比。

状态消息使用 `messageKind = taskStatus` 并关联 `taskId`。它是应用根据持久化状态生成的操作消息，
不应被标成“已验证的模型事实”。

## 8. 最终结果与验证模式

### 8.1 复用现有验证能力

后台路径继续使用现有：

- `ToolExecutionRecord` 与 `ToolEvidenceRecord`；
- 写操作后的读取验证策略；
- `GroundedAnswerCandidate` 与 `GroundedAnswerValidator`；
- `AnswerTrustPolicy`；
- `StrictGroundingPolicy`。

工具证据需增加 `taskId` 和 `segmentId`，或通过不可变关联表建立同等关系。验证器只接受同一任务
的已成功证据，不能把另一轮聊天或另一后台任务的工具结果当作本任务依据。

### 8.2 策略快照

创建任务时保存 `VerificationPolicySnapshot`：

```dart
final class VerificationPolicySnapshot {
  const VerificationPolicySnapshot({
    required this.reliabilityEnabled,
    required this.strictGroundingEnabled,
    required this.showVerificationStatus,
    required this.policyVersion,
  });

  final bool reliabilityEnabled;
  final bool strictGroundingEnabled;
  final bool showVerificationStatus;
  final int policyVersion;
}
```

运行中修改个人设置只影响新任务。当前任务仍按接受时的策略验证，避免同一任务在最后一步因为 UI
设置变化而改变正确性语义。展示层可以采用最新主题，但不能改写保存的验证结论。

### 8.3 整体发送

后台执行期间不把规划草稿、工具观察或未验证候选答案作为普通助手消息写入时间线。它们只作为受
限任务事件和检查点存在。完成路径为：

```text
汇总跨分段证据
  -> 合成一个 GroundedAnswerCandidate
  -> 声明级验证
  -> 应用 StrictGroundingPolicy
  -> 在同一事务中保存 taskId:result + 任务终态
  -> 通知会话 UI
```

最终结果使用稳定消息 ID `taskId:result`，重复提交必须幂等。严格模式下无法证实的关键声明仍按
现有策略抑制；必要时发送一个整体的部分结果或验证失败说明，而不是先发送未经验证答案再补一条
更正。

回执、状态和等待审批消息属于操作信息；只有 `directReply` 与 `taskResult` 进入回答可信状态计算。

## 9. Domain 模型与持久化

### 9.1 核心实体

```dart
/// 字段名称是目标模型，最终实现可按项目命名约定微调。
final class ConversationTask {
  const ConversationTask({
    required this.taskId,
    required this.chatId,
    required this.botId,
    required this.originTurnId,
    required this.originUserMessageId,
    required this.ackMessageId,
    required this.title,
    required this.objective,
    required this.status,
    required this.phase,
    required this.planRevision,
    required this.progress,
    required this.verificationPolicy,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
    this.resultMessageId,
    this.waitingReason,
    this.failureCode,
    this.completedAt,
  });

  final String taskId;
  final String chatId;
  final String botId;
  final String originTurnId;
  final String originUserMessageId;
  final String ackMessageId;
  final String? resultMessageId;
  final String title;
  final String objective;
  final ConversationTaskStatus status;
  final ConversationTaskPhase phase;
  final int planRevision;
  final TaskProgress progress;
  final VerificationPolicySnapshot verificationPolicy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? waitingReason;
  final String? failureCode;
  final int revision;
}
```

另设以下值对象：

- `ConversationTaskPlan`：版本化目标、步骤与工具白名单；
- `ConversationTaskEvent`：只追加的状态变更、尝试、审批和外部 job 事件；
- `ConversationTaskCheckpoint`：恢复所需的最小状态、下一步骤和证据游标；
- `TaskProgress`：可向用户展示的净化进度；
- `TaskLease`：runner 所有权和过期时间，不等同于任务超时；
- `TaskMessageKind`：`acknowledgement`、`status`、`result`。

### 9.2 Repository 契约

Repository 接口位于 Domain 层，实现位于 Data 层：

```dart
abstract interface class ConversationTaskRepository {
  Future<ConversationTask?> getById(String taskId);

  Future<List<ConversationTask>> listActiveForChat(String chatId);

  Future<void> createWithAcknowledgement({
    required ConversationTask task,
    required ConversationTaskPlan plan,
    required Message acknowledgement,
  });

  Future<TaskLease?> tryAcquireLease(String taskId, DateTime now);

  Future<void> appendEventAndCheckpoint({
    required ConversationTaskEvent event,
    required ConversationTaskCheckpoint checkpoint,
    required int expectedRevision,
  });

  Future<void> commitResult({
    required String taskId,
    required Message result,
    required ConversationTaskStatus terminalStatus,
    required int expectedRevision,
  });

  Future<void> requestCancellation(String taskId);
}
```

所有状态更新使用 `revision` 乐观并发控制。事件使用 `(taskId, sequence)` 唯一键；工具尝试使用稳定
幂等键。repository 方法表达领域事务，UI 不直接拼装数据库写操作。

### 9.3 数据表

目标 schema 至少包含：

| 表/字段调整 | 用途 |
| --- | --- |
| `conversation_tasks` | 当前任务生命周期、阶段、进度、策略快照、租约和终态 |
| `conversation_task_plans` | 版本化计划及允许的工具集合 |
| `conversation_task_events` | 只追加审计与恢复事件 |
| `conversation_task_checkpoints` | 每个计划版本的最新可恢复检查点 |
| `messages.task_id` | 将回执、状态和最终结果关联到任务 |
| `messages.task_message_kind` | 区分普通回答与任务操作/结果消息 |
| 工具执行与证据记录的 `task_id`、`segment_id` | 汇总跨分段证据并保证验证作用域 |

任务表只保存 bot ID、配置版本摘要和运行时所需的非敏感参数。Provider API key 和工具凭据继续从
当前安全配置读取，绝不复制到任务、事件、检查点或导出数据。

### 9.4 不兼容历史数据

目标实现从当前数据库 schema 版本创建一个新的 schema 版本，并采用**干净重建**路径：

- 不提供旧版本到新版本的数据迁移；
- 不回填旧消息的 `taskId` 或消息类型；
- 不恢复旧的非终态 Agent Run；
- 不保留新旧表双读或兼容 DTO；
- 旧数据库不能直接由新版本打开后继续使用。

实现时应在开发和测试环境删除并重建本地数据库；若产品需要让用户保留旧数据，必须先另行设计
导出方案，该方案不属于本规范。Schema 测试必须直接以新建数据库为基线，不测试历史升级。

## 10. 调度、恢复与幂等

### 10.1 调度边界

`ConversationTaskScheduler` 由 `AppDependencies` 创建为应用级单例，并在 repository 初始化后启动。
它不依赖页面 BuildContext。MVP 并发规则为：

- 每个会话最多一个 `running` 任务，其余保持 `queued`；
- 不同会话受全局和 Provider 并发上限控制；
- 前台分流每个会话最多一个，但不受后台任务占用影响；
- 等待用户或退避中的任务不占用执行槽；
- 同一任务同一时刻只有持有有效 lease 的 runner 可以提交进展。

后台任务使用接受时冻结的会话上下文、bot ID、配置摘要和计划。之后发送的普通消息不会隐式改变
任务。如果未来支持“给任务补充信息”，必须作为带 revision 的显式命令设计。

### 10.2 恢复规则

应用启动后扫描 `queued`、`running`、`paused`、`cancelRequested` 和可继续的
`waitingForUser` 任务：

1. 过期 lease 只表示 runner 已失联，不表示任务失败；
2. Provider 会话不可序列化，使用检查点上下文建立新会话；
3. 已有成功终态的工具尝试绝不再次执行；
4. 只读或声明为幂等的中断调用可以使用同一幂等键重试；
5. 写操作或外部进程先查询外部 job、读取目标状态或执行专用 reconcile；
6. 无法确定副作用是否发生时进入 `waitingForUser`，不得盲目重放；
7. 恢复后继续积累同一 `taskId` 的证据，最终只提交一次结果消息。

现有 `RecoverAgentRuns` 的“把未完成调用标记为中断并提交安全失败消息”不再作为后台任务恢复
策略；它应被任务恢复用例替换，而不是在 UI 层增加例外。

### 10.3 删除与取消

- 用户取消任务时先持久化 `cancelRequested`，再通知 runner 或外部 job；
- 外部副作用需要对账后才能进入 `cancelled`；
- 删除有非终态任务的会话必须明确提示并走取消/对账流程，禁止留下孤儿任务；
- 删除 bot 时若仍有非终态任务，应阻止删除或先取消相关任务；
- 运行时找不到 bot、Provider 或密钥时，任务进入带可操作原因的 `waitingForUser` 或明确失败，
  不保存密钥副本作为规避手段。

## 11. 分层落地

调整必须遵守[应用架构](../architecture.md)的依赖方向：

```text
View -> ViewModel -> Domain Use Case -> Repository Contract
                                      ^
                                      |
                          Data Repository -> Service/SQLite/Provider
```

### 11.1 Domain 层

新增或拆分：

- `models/conversation_task.dart`：任务、状态、阶段、计划、进度和策略快照；
- `repositories/conversation_task_repository.dart`：持久化领域契约；
- `use_cases/conversation_turn_dispatcher.dart`：三路前台处置；
- `use_cases/conversation_task_runner.dart`：从检查点推进一个有界分段；
- `use_cases/conversation_task_scheduler.dart`：排队、lease、并发和退避；
- `use_cases/recover_conversation_tasks.dart`：启动恢复与副作用对账；
- 将 `AgentRunCoordinator` 可复用的规划、执行、观察、验证和合成能力下沉为分段协调组件。

Domain 层不依赖 Flutter、SQLite 或具体 Provider。任务状态变换集中在实体/用例中并进行单元测试。

### 11.2 Data 层

新增 SQLite repository、schema 和映射 DTO；扩展工具执行/证据存储的任务作用域。长工具适配器
实现 start/poll/cancel/reconcile 协议。事务、唯一键、lease 和乐观锁在 repository/service 中实现，
而不是泄漏到 ViewModel。

### 11.3 UI 层

- 将现有 `ChatGenerationViewModel` 收缩或重命名为前台回复 ViewModel；
- 新增只订阅任务摘要的 `ConversationTasksViewModel`；
- `_isTyping` 只反映前台分流/直接回复，不反映后台任务；
- 时间线展示回执和一次性结果，任务卡片展示进度、等待审批、取消和重试动作；
- 状态卡片使用 shadcn 风格的语义 token、紧凑层级和可访问状态标签，不用颜色作为唯一状态信号；
- View 只绑定不可变状态并转发命令，不启动 runner、不直接轮询数据库。

任务更新通过 repository watch stream 或应用级事件流通知 UI。页面重新进入时从持久化快照恢复显示，
不依赖内存中的旧 ViewModel。

### 11.4 依赖注入

`AppDependencies` 负责组装 repository、dispatcher、runner、scheduler 和 recovery use case。启动顺序为：

```text
初始化数据库
  -> 构造任务依赖
  -> 恢复未终态任务
  -> 启动 scheduler
  -> 构造/展示页面
```

UI 不使用 service locator 获取 runner；测试通过构造函数注入 fake repository、clock、ID generator、
provider session factory 和 tool executor。

### 11.5 现有代码调整映射

| 现有事实源 | 目标调整 |
| --- | --- |
| [`chat_send_commands.dart`](../../lib/ui/features/chat/views/chat_send_commands.dart) | 发送入口改为调用前台 dispatcher；后台任务不再保持 `_isTyping` |
| [`chat_generation_view_model.dart`](../../lib/ui/features/chat/view_models/chat_generation_view_model.dart) | 收缩为前台 run 生命周期；移出工具长任务、后台恢复和最终结果提交职责 |
| [`chat_generation_registry.dart`](../../lib/ui/features/chat/view_models/chat_generation_registry.dart) | 只管理前台会话交互，不再代表后台任务注册表 |
| [`prepare_text_generation.dart`](../../lib/domain/use_cases/prepare_text_generation.dart) 与 [`compose_chat_turn.dart`](../../lib/domain/use_cases/compose_chat_turn.dart) | 保留上下文和工具白名单准备，输出交给三路 dispatcher |
| [`agent_run_coordinator.dart`](../../lib/domain/use_cases/agent_run_coordinator.dart) | 拆出可检查点化的任务分段协调器，取消任务级 deadline |
| [`recover_agent_runs.dart`](../../lib/domain/use_cases/recover_agent_runs.dart) | 由持久化任务恢复用例替代，不再把所有未完成任务直接转为安全失败 |
| [`message.dart`](../../lib/domain/models/message.dart) | 增加任务关联与消息语义类型，区分回执、状态和最终结果 |
| [`tool_evidence.dart`](../../lib/domain/models/tool_evidence.dart) | 增加任务/分段作用域，支持跨分段、同任务验证 |
| [`answer_trust_policy.dart`](../../lib/domain/services/answer_trust_policy.dart) 与 [`strict_grounding_policy.dart`](../../lib/domain/services/strict_grounding_policy.dart) | 接收任务创建时的验证策略快照，只为直接回答和任务结果计算可信终态 |
| [`database_service.dart`](../../lib/data/services/database_service.dart) | 创建全新 schema 基线和任务表，不实现旧版本升级路径 |
| [`app_dependencies.dart`](../../lib/ui/core/dependency_injection/app_dependencies.dart) | 组装任务 repository、runner、scheduler 与启动恢复流程 |

## 12. 消息身份与时间线语义

同一用户输入保留一个 `originTurnId`。消息身份规则为：

| 场景 | 消息 ID | `taskId` | 消息类型 |
| --- | --- | --- | --- |
| 直接回复 | `turnId:assistant` | 空 | `directReply` |
| 后台回执 | `taskId:ack` | 有 | `taskAcknowledgement` |
| 用户询问后的状态回复 | 新消息 ID | 有或为空 | `taskStatus` |
| 后台整体结果 | `taskId:result` | 有 | `taskResult` |

最终结果可能在用户后续消息之后到达，按数据库提交序列进入时间线。客户端不得为了视觉上紧邻原始
请求而改写历史顺序。通知与重新加载都以稳定消息 ID 去重。

## 13. 安全、隐私与可观测性

### 13.1 数据最小化

- 检查点保存继续执行所需的结构化状态，不保存模型完整 reasoning；
- 工具输出沿用当前长度限制和净化策略，大对象保存受控引用与摘要；
- UI 进度摘要由受约束字段生成，不能直接展示异常堆栈或原始响应；
- 日志和指标只记录任务短 ID、阶段、耗时、计数和错误代码，不记录用户内容或凭据；
- 导出智能体配置时现有“不导出密钥”的边界同样适用于任务数据。

### 13.2 指标

至少观测：

- 用户提交到直接回复首字符/完成的延迟；
- 用户提交到后台回执提交的延迟；
- 排队时长、有效执行时长、等待用户时长和端到端完成时长；
- 每任务分段数、恢复次数、工具重试次数；
- `task_no_progress`、对账失败和永久失败数量；
- 最终结果的证据覆盖与严格模式抑制数量；
- 回执已显示但任务未成功创建的数量，该指标必须恒为零。

任务没有整体超时，因此“长时间没有终态”不能自动算失败；应通过最近进展时间、等待原因和恢复
状态建立可观测告警。

## 14. 实现顺序

实现应按可验证的架构切面推进：

1. 建立全新的任务 Domain 模型、repository 契约和新建数据库 schema；
2. 实现任务与回执原子写入、消息关联和只读状态查询；
3. 引入前台三路 dispatcher，使直接回复不再因工具存在而进入 Agent Loop；
4. 将现有 Agent Loop 拆为可检查点化的执行分段，移除任务级 deadline；
5. 实现 scheduler、lease、队列、恢复、幂等工具尝试与副作用对账；
6. 接入跨分段证据与验证策略快照，原子提交整体结果；
7. 解开会话输入锁，增加任务状态卡片、审批、取消和状态询问；
8. 删除旧 run 恢复路径、旧 schema 与临时兼容代码；
9. 完成单元、repository、ViewModel、Widget 和恢复集成测试后更新
   [现有消息流转](../reference/user-message-agent-response-flow.md)为实际代码路径。

任一步都不得以 ViewModel 内的全局 Map 或仅内存队列代替持久化任务事实。

## 15. 验收标准

### 15.1 行为测试

| 场景 | 必须结果 |
| --- | --- |
| 简单问候 | 一个模型回合产生一个完整直接回复；无任务、无工具调用 |
| 可直接回答的问题 | 工具可用也不自动进入 Agent Loop |
| 长任务 | 任务与回执原子保存；回执后输入框立即可用 |
| 后台进行中继续聊天 | 新消息正常进入前台分流，不取消、不覆盖后台任务 |
| 询问单个任务 | 回复内容与 repository 快照完全一致，不调用工具生成进度 |
| 多个活动任务 | 返回可区分的短 ID 和状态，不擅自选择错误任务 |
| 后台工具产生中间文本 | 时间线不出现 partial 结果；终态只出现一个 `taskId:result` |
| 运行时间超过旧总时限 | 任务保持可运行或明确等待，不进入 `timedOut` |
| 单次调用超时 | 记录失败尝试并按策略重试/暂停，不直接结束整个任务 |
| 等待审批 | 重启和长时间等待后仍可审批；等待不占执行槽 |
| 严格验证成功 | 最终声明可追溯到同一任务的有效证据 |
| 严格验证失败 | 未验证关键声明被抑制，只提交安全的整体结果 |
| 用户取消 | 先保存取消请求，副作用对账后只形成一个取消终态 |

### 15.2 崩溃与幂等测试

必须在以下故障点终止并重启应用：

- 任务与回执事务提交前后；
- 工具请求发出前、发出后但结果落库前；
- 外部 job 创建后、句柄落库前后；
- 检查点保存前后；
- 最终消息保存前后；
- 用户取消写入前后。

每个测试都要证明：不重复回执、不重复最终结果、不盲目重复副作用、任务能恢复或进入可解释的
等待/失败状态。

### 15.3 分层与 UI 测试

- Domain 单元测试覆盖所有合法/非法状态变换和无进展检测；
- Repository 测试覆盖事务、唯一键、revision 冲突、lease 与全新 schema；
- ViewModel 测试证明后台更新不改变前台 typing 状态；
- Widget 测试覆盖任务卡片、状态标签、键盘操作、屏幕阅读语义和不同宽度；
- 架构测试禁止 UI 导入 Data 实现，禁止 Domain 导入 Flutter；
- 静态分析和格式化必须通过。

## 16. 关键设计结论

- 快速响应来自“一次前台模型回合完成分流和直接回答”，不是用未经验证的占位答案冒充结果；
- 后台任务是持久化领域实体，不是页面里未 `await` 的 `Future`；
- 回执由应用控制并与任务原子保存，最终结果只在执行与验证完成后整体发送；
- 状态询问以 repository 为事实源，模型只识别意图，不编造状态；
- 无整体超时与有界分段、单次调用超时、无进展检测并存；
- 验证策略在任务创建时快照，证据跨分段但不跨任务；
- 新实现不兼容历史数据库和旧 run，避免长期维护双重生命周期语义。
