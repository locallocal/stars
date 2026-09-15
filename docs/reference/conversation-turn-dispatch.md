# 会话前台分流与任务接受

[文档导航](../README.md) | [目标规格](../specs/conversation-foreground-background-model.md) |
[任务持久化](conversation-task-persistence.md) | [验收与观测](conversation-task-verification.md)

前台三路分流、直接回复提交、任务接受、状态查询及失败重试已实现。已接入[生产会话交互](conversation-task-chat-ui.md)，并通过真实 SQLite 和完整页面流程测试；旧入口与恢复已删除，见[正式运行边界](conversation-task-cutover.md)。

## 职责与入口

| 入口 | 职责 |
| --- | --- |
| [ConversationTurnDispatcher](../../lib/domain/use_cases/conversation_turn_dispatcher.dart) | 保存用户消息，准备上下文，消费一次分流，提交回复或接受任务，查询状态 |
| [输入、结果与重试契约](../../lib/domain/use_cases/conversation_turn_dispatch_contracts.dart) | 原始消息和 turn、准备结果、策略快照、展示事件、结果与指标 |
| [TurnDisposition](../../lib/domain/models/turn_disposition.dart) | `DirectReply`、`BackgroundTaskPlan`、`TaskStatusRequest` 三个互斥领域结果 |
| [ProviderConversationTurnRouter](../../lib/data/services/ai/provider_conversation_turn_router.dart) | 单次无工具的 Provider 传输、终态与超时检查、协议事件转换 |
| [TurnRoutingProtocol](../../lib/data/services/ai/turn_routing_protocol.dart) | 路由协议、schema、长度、工具子集及重复字段校验 |
| [TaskAcknowledgementPolicy](../../lib/domain/services/task_acknowledgement_policy.dart) | 接受语义校验和本地化兜底，不调用模型 |
| [任务接受构造](../../lib/domain/use_cases/conversation_turn_acceptance.dart) | 冻结配置、上下文、白名单、验证和分段策略；建立任务与回执身份 |

`PrepareTextGeneration` 和 `ComposeChatTurn` 继续负责上下文、压缩、Skill/MCP 准备、工具发现与
preflight Token。dispatcher 将请求工具与验证工具在实际 registry 中解析，再把名称白名单交给
router；工具可用不触发 Agent Loop。run-scoped 工具仍由准备结果携带，接受时记录其允许名称。

## 单次分流协议

协议 v1 使用逐行 JSON 对象，流式和缓冲传输共用同一个解析器。首帧只包含 `kind`，末帧只包含
`done: true`。直接回复的中间帧包含 `text`，任务只允许一个完整计划帧，状态只允许一个 `taskId`
帧。例如：

```jsonl
{"kind":"directReply"}
{"text":"你好！"}
{"done":true}
```

计划字段和限制以解析器为准：标题 200 字符、目标 16000 字符、1–32 个唯一待执行步骤、步骤
摘要 2000 字符、最多 256 个允许工具；整个响应有大小和帧数上限。未知类型、额外字段、错误
类型、重复字段（含 Unicode 转义别名）、重复步骤、越权工具、缺少末帧和 Provider 截断均拒绝。
错误只返回固定的可恢复原因，不把原始 Provider 异常、JSON 或未校验草稿显示给用户。

流式路径先发送 `TurnDispositionStarted`，只有 `directReply` 的完整文本帧可用于即时展示。
任务计划与回执一直留在内部，直到全部校验成功并提交接受事务。缓冲路径须完成整次响应及
协议校验后才发布领域事件。协议末帧不能替代 Provider 的成功终态。

### Provider 边界

`AiProvider.foregroundRoutingTransport` 默认不可用，只有审查过的无工具路径明确启用：

- OpenAI 和 Anthropic 使用初始 model session；不调用 continuation、synthesis 或 coordinator。
  OpenAI Chat Completions 在 `foregroundRouting` 选项下启用文本流，既有 Agent Loop 传输保持
  原来的选择；Responses 和 Anthropic 使用当前适配器的整次响应传输。
- Gemini、Deepseek 和 Ollama 使用缓冲文本路径，关闭搜索和深度思考开关。
- OpenAI 搜索类模型及尚未审查的其他 Provider 返回可恢复的 `unsupportedProvider`。

`ModelRequest` 在前台路由模式下禁止应用工具、原生搜索、并行工具调用和深度思考选项。路由
适配器也拒绝意外的工具请求、原生工具结果及非路由输出；不会因为收到这些事件而执行工具。
请求有整体超时，持续发送 reasoning 也不会延长时限。公开能力的事实源是对应 Provider getter。

## 保存、接受与恢复

调用方先用现有 `CreateUserMessage` 建立原始消息，再创建 `ConversationTurnInput`。输入复制
附件列表与嵌套配置，冻结语言、验证与分段策略。配置只以摘要进入任务存储，API Key 和 Provider
地址不以原始配置字段持久化；reasoning 不进入路由消息或任务上下文，任务记录继续经过存储净化。

| 处置 | 持久化与返回行为 |
| --- | --- |
| 直接回复 | 只提交完整的 `turnId:assistant`，应用现有终态与 `AnswerTrustPolicy`；没有工具证据时不标为已验证 |
| 接受任务 | 原子提交任务、初始计划、事件、进度投影及 `taskId:ack`，提交后调用 `enqueue` |
| 查询状态 | 返回持久化摘要；由 PresentConversationTaskProgress 保存卡片并启动同版本润色 |

直接回复的 delta 仅供显示，不落 partial 消息；流中断或格式错误时返回失败，UI 应丢弃展示中的
临时文本。有效的空回复按 `emptyResponse` 保存；失败或取消的类型化直接结果不保存半段正文。

任务 ID 由原始 turn 的 SHA-256 派生并保持有界。接受成功返回持久化任务与回执 ID，UI 从数据库
观察回执，不使用内部草稿确认接受。调度契约只负责唤醒；通知抛错或超过短通知时限时，仍返回
任务已接受，`notificationDelivered` 为 false。数据库中的 queued 任务供后续扫描恢复。

每个会话同时只有一个前台请求；多个 dispatcher 入口应共享 `ForegroundTurnGate`，通常由
组合根创建一个共享 dispatcher。后台任务数量不占这个锁，通知失败也不会把已接受任务留在锁中。

### 回执

回执与计划由同一个主回复模型回合生成。策略保留符合任务引用、语言、简洁和接受语义约束的
自然草稿；英语与简体中文使用保守的整句接受语法，不依赖可能漏掉虚假声明的关键词黑名单。
不能确认合格的草稿使用应用支持语言的本地模板。空草稿、无关内容、已执行/完成声明和精确时间
承诺均不会成为接受回执。模板说明需要时间、已经记录、完成后发送完整结果，不增加模型调用。

### 失败与幂等

- 用户消息尚未保存：尝试恢复文本与附件草稿；即使草稿存储也失败，结果仍携带 UI 恢复材料。
- 用户消息已保存：错误带有原始输入和不透明 `TurnDispatchRetry`；重试不新建用户消息或 turn。
- 计划已校验但接受失败：重试保留准备结果、冻结策略、计划与回执，不再调用主回复模型。
- 直接回复落库失败：重试保留完整文本；只重试同一助手消息的持久化。
- 提交成功但响应丢失：重试先按原始 turn 对账，复用已经持久化的任务或直接回复。
- 同一消息身份对应不同内容：返回身份冲突，不覆盖原消息；保存成功也不清除后来输入的新草稿。

重试对象用于当前进程内保留未提交材料；数据库是已经接受任务的事实源。进程重启后重新派发
原始输入也会先检查持久化成功，不能以重建内存队列代替数据库恢复。

## 状态选择

显式任务引用直接调用 `GetConversationTaskProgress`，跳过准备和模型请求。普通自然语言状态
问题由主回复回合产生 `TaskStatusRequest`，再读取持久化事实：

1. 有任务 ID：只查询该会话内的指定任务，不存在或属于其他会话时返回空结果。
2. 无 ID：返回非终态候选；一个候选可直接展示，多个候选要求用户选择。
3. 没有活动任务：查询最近终态；没有历史任务则返回空结果。

进度、工具次数、审批与验证均来自 repository 摘要，不从聊天内容推测，不启动 Agent Loop。

## 指标与测试入口

`TurnDispatchMetrics` 分别记录准备流水线调用次数、preflight Token、准备耗时和主回复调用次数，
以及直接回复首字符/提交延迟、回执提交延迟、路由可恢复回退和回执兜底次数。延迟按每次派发的
单调时钟计算；持久化重试的主回复调用数为零。状态润色单独记录指标，不属于这个主回复调用统计。

- [协议与流式校验](../../test/data/services/ai/turn_routing_protocol_test.dart)
- [Provider 传输与禁止工具边界](../../test/data/services/ai/provider_conversation_turn_router_test.dart)
- [回执策略](../../test/domain/services/task_acknowledgement_policy_test.dart)
- [SQLite 接受、重试、并发与恢复](../../test/domain/use_cases/conversation_turn_dispatcher_test.dart)
- [状态选择与会话隔离](../../test/domain/use_cases/conversation_turn_status_test.dart)

测试使用 fake 模型输出和 HTTP transport、真实临时 SQLite，以及 fake 调度通知；不要求 API Key
或外部模型服务。完整页面流程见[会话交互测试](conversation-task-chat-ui.md#指标与验证)；外部模型分类质量和真实首字符体验仍需产品验收。
