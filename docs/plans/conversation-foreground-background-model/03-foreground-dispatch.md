# 03：前台三路分流与回执

[总计划](README.md) | [事务持久化（已实现）](../../reference/conversation-task-persistence.md) | [下一阶段：有界执行分段](04-segment-runner.md)

前置依赖：阶段 01、02。对应目标规格第 3、4、7.1、11、12 节。

目标：主回复的首个模型回合同时完成分流与回答/计划生成，让直接回答和任务接受拥有清晰终点。

## 实现步骤

1. 定义 `TurnDisposition` 的三个互斥结果：`DirectReply`、`BackgroundTaskPlan`、
   `TaskStatusRequest`。为 dispatcher 定义输入、结构化流事件和结果契约，显式携带原始
   turn/消息身份、准备结果与接受时策略，避免 UI 补拼业务字段。
2. 复用 `PrepareTextGeneration`、`ComposeChatTurn` 的上下文、Token、Skill、MCP 和白名单准备。
   去掉“工具非空就进入 Agent Loop”的判定；不新增分类专用模型请求。
   调用次数统计明确区分主回复分流与现有准备流程，状态润色属于后续独立表达步骤。
3. 在 Data 层 Provider 适配器实现统一路由协议：校验 schema、长度、枚举、计划字段和
   工具白名单子集。前台路由回合不执行应用工具或 Provider 原生副作用操作。
4. 支持结构化流时先发 `TurnDispositionStarted(kind)`；明确 `directReply` 后才展示文本 delta，
   任务分支必须缓冲到完整计划校验成功。不支持结构化流时缓冲整次响应后解析为相同领域类型。
   无效 JSON、未知类型或越权工具计划回退为安全直接回复或可恢复错误，禁止启动不完整任务。
5. 直接回复路径应用已有回答终态和可信状态规则，仅保存一个 `turnId:assistant`。
   流式内容只供前台展示，不沿用旧的 partial 消息落库机制，不创建任务或回执。
6. 实现 `TaskAcknowledgementPolicy`：校验与当前任务相关、语言一致、简洁且无虚假执行声明。
   空草稿、无关内容、虚构完成或不可靠时间承诺使用本地化兜底；无需第二次模型调用。
7. 任务路径冻结上下文和策略，调用阶段 02 的原子接受方法。提交成功后才能 `enqueue` 和
   释放前台接受状态；即使入队通知丢失，任务也已在数据库中等待后续调度扫描。
   调度实现尚未完成时用 fake 验证调用顺序，不接通用户可用的后台入口。
8. 状态分支交给阶段 02 的查询用例；显式任务引用可直接查询、跳过意图识别。
   本阶段验证它不启动 Agent Loop，卡片和状态模型润色由阶段 07 完成。
9. 明确错误恢复：用户消息未保存时恢复草稿；已保存而任务创建失败时提供基于原消息的重试，
   复用 `originTurnId`。保留每会话一个前台请求的重复提交保护，不把后台任务数量纳入该锁。

## 代码落点

| 类型 | 入口 |
| --- | --- |
| 新用例与策略 | `lib/domain/use_cases/conversation_turn_dispatcher.dart`、`lib/domain/services/task_acknowledgement_policy.dart` |
| 准备流程 | [prepare_text_generation.dart](../../../lib/domain/use_cases/prepare_text_generation.dart)、[compose_chat_turn.dart](../../../lib/domain/use_cases/compose_chat_turn.dart) |
| Provider 协议 | [AI 适配器目录](../../../lib/data/services/ai/)，解析留在 Data 层，Domain 只接收类型化结果 |
| 后续前台接入点 | [chat_generation_view_model.dart](../../../lib/ui/features/chat/view_models/chat_generation_view_model.dart)、[chat_send_commands.dart](../../../lib/ui/features/chat/views/chat_send_commands.dart) |

## 验证与退出条件

- [ ] 问候、无需外部事实的解释和上下文改写在工具可用时仍走直接回复；只有一个主回复模型回合。
- [ ] 直接回复只保存一个助手消息，没有任务、回执、工具调用或 partial 落库。
- [ ] 任务回执在同一分流调用中生成；接受事务失败时不显示“已经记录”，不调用 enqueue。
- [ ] 路由格式错误、非法工具和不合格回执覆盖到安全回退；未知 kind 前不显示草稿。
- [ ] 重复提交、创建失败后重试和通知丢失均保持消息/任务身份稳定。
- [ ] `TaskStatusRequest` 只读取持久化事实，不进入工具循环。

记录直接回复首字符/完成延迟、任务回执提交延迟和路由/回执回退次数，供阶段 09 验收。
