# 用户消息到智能体回复的现有流转

[返回文档导航](../README.md) | [事实依据与防幻觉协议](conversation-loop-grounding.md)

本文记录 Stars 当前实现中，用户在会话页提交一条消息之后，到助手回复完成并进入历史记录的
完整运行路径。它用于定位职责、排查中断位置和约束后续重构；代码行为发生变化时应同步更新
本文。

本文以文本会话为主。图片、语音、音乐和视频生成会在发送入口提前分流，不进入文本
`AgentRunCoordinator`，其差异见“媒体生成旁路”。

## 总览

```text
ChatPage._sendMessage
  -> 按 Provider 输出模态分流
  -> 文本输入校验、草稿保护、附件复制到会话目录
  -> 创建用户 Message，并先乐观显示在时间线
  -> ChatGenerationViewModel.startTextWithPreparation
       -> 分配 runId / turnId，进入 submitting
       -> PrepareTextGeneration
            -> ComposeChatTurn
                 -> 组合系统提示、Bot 提示、Skill 与 MCP
                 -> PrepareConversationContext
                      -> Memory / 摘要 / 最近历史 / 当前消息
                      -> Token 预算、历史裁剪与必要的会话压缩
            -> 创建本轮历史、Skill/MCP inventory 等临时工具
            -> 发现基础事实验证工具
       -> 持久化用户消息、Skill 激活记录，更新会话预览
       -> 进入 connecting
       -> 按 Provider 能力与本轮工具分流
            |-- Agent Loop
            |     -> 模型规划
            |     -> 工具参数校验 / 策略 / 审批 / 执行 / 证据落库
            |     -> 工具结果回送模型，必要时继续下一模型轮
            |     -> 证据覆盖检查与结构化回答合成
            |     -> 声明级可信性校验
            |
            `-- 普通 Provider 流
                  -> provider.generateText
                  -> 文本 / reasoning / usage 回调直接归并
       -> 流式快照通知 UI，并节流保存 partial 助手消息
       -> completed / cancelled / failed / emptyResponse
       -> 计算 MessageGrounding，提交终态助手消息
       -> 更新会话预览，按需触发会话压缩
       -> UI 接收终态消息、清理草稿，并 acknowledge 回到 idle
```

## 参与对象与职责

| 层级 | 对象 | 当前职责 |
| --- | --- | --- |
| View | `ChatPage` 与 `chat_send_commands.dart` | 校验输入、保存待发送草稿、乐观更新消息列表、呈现流式状态和审批卡片 |
| UI 协调 | `ChatViewModel` / `ChatInteractionFacade` | 将页面命令转给会话用例，并把长运行生命周期交给共享 generation registry |
| 运行状态 | `ChatGenerationViewModel` | 建立 run、持久化用户消息、选择生成路径、归并事件、增量保存和提交终态 |
| 上下文准备 | `PrepareTextGeneration` / `ComposeChatTurn` / `PrepareConversationContext` | 组合提示、历史、Memory、Skill、MCP、工具白名单与 Token 预算 |
| Agent Loop | `AgentRunCoordinator` | 驱动多轮模型与工具交互、执行策略和审批、保存工具证据、合成并验证回答 |
| Provider | `AiProvider` / `AgentModelSession` | 将统一请求转换为厂商协议，并发出文本、reasoning、工具和 usage 事件 |
| 持久化 | Message、Tool execution/evidence、Memory repositories | 保存用户消息、partial/终态回复、工具审计证据、声明关系和会话摘要 |

`ChatGenerationRegistry` 按 `chatId` 保存 `ChatGenerationViewModel`。因此页面销毁或布局切换不会
天然终止正在运行的文本生成；导航、清空会话等动作通过 registry 检查并尝试停止活动运行。

## 1. 发送入口与输入保护

`ChatPage._sendMessage` 首先拒绝重复提交：只要当前会话仍处于 typing/running 状态，就不会再
启动一个 run。随后根据 Provider 的输出模态选择图片、语音、音乐、视频或文本路径。

文本路径 `_generateText` 接受以下任一输入：非空文本、图片附件或文件附件。发送前页面会：

1. 保存原始文本和附件到 pending draft，并写入 `ConversationDraftRepository`；
2. 通过 `PersistConversationAssets` 把附件复制到当前会话的受管目录；
3. 用 `CreateUserMessage` 创建带 `messageId`、`turnId`、附件和 file-edit 投影的用户消息；
4. 将用户消息先加入页面时间线，清空输入框与附件并滚动到底部；
5. 把发送前的历史快照和用户消息交给 generation ViewModel。

此时用户消息只是 UI 中的乐观状态。只有 generation ViewModel 成功写入 Message repository 后，
`snapshot.userPersisted` 才会变为 `true`。准备或持久化失败时，页面会移除乐观消息并恢复 pending
draft，避免丢失用户输入。

## 2. 建立本轮身份与生命周期

`startTextWithPreparation` 为本轮创建唯一 `runId`，沿用用户消息已有的 `turnId`，并把身份写回
用户消息。助手消息固定使用同一轮的 `"$runId:assistant"`，因此 partial 与终态保存会更新同一
条记录，而不是不断追加新消息。

外层 UI 生命周期是：

```text
idle
  -> submitting
  -> connecting
  -> active
  -> stopping                 # 仅取消过程中出现
  -> completed | cancelled | failed | emptyResponse
  -> idle                     # UI acknowledgeTerminal 后
```

每次运行创建新的 Provider 实例，并让所有异步回调捕获 `runId`。事件只有同时满足“仍是当前
run、尚未终态、未进入 finalizing”时才允许修改快照，因此旧请求迟到的 token、工具事件或终态
通知不能污染后续运行。

## 3. 生成前准备

### 3.1 组合本轮会话

`ComposeChatTurn` 依次完成：

- 取得会话产物目录并构造 Stars 会话上下文；
- 读取 Bot 绑定且可用的 Skill，加载内置 Skill，并在 Provider 支持时执行自动 Skill 激活；
- 合并 Stars 系统提示、Bot 系统提示、已激活 Skill 说明和受限 Skill 参考资料；
- 解析当前 Bot 已启用的 MCP 工具；
- 调用 `PrepareConversationContext` 生成 Provider 无关的消息列表。

Skill 激活失败会形成 `MessageToolCall`/activation attempt 投影，通常不会单独终止整轮准备。
激活成功的 Skill 只把其显式请求的工具加入本轮候选集；MCP、历史查询工具和免审批设置也在
这里形成明确集合。

### 3.2 组装受 Token 约束的上下文

`PrepareConversationContext` 以系统提示和当前用户消息为最高优先级，并根据模型上下文窗口
装配：

```text
系统提示
  + 会话历史查询策略（可用时）
  + 选中的 Memory
  + 滚动摘要
  + Token 预算内的最近完整 turn
  + 当前用户消息
```

历史助手消息会带可信性 envelope；失败、取消和不受信的 partial 内容默认不回放。过期事实
会被标记为需要重新验证。若历史过长，预算器会裁剪完整 turn，必要时同步压缩会话后重新装配，
或退化为保留最近历史的裁剪方案。系统提示、当前消息和固定上下文仍无法放入窗口时，准备直接
失败，不会向 Provider 发请求。

### 3.3 构造本轮工具集合

`PrepareTextGeneration` 在组合结果之外按需创建仅对本轮有效的会话历史、Skill inventory 和
MCP inventory 工具，并从受信内置工具中发现事实验证工具。最终结果包含：

- Provider 消息列表；
- 激活的 Skill 及尝试记录；
- `requestedToolNames` 与 `verificationToolNames`；
- `approvalExemptToolNames`；
- run-scoped 工具、预检 Token 用量、上下文装配报告和模型轮数上限；
- 无法提供验证工具时的明确降级原因。

工具不会因为存在于全局 registry 就自动暴露给模型。运行时只解析请求集合与验证集合的并集，
并在真正执行时再次校验该工具是否属于本轮白名单。

## 4. 用户消息先于主回复请求落库

准备完成后，generation ViewModel 才持久化带完整 run/turn 身份的用户消息。成功后会：

- 发布 `userPersisted = true`，使 UI 将乐观消息视为已提交；
- 尽力保存 Skill 激活记录；
- 尽力把用户内容更新为会话列表预览；
- 将生命周期推进到 `connecting`。

用户消息保存是硬边界：保存失败时不会启动正式回复的 Provider 请求或 Agent session。生成前
自动 Skill 激活可能已经使用独立的预检 Provider session，但它不会产生本轮回复。Skill 激活
记录和会话预览属于可恢复的附属写入，失败只记录诊断，不回滚已经保存的用户消息。

## 5. 生成路径分流

满足以下条件时进入 Agent Loop：

```text
provider.capabilities.supportsAgentLoop
  && (本轮至少有一个实际可用的应用工具
      || 已开启 web search 且 Provider 支持原生工具证据归一化)
```

其他情况进入普通 Provider 流。`supportsAgentLoop` 本身不足以启动 Loop；相反，Provider 有工具
能力但本轮没有获准暴露任何工具时，也会走普通文本生成。

### 5.1 Agent Loop

`AgentRunCoordinator` 建立独立 cancellation token 和内部状态机：

```text
planning
  -> awaitingApproval? -> executing
  -> observing
  -> verifying
  -> planning ...       # 需要继续调用工具或补证据
  -> synthesizing
  -> verifying          # 声明级校验
  -> committing
  -> completed | cancelled | failed | timedOut | limitExceeded
```

每个模型轮可能发出 reasoning、usage、应用工具调用或 Provider 原生工具结果。规划阶段的普通
`TextDelta` 只作为 draft 收集，不直接显示为最终正文；应用只在结构化合成和校验完成后，把
`GroundedAnswerCandidate.renderedText` 发布给 UI。这样工具前的猜测不会先以可信答案形式闪现。

#### 工具调用

每次应用工具调用遵循固定顺序：

```text
分配 invocationId / attemptId
  -> 检查重复 callId、参数冲突和重试上限
  -> 检查工具是否在本轮白名单
  -> JSON Schema 输入校验
  -> ToolPolicy 判定
       |-- deny -> 记录 denied 并返回错误 ToolResult
       |-- requireApproval -> UI 展示 ToolApprovalCard，等待 allowOnce/deny/超时
       `-- allow -> 继续
  -> 记录 running
  -> 执行工具并应用单工具超时/取消
  -> 拒绝空结果，校验输出与证据契约，限制输出大小
  -> 先持久化终态审计与可用证据
  -> 把 ToolResult 回送模型
```

只读且可安全并行的多个调用可在 Provider 支持时并行；写入、进程、网络或有顺序依赖的调用按
顺序执行。相同 Provider call ID 和相同参数不会重复执行副作用；相同 ID 但参数不同会作为冲突
失败。连续工具失败会打开熔断并推动回答降级。

工具事件一方面写入独立的 execution/evidence repository，另一方面转换为脱敏的
`MessageToolCall` 与 `MessageCommandExecution` 供时间线显示。会话历史查询参数、Shell 命令、
MCP 凭据等敏感信息只保留哈希、计数或脱敏摘要。成功的本地文件工具还会把产物路径挂到回复。

#### 证据覆盖与回答合成

每轮工具结束后协调器先检查声明验证需求是否已被本轮持久化证据覆盖：

- 仍缺证据且预算足够时，应用生成缺口反馈，要求下一模型轮只补需要的观测；
- 用户拒绝验证工具、工具熔断或预算耗尽时，记录降级原因；
- 写操作会按策略追加 action receipt 和必要的写后读要求；
- 已覆盖或无法继续验证时，进入结构化回答合成。

合成只接受一个 `GroundedAnswerProduced`，随后由 `GroundedAnswerValidator` 检查 claim kind、
subject/scope、evidence ID、时效和完整性。协议或绑定可在不重复执行副作用工具的前提下修复
一次。最终只有应用渲染的结构化 claim/non-factual 内容进入回复正文，可信等级由应用计算。

Agent Loop 的模型轮数、工具数、重复调用、总时长、单工具、审批与合成都有硬上限；具体默认
值以 `AgentRunLimits` 及对应测试为事实来源。

### 5.2 普通 Provider 流

普通路径给 Provider 注册文本、reasoning、工具投影、命令投影、Token 用量和终态回调，然后
调用 `provider.generateText(messages)`。回调按 `runId` 归并到当前 snapshot：

- `onResponse` 追加正文；
- `onReasoningResponse` 追加 reasoning；
- `onToolCall`/`onCommandExecution` 只更新该 Provider 路径给出的过程投影；
- `onTokenUsage` 合并 Skill 预检和正式生成用量；
- `onTerminal` 或 generation Future 的结束状态触发统一 finalization。

这条路径没有应用侧的多轮工具执行和结构化证据门禁。即使生成成功，`AnswerTrustPolicy` 也只会
将无合格证据的内容保存为 `unverified`；Provider 或关键持久化失败则为 `failed`。

## 6. UI 流式投影与 partial 保存

每次正文、reasoning、工具状态、命令状态、文件或 Token 用量变化都会生成新的不可变
`ChatGenerationSnapshot` 并通知页面。`ChatPage._handleGenerationChanged` 将它映射为 typing、
streaming、可取消状态和当前回复投影。

只要快照已有生成内容，generation ViewModel 会按节流间隔构造同一
`"$runId:assistant"` 的 partial 消息并排队写入。partial 消息包含当时的正文、reasoning、工具、
命令、Skill、文件和 usage，并设置 `hasPartialContent = true`。保存失败不会打断网络生成，但会
记录诊断；终态提交前必须先等待已排队的 partial 写入结束。

## 7. 终态提交与页面收尾

Provider 或 Agent Loop 结束后，所有路径都进入 `_finalizeRun`：

1. 停止 partial 定时器并排空持久化队列；
2. 将结果映射为 `completed`、`cancelled` 或 `failed`；成功但完全无内容时改为
   `emptyResponse`；
3. 汇总正文、reasoning、工具/命令/Skill 投影、文件、Token、耗时和 partial 标记；
4. 通过 `AnswerTrustPolicy` 计算 `MessageGrounding`；
5. 提交终态助手消息；证据型消息同时提交 claim-evidence 关系，并使用 recovery checkpoint
   防止“证据已落库但最终回答未提交”的崩溃窗口；
6. 终态消息成功后，尽力更新会话预览和 grounding 指标；
7. 根据上下文装配报告异步触发必要的会话压缩；
8. 发布终态 snapshot，释放 Provider、取消令牌和待审批请求。

终态消息持久化失败会把本轮改为 `failed`，并把可信性标记为关键持久化失败；不会把仅存在于
内存的内容当作可靠的历史记录。

页面收到新的终态 snapshot 后会：

- 确认用户消息是否真的落库；未落库则删除乐观消息并恢复草稿；
- 将尚未出现的终态助手消息加入时间线；
- 清理已经成功提交的草稿；
- 刷新会话列表并滚动到最新消息；
- 下一帧调用 `acknowledgeTerminal`，把 generation snapshot 清回 `idle`。

## 8. 取消、失败与导航

- `submitting` 阶段可以取消；取消标记会阻止后续 Provider 启动。
- Agent Loop 取消会触发 cancellation token，并取消活动 Provider session 或工具等待。
- 普通路径调用 Provider 的 `cancelRequest`；Provider 不支持取消时保持活动状态并阻止离开或
  清空会话。
- 等待工具审批时取消会按 deny 结束等待，工具不会继续执行。
- 已产生的内容在取消或失败时作为带 `hasPartialContent` 的终态消息保存，且明确标记
  `cancelled`/`failed`，默认不会作为可信历史重新注入。
- 没有任何生成内容的 Provider 失败只发布错误状态；已经落库的用户消息仍保留，页面展示可重试
  的错误提示。

## 9. 媒体生成旁路

当 Bot 的输出模态是图片、语音、音乐或视频时，发送入口改走 `GenerateMediaTurn`：

```text
校验 prompt
  -> 复制适用的参考附件
  -> 创建并持久化 user Message（随后才清空 UI 草稿）
  -> 调用 AiProviderRepository 的对应媒体生成方法
  -> 把输出文件写为 assistant Message
  -> 更新会话预览并刷新时间线
```

媒体路径由 `ChatInteractionFacade` 在 registry 中登记外部 canceller，支持导航前停止；它不组装
文本 Memory/Skill 上下文，不运行 `AgentRunCoordinator`，也不执行文本回答的 claim-evidence
门禁。Provider 或保存失败时，只要用户消息已经落库，就会尽力保存一个 `failed` 助手终态；
如果失败发生在用户消息落库前，页面恢复原 prompt 和附件。

## 关键不变量

- 同一会话一次只允许一个阻塞运行；run/turn/message 身份贯穿 UI、Provider、工具与数据库。
- 用户消息必须先成功持久化，Provider 才能开始正式生成。
- 工具采用显式白名单；Schema、策略和审批都在执行之前完成。
- 工具终态与证据先于依赖它们的回答提交。
- Agent 规划 draft 不直接成为最终正文；结构化合成和应用校验决定可发布内容。
- partial、终态和 recovery 使用同一助手消息身份，迟到事件不能重开已结束的 run。
- `completed` 只表示流程结束，不等于内容已验证；可信等级只由应用策略计算。
- 预览、指标和后台压缩失败不能回滚已提交消息；用户消息、工具证据和终态回答是硬边界。

## 代码索引

| 环节 | 事实来源 |
| --- | --- |
| 发送、乐观 UI、草稿恢复 | [`chat_send_commands.dart`](../../lib/ui/features/chat/views/chat_send_commands.dart)、[`chat.dart`](../../lib/ui/features/chat/views/chat.dart) |
| 媒体分流 | [`chat_draft_and_media.dart`](../../lib/ui/features/chat/views/chat_draft_and_media.dart)、[`generate_media_turn.dart`](../../lib/domain/use_cases/generate_media_turn.dart) |
| run 生命周期与终态 | [`chat_generation_view_model.dart`](../../lib/ui/features/chat/view_models/chat_generation_view_model.dart)、[`chat_generation_state.dart`](../../lib/ui/features/chat/view_models/chat_generation_state.dart) |
| 事件归并与 partial 保存 | [`chat_generation_events.dart`](../../lib/ui/features/chat/view_models/chat_generation_events.dart)、[`chat_generation_persistence.dart`](../../lib/ui/features/chat/view_models/chat_generation_persistence.dart) |
| 系统提示、Skill、MCP | [`compose_chat_turn.dart`](../../lib/domain/use_cases/compose_chat_turn.dart) 及其同名 part 文件 |
| Memory、摘要与 Token 预算 | [`prepare_conversation_context.dart`](../../lib/domain/use_cases/prepare_conversation_context.dart) |
| 本轮工具准备 | [`prepare_text_generation.dart`](../../lib/domain/use_cases/prepare_text_generation.dart) |
| Agent Loop 与工具执行 | [`agent_run_coordinator.dart`](../../lib/domain/use_cases/agent_run_coordinator.dart) 及其同名 part 文件 |
| 依赖装配与终态观察器 | [`app_dependencies.dart`](../../lib/ui/core/dependency_injection/app_dependencies.dart) |
| 消息与 grounded 原子提交 | [`sqlite_message_repository.dart`](../../lib/data/repositories/sqlite_message_repository.dart)、[`local_database_tool_evidence.dart`](../../lib/data/services/local_database_tool_evidence.dart) |
