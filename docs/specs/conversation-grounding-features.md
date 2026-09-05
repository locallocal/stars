# 会话事实化功能清单与实施优先级

[返回文档导航](../README.md) | [可信性协议](../reference/conversation-loop-grounding.md)

本文把[《会话 Loop 的事实依据与防幻觉协议》](../reference/conversation-loop-grounding.md)
拆成可以开发、测试和独立交付的功能项。列表顺序同时表示默认实施顺序；只有明确标注可并行的
项目才能跨序号开发。

## 优先级定义

| 优先级 | 目标 | 发布要求 |
| --- | --- | --- |
| P0 | 先停止错误授信和错误重试 | 必须完整交付后才能声称应用支持可信等级 |
| P1 | 建立可恢复、可复验的事实账本 | 必须完整交付后才能持久化 `verified` |
| P2 | 建立声明级证据校验和闭环观测 | 必须完整交付后才能对业务事实显示“已验证” |
| P3 | 将可信边界扩展到历史、Memory、完整 UI 和运营指标 | 可按功能逐项发布，但不能降低 P0–P2 门禁 |

实施过程中遵守两个总规则：

1. `completed` 只表示生成流程结束，不表示内容可信；`verified` 必须由应用根据持久化证据计算。
2. 功能未完成时只能降级为 `unverified` 或 `failed`，不能回退到旧页脚并授予可信状态。

## 总览与依赖顺序

| 顺序 | ID | 优先级 | 功能 | 依赖 | 可交付结果 |
| ---: | --- | --- | --- | --- | --- |
| 1 | GRD-001 | P0 | 回答可信等级领域模型 | 无 | 消息能够表达已验证、部分验证、未验证和失败 |
| 2 | GRD-002 | P0 | 可信元数据序列化与旧数据兼容 | GRD-001 | 可信等级可安全落库和恢复 |
| 3 | GRD-003 | P0 | 所有文本生成统一经过终态信任门禁 | GRD-001、002 | 无工具路径不再被误认为可信 |
| 4 | GRD-004 | P0 | 调用、尝试和证据身份分离 | 无 | duplicate 不再覆盖首次成功语义 |
| 5 | GRD-005 | P0 | Provider 失败结构化分类 | 无 | 404 等错误得到正确诊断和重试策略 |
| 6 | GRD-006 | P0 | 不可信历史正文隔离 | GRD-001、002 | 失败、取消、partial 输出不再污染下一轮 |
| 7 | GRD-007 | P0 | 最小可信状态 UI | GRD-001、003 | 用户能够看见未验证和失败状态 |
| 8 | GRD-008 | P1 | 不可变工具证据领域模型 | GRD-004 | 终态观测拥有稳定、类型化证据记录 |
| 9 | GRD-009 | P1 | 事实账本数据库与 Repository | GRD-008 | 证据和调用事件可恢复、可查询 |
| 10 | GRD-010 | P1 | 证据先于回答的提交协议 | GRD-003、009 | 证据落库失败时无法发布可信回答 |
| 11 | GRD-011 | P1 | 证据型工具输出契约 | GRD-008 | 工具声明作用域、时效和结构化事实 |
| 12 | GRD-012 | P1 | Provider 原生工具证据归一化 | GRD-009、011 | Web search 等原生工具进入同一账本 |
| 13 | GRD-013 | P2 | 结构化回答声明协议 | GRD-002、011 | 最终回答按 claim 输出而非消息级页脚 |
| 14 | GRD-014 | P2 | 声明级确定性证据门禁 | GRD-009、013 | 无关、过期或越权证据无法支持声明 |
| 15 | GRD-015 | P2 | Observe–Verify–Synthesize Loop | GRD-010、014 | 缺证据时继续观测，预算耗尽时安全降级 |
| 16 | GRD-016 | P2 | 副作用写后验证 | GRD-011、014、015 | 动作回执与最终状态声明严格区分 |
| 17 | GRD-017 | P2 | 基础验证工具发现与授权 | GRD-011、015 | 验证不再完全依赖 Skill 是否激活 |
| 18 | GRD-018 | P3 | 声明级历史与 Memory 传播 | GRD-014、015 | 跨轮继续保留来源、时间和可信边界 |
| 19 | GRD-019 | P3 | 证据详情 UI 与严格模式 | GRD-014、018 | 可查看声明映射，并可拒绝未验证答案 |
| 20 | GRD-020 | P3 | 恢复、指标和发布门禁 | GRD-009、015 | 可恢复中断运行并持续监控可信不变量 |

建议交付里程碑：

- 安全底座：GRD-001 至 GRD-007。此时所有旧回答和无工具回答最多为 `unverified`。
- 可追溯底座：GRD-008 至 GRD-012。此时证据可持久化，但尚不对业务声明授予 `verified`。
- 可信回答 MVP：GRD-013 至 GRD-017。此时才能上线业务事实的“已验证”状态。
- 完整能力：GRD-018 至 GRD-020。

## P0：停止错误授信

### GRD-001 回答可信等级领域模型

状态：已完成。

实现入口：`lib/domain/models/message.dart`；领域回归测试：
`test/domain/models/message_grounding_test.dart`。

目标：把流程终态和回答可信度拆成两个正交概念。

实现范围：

- 在 `lib/domain/models/message.dart` 新增 `AnswerTrustLevel`：`verified`、
  `partiallyVerified`、`unverified`、`failed`。
- 新增 `MessageGrounding`，第一阶段至少包含 `protocolVersion`、`trustLevel`、
  `reasonCode`、`evidenceIds`；默认值必须是 `unverified`，不能默认 `verified`。
- `Message` 增加不可变的 `grounding` 字段和对应 `copyWith` 行为。
- 明确映射：`MessageTerminalOutcome.completed` 不自动影响 `trustLevel`；取消、失败和空响应只能
  映射到 `failed` 或 `unverified`。

验收标准：

- 新建 assistant 消息未提供证据时默认 `unverified`。
- `completed + unverified` 是合法状态，`failed + verified` 是非法状态。
- 领域测试覆盖所有组合和不可变复制。

测试入口：新增 `test/domain/models/message_grounding_test.dart`。

### GRD-002 可信元数据序列化与旧数据兼容

状态：已完成。

实现入口：`lib/data/models/local_records.dart`、
`lib/data/services/database_service.dart`；持久化与兼容回归测试：
`test/data/models/local_records_test.dart`、
`test/data/repositories/sqlite_repositories_test.dart` 和
`test/data/services/database_service_test.dart`。

目标：让可信状态随消息保存，并安全读取旧消息。

实现范围：

- 更新 `MessageProcessInfoRecord` 或增加独立的 grounding JSON 字段。若放入 `process_info`，必须
  将当前“字段集合完全相等”校验升级为带 `schema_version` 的版本化解析。
- 更新 `lib/data/models/local_records.dart` 的双向映射。
- 旧记录没有 grounding 时映射为 `protocolVersion: 0 + unverified`，不得推断旧
  `succeeded` 工具调用意味着整条回答可信。
- 为非法枚举、未知协议版本和字段缺失定义 fail-closed 行为。

验收标准：

- 新格式 round-trip 后字段不丢失。
- 当前数据库里的旧格式消息仍可读取，且全部为 `unverified`。
- 未知协议版本不会被解析成 `verified`。

测试入口：扩展 `test/data/models/local_records_test.dart` 和
`test/data/repositories/sqlite_repositories_test.dart`。

### GRD-003 所有文本生成统一经过终态信任门禁

状态：已完成。

实现入口：`lib/domain/services/answer_trust_policy.dart`、
`lib/ui/features/chat/view_models/chat_generation_view_model.dart`；领域与流程回归测试：
`test/domain/services/answer_trust_policy_test.dart` 和
`test/ui/features/chat/view_models/chat_generation_view_model_test.dart`。

目标：消除 `provider.generateText` 直通完成态造成的错误授信。

实现范围：

- 新增领域服务 `AnswerTrustPolicy`，输入包括 Provider 终态、工具调用、证据状态和门禁结果，
  输出只能由应用生成。
- 在 `ChatGenerationViewModel._finalizeRun` 保存消息前统一调用该策略；Agent Loop 和 legacy
  Provider 路径不能各自计算可信等级。
- 无工具、Provider 不支持工具、可靠性提示被关闭、工具被拒绝或工具不可用时，正文最多保存为
  `unverified`。
- Provider、门禁或关键持久化失败时使用 `failed`，并保留安全原因码。
- 旧 `<stars_evidence>` 校验可暂时保留为格式防护，但不能产生 `verified`。

验收标准：

- `agentTools.isEmpty` 和 `supportsAgentLoop == false` 两条路径都不能产生 `verified`。
- 关闭应用 system prompt 后，应用侧门禁仍有效。
- Provider 返回流式正文后失败，最终消息不会因为有部分正文而成为可信回答。

测试入口：扩展
`test/ui/features/chat/view_models/chat_generation_view_model_test.dart`，新增
`test/domain/services/answer_trust_policy_test.dart`。

### GRD-004 调用、尝试和证据身份分离

状态：已完成。

实现入口：`lib/domain/use_cases/agent_run_coordinator.dart`、
`lib/domain/models/tool.dart`、`lib/ui/features/chat/view_models/chat_generation_events.dart`、
`lib/data/services/database_tool_execution_schema.dart`；运行时、消息投影和持久化回归测试：
`test/domain/use_cases/agent_run_coordinator_test.dart`、
`test/ui/features/chat/view_models/chat_generation_view_model_test.dart`、
`test/data/repositories/sqlite_tool_execution_repository_test.dart` 和
`test/data/services/database_service_test.dart`。

目标：修复同一 `call_id` 的 duplicate 状态覆盖首次成功调用的问题。

实现范围：

- 引入应用生成的 `invocationId` 和每次执行唯一的 `attemptId`；Provider `callId` 只作为关联字段。
- `AgentRunCoordinator` 的 invocation 索引不能只以 `callId` 为键。
- 相同 ID、相同参数的重复调用返回第一次结果，但追加 `duplicateReused` 尝试事件，不改写第一次
  终态。
- 相同 ID、不同参数追加 `duplicateConflict` 失败尝试，绝不复用结果或覆盖原记录。
- 重试上限按 fingerprint 或明确的 invocation 计算，所有越限结果也必须产生终态记录。

验收标准：

- 首次成功记录在任意重复调用后仍为 `succeeded`。
- 相同参数不重复执行副作用；不同参数不会取得第一次结果。
- 运行时结果、消息投影和数据库终态一致。

测试入口：扩展 `test/domain/use_cases/agent_run_coordinator_test.dart` 和
`test/data/repositories/sqlite_tool_execution_repository_test.dart`。

### GRD-005 Provider 失败结构化分类

状态：已完成。

实现入口：`lib/domain/models/provider_failure.dart`、
`lib/data/services/ai/provider_transport.dart`、`lib/data/services/ai/openai.dart`、
`lib/data/services/ai/skill_tool_sessions.dart` 和
`lib/domain/use_cases/agent_run_coordinator.dart`；分类、重试、脱敏、Base URL 预检及运行终态测试：
`test/domain/models/app_failure_test.dart`、`test/data/services/ai/openai_test.dart`、
`test/data/services/ai/skill_tool_sessions_test.dart` 和
`test/domain/use_cases/agent_run_coordinator_test.dart`。

目标：让传输失败成为明确的运行事实，而不是模糊字符串。

实现范围：

- 在 Domain 新增 `ProviderFailure`，至少包含 `code`、`kind`、`httpStatus`、`endpointKind`、
  `retryable` 和脱敏后的 `requestTraceId`。
- Provider adapter 不再只发出 `provider_http_error`；安全解析 401/403、404、408、429 和 5xx。
- 404 默认 `retryable: false`；408、429 和 5xx 根据策略退避重试，且每次重试属于同一运行中的
  独立传输尝试。
- URL、响应正文、API key、Cookie 和 Authorization 不进入用户可见错误或普通日志。
- OpenAI adapter 增加 Base URL 预检：公开 API 使用默认根地址或兼容服务声明的根地址，不能把
  `chatgpt.com/backend-api/codex` 当作公开 API 根地址。

验收标准：

- 404 不触发同端点盲目重试，运行终态为失败且无可信正文。
- 401/403、429、超时和 5xx 分类正确；敏感响应正文不泄漏。
- 错误来自独立 Codex/ChatGPT 客户端时，Stars 诊断不把它误归因于本地 Agent Loop。

测试入口：扩展 `test/domain/models/app_failure_test.dart`、
`test/data/services/ai/openai_test.dart` 和 `test/data/services/ai/skill_tool_sessions_test.dart`。

### GRD-006 不可信历史正文隔离

状态：已完成。

实现入口：`lib/domain/use_cases/prepare_conversation_context.dart`、
`lib/domain/use_cases/compose_chat_turn.dart` 和
`lib/domain/use_cases/compose_chat_turn_skills.dart`；主路径、fallback 与显式续写回归测试：
`test/domain/use_cases/prepare_conversation_context_test.dart`、
`test/domain/use_cases/compose_chat_turn_test.dart` 和
`test/domain/use_cases/compose_chat_turn_grounding_test.dart`。

目标：防止失败、取消和 partial 回答被下一轮当作既成事实。

实现范围：

- 修改 `PrepareConversationContext._normalizeTurns`：默认不把 `failed`、`cancelled`、
  `emptyResponse` 或 `hasPartialContent` 的 assistant 正文放入普通历史消息。
- 需要继续未完成任务时，将部分正文放入应用生成的 `<untrusted_partial_output>` 数据 envelope，
  同时携带 run、terminal 和 trust 元数据。
- 修改 `ComposeChatTurn._composeHistory` 的 fallback 路径，确保其规则与
  `PrepareConversationContext` 一致。

验收标准：

- 失败、取消和 partial 文本不会以普通 assistant 消息进入模型上下文。
- 正常完成但未验证的历史正文带 `unverified` 标记，而不是静默回放。
- 主上下文路径与 fallback 路径输出相同的信任语义。

测试入口：扩展 `test/domain/use_cases/prepare_conversation_context_test.dart` 和
`test/domain/use_cases/compose_chat_turn_test.dart`。

### GRD-007 最小可信状态 UI

状态：已完成。

实现入口：`lib/ui/features/chat/views/message_list.dart`、
`lib/ui/features/chat/views/message_list_bubble.dart` 和
`lib/ui/features/chat/views/message_list_status.dart`；本地化目录 `lib/l10n/` 通过项目
`intl_utils` 流程更新；持久化回读、可访问性、P0 展示边界与原因分类测试：
`test/widget/message_trust_status_test.dart` 和
`test/l10n/localization_contract_test.dart`。

目标：P0 发布时不让用户把未验证回答误认为已验证。

实现范围：

- 在消息气泡状态区域显示 `未验证` 或 `失败`；P0 阶段不显示 `已验证`。
- 为原因码提供本地化文案：无工具、Provider 不支持、工具拒绝、Provider 失败、门禁失败。
- 状态必须来自持久化 `MessageGrounding`，不能根据是否展示过工具卡临时推断。

验收标准：

- 重启并重新加载会话后状态保持一致。
- 屏幕阅读器能够读出可信状态，颜色不是唯一提示。
- 所有支持语言拥有相同 key；生成文件仅由项目本地化流程更新。

测试入口：新增消息可信状态 Widget 测试，并扩展
`test/l10n/localization_contract_test.dart`。

## P1：建立可恢复事实账本

### GRD-008 不可变工具证据领域模型

状态：已完成。

实现入口：`lib/domain/models/tool_evidence.dart`、
`lib/domain/models/tool.dart` 和
`lib/domain/use_cases/agent_run_coordinator_support.dart`；不可变性、身份、终态、证据类型、
完整性、有效期与持久化门禁测试：
`test/domain/models/tool_evidence_test.dart`。

目标：把“调用发生过”的审计与“可支持声明”的证据分开。

实现范围：

- 在 Domain 新增 `ToolInvocationEvent`、`ToolEvidenceRecord`、`EvidenceKind` 和
  `StructuredFact`。
- `ToolEvidenceRecord` 至少实现可信性协议中规定的身份、来源、作用域、摘要、观测时间、有效
  期、完整性和持久化字段。
- 明确错误证据只能支持 `executionFailure`，成功动作回执是 `actionReceipt`，读取结果是
  `observation`。
- 所有模型为不可变对象，并验证 ID、时间范围、终态和 digest 格式。

验收标准：

- 非终态、空结果、截断结果或 Schema 无效结果无法构造业务事实证据。
- 错误结果可以构造执行失败证据，但不能构造 observation。
- evidence ID 不依赖 Provider `callId`，跨 Provider 保持同一格式。

测试入口：新增 `test/domain/models/tool_evidence_test.dart`。

### GRD-009 事实账本数据库与 Repository

状态：已完成。

实现入口：`lib/data/services/database_tool_evidence_schema.dart`、
`lib/data/services/local_database_tool_evidence.dart`、
`lib/data/models/tool_evidence_record.dart`、
`lib/domain/repositories/tool_evidence_repository.dart` 和
`lib/data/repositories/sqlite_tool_evidence_repository.dart`；v18→v19 迁移、幂等事务、
append-only、digest 自校验、敏感 payload 保留期与级联清理测试：
`test/data/services/database_service_test.dart`、
`test/data/repositories/sqlite_tool_evidence_repository_test.dart`。

目标：证据可以在进程退出后恢复和复验。

实现范围：

- 以当前 `databaseVersion` 的下一版本新增 append-only `tool_invocation_events`、
  `tool_evidence_records` 和 `answer_claim_evidence` 表。
- 保留 `tool_execution_records` 作为当前状态投影，不能再把它当作完整事件历史。
- 为 `run_id`、`message_id`、`evidence_id`、`observed_at` 建立必要索引和外键清理规则。
- 新增 `ToolEvidenceRepository`：按运行批量提交、按证据 ID 查询、按消息读取、验证 digest。
- payload 默认只保存规范化事实、脱敏摘要和 digest；原始敏感结果使用可选加密引用与保留期。

验收标准：

- 数据库升级不丢失现有消息和工具审计；降级/备份检查遵循现有数据库策略。
- 相同幂等键重复写入不会产生多份证据，内容冲突会失败。
- 删除会话时相关调用事件、证据和 claim 关系全部级联删除。
- Repository 返回的记录能通过 digest 自校验。

测试入口：扩展 `test/data/services/database_service_test.dart`，新增
`test/data/repositories/sqlite_tool_evidence_repository_test.dart`。

### GRD-010 证据先于回答的提交协议

状态：已完成。

实现入口：`lib/domain/use_cases/agent_run_persistence.dart`、
`lib/domain/use_cases/persist_tool_invocation.dart`、
`lib/data/services/local_database_tool_evidence.dart`、
`lib/data/repositories/sqlite_message_repository.dart` 和
`lib/ui/features/chat/view_models/chat_generation_persistence.dart`；终态等待、幂等重试、失败关闭、
原子回答提交与重启恢复测试：`test/domain/use_cases/agent_run_coordinator_test.dart`、
`test/domain/use_cases/persist_tool_invocation_test.dart`、
`test/ui/features/chat/view_models/chat_generation_view_model_test.dart`、
`test/data/repositories/sqlite_repositories_test.dart` 和
`test/data/repositories/sqlite_tool_evidence_repository_test.dart`。

目标：数据库中不存在“回答已验证但证据未落库”的状态。

实现范围：

- 将 `ToolInvocationPersister` 从忽略异常的 UI 回调提升为运行协调器依赖；终态证据必须 await。
- 提交顺序固定为：调用终态事件 → 证据 → claim 关系与最终消息 → 发布 UI 终态。
- 增加幂等重试；消息保存失败时证据可以保留待恢复，证据保存失败时回答只能失败或未验证。
- `_finalizeRun` 不得在关键事实写入失败后继续发布 `completed + verified`。

验收标准：

- 注入证据 Repository 写失败后，UI 和数据库都不存在 `verified` 消息。
- 重试不会重复工具副作用，也不会重复证据记录。
- 应用在“证据已提交、回答未提交”之间退出后能够安全恢复。

测试入口：扩展 ChatGeneration ViewModel 测试，并新增故障注入 Repository 测试。

### GRD-011 证据型工具输出契约

状态：已完成。

实现入口：`lib/domain/models/tool.dart`、
`lib/domain/models/tool_evidence_contract.dart`、
`lib/domain/use_cases/agent_run_evidence.dart`、
`lib/domain/use_cases/persist_tool_invocation.dart`、
`lib/data/services/tools/built_in_tools.dart` 和
`lib/data/services/mcp/mcp_tool_adapter.dart`；领域契约、运行协调、账本衔接、内置工具与 MCP
回归测试：`test/domain/models/tool_evidence_contract_test.dart`、
`test/domain/use_cases/agent_run_coordinator_test.dart`、
`test/domain/use_cases/persist_tool_invocation_test.dart`、
`test/data/services/tools/built_in_tools_test.dart` 和
`test/data/services/mcp/mcp_tool_adapter_test.dart`。

目标：让应用能够机械判断工具结果能支持什么类型的声明。

实现范围：

- 为 `ToolDefinition` 增加 `evidenceCapabilities`、`toolVersion`、作用域规则、默认时效策略和
  `requiresReadAfterWrite`。
- 为证据型工具强制提供 `outputSchema`；结果至少包含规范化 subject、facts 和 observedAt。
- 扩展 `ToolResult`，显式携带 `schemaValid`、`observedAt`、`validUntil` 和结果 digest。
- 现有只返回自由文本的工具继续可用，但只能产生审计或 `unverified` 材料。
- 更新 `encodeToolResultForModel`，明确工具输出是数据而非指令。

验收标准：

- 没有输出 Schema 的工具不能产生 observation 证据。
- subject/scope 与输入不一致时结果被拒绝。
- 结果 envelope 不丢失错误、截断、来源、时间和 digest 字段。

测试入口：扩展工具模型、JSON Schema、内置工具和 MCP adapter 测试。

### GRD-012 Provider 原生工具证据归一化

状态：已完成。

实现入口：`lib/data/services/ai/openai_native_tool_evidence.dart`、
`lib/data/services/ai/skill_tool_agent_sessions.dart`、
`lib/data/services/database_tool_evidence_schema.dart`、
`lib/domain/models/ai_models.dart`、
`lib/domain/use_cases/agent_run_provider_tools.dart` 和
`lib/ui/features/chat/view_models/chat_generation_view_model.dart`；OpenAI Responses 归一化、未支持
Provider 降级、统一调用生命周期、混合证据集合和账本身份映射回归测试：
`test/data/services/ai/openai_test.dart`、
`test/data/services/ai/skill_tool_sessions_test.dart`、
`test/data/repositories/sqlite_tool_evidence_repository_test.dart`、
`test/data/services/database_service_test.dart`、
`test/domain/use_cases/provider_native_tool_coordinator_test.dart`、
`test/domain/use_cases/persist_tool_invocation_test.dart` 和
`test/ui/features/chat/view_models/chat_generation_native_tools_test.dart`。

目标：Provider 托管的搜索等工具与本地、MCP 工具遵循同一证据协议。

实现范围：

- 第一阶段支持 `OpenAiResponsesAgentModelSession` 的 web search 输出项和引用。
- 把开始、完成、失败、来源 URL/资源标识和时间转换为统一调用事件与 ToolResult；引用文本遵守
  长度和隐私限制。
- 后续按 adapter 增加 Anthropic、Moonshot 等原生搜索；不支持归一化的 Provider 搜索只能给
  回答 `unverified`。
- Provider 引用 ID 与应用 evidence ID 分离并保存映射。

验收标准：

- OpenAI 原生搜索成功后产生持久化 observation 证据。
- 搜索失败、缺引用或结果被截断时不能支持当前事实。
- 同一回答混用 MCP 与 Provider 原生工具时，门禁使用统一证据集合。

测试入口：扩展 `test/data/services/ai/openai_test.dart` 和
`test/data/services/ai/skill_tool_sessions_test.dart`。

## P2：声明级验证闭环

### GRD-013 结构化回答声明协议

状态：已完成。

实现入口：`lib/domain/models/grounded_answer.dart`、
`lib/domain/models/ai_models.dart`、
`lib/data/services/ai/grounded_answer_protocol.dart`、
`lib/data/services/ai/skill_tool_agent_sessions.dart`、
`lib/data/services/ai/skill_tool_sessions.dart`、
`lib/domain/use_cases/agent_run_grounded_answer.dart` 和
`lib/domain/services/answer_trust_policy.dart`；严格领域解析、旧页脚迁移、三个 Provider 的统一
DTO 协议、协调器仅提交结构化段落及未校验声明不升级可信等级的回归测试：
`test/domain/models/grounded_answer_test.dart`、
`test/data/services/ai/skill_tool_sessions_test.dart`、
`test/domain/use_cases/agent_run_coordinator_test.dart` 和
`test/domain/services/answer_trust_policy_test.dart`。

目标：不再从自由文本页脚推测整条回答是否可信。

实现范围：

- 新增 `AnswerClaim`、`ClaimKind` 和 `GroundedAnswerCandidate`，字段遵循可信性协议。
- `AgentModelSession` 增加结构化合成入口；各 Provider adapter 输出同一候选 DTO。
- claim kind 至少包括 `externalFact`、`currentFact`、`completedAction`、
  `executionFailure`、`userAssertion` 和 `nonFactual`。
- 旧 `<stars_evidence>` 仅做迁移解析；新协议输出中不再显示或保存该页脚。

验收标准：

- 非法 JSON、未知 claim kind、重复 claim ID、空事实或越界 evidence ID fail closed。
- 每段用户可见事实文本都来自结构化 claim；自由文本只能进入 `nonFactual`。
- Provider 差异不会泄漏到 Domain DTO。

测试入口：新增 `test/domain/models/grounded_answer_test.dart` 和 Provider session 协议测试。

### GRD-014 声明级确定性证据门禁

状态：已完成。

实现入口：`lib/domain/services/grounded_answer_validator.dart`；应用侧声明语义约束、逐证据账本
复验、声明可信等级与消息级聚合、保守模型复核和表驱动拒绝原因测试：
`test/domain/services/grounded_answer_validator_test.dart`。

目标：阻止任意成功工具调用为无关事实背书。

实现范围：

- 新增 `GroundedAnswerValidator`，逐条校验证据所属运行、终态、kind、tool capability、subject、
  scope、有效期、Schema、完整性和持久化状态。
- 计算 claim trust 后再聚合消息 trust：全覆盖为 `verified`，部分覆盖为
  `partiallyVerified`，无覆盖为 `unverified`。
- 错误证据只允许绑定 `executionFailure`；action receipt 不允许绑定最终状态 claim。
- 未被任何 claim 使用的证据不影响可信等级，避免装饰性调用。
- 可选模型复核只能拒绝或降级，不能升级确定性结果。

验收标准：

- 成功计算工具不能支持天气、文件或网络事实。
- 跨运行、过期、空、截断、未持久化和作用域不匹配的证据均被拒绝。
- 同一消息一条有证据、一条无证据时结果严格为 `partiallyVerified`。

测试入口：新增 `test/domain/services/grounded_answer_validator_test.dart`，使用表驱动覆盖所有
拒绝原因。

### GRD-015 Observe–Verify–Synthesize Loop

状态：已完成。

实现入口：`lib/domain/use_cases/agent_run_coordinator.dart`、
`lib/domain/use_cases/agent_run_state_machine.dart`、
`lib/domain/use_cases/agent_run_grounded_answer.dart`、
`lib/domain/use_cases/agent_run_models.dart` 和
`lib/domain/services/grounded_answer_validator.dart`；证据提交屏障、覆盖率续跑、预算降级、合成修复、
副作用隔离、run ID 事件与超时回归测试：
`test/domain/use_cases/agent_run_loop_test.dart` 和
`test/domain/services/grounded_answer_validator_test.dart`。

目标：把工具执行、证据覆盖和回答合成连接成显式状态机。

实现范围：

- 将协调器状态显式化为 `planning`、`awaitingApproval`、`executing`、`observing`、
  `verifying`、`synthesizing`、`committing` 和终态。
- 第一轮模型只规划或请求工具；工具结果持久化后计算验证需求覆盖率，再进入回答合成。
- 缺证据且预算充足时发送应用生成的“缺失证据”反馈；达到轮数、调用数或时间上限时降级。
- 合成修复最多一次，并禁止重新执行已经成功或产生副作用的工具。
- 所有事件携带 run ID；迟到事件不能修改其他运行或已提交终态。

验收标准：

- 工具结果未持久化前不会启动最终合成。
- 缺证据时最多按预算继续观测，不会输出伪造事实。
- 修复轮不重复副作用；取消和总超时能终止每个状态。

测试入口：拆分并扩展 `test/domain/use_cases/agent_run_coordinator_test.dart`，增加状态迁移和竞态
测试。

### GRD-016 副作用写后验证

状态：已完成。

实现入口：`lib/domain/services/post_write_verification_policy.dart`、
`lib/domain/services/grounded_answer_validator.dart`、
`lib/domain/use_cases/agent_run_coordinator.dart`、
`lib/domain/use_cases/agent_run_grounded_answer.dart`、
`lib/data/services/tools/local_file_system_tools.dart` 和
`lib/data/services/mcp/mcp_tool_adapter.dart`；动态后置声明约束、本地文件摘要回读、MCP 幂等提示与
副作用隔离回归测试：`test/domain/services/post_write_verification_policy_test.dart`、
`test/domain/use_cases/agent_run_loop_test.dart`、
`test/domain/services/grounded_answer_validator_test.dart`、
`test/data/services/tools/local_file_system_tools_test.dart` 和
`test/data/services/mcp/mcp_tool_adapter_test.dart`。

目标：区分“调用成功”“动作完成”和“最终状态已确认”。

实现范围：

- 工具策略根据 `requiresReadAfterWrite` 生成后置验证需求。
- 写工具成功只产生 `actionReceipt`；由配对只读工具确认资源 ID、版本或内容摘要后才产生
  observation。
- 无配对读取工具时只能回答“工具报告动作已完成”，不能声称最终状态；严格模式下保持未验证。
- 修复轮只能复用动作回执或执行只读验证，不能重复写入。

验收标准：

- 写成功、读失败时不能生成最终状态 `verified` claim。
- 写和读的 subject 不一致时门禁拒绝。
- 幂等和非幂等写工具都不会因模型修复再次执行。

测试入口：为本地文件、MCP 写工具和 shell 副作用各增加一组写后验证测试。

### GRD-017 基础验证工具发现与授权

状态：已完成。

实现入口：`lib/domain/services/verification_tool_discovery.dart`、
`lib/domain/use_cases/prepare_text_generation.dart`、
`lib/domain/use_cases/agent_run_coordinator.dart`、
`lib/domain/models/tool.dart` 和
`lib/ui/core/dependency_injection/app_dependencies.dart`；独立发现通道、最小候选集、审批保留、
拒绝降级与 UI 原因传播回归测试：
`test/domain/services/verification_tool_discovery_test.dart`、
`test/domain/models/tool_policy_test.dart`、
`test/domain/use_cases/prepare_text_generation_test.dart`、
`test/domain/use_cases/compose_chat_turn_test.dart`、
`test/domain/use_cases/agent_run_coordinator_test.dart` 和
`test/ui/features/chat/view_models/chat_generation_view_model_test.dart`。

目标：避免事实验证完全取决于 Skill 是否偶然激活。

实现范围：

- `PreparedChatGeneration` 增加独立的 `verificationToolNames`，与 Skill 请求工具分开。
- 应用仅为明确支持所需 evidence capability 的最小只读工具生成候选集合。
- 所有候选继续经过 `ToolPolicy`；网络、外部读取和本地读取仍按现有策略审批。
- 没有合适工具或用户拒绝时，保存明确原因并降级，不自动扩大权限。

验收标准：

- 没有激活 Skill 时，允许的基础只读验证工具仍可被选择。
- 工具发现不会暴露未授权写工具、进程工具或整个 MCP inventory。
- 用户拒绝后不会换用权限更大的替代工具。

测试入口：扩展 `prepare_text_generation_test.dart`、`compose_chat_turn_test.dart` 和工具策略
测试。

## P3：跨轮、完整 UI 与运营保障

### GRD-018 声明级历史与 Memory 传播

状态：已完成。

实现入口：`lib/domain/models/message.dart`、
`lib/domain/repositories/context_summarizer.dart`、
`lib/domain/use_cases/conversation_history_projection.dart`、
`lib/domain/use_cases/prepare_conversation_context.dart`、
`lib/domain/use_cases/compact_conversation.dart`、
`lib/data/services/ai/provider_context_summarizer.dart`、
`lib/data/models/local_records.dart`、
`lib/data/repositories/sqlite_message_repository.dart` 和
`lib/data/repositories/sqlite_conversation_memory_repository.dart`；声明级 grounding 持久化、历史
trust envelope、verified-claim Memory 门禁、摘要来源/观测时间保留及过期 current claim
重新观测需求测试：
`test/data/services/ai/provider_context_summarizer_test.dart`、
`test/domain/use_cases/prepare_conversation_context_test.dart` 和
`test/domain/use_cases/compact_conversation_test.dart`。

目标：让可信性边界在后续会话和压缩摘要中保持不变。

实现范围：

- `PrepareConversationContext` 注入带终态、claim trust、evidence 摘要和观测时间的 trust
  envelope。
- `ContextSourceEvidence` 从消息级 `isToolGrounded` 改为 claim-evidence 集合。
- 外部事实 Memory 只能来源于 verified claim；用户输入只能生成 user assertion、偏好或决策。
- “当前”问题不能直接复用过期历史观测，必须生成新的验证需求。

验收标准：

- 一条消息中的已验证 claim 不会让未验证 claim 一起进入事实 Memory。
- 历史证据的来源和时间在摘要压缩后仍可追溯。
- 过期事实不会被回答为当前状态。

测试入口：扩展 `provider_context_summarizer_test.dart`、
`prepare_conversation_context_test.dart` 和 `compact_conversation_test.dart`。

### GRD-019 证据详情 UI 与严格模式

状态：待实现。

目标：让用户理解可信状态并控制未验证回答的展示策略。

实现范围：

- 消息气泡支持四种可信等级，展开后按 claim 显示工具、来源、观测时间和失败原因。
- 工具卡区分动作已接受、动作已完成、状态已回读验证。
- Profile 增加严格模式；非 `verified` 事实答案只显示应用生成的无法验证提示，创作类内容显示
  `notFactChecked` 而不伪装成事实。
- 分享、复制和导出时保留或明确附加可信状态，不能只导出正文后丢失边界。

验收标准：

- 键盘、屏幕阅读器、高对比度和移动/桌面布局均可使用。
- 严格模式不会隐藏工具失败原因，也不会把未验证正文写入聊天预览。
- 重启后设置和每条消息状态保持一致。

测试入口：Widget、语义、本地化和桌面视觉回归测试。

### GRD-020 恢复、指标和发布门禁

状态：待实现。

目标：让可信不变量在崩溃、升级和生产运行中可持续验证。

实现范围：

- 启动时扫描非终态调用事件：未完成外部调用标记为 interrupted，不自动重放副作用。
- 恢复“证据已提交、回答未提交”的运行；无法恢复时保持证据并生成安全失败状态。
- 增加脱敏指标：unsupported claim 通过数、证据引用解析率、verified 证据持久化率、重复副作用
  数、各类门禁拒绝数和 Provider 失败分类。
- 在发布测试中锁定三个不变量：未支持事实通过数为 0、verified 证据持久化率为 100%、修复轮
  重复副作用数为 0。

验收标准：

- 在每个 Loop 状态注入进程中断后，重启结果确定且不重复写操作。
- 指标不包含工具原文、用户正文、URL 查询参数或凭据。
- CI 中任一可信不变量失败都会阻止发布。

测试入口：新增恢复集成测试，扩展 `test/architecture/release_configuration_test.dart`。

## 每项功能的完成定义

任一 GRD 功能只有同时满足以下条件才算完成：

- Domain 行为、持久化格式和 UI 状态没有互相矛盾的定义。
- 正向、拒绝、超时、取消、重复调用、持久化失败和旧数据兼容路径均有测试。
- 错误信息经过脱敏，不保存原始凭据或把工具输出当作指令。
- 新功能不绕过现有工具权限、审批、次数限制、总超时和取消机制。
- 更新[可信性协议](../reference/conversation-loop-grounding.md)中的长期约束；完成全部功能后，本清
  单可以从排期文档收敛为稳定的能力矩阵。

## 推荐的首个开发批次

首个变更集只实施 GRD-001、GRD-002 和 GRD-003，不同时引入事实账本或结构化 claims。该批次
的唯一目标是建立安全默认值：所有现有路径仍能工作，但任何未经新协议验证的回答都明确为
`unverified`。随后单独实施 GRD-004 至 GRD-007，以降低一次提交同时修改领域模型、数据库、
Provider、协调器和 UI 的回归风险。
