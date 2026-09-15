# 用户消息到智能体回复的现有流转

[文档导航](../README.md) | [目标规格](../specs/conversation-foreground-background-model.md) |
[会话交互](conversation-task-chat-ui.md) | [事实依据与防幻觉协议](conversation-loop-grounding.md)

本文描述生产文本发送的前台与后台路径。旧 Agent Run 恢复及未注入 dispatcher 的旧测试路径
仍待阶段 08 清理；生产 `AppDependencies` 已组装完整前后台链。

## 总览

```text
ChatPage._sendMessage
  -> 按输出模态分流；保存草稿与附件；防止前台重复发送
  -> CreateUserMessage / ChatGenerationViewModel.dispatchText
  -> ConversationTurnDispatcher：保存用户消息、准备上下文、单次无工具分流
       |-- DirectReply：流式展示 -> 完整 turnId:assistant 提交 -> 释放输入
       |-- BackgroundTaskPlan：任务/计划/事件/taskId:ack 原子提交 -> 释放输入
       |     -> 应用级 scheduler / runner：检查点、工具、审批、证据
       |     -> FinalizeConversationTask：冻结策略验证 -> 唯一 taskId:result
       `-- TaskStatusRequest：持久摘要 -> 确定性卡片提交 -> 同版本有界润色
```

回执提交后，用户可以继续聊天或查询状态。后台更新和终态通过提交后通知更新时间线，
不改变前台 typing。离开页面、重建布局或释放 ViewModel 不取消后台任务。

## 身份、保存和失败边界

[前台 dispatcher](conversation-turn-dispatch.md)保存用户消息后才执行主回复分流；首个模型回合
同时决定直接回复、后台任务计划或状态查询。工具存在不意味着执行工具，前台禁止工具调用。
直接回复仅完整正文落库，未完成流不会保存为 partial 助手消息。

后台接受将原始 turn、上下文、允许工具和验证策略冻结，任务与回执同事务保存；提交成功后
`enqueue` 唤醒扫描。重试按原始 turn 对账，不新增重复任务。已接受任务由持久队列恢复，
不依赖内存通知或页面存活。详情见[任务持久化](conversation-task-persistence.md)。

状态查询依据净化快照，显式引用验证会话归属。卡片与文本固定为同一 revision，润色只更新
同一条状态消息；过期润色不能覆盖更新后的任务事实。详情见[会话交互](conversation-task-chat-ui.md)。

## 上下文与工具准备

### 组合本轮会话

`ComposeChatTurn` 依次完成：

- 取得会话产物目录并构造 Stars 会话上下文；
- 读取 Bot 绑定且可用的 Skill，加载内置 Skill，并在 Provider 支持时执行自动 Skill 激活；
- 合并 Stars 系统提示、Bot 系统提示、已激活 Skill 说明和受限 Skill 参考资料；
- 解析当前 Bot 已启用的 MCP 工具；
- 调用 `PrepareConversationContext` 生成 Provider 无关的消息列表。

Skill 激活失败会形成 `MessageToolCall`/activation attempt 投影，通常不会单独终止整轮准备。
激活成功的 Skill 只把其显式请求的工具加入本轮候选集；MCP、历史查询工具和免审批设置也在
这里形成明确集合。

### 组装受 Token 约束的上下文

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

### 构造本轮工具集合

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

## 后台执行、验证和终态

[runner](conversation-task-runner.md)使用冻结上下文和检查点推进有界分段；模型、工具、审批与
验证事实先保存再继续。单次请求和分段有预算，整个任务没有总墙钟超时。步骤草稿、完整 reasoning
和原始工具输出不会进入聊天时间线。

[scheduler](conversation-task-scheduling.md)拥有 lease、并发和恢复；审批、退避与外部 job
等待释放执行槽。取消先保存意图，有副作用时对账后才终结；普通新消息不修改已有任务。

[finalizer](conversation-task-terminal-results.md)按接受时冻结的策略统一验证跨分段证据，
原子保存成功、失败或取消状态与唯一 `taskId:result`。终态消息使用实际提交时间，不插入旧 turn
的位置；`completed` 不等于已验证，可信等级由应用策略计算。回执和状态消息不显示事实验证徽标。

## 媒体生成旁路

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

## 代码入口

- [发送命令](../../lib/ui/features/chat/views/chat_send_commands.dart)与
  [前台协调](../../lib/ui/features/chat/view_models/chat_foreground_dispatch.dart)
- [任务状态 ViewModel](../../lib/ui/features/chat/view_models/conversation_tasks_view_model.dart)
- [应用依赖组合](../../lib/ui/core/dependency_injection/app_dependencies_tasks.dart)
- [真实组合根页面测试](../../test/ui/features/chat/views/chat_task_flow_test.dart)
