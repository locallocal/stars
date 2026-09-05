# 会话 Loop 的事实依据与防幻觉协议

[返回文档导航](../README.md) | [后续工作](../specs/conversation-grounding-future-work.md)

本文定义 Stars 文本会话当前实现的长期可信性边界。目标不是依靠更强的提示词让模型“少
犯错”，而是让应用能够机械地回答三个问题：一条陈述依据了哪次工具观测、该观测是否有效，
以及没有依据时为什么仍允许展示或为何拒绝展示。

本协议中的“可信”只表示陈述可追溯到符合策略的工具观测，不表示外部世界绝对真实。工具本身
可能返回错误、过期或不完整的数据，因此来源、时间、作用域和完整性也必须成为证据的一部分。

## 当前流程与稳定保护

当前文本生成链路如下：

```text
PrepareTextGeneration
  -> ComposeChatTurn / PrepareConversationContext
  -> ChatGenerationViewModel
       |-- Provider 不支持 Agent Loop，或本轮没有可用工具
       |     -> provider.generateText
       |     -> AnswerTrustPolicy（只能 unverified / failed）
       |
       `-- Provider 支持 Agent Loop，且本轮有应用工具或已归一化的原生工具
             -> AgentRunCoordinator
                  -> model turn
                  -> ToolCallRequested
                  -> 参数校验 / 策略 / 审批 / 执行 / 结果校验
                  -> ToolResult 回送模型
                  -> 等待调用终态事件与可构造证据提交
                  -> model draft turn
                  -> Provider adapter 结构化合成
                  -> 严格解析 GroundedAnswerCandidate
             -> 原子提交最终消息与 claim-evidence 关系
             -> 发布 UI 终态
```

以下机制构成稳定协议，后续改动必须保留：

- `AgentRunCoordinator` 对模型轮数、工具次数、同一调用重试、总超时、工具超时和审批超时设有
  上限，并支持取消。
- 工具只从 `requestedToolNames` 暴露；参数和声明了 `outputSchema` 的结果会经过 JSON Schema
  校验；写入、进程、网络等能力进入策略与审批。
- `ToolResult` 回送模型时由 `encodeToolResultForModel` 包装，包含 `evidence_id`、来源、成功或
  失败、错误码和截断状态。
- 普通模型文本只作为草稿暂存；Provider adapter 的独立合成入口必须返回统一的
  `GroundedAnswerCandidate`，协调器只把结构化 claim 与 `nonFactual` 段落发布为 `TextDelta`。
- `ToolExecutionRecord` 和消息中的 `MessageToolCall` 记录工具状态，并对敏感参数做摘要、哈希
  或脱敏。
- OpenAI Responses 的原生 web search 会归一化为应用统一的调用生命周期和 observation 证据；
  未实现该适配的 Provider 仍保持 `unverified`。
- 会话摘要和 Memory 只接收 verified claim，并保留来源与观测时间；消息中其他声明不会随之
  获得信任。

这些措施共同保证：没有合格工具证据的回复不会被授予 `verified`，空、截断、跨运行或未持久化
的证据不能为声明背书，修复轮也不会重复执行副作用。

## 关键可信性不变量

### 无工具路径统一降级

Agent Loop、legacy Provider 和无工具路径都经过 `AnswerTrustPolicy`。`completed` 只表示生成
结束；没有合格证据时最多保存为 `unverified`，Provider、门禁或关键持久化失败时保存为
`failed`。模型输出不能自行指定可信等级。

### 声明必须由相关证据支持

最终回答使用 `GroundedAnswerCandidate` 和声明级 evidence ID。`GroundedAnswerValidator` 按
kind、能力、subject、scope、有效期、Schema、完整性和持久化状态逐项复核；未被声明使用的
成功调用不影响可信等级。写动作回执只能支持动作声明，最终状态还需配对只读观测。

### 证据和回答采用可恢复提交协议

调用事件、不可变证据、claim-evidence 关系和最终消息遵守“证据先于回答”的提交顺序。最终
消息与声明关系在同一数据库事务中写入；关键证据失败会关闭运行。独立 final answer checkpoint
允许启动恢复只重试本地提交，不重新连接模型或执行工具。

### 调用、尝试和证据身份独立

应用分别生成 `invocationId`、`attemptId` 和 evidence ID，Provider `callId` 只用于关联。相同
参数的重复调用复用首次结果并追加审计事件，不覆盖首次成功；冲突参数生成独立失败尝试，也不
执行副作用。

### 跨轮上下文保留声明边界

历史回放注入应用生成的 trust envelope，携带终态、逐声明可信等级、证据摘要和观测时间。
失败、取消和 partial 正文默认隔离；Memory 只接收 verified claim，过期的 current fact 必须
重新观测，不能因摘要压缩丢失来源边界。

### Provider 原生工具按 adapter 明确授予证据资格

OpenAI Responses 的 `web_search_call` 和 `url_citation` 已归一化为
`ProviderNativeToolResult`，再由协调器生成统一的 requested、running 和终态事件，并按 GRD-011
契约复核后进入同一事实账本。请求会显式取得 action sources；只有已完成且引用能绑定到来源的
结果才能产生 observation。查询正文只保留摘要，URL 去除凭据、query 和 fragment，引用正文、
标题与数量均有上限并经过凭据脱敏。Provider 引用 ID 保存在 structured fact 属性中，应用生成
的 evidence ID 仍由 attempt ID 推导，两类身份不会混用。

Anthropic、Moonshot 等尚未实现原生搜索归一化的 Provider 不会获得此能力标志，其搜索正文只能
保持 `unverified`；扩展计划见[会话事实化后续工作](../specs/conversation-grounding-future-work.md)。
传输失败由 `ProviderFailure` 保存状态码、端点类别、请求追踪 ID 和可重试性等安全诊断字段，
响应正文不进入回答或普通日志。

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
`unverified` 或单独的 `notFactChecked`，不能因为“不需要工具”而获得 `verified`。用户偏好和
用户决策应标记为 `userAssertion`，表示“用户确实这样说过”，不等价于外部事实。

产品提供严格模式：当最终等级不是 `verified` 时，不展示模型生成的事实答案，只展示应用
生成的“无法验证”状态和原因。默认模式可以展示未验证内容，但视觉、持久化和后续召回都必须
保留该标签。

### 工具证据记录

保留现有 `ToolExecutionRecord` 作为生命周期审计，另增不可变的终态证据记录，至少包含：

```text
ToolEvidenceRecord
  evidenceId             全局稳定 ID，不直接复用可冲突的 Provider call_id
  runId / turnId
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

1. 证据存在于本轮的持久化事实账本；历史事实必须先通过本轮历史读取工具重新取得。
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

- 在 `lib/domain/models/tool.dart` 拆分调用生命周期和 `ToolEvidenceRecord`；为调用尝试生成独立
  ID，避免 `duplicate` 覆盖第一次成功事实。
- 为 `ToolDefinition` 增加证据能力声明，例如可支持的 claim kind、作用域提取器、时效策略和
  是否需要写后读。
- 在 `lib/domain/models/message.dart` 增加消息可信等级、结构化 claims、证据引用和门禁失败
  原因。`MessageToolCall` 增加 `truncated`、`schemaValid`、`observedAt` 等最小投影。
- `AgentRunCoordinator` 已接入独立 Loop 状态机、覆盖率验证和最终声明门禁；工具执行、限制与
  取消继续由协调器统一拥有。
- `VerificationToolDiscovery` 只检查应用显式允许的候选名称，根据读风险、证据能力和
  contract 去重生成独立的 `verificationToolNames`；`ToolPolicyContext` 保留 Skill 与验证两条
  授权来源，发现本身不授予执行权。
- `PostWriteVerificationPolicy` 只从本轮已暴露的只读工具中配对写后验证，MCP 配对还要求同一
  server；它不发现新工具或扩大权限。验证反馈轮拒绝所有写入和进程工具，幂等提示也不会放宽
  该限制。
- `AnswerClaim`、`ClaimKind` 和 `GroundedAnswerCandidate` 已替代消息级
  `_validateFinalAnswer`；`GroundedAnswerValidator` 使用应用侧语义约束校验每条声明。旧
  `<stars_evidence ... />` 仅用于 adapter 迁移兼容，不能保存或授予 `verified`。

### Data

- `tool_execution_records` 保留为当前状态投影；append-only 调用事件表、终态证据表和
  claim-evidence 关联表使用幂等键和摘要校验。
- “工具终态 + 证据 + 最终消息 + 声明关系”使用可恢复提交协议。外部调用结束后先提交证据，再
  提交回答；回答提交失败可重试，证据提交失败则不得发布 `verified`。
- 当前提交边界由运行协调器拥有：所有调用事件按尝试内单调序号排队，终态会等待事实账本提交
  并使用同一幂等身份重试，重试不会重新执行工具。账本成功且验证需求覆盖率已计算后才允许进入
  回答合成与提交。
- 最终回答与 claim-evidence 关系在一个本地数据库事务中写入；事务前保存的 `unverified` 部分
  检查点以及独立的 final answer 恢复检查点，使“证据已提交、回答未提交”的中断状态可在重启
  后仅重试数据库提交。启动恢复先把 `requested`、`awaitingApproval` 或 `running` 的最后事件
  追加为 `interrupted`，绝不重新打开 Provider session 或调用工具；若证据摘要、身份或 final
  检查点无法复验，则保留不可变证据并写入无正文的安全失败消息。自由文本工具以及未在
  GRD-015 状态机中通过声明级门禁的回答仍只能得到 `unverified`，不能因提交成功提前升级为
  `verified`。
- 不再吞掉关键证据持久化异常。UI 增量快照写失败可以降级，但最终事实账本写失败必须让运行
  进入明确失败状态。
- Provider 适配器把原生 web search 等结果转换成统一的调用和证据事件。Provider HTTP 失败
  转换为结构化 `ProviderFailure`，保存安全字段：状态码、端点种类、请求追踪 ID、是否可重试；
  响应正文只进入脱敏诊断。
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
- 严格模式用应用生成的拒绝提示替代未验证事实正文；复制、分享、导出和聊天预览继续保留可信
  边界，设置及逐消息状态可在重启后恢复。

## 404 与 Provider 错误的处理边界

仓库中的 OpenAI 默认 Responses 地址是 `https://api.openai.com/v1/responses`；当 Bot 配置了
自定义 `baseURL` 时，`OpenAI._endpoint` 会直接在它后面追加 `responses`。仓库中没有
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

## 已交付能力矩阵

原实施清单 GRD-001 至 GRD-020 已全部完成。稳定能力按层次归纳如下；具体行为以本协议、代码和
自动化测试为准，不再维护已完成任务的排期文档。

| 层次 | 已交付编号 | 稳定能力 |
| --- | --- | --- |
| P0 | GRD-001–007 | 消息可信模型与兼容序列化、统一终态门禁、调用身份分离、Provider 失败分类、不可信历史隔离和最小可信状态 UI |
| P1 | GRD-008–012 | 不可变事实账本、可恢复提交、证据型工具契约，以及 OpenAI Responses 原生搜索与本地/MCP 工具的统一证据协议 |
| P2 | GRD-013–017 | 结构化 claims、确定性证据门禁、Observe–Verify–Synthesize 状态机、写后验证和最小权限验证工具发现 |
| P3 | GRD-018–020 | 声明级历史与 Memory、证据详情和严格模式、启动恢复、脱敏指标及发布门禁 |

运行可靠性遵守以下固定约束：

1. 启动完成前执行本地恢复。恢复只允许追加 `interrupted` 审计终态、重试 final answer 本地事务
   或生成安全失败状态，不持有工具执行器或模型会话依赖；对同一数据库状态重复执行必须幂等。
2. 指标只接受应用枚举、脱敏类别和计数，不接受消息正文、工具原文、URL、请求参数、凭据或
   异常文本。
3. 发布门禁固定检查三个不变量：unsupported claim 通过数为零、verified 证据持久化率为
   100%、重复副作用数为零；任一不变量失败必须使发布测试失败。
4. 尚未交付的可选扩展统一记录在[会话事实化后续工作](../specs/conversation-grounding-future-work.md)，
   未完成前不得改变现有降级语义。

## 验收标准

以下场景必须由自动化测试锁定：

- 本轮没有工具调用时，回答绝不能被标记为 `verified`。
- 用一个成功计算调用引用无关的文件、网络或时间事实时，门禁拒绝或降级。
- 伪造、跨运行、过期、空、截断、Schema 无效或未持久化的证据 ID 均不能通过。
- 工具失败只能支持“本次尝试失败”，不能支持目标状态；拒绝授权不能被表述为动作成功。
- 写工具返回成功但没有满足回读策略时，最终状态声明不能通过。
- 重复 `call_id` 不重复副作用，也不覆盖第一次成功证据；冲突参数产生独立失败尝试。
- 证据持久化失败时不发布可信回答；进程重启后可依据账本复验已完成消息。
- Provider 原生 web search 产生与 MCP/内置工具相同形态的证据。
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
