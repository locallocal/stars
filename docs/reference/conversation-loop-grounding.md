# 会话 Loop 的事实依据与防幻觉协议

[返回文档导航](../README.md) | [后续工作](../specs/conversation-grounding-future-work.md)

本文定义 Stars 文本会话当前实现的长期可信性边界。目标不是依靠更强的提示词让模型“少
犯错”，而是让应用能够机械地回答三个问题：一条陈述依据了哪次工具观测、该观测是否有效，
以及没有依据时为什么仍允许展示或为何拒绝展示。

本协议中的“可信”只表示陈述可追溯到符合策略的工具观测，不表示外部世界绝对真实。工具本身
可能返回错误、过期或不完整的数据，因此来源、时间、作用域和完整性也必须成为证据的一部分。

## 当前流程与稳定保护

当前文本发送只使用[前台分流](conversation-turn-dispatch.md)和[后台任务链](conversation-task-cutover.md)：

```text
ConversationTurnDispatcher
  -> PrepareTextGeneration / ComposeChatTurn / PrepareConversationContext
  -> DirectReply: 提交完整直接回复，可信等级为 unverified
  -> TaskStatusRequest: 查询已提交任务事实
  -> BackgroundTaskPlan: 原子提交任务和回执
       -> ConversationTaskScheduler / RecoverConversationTasks
       -> ConversationTaskRunner: 计划、持久审批、工具意图、观测与检查点
       -> 结构化 GroundedAnswerCandidate
       -> FinalizeConversationTask: 证据验证、写后验证、终态消息事务
```

稳定保护如下：

- runner 限制单个分段的模型/工具次数、重试与预算；单次 I/O 有超时。任务没有总时限，审批不自动超时。
- 工具受冻结的白名单、当前策略和持久审批约束。输入及声明了 `outputSchema` 的结果经过 Schema 校验。
- 执行前提交调用意图；终态工具结果、可用证据及任务进度使用原子事务。重启先对账，未知副作用不重放。
- 普通模型草稿与 reasoning 不写消息表。只有结构化候选经过应用门禁后才能形成最终任务结果。
- 任务与 `taskId:result`、claim-evidence 关系一次提交；页面只展示已提交事实。
- 文件/MCP 工具的证据与写后验证继续使用共享协议；Provider 原生工具 adapter 保留归一化，
  任务 runner 拒绝未取得应用调用意图和 attempt 身份的原生结果。
- 会话摘要和 Memory 只把 verified assistant claim 当作事实，用户来源保持 `userAssertion` 边界。

## 关键可信性不变量

### 无证据不能升级为已验证

直接回复没有工具循环，只能保存为 `unverified`。任务终态和可信度分别计算：成功不自动代表
已验证，失败/取消可以保留已验证的部分成果。依据冻结策略，由 `AnswerTrustPolicy` 和声明门禁
计算可信等级，Provider 不能自行指定。

### 声明必须由相关证据支持

最终回答使用 `GroundedAnswerCandidate` 和声明级 evidence ID。`GroundedAnswerValidator` 按
kind、能力、subject、scope、有效期、Schema、完整性和持久化状态逐项复核；未被声明使用的
成功调用不影响可信等级。写动作回执只能支持动作声明，最终状态还需配对只读观测。

### 证据和回答采用可恢复提交协议

任务检查点、调用事件和不可变证据遵守“证据先于回答”的顺序。统一 finalizer 从持久化的
`committing` 检查点复验候选，原子提交终态、结果消息和声明关系。提交失败可用同一身份重试，
不重新执行已成功的工具。旧独立 final answer 表和旧运行恢复器均已删除。

### 调用、尝试和证据身份独立

应用生成 `invocationId`、`attemptId` 和 evidence ID，Provider `callId` 只用于关联。任务工具
执行意图、幂等键和证据属于同一 task；跨分段可以复用已提交成功事实，不能覆盖首次成功。
写操作中断时必须查询外部 job 或 reconcile；无法证明结果时进入持久等待。

### 跨轮上下文保留声明边界

历史回放注入应用生成的 trust envelope，携带终态、逐声明可信等级、证据摘要和观测时间。
失败、取消和 partial 正文默认隔离；Memory 只把 verified assistant claim 作为事实来源，用户
来源的 assertion、偏好、决策与任务则保留其来源类型。过期的 current fact 必须重新观测，不能
因摘要压缩丢失来源边界。

### Provider 原生工具按 adapter 明确授予证据资格

OpenAI Responses adapter 保留 `web_search_call`、`url_citation` 到 `ProviderNativeToolResult`
的确定性归一化和净化测试，包括来源绑定、URL 凭据/query/fragment 清理、内容上限与摘要。
该共享能力不等于任务链已经授予原生执行权限。当前任务 runner 拒绝未经应用记录调用意图的
原生结果；未来接入必须补齐任务 attempt、权限和恢复语义，不能事后伪造审批。

Anthropic、Moonshot 等未完成归一化的 Provider 不会从引用正文获得证据资格。扩展计划见
[原生工具设计](../specs/provider-native-tool-evidence-normalization.md)。传输失败使用
`ProviderFailure` 的安全诊断字段，原始响应不进入回答或普通日志。

### 错误证据与业务事实分离

失败、拒绝、超时和取消可以生成 `executionFailure` 证据，只支持描述该次尝试的终态。它们不
能证明查询对象不存在、目标状态未改变或动作成功。

## 可信模型

### 回答可信等级

每条助手消息必须保存并展示一个由应用计算的等级，模型不能自行指定：

| 等级 | 含义 | 后续上下文用途 |
| --- | --- | --- |
| `verified` | 所有可核验事实和动作声明均有合格证据 | 可作为带来源的历史线索 |
| `partiallyVerified` | 只有部分声明有合格证据 | 必须按声明保留边界，不得整体当作事实 |
| `unverified` | 没有工具证据，或证据覆盖不足 | 可展示，但必须显式标记；不得沉淀为事实 |
| `failed` | Provider、工具、门禁或持久化失败 | 只保留诊断和部分输出，不作为事实 |

问候、创作、改写、基于当前用户文本的摘要等内容未必需要查询外部世界，但仍只能是
`unverified`；结构化候选中的非事实段使用 `ClaimKind.nonFactual`，并落为
`ClaimTrustLevel.notVerifiable`，不能因为“不需要工具”而获得 `verified`。用户偏好和用户决策
应标记为 `userAssertion`，表示“用户确实这样说过”，不等价于外部事实。

产品提供严格模式：只展示已验证事实以及 `userAssertion`/`nonFactual` 等无需外部验证的段落，
抑制未验证的事实段并追加应用生成的“无法验证”状态和原因；没有结构化声明边界的内容按事实
内容失败关闭。默认模式可以展示未验证内容，但视觉、持久化和后续召回都必须保留该标签。

### 工具证据记录

保留现有 `ToolExecutionRecord` 作为生命周期审计，另增不可变的终态证据记录，至少包含：

```text
ToolEvidenceRecord
  evidenceId             全局稳定 ID，不直接复用可冲突的 Provider call_id
  taskId / segmentId / runId / turnId
  invocationId / attemptId / providerCallId
  toolName / toolVersion / source / capabilities
  terminalStatus         succeeded、failed、denied、timedOut、cancelled
  evidenceKind           observation、calculation、actionReceipt、executionFailure
  subject / scope        查询对象、资源或动作目标的规范化标识
  argumentsDigest
  resultDigest
  structuredFacts[]      经过输出 Schema 验证的最小事实集合
  observedAt / validUntil
  payloadRef             可选的加密结果快照引用
  truncated / schemaValid / persisted
```

约束如下：

- 只有终态记录能够成为证据；`requested`、`running` 和 `awaitingApproval` 只是审计事件。
- 成功但为空、被截断、输出 Schema 无效或尚未持久化的结果不能支持业务事实。
- 失败记录只支持“本次尝试失败/被拒绝/超时”，不能支持“目标不存在”“没有发生副作用”。
- `actionReceipt` 只能证明工具接受或完成了动作。`requiresReadAfterWrite` 写工具成功后，应用从
  回执的资源版本、内容摘要等事实生成独立的 `completedAction` 与 `currentFact` 需求；后者必须
  由同 subject、同 scope 且事实值完全一致的只读 `observation` 支持。无配对读取时只能发布动作
  回执，不能把它提升为最终状态。
- 外部可变状态必须带 `observedAt` 和领域相关的有效期；过期证据不能为“当前”陈述背书。
- 自由文本结果默认只能作为未验证材料。只有显式声明证据能力、版本、作用域规则和
  `outputSchema` 的工具，才能在运行时 Schema 与输入作用域复核通过后产生业务证据候选；候选
  仍须经过后续声明级门禁才能支持 `verified`。结果必须输出规范化 subject、structured facts、
  观测时间、有效期策略和摘要哈希。
- 工具输出始终是“不可信数据而非指令”。JSON 包装解决了来源标识，但系统提示还必须明确
  禁止执行结果文本中的指令。

完整结果可能包含隐私或凭据，不能为了可追溯性无条件明文落库。默认保存规范化事实、摘要和
摘要哈希；领域与数据库契约只接受带保留期限的加密 payload 引用，生产快照后端属于
[可选后续工作](../specs/conversation-grounding-future-work.md)。日志与 UI 不显示密钥、Cookie、
Authorization 或原始私有命令。

### 声明与证据绑定

最终输出不再使用一个消息级页脚，而使用 Provider 无关的结构化候选：

```json
{
  "schema_version": 1,
  "claims": [
    {
      "claim_id": "c1",
      "text": "目标文件存在。",
      "kind": "external_fact",
      "evidence_ids": ["ev_01"]
    }
  ],
  "non_factual_text": ""
}
```

模型可以提出绑定关系，但可信等级只能由应用计算。确定性门禁逐条检查：

1. 证据存在于当前任务的持久化事实账本；跨分段可以复用，同任务之外的历史事实必须重新读取。
2. 终态、完整性、Schema、来源、作用域和有效期符合该声明类型的策略。
3. 每个 `external_fact`、`current_fact` 和 `completed_action` 都至少绑定一个合格证据。
4. 错误证据只绑定 `execution_failure`；动作回执不能越权绑定读取后的状态。
5. 所有被引用证据都实际被某条声明使用，不允许用无关成功调用装饰回答。
6. 声明列表校验成功后，由应用从已校验字段渲染正文和来源标记；不再从自由文本中猜测句子
   边界。

仅靠字符串页脚无法确定语义蕴含关系。`ClaimEvidenceReviewer` 契约允许在确定性检查之后增加
保守复核，但它只能拒绝或降级，不能把回答升级为 `verified`；生产复核器属于
[可选后续工作](../specs/conversation-grounding-future-work.md)。严格场景优先使用领域工具返回的
类型化事实，并由确定性模板生成关键结论。

## 会话 Loop

```text
接收用户消息
  -> 建立 run/turn，并持久化用户消息
  -> 生成验证需求（事实类型、对象、时间、期望工具能力）
  -> 规划并调用最小权限工具
  -> 参数 / 策略 / 审批
  -> 执行与输出 Schema 校验
  -> 先持久化审计终态与不可变证据
  -> 检查验证需求覆盖率
       |-- 缺证据且预算充足 -> 带“缺什么证据”的应用反馈继续工具轮
       |-- 缺证据且预算耗尽 -> 进入 unverified/failed，不伪造答案
       `-- 已覆盖 -> 结构化合成 claims
  -> 声明级确定性门禁
       |-- 可修复 -> 最多一次合成修复，不重新执行副作用工具
       |-- 不可修复 -> 降级或失败
       `-- 通过 -> 应用渲染
  -> 在同一提交边界保存回答、claim-evidence 关系和可信等级
  -> 发布终态
```

Loop 状态显式建模为 `planning -> awaitingApproval -> executing -> observing ->
verifying -> synthesizing -> committing -> completed`。Provider 文本、工具结果和持久化事件都
必须携带 `runId`；迟到事件只能归档，不能改变已结束或更新一轮的状态。

当前协调器按上述状态发布应用事件。终态工具证据提交完成后才计算验证需求覆盖率；缺失证据只
能在模型轮数、工具调用数和总时限内触发应用生成的只读观测反馈。预算耗尽时回答降级。结构化
合成最多修复一次，修复只重做声明绑定，不重新执行已成功或产生副作用的工具。

所有文本会话都应经过同一个终态门禁。Provider 不支持结构化工具、没有合适工具、用户拒绝
授权或网络不可用时，结果应是 `unverified`/`failed`，不能回落到“看起来正常”的可信回答。
基础只读事实工具的发现不依赖 Skill 是否恰好激活：应用从受信的内建工具中生成显式候选
白名单，按 evidence contract 去重得到最小 `verificationToolNames`，不枚举整个 MCP
inventory。该通道与 Skill 请求工具分离，但同样经过 `ToolPolicy`；本地、外部和网络读取仍需
用户审批。无合适工具或用户拒绝后，Loop 保存明确原因并降级，不再尝试更高权限的替代工具。

## 与现有代码的落地映射

### Domain

- `lib/domain/models/tool.dart` 定义 Tool、调用结果、策略和当前执行投影；
  `lib/domain/models/tool_evidence.dart` 定义 append-only 调用事件与 `ToolEvidenceRecord`。调用
  尝试使用独立 ID，避免 `duplicate` 覆盖第一次成功事实。
- 为 `ToolDefinition` 增加证据能力声明，例如可支持的 claim kind、作用域提取器、时效策略和
  是否需要写后读。
- `lib/domain/models/grounded_answer.dart` 定义结构化 claim 和候选，
  `lib/domain/models/message.dart` 保存消息可信等级、声明级证据引用和门禁失败原因。
  `MessageToolCall` 只保存调用身份、来源/风险、参数与结果摘要、审批、错误和耗时等 UI 投影；
  `truncated`、`schemaValid`、`observedAt` 等证据完整性字段由 `ToolResult` 和
  `ToolEvidenceRecord` 保存。
- `ConversationTaskRunner` 推进可恢复分段并生成候选，`FinalizeConversationTask` 负责最终声明
  门禁和结果提交；scheduler 拥有运行生命周期。
- `VerificationToolDiscovery` 只检查应用显式允许的候选名称，根据读风险、证据能力和
  contract 去重生成独立的 `verificationToolNames`；`ToolPolicyContext` 保留 Skill 与验证两条
  授权来源，发现本身不授予执行权。
- `PostWriteVerificationPolicy` 只从本轮已暴露的只读工具中配对写后验证，MCP 配对还要求同一
  server；它不发现新工具或扩大权限。验证反馈轮拒绝所有写入和进程工具，幂等提示也不会放宽
  该限制。
- `AnswerClaim`、`ClaimKind` 和 `GroundedAnswerCandidate` 已替代消息级
  字符串页脚；`GroundedAnswerValidator` 使用应用侧语义约束校验每条声明。
  `<stars_evidence ... />` 不再作为兼容输入解析。

### Data

- `tool_execution_records` 保留为当前状态投影；append-only 调用事件表、终态证据表和
  claim-evidence 关联表使用幂等键和摘要校验。
- “工具终态 + 证据 + 最终消息 + 声明关系”使用可恢复提交协议。外部调用结束后先提交证据，再
  提交回答；回答提交失败可重试，证据提交失败则不得发布 `verified`。
- runner 在 lease 与 revision 检查后提交任务检查点、工具事件和证据；finalizer 从持久候选复验，
  不信任回调携带的草稿。结果事务失败保留候选供恢复器再次交给 finalizer，不重做副作用。
- 前台只提交完整直接回复。UI 不定时保存 partial，后台草稿不会形成最终消息。
- Provider HTTP 失败转换为结构化 `ProviderFailure`，保留状态码、端点类别、请求追踪 ID、是否
  可重试等安全字段；原始响应不作为业务事实。
- 内置目录列表、文件查询和完整文件读取输出 `observation`；目录创建/删除与文件写入、复制、
  移动、删除输出 `actionReceipt`，并携带精确参数 scope 和结构化完成事实。目录列表与文件查询
  的截断状态同时写入结构化结果和顶层工具信封；任何分段或截断结果仍可作为不可信工具数据
  返回，但不能进入事实证据账本。文件写入继续要求同路径读取来验证最终内容状态。

### Context 与 Memory

- `PrepareConversationContext` 回放历史时注入应用生成的 trust envelope，包含消息终态、声明级
  可信等级和允许引用的证据摘要，不能只回放 assistant 正文。
- 默认排除 `failed`、`cancelled` 和 partial assistant 正文；如为继续任务必须保留，则放入
  明确的 `untrusted_partial_output` 数据段。
- 摘要与 Memory 从消息级 `tool_grounded` 升级到 claim-evidence 关系。外部事实只能由已验证
  claim 生成；用户输入只生成 `userAssertion`、偏好或决策，不能自动升级为客观事实。
- 历史信息即使曾经验证过，也先作为带时间的历史证据；用户询问“现在”时必须重新观测。

### UI

- 在消息气泡显示 `已验证`、`部分验证`、`未验证` 或 `失败`，并允许展开查看工具、观测时间和
  声明到证据的映射。
- 工具卡区分“动作已接受”“动作已完成”“状态已回读验证”，避免统一显示为成功。
- 错误界面显示安全、可操作的分类，不把 Provider 错误正文当作模型回答。
- 严格模式用应用生成的拒绝提示替代未验证事实正文；复制仅使用当前可见正文，不输出被隐藏的
  未验证事实，分享、导出和聊天预览继续保留可信边界，设置及逐消息状态可在重启后恢复。

## 404 与 Provider 错误的处理边界

仓库中的 OpenAI 默认 Responses 地址是 `https://api.openai.com/v1/responses`；当 Bot 配置了
合法的自定义 `baseURL` 时，`OpenAI._endpoint` 会在规范化后的末尾追加 `responses`。配置必须
使用 HTTP(S)、包含有效 host，且不能带 user info、query 或 fragment；`chatgpt.com` host 和
`/backend-api/codex` 内部路径会以 `openai_invalid_base_url` 在发出请求前拒绝。仓库中没有
`https://chatgpt.com/backend-api/codex/responses` 这个常量。

因此日志中出现该 URL 时应先区分来源：

- 如果请求由 Stars 发出，检查 Bot 的自定义 Base URL。使用 OpenAI 公共 API 时应留空以采用
  默认值，或配置为兼容服务明确提供的 API 根地址，并使用相应 API 凭据；不要把 ChatGPT
  网页后端地址当作 OpenAI 公共 API 根地址。
- 如果错误来自独立的 Codex/ChatGPT 客户端，它不属于本仓库这条 Provider 链路，应在该客户
  端检查版本、登录会话、代理和服务状态，不能通过修改 Stars 的 Agent Loop 修复。

无论来源如何，HTTP 404 都表示本次请求没有取得模型或工具结果。Loop 必须记录结构化传输失
败、停止事实合成并给出配置诊断；不得重用缓存文本或生成“操作已完成”。404 通常不应进行同
一端点的盲目重试，只有端点发现或配置被纠正后才发起新运行。

## 恢复与观测边界

启动必须先验证当前数据库，再恢复任务队列。过期 lease、平台挂起和分段切换不直接构成失败；
恢复在同一 task 身份下复用检查点，已提交终态不重复生成消息。细节见
[调度恢复](conversation-task-scheduling.md)和[终态验证](conversation-task-terminal-results.md)。

前台分流、scheduler、runner 和 finalizer 的指标只保存安全枚举、类别、计数和耗时，不包含
消息、工具原文、URL、请求参数、凭据或异常正文。共享 grounding 指标模型和存储继续保留，
旧 ViewModel/coordinator 的回调已删除，不能把旧回调视为当前生产观测入口。

验证门禁必须保持：无依据声明不能被授予 verified、verified 证据已持久化、重启不重复执行
已成功的副作用。可选扩展记录在[后续工作](../specs/conversation-grounding-future-work.md)。

## 验收标准

以下场景必须由自动化测试锁定：

- 本轮没有工具调用时，回答绝不能被标记为 `verified`。
- 用一个成功计算调用引用无关的文件、网络或时间事实时，门禁拒绝或降级。
- 伪造、跨运行、过期、空、截断、Schema 无效或未持久化的证据 ID 均不能通过。
- 工具失败只能支持“本次尝试失败”，不能支持目标状态；拒绝授权不能被表述为动作成功。
- 写工具返回成功但没有满足回读策略时，最终状态声明不能通过。
- 重复 `call_id` 不重复副作用，也不覆盖第一次成功证据；冲突参数产生独立失败尝试。
- 证据持久化失败时不发布可信回答；进程重启后可依据账本复验已完成消息。
- Provider 原生结果 adapter 的归一化继续通过共享契约测试；未提交调用意图的任务原生结果被拒绝。
- 404、超时、401/403、429 和 5xx 得到正确的安全分类与重试策略，且不会生成事实答案。
- 失败、取消和 partial assistant 消息不会在下一轮或摘要中被当作事实。
- 同一助手消息中，一条有证据、一条无证据时只能是 `partiallyVerified`，不能整条升级。

测试以领域门禁和持久化不变量为主，模型评分只作为补充。指标持续观测证据引用解析率、门禁
拒绝分类和 Provider 失败分类；硬发布门禁只采用上节三个不变量，避免把诊断指标误当作授权
信号。

## 不采用的捷径

- 只增强 system prompt：模型仍可忽略规则，也无法让应用判断引用是否相关。
- 只要求一个证据页脚：只能证明调用 ID 存在，不能证明声明与结果之间的关系。
- 用第二个模型给第一个模型盖章：两个模型都可能在同一份错误材料上达成一致。
- 把所有成功工具结果永久明文保存：会扩大凭据、隐私和受管数据的泄露面。
- 把用户陈述直接当作外部事实：应保留“用户说过”与“世界状态已验证”的区别。

当前实现已将工具调用记录从“供 UI 展示的过程日志”提升为“回答可信等级的唯一应用侧事实
依据”；任何没有合格工具证据的内容仍可按产品策略展示，但系统不会把它包装成已验证事实，
也不会让它在后续会话中无声升级为事实。
