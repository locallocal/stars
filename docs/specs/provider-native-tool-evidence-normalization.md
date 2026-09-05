# FUT-GRD-001 Provider 原生工具证据归一化设计

[返回文档导航](../README.md) | [后续工作](conversation-grounding-future-work.md) |
[稳定可信性协议](../reference/conversation-loop-grounding.md)

状态：设计完成，等待实施。

本文规划如何把 OpenAI Responses 之外的 Provider 原生工具接入 Stars 的统一调用生命周期、事实
账本和声明级门禁。第一交付目标是 Anthropic Messages 原生 web search；Moonshot `$web_search`
只有在上游提供可稳定验证的来源契约后才进入可信路径。

## 1. 目标与非目标

目标：

- Provider adapter 把远端已经执行的原生工具转换为 `ProviderNativeToolResult`。
- 每次原生调用拥有稳定的 Provider call ID，并由协调器继续生成应用侧 invocation、attempt 和
  evidence ID。
- 成功结果只有在来源、引用、作用域、时间、Schema 和完整性都通过确定性检查后才能产生
  observation。
- 错误、空结果、截断、歧义绑定和未知协议都生成安全失败或 `unverified`，不回退到正文推断。
- 原生工具与本地、MCP 工具混用时继续复用同一预算、账本、声明验证和发布门禁。

非目标：

- 不把普通 Provider 自由文本、Markdown 链接或模型自报引用转换成证据。
- 不为不受支持的 Provider 自动猜测响应格式。
- 不新增绕过 `ToolPolicy` 的客户端工具，也不把 Provider 原生执行误记为本地审批后执行。
- 不在事实账本中保存原始搜索查询、URL 查询参数、完整页面、Anthropic `encrypted_content`、
  Moonshot opaque arguments 或 Provider 错误正文。
- 不在本项中实现 FUT-GRD-002 的加密原始证据快照。

## 2. 当前基线与差距

| Provider | 当前执行入口 | 当前证据状态 | 本项决策 |
| --- | --- | --- | --- |
| OpenAI Responses | `OpenAiResponsesAgentModelSession` | 已把 `web_search_call` 与 `url_citation` 归一化 | 保持行为不变，并提取可复用的安全工具 |
| Anthropic Messages | `AnthropicAgentModelSession` / legacy `generateText` | Agent Session 不声明原生搜索；收到服务器工具块时也不归一化 | 第一阶段完整实现并启用可信能力 |
| Moonshot Chat Completions | legacy `generateText` 内部回显 `$web_search` 参数；Agent Session 复用普通 OpenAI tool-call 解析 | 没有稳定 citation/来源 Schema，保持 `unverified` | 先保留降级并建立协议准入门；上游契约稳定后再实现 |
| 其他 Provider | 各自的 legacy 或兼容接口 | 无专用 adapter | 必须逐 Provider 完成准入清单，不能继承其他 adapter 的资格 |

现有 Domain 和持久化能力已经足够：

- [`ProviderNativeToolResult`](../../lib/domain/models/ai_models.dart) 表示已在 Provider 侧执行的工具，
  协调器只记录和复核，不会再次调用。
- [`AgentRunCoordinator`](../../lib/domain/use_cases/agent_run_coordinator.dart) 会为其生成 requested、
  running 和终态事件，并复用 duplicate、预算、证据契约与持久化屏障。
- [`PersistToolInvocation`](../../lib/domain/use_cases/persist_tool_invocation.dart) 已能把成功 observation
  或安全的 `executionFailure` 写入现有事实账本。

因此本项不增加数据库表，也不改变 evidence ID 算法；主要改动集中在 Data 层 Provider session、
响应归一化和能力声明。

## 3. 外部协议基线

实现前必须重新核对官方协议，测试 fixture 也必须注明所支持的 wire version：

- [Anthropic Web search tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/web-search-tool)
  定义了 `server_tool_use`、`web_search_tool_result`、文本 citations、内嵌错误和 `pause_turn`。
- [Kimi API Web Search](https://platform.kimi.ai/docs/guide/use-web-search) 规定 `$web_search` 使用
  `builtin_function`，调用方把 `tool_call.function.arguments` 原样作为 tool result 回传。
- [Kimi API troubleshooting](https://www.kimi.ai/help/kimi-api/api-troubleshooting) 仍提示 web search
  正在更新且不建议近期依赖。Moonshot 在该状态消失且来源 Schema 固定前不得启用证据资格。

外部文档只定义 wire contract，不定义 Stars 的可信等级。即使 Provider 声称工具成功，仍必须
通过本协议中的确定性证据检查。

## 4. 总体架构

```text
Provider HTTP response
  -> Provider-specific session preserves required continuation blocks
  -> Provider-specific native normalizer
       -> validate supported wire version and call identity
       -> correlate call, result and citations
       -> sanitize URLs / bound text / digest private arguments
       -> build ToolDefinition + ToolCallRequest + ToolResult
  -> ProviderNativeToolResult
  -> AgentRunCoordinator
       -> requested / running / terminal audit events
       -> shared Tool output Schema and evidence-contract validation
       -> immutable ToolEvidenceRecord
  -> GroundedAnswerValidator
  -> message + claim-evidence transaction
```

### 4.1 Data 层内部归一化契约

新增一个仅在 `lib/data/services/ai/` 内使用的接口；原始 Provider Map 不进入 Domain：

```dart
abstract interface class ProviderNativeToolNormalizer {
  NativeToolNormalizationBatch normalize(NativeToolTurn turn);
}

final class NativeToolTurn {
  const NativeToolTurn({
    required this.providerId,
    required this.protocolVersion,
    required this.receivedAt,
    required this.rawResponse,
  });
}

final class NativeToolNormalizationBatch {
  const NativeToolNormalizationBatch({
    required this.results,
    required this.consumedCallIds,
    required this.rejectionCode,
  });
}
```

这是设计形态而非必须逐字采用的公共 API。实现必须保持以下语义：

- `results` 只包含身份完整的 `ProviderNativeToolResult`。
- 每个发现的原生调用要么出现在 `consumedCallIds`，要么产生安全 `rejectionCode`；不能静默忽略
  Provider 已执行的未知原生工具块。
- `rejectionCode` 只能来自应用枚举，不携带原始异常、查询或响应正文。
- normalizer 是纯解析器，不访问数据库、不发网络请求、不执行工具。

### 4.2 共享安全组件

从 `openai_native_tool_evidence.dart` 中提取 Provider 无关的内部组件：

- HTTP/HTTPS URL 规范化：移除 user info、query、fragment，限制长度，统一 scheme 与 host。
- `source_resource_id = url:<sha256>`，不把原 URL 用作应用身份。
- Unicode 字符级截断、控制字符清理和凭据模式脱敏。
- Provider ID 安全校验、查询 digest 和固定上限。
- 统一的 citation DTO 与 `StructuredFact(name: web.citation.N)` 生成器。
- 统一错误码及默认 15 分钟有效期。

OpenAI 先迁移到共享组件并运行现有测试，输出 JSON、digest、错误码和可信结果必须不变。该步骤
是后续 Provider 接入的回归基线。

### 4.3 能力声明

`AiProviderCapabilities.supportsNativeToolEvidence` 继续作为进入 Agent Loop 的硬门。它只能在以下
条件同时满足时为 `true`：

1. 使用明确的第一方 Provider adapter，而不是仅声称兼容的自定义 Base URL。
2. 当前 endpoint、模型和原生工具 wire version 在应用 allowlist 中。
3. normalizer 已实现成功、错误、空结果、截断和协议漂移测试。
4. session 能完整处理该 Provider 要求的 continuation 语义。

动态模型目录中的 `supportsWebSearch` 只决定“Provider 可能提供搜索”，不能自动授予证据资格。
自定义兼容端点在没有单独 adapter 与测试前继续为 `false`。

## 5. Anthropic 设计

### 5.1 支持范围

首版只支持 Messages API 的 `web_search_20250305` 直接调用：

- 工具名：`anthropic.messages.web_search`
- 工具版本：`anthropic.messages.web_search_20250305.1`
- evidence kind：`observation`
- subject：`web:search`
- capability：`network`、`externalRead`
- 有效期：15 分钟
- 单次请求 `max_uses`：5，并继续受 Agent Run 全局工具预算约束

`web_search_20260209`、`web_search_20260318`、dynamic filtering、code execution caller 和
`response_inclusion=excluded` 首版不启用。它们可能隐藏或嵌套结果块，必须分别增加 fixture 与
绑定测试后才能加入 allowlist。

### 5.2 请求与 session 生命周期

修改 `AnthropicAgentModelSession._send`：

- 当 `groundedRequest == null`、`request.options.webSearch == true` 且 adapter eligible 时，在
  client tools 之外追加固定版本的 Anthropic web-search 定义。
- grounded synthesis 请求不得携带任何工具，保持现有结构化回答协议。
- 保存 Provider 返回的完整 assistant content block 仅用于本次内存 session continuation；其中
  `encrypted_content` 和 `encrypted_index` 不进入日志、消息、证据或指标。
- `stop_reason=pause_turn` 时把 assistant content 原样加入下一请求并由 session 内部继续，最多
  两次；达到上限产生 `provider_native_continuation_limit`，不交给模型正文兜底。
- 混合 server tool 与 client tool 且 `stop_reason=tool_use` 时，先把 client `ToolCallRequested`
  交给协调器；`continueWith` 回传客户端结果后，再接收服务器搜索结果。未出现结果前不提前把
  server call 记为成功或失败。
- 只有最终非 `pause_turn` 响应发出 `ModelTurnCompleted`。中间响应的 token usage 可以累计，但
  不能制造额外的协调器完成态。

### 5.3 调用、结果与引用绑定

归一化严格执行以下顺序：

1. 读取 `server_tool_use`，要求 `name=web_search`、安全且唯一的 `id`、非空 query；证据参数只保留
   `action=search` 和 `query_digest`。
2. 使用 `web_search_tool_result.tool_use_id` 与 call ID 一一关联。缺失、重复或未知 ID 视为协议
   漂移。
3. 成功 content 必须是 `web_search_result` 列表，每项至少有合法 URL 和非空 title；
   `encrypted_content` 只用于 continuation，不进入归一化结果。
4. 从 text block 的 `web_search_result_location` citations 取得 URL、title 与 `cited_text`；只接受
   URL 存在于且仅存在于一个关联结果集合中的引用。
5. 多个 search call 命中同一 URL、citation 无对应结果或引用无法唯一绑定时，相关调用产生
   `provider_native_citations_unbound`，不能跨调用猜测归属。
6. 每个调用至少需要一条合格 citation；否则产生 `provider_native_citation_missing`。
7. 通过的 citation 使用共享清洗器构造 `web.citation.N` facts，再由现有 output Schema 和
   `validateToolEvidenceResult` 复验。

`observedAt` 使用完整 HTTP 响应被应用接收的 UTC 时间。Provider 响应没有可信服务器时间时，
不能从 citation 页面时间推导观测时间；`page_age` 只可作为脱敏属性，不改变有效期。

### 5.4 内嵌错误映射

Anthropic 可能在 HTTP 200 中返回 `web_search_tool_result_error`。只保存以下应用错误码：

| Provider error | Stars error code |
| --- | --- |
| `too_many_requests` | `provider_native_tool_rate_limited` |
| `invalid_tool_input`、`query_too_long`、`request_too_large` | `provider_native_tool_invalid_input` |
| `max_uses_exceeded` | `provider_native_tool_limit_reached` |
| `unavailable` | `provider_native_tool_unavailable` |
| 未知值或错误结构 | `provider_native_protocol_drift` |

错误结果生成 `ProviderNativeToolResult`，让协调器持久化调用终态和 `executionFailure`；它不能生成
observation。HTTP 失败仍走现有 `ProviderFailure`，不能伪装成工具内错误。

### 5.5 启用条件

最后一步才在 `Anthropic.capabilities` 打开 `supportsNativeToolEvidence`。首版只对第一方
Anthropic Messages endpoint 和内置目录中明确支持 web search 的模型启用；自定义 `baseURL`、
未知模型、未知工具版本继续走 legacy `generateText + unverified`。

## 6. Moonshot 设计与准入门

Moonshot 当前不能直接复用 Anthropic/OpenAI 的证据策略。官方 `$web_search` 流程要求：模型先
返回 `tool_calls`，调用方把 `function.arguments` 原样作为 tool result 回传，搜索再由 Provider
完成。当前官方材料没有给 Stars 可依赖的、带稳定来源身份和 cited text 的结果 Schema；帮助
中心同时提示该功能正在更新。

因此本项对 Moonshot 分两步：

### 6.1 当前交付

- 保持 `supportsNativeToolEvidence == false`，web-search-only 会话继续明确为 `unverified`。
- 保留现有 legacy 回显流程及测试，不把 `$web_search` 当作应用本地 `ToolCallRequested`。
- 增加协议 fixture 测试，证明 opaque arguments、usage token 数和最终 Markdown 链接都不能产生
  `ProviderNativeToolResult` 或 observation。
- 在诊断中使用固定原因 `provider_native_source_contract_missing`，不记录 arguments 原文。

### 6.2 上游契约满足后的实现

只有同时满足以下条件才开始 Moonshot normalizer：

1. 官方文档给出版本化的来源/引用结构，至少包含 call ID、URL、title、被引用文本或等价可验证
   摘要，以及明确的成功/失败终态。
2. 该结构能与每个 `$web_search` call 一一关联，而不是只能从最终正文猜测。
3. 官方不再把该能力标记为正在更新或不建议依赖。
4. 能取得脱敏的成功、空结果、失败、多调用和流式分片 fixture。

届时新增专用 `MoonshotAgentModelSession`：它在 session 内完成 `$web_search` 原样回传，不把该调用
交给本地工具执行器；完整响应确认后才发出 `ProviderNativeToolResult`。如果上游仍只提供 opaque
arguments，则该阶段继续阻塞，不能通过启发式解析绕过。

## 7. 文件级实施计划

### 阶段 A：共享安全基线

- 新增 `lib/data/services/ai/provider_native_tool_evidence.dart`，承载内部 normalizer 契约、URL
  清洗、文本脱敏、边界限制、digest、citation DTO 和错误码。
- 重构 `lib/data/services/ai/openai_native_tool_evidence.dart` 使用共享组件，保持现有输出不变。
- 新增 `test/data/services/ai/provider_native_tool_evidence_test.dart`，覆盖 Unicode 截断、URL
  credential/query/fragment 去除、凭据脱敏、ID 限制和确定性 digest。
- 运行 OpenAI、协调器、账本和 release gate 现有回归，作为零行为变化门禁。

### 阶段 B：Anthropic 归一化

- 新增 `lib/data/services/ai/anthropic_native_tool_evidence.dart`。
- 更新 `lib/data/services/ai/skill_tool_sessions.dart` 的 part 声明。
- 更新 `lib/data/services/ai/skill_tool_agent_sessions.dart`：声明原生工具、保存 continuation block、
  处理 `pause_turn` 和混合 client/server tools、发出归一化事件。
- 更新 `lib/data/services/ai/anthropic.dart`：以第一方 endpoint、模型目录和 adapter eligibility
  计算 capability。
- 扩展 `test/data/services/ai/skill_tool_sessions_test.dart` 与
  `test/domain/use_cases/provider_native_tool_coordinator_test.dart`。
- 扩展 `test/ui/features/chat/view_models/chat_generation_native_tools_test.dart`，验证 web-search-only
  Anthropic 会话进入 Agent Loop，禁用/不支持时仍走 `unverified`。

### 阶段 C：持久化、混用和故障注入

- 扩展 `test/data/repositories/sqlite_tool_evidence_repository_test.dart`，验证 Anthropic provider
  call ID 与应用 evidence ID 分离、digest round-trip 和删除级联。
- 增加 Anthropic + MCP 混合结果、重复 call ID、证据写失败、回答事务失败和重启恢复测试。
- 确认现有 grounding 指标只记录应用错误分类与计数，不接收 URL、查询、citation text 或原始
  Provider error。
- 在 `test/architecture/release_configuration_test.dart` 中保持三个发布不变量不变。

### 阶段 D：Moonshot 协议观察

- 扩展 `test/data/services/ai/moonshot_test.dart`，固定当前 opaque/回显行为和 fail-closed 断言。
- 在每次 Moonshot 官方协议升级时重新执行第 6.2 节准入检查。
- 准入前不添加 capability、不创建 observation，也不把 Markdown 来源展示为“已验证”。

## 8. 验收矩阵

| 场景 | 预期结果 |
| --- | --- |
| Anthropic 一次搜索、一条可唯一绑定 citation | 持久化一条 observation，声明可参与 `verified` |
| 一次搜索返回多个合格 citations | 同一 evidence 内生成有界、确定顺序的 facts |
| 多次搜索且 URL 能唯一归属 | 每个 call 生成独立 invocation/attempt/evidence |
| 多次搜索共享 URL，无法唯一绑定 citation | 相关调用失败，回答降级 |
| 成功结果列表为空或没有 citations | `provider_native_citation_missing`，无 observation |
| citation URL 含 user info、query、fragment | 只保留规范化安全 URL；身份使用 SHA-256 |
| citation 文本超限或发现凭据 | 截断/脱敏；截断结果不能成为业务证据 |
| Anthropic 内嵌工具错误 | 持久化 `executionFailure`，不支持业务事实 |
| HTTP 401/403/404/429/5xx | 继续使用结构化 `ProviderFailure`，不输出可信正文 |
| `pause_turn` 后成功 | session 有界续跑，最终只发布一个模型轮完成态 |
| `pause_turn` 超限或响应结构变化 | `provider_native_continuation_limit` 或 `provider_native_protocol_drift` |
| 同轮混合 Anthropic search 与 MCP 工具 | 两类证据进入同一账本和声明门禁 |
| 相同 call ID/相同参数重复出现 | 复用首次结果，追加 duplicate audit，不重复副作用 |
| 相同 call ID/不同参数 | `duplicateConflict`，不复用证据 |
| 自定义 Anthropic Base URL 或未知模型 | capability 关闭，最多 `unverified` |
| Moonshot 仅返回 opaque arguments 或最终 Markdown URL | 不产生 observation，保持 `unverified` |
| 证据或回答持久化失败 | 不发布 `verified`；现有恢复协议保持幂等 |

## 9. 安全与隐私门禁

- normalizer 的原始输入只在当前 Provider session 内存中存活，不进入普通日志和 metrics。
- query 只保存 SHA-256 digest；URL 去除凭据、query 和 fragment 后才可进入 structured facts。
- citation text、title、来源数量和单个 URL 都有固定上限；任一截断必须阻止业务 observation。
- `encrypted_content`/`encrypted_index` 只按 Anthropic continuation 要求原样回传，不能写入消息、
  evidence、checkpoint、错误或调试输出。
- Provider wire error 只映射到 allowlist code；未知值统一为 `provider_native_protocol_drift`。
- normalizer 不拥有网络、数据库、文件或工具执行依赖，避免解析阶段扩大权限。

## 10. 发布与回滚

发布顺序固定为：共享重构 → Anthropic adapter（capability 仍关闭）→ 全部回归 → 打开第一方
Anthropic capability。不能先打开能力再依赖运行时异常降级。

回滚只需关闭对应 Provider 的 `supportsNativeToolEvidence`；数据库无需降级，已经写入的不可变
证据仍可复验。回滚后新会话最多为 `unverified`，历史已验证消息继续按原 evidence digest 读取。

生产观察至少包括以下脱敏指标：

- `gateRejection/provider_native_citation_missing`
- `gateRejection/provider_native_citations_unbound`
- `gateRejection/provider_native_protocol_drift`
- 证据引用解析率与 verified 证据持久化率

这些诊断指标不能升级可信等级；现有 unsupported claim、证据持久化和重复副作用三个硬发布
门禁保持不变。

## 11. 完成定义

FUT-GRD-001 的第一可发布批次在以下条件全部满足后完成：

- OpenAI 归一化行为在共享重构后零回归。
- Anthropic 第一方受支持模型能从 web search 产生可持久化、可复验的 observation。
- 空、错、截断、歧义、协议漂移、pause、混合工具和故障注入路径全部 fail closed。
- Provider call ID 与应用 invocation/attempt/evidence ID 始终分离。
- 日志、消息、指标和数据库不包含查询原文、URL 查询参数、凭据或 Provider 私有 continuation
  内容。
- web-search-only 路径、MCP 混用、重启恢复和三个发布不变量均有自动化测试。
- 稳定协议与 Provider 能力文档同步更新。

Moonshot 不作为第一批次启用条件；它只有通过第 6.2 节的上游协议准入门后，才形成独立的后续
可发布批次。在此之前，明确的 `unverified` 是正确行为，不是需要绕过的失败。
