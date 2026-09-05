# 会话 Loop 的事实依据与防幻觉协议

[返回文档导航](../README.md) | [实施功能清单](../specs/conversation-grounding-features.md)

本文定义 Stars 文本会话的长期可信性边界和演进方案。目标不是依靠更强的提示词让模型“少
犯错”，而是让应用能够机械地回答三个问题：一条陈述依据了哪次工具观测、该观测是否有效，
以及没有依据时为什么仍允许展示或为何拒绝展示。

本协议中的“可信”只表示陈述可追溯到符合策略的工具观测，不表示外部世界绝对真实。工具本身
可能返回错误、过期或不完整的数据，因此来源、时间、作用域和完整性也必须成为证据的一部分。

## 现有流程与已有保护

当前文本生成链路如下：

```text
PrepareTextGeneration
  -> ComposeChatTurn / PrepareConversationContext
  -> ChatGenerationViewModel
       |-- Provider 不支持 Agent Loop，或本轮没有可用工具
       |     -> provider.generateText（直接接受自由文本）
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

以下机制已经存在，应在改造中保留：

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
- 会话摘要不会把完全没有成功工具记录的助手消息当作自动事实来源。

这些措施已经阻止了伪造 `call_id`、把空结果或截断结果当作成功以及重复执行部分副作用，但
还不能满足“没有工具验证的回复不可信”这一产品约束。

## 现有实现的可信性缺口

### 1. 无工具路径完全绕过可信性门禁

`ChatGenerationViewModel.startTextWithPreparation` 只有在 Provider 支持 Agent Loop 且
`agentTools.isNotEmpty` 时才进入 `AgentRunCoordinator`，否则直接调用
`provider.generateText`。这条路径可以把任何自由文本保存为 `completed`。

即使进入协调器，`_validateFinalAnswer` 在 `completedCalls.isEmpty` 时也允许没有证据页脚的
回答。因此“没有工具调用”目前等价于“无需校验”，而不是“不可信”。

### 2. 引用了成功调用，不代表陈述被结果支持

当前门禁只验证页脚中的 ID 是否属于本轮成功、非空、未截断的 `ToolResult`。它没有验证：

- 陈述是否真的能从该工具结果推出；
- 工具查询的对象、时间范围和回答中的对象、时间是否相同；
- 一个成功的计算调用是否被拿来为无关的天气、文件或执行结果背书；
- 写工具的成功回执是否足以证明写入后的最终状态。

因此任意一次成功调用仍可能被用于“证据漂白”。GRD-013 已停止从整条自由文本和页脚推测可信
关系。GRD-014 已提供确定性门禁，按应用侧声明要求复核 kind、能力、subject、scope、时效与
账本状态；GRD-015 已将该门禁接入完整 Observe–Verify–Synthesize 状态机。

### 3. 内存判定与持久化事实源曾经分离

GRD-010 已把工具审计回调提升为协调器依赖：生命周期事件排队写入，终态提交必须成功后才
继续最终回答；关键写入失败会使运行失败，不能只打印日志后发布可信终态。回答与
claim-evidence 关系也在一个事务中提交，回答失败时保留未验证恢复检查点和已提交证据。

GRD-013 已将声明支持关系改为 `GroundedAnswerCandidate` 中的应用 evidence ID；旧页脚只允许在
Provider adapter 内迁移解析，移除后才可发布或保存，并且迁移候选及尚未经过 GRD-014 声明级
校验的新候选都只能产生 `unverified`。应用重启后的自动扫描与恢复编排属于 GRD-020。

当前数据库只保存最多 512 字符的脱敏摘要。对于大多数非纯计算工具，成功摘要只是
`completed`，无法证明具体答案。审计记录适合说明“调用发生过”，还不是可重放的事实账本。

### 4. 同一 `call_id` 的生命周期会覆盖证据语义

同一 ID 再次出现时，`observeInvocation` 会用 `duplicate` 状态替换原来的成功记录；但
`completedCalls` 仍可能复用第一次的成功结果。于是运行时门禁认为证据有效，最终数据库记录却
可能只显示 `duplicate`。调用尝试、执行生命周期和事实证据需要分开建模。

### 5. 跨轮上下文丢失证据边界

`PrepareConversationContext._turnsToMessages` 和 `ComposeChatTurn._composeHistory` 回放历史时
只构造普通的 assistant 正文，不携带终态、可信等级或证据引用。失败、取消但有部分正文的消息
也可能进入后续上下文。模型无法区分已验证事实、未验证陈述和失败运行的残留文本。

摘要侧的 `tool_grounded` 也是消息级布尔值：只要助手消息存在一个成功调用，该消息中的所有
事实就可能一起获得信任。这仍然存在证据漂白。

### 6. Provider 原生工具按 adapter 明确授予证据资格

GRD-012 已把 OpenAI Responses 的 `web_search_call` 和 `url_citation` 归一化为
`ProviderNativeToolResult`，再由协调器生成统一的 requested、running 和终态事件，并按 GRD-011
契约复核后进入同一事实账本。请求会显式取得 action sources；只有已完成且引用能绑定到来源的
结果才能产生 observation。查询正文只保留摘要，URL 去除凭据、query 和 fragment，引用正文、
标题与数量均有上限并经过凭据脱敏。Provider 引用 ID 保存在 structured fact 属性中，应用生成
的 evidence ID 仍由 attempt ID 推导，两类身份不会混用。

Anthropic、Moonshot 等尚未实现原生搜索归一化的 Provider 不会获得此能力标志，其搜索正文只能
保持 `unverified`。传输失败由 GRD-005 的 `ProviderFailure` 保存状态码、端点类别、请求追踪 ID
和可重试性等安全诊断字段，响应正文不进入回答或普通日志。

### 7. 错误记录也是事实，但不是业务事实

当前所有 `isError` 结果都不能作为证据。这能防止把失败说成成功，但也导致“调用超时”“用户
拒绝了写入”这类执行事实只能使用空证据页脚。错误记录可以证明一次尝试的终态，却不能证明
被查询对象不存在或目标状态未改变；两类事实应分别建模。

## 目标可信模型

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

产品可提供严格模式：当最终等级不是 `verified` 时，不展示模型生成的事实答案，只展示应用
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
摘要哈希；确需复验原文时使用加密 payload、最小权限读取和保留期限。日志与 UI 不显示密钥、
Cookie、Authorization 或原始私有命令。

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

仅靠字符串页脚无法确定语义蕴含关系。可增加一个独立模型做“证据是否支持声明”的保守复核，
但它只能拒绝或降级，不能单独把回答升级为 `verified`。严格场景应优先使用领域工具返回的类型
化事实，并由确定性模板生成关键结论。

## 目标 Loop

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

Loop 状态应显式建模为 `planning -> awaitingApproval -> executing -> observing ->
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

- 保留 `tool_execution_records` 作为当前状态投影，新增 append-only 的调用事件表、终态证据表和
  claim-evidence 关联表；证据写入应具备幂等键和摘要校验。
- “工具终态 + 证据 + 最终消息 + 声明关系”至少要有可恢复的提交协议。若无法跨外部调用使用
  单一数据库事务，则先提交证据，再提交回答；回答提交失败可重试，证据提交失败则不得发布
  `verified`。
- 当前提交边界由运行协调器拥有：所有调用事件按尝试内单调序号排队，终态会等待事实账本提交
  并使用同一幂等身份重试，重试不会重新执行工具。账本成功且验证需求覆盖率已计算后才允许进入
  回答合成与提交。
- 最终回答与 claim-evidence 关系在一个本地数据库事务中写入；事务前保存的 `unverified` 部分
  检查点使“证据已提交、回答未提交”的中断状态可在重启后安全重试。自由文本工具以及未在
  GRD-015 状态机中通过声明级门禁的回答仍只能得到 `unverified`，不能因提交成功提前升级为
  `verified`。
- 不再吞掉关键证据持久化异常。UI 增量快照写失败可以降级，但最终事实账本写失败必须让运行
  进入明确失败状态。
- Provider 适配器把原生 web search 等结果转换成统一的调用和证据事件。Provider HTTP 失败
  转换为结构化 `ProviderFailure`，保存安全字段：状态码、端点种类、请求追踪 ID、是否可重试；
  响应正文只进入脱敏诊断。
- 本地文件写工具输出 `actionReceipt`，包含完成标记、最终字节数和 SHA-256；完整文件读取输出
  独立 `observation`。分段或截断读取仍可作为不可信工具数据返回，但不能进入事实证据账本。

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

## 分阶段实施

### P0：封闭错误信任路径

1. 给所有助手消息增加应用计算的可信等级；无工具路径一律为 `unverified`。
2. 所有 Provider 路径统一经过终态门禁；工具、Provider 或持久化失败不能产生
   `completed + verified`。
3. 修复 duplicate 覆盖成功记录的问题，区分 invocation、attempt 和 evidence ID。
4. 历史上下文排除失败/取消/partial 正文，或用不可信数据 envelope 包装。
5. 将 HTTP 状态码和可重试性结构化；404 不做盲目重试。

### P1：建立持久化事实账本

1. 新增不可变证据表和 claim-evidence 表，定义迁移与清理策略。
2. 证据先于回答持久化，关键写入失败时 fail closed。
3. 证据型工具强制输出 Schema、作用域、观测时间和结果摘要哈希。
4. 原生 web search 与 MCP 结果进入同一证据协议。

### P2：声明级门禁

1. Provider 输出结构化 claims；应用验证并渲染最终正文。
2. 引入 claim kind 与 tool evidence capability 的确定性匹配。
3. 写操作增加 read-after-write 或强语义回执策略。
4. 证据不足时继续观测；达到预算后明确降级，不让合成修复触发重复副作用。

### P3：跨轮可信性与体验

1. 历史、摘要和 Memory 保留声明级来源、时间和可信等级。
2. 增加证据详情 UI、严格模式和部分验证展示。
3. 建立按 Provider、工具类型和失败类别统计的可观测指标。

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

测试应以领域门禁和持久化不变量为主，模型评分只作为补充。核心发布指标至少包括：未支持事实
通过数必须为零、证据引用可解析率为 100%、`verified` 消息的证据持久化率为 100%，以及副
作用工具在修复轮中的重复执行数为零。

## 不采用的捷径

- 只增强 system prompt：模型仍可忽略规则，也无法让应用判断引用是否相关。
- 只要求一个证据页脚：只能证明调用 ID 存在，不能证明声明与结果之间的关系。
- 用第二个模型给第一个模型盖章：两个模型都可能在同一份错误材料上达成一致。
- 把所有成功工具结果永久明文保存：会扩大凭据、隐私和受管数据的泄露面。
- 把用户陈述直接当作外部事实：应保留“用户说过”与“世界状态已验证”的区别。

完成上述改造后，工具调用记录才从“供 UI 展示的过程日志”提升为“回答可信等级的唯一应用侧
事实依据”；任何没有合格工具证据的内容仍可按产品策略展示，但系统不会再把它包装成已验证
事实，也不会让它在后续会话中无声升级为事实。
