# 会话任务验收与观测

[文档导航](../README.md) | [规格](../specs/conversation-foreground-background-model.md) |
[消息流转](user-message-agent-response-flow.md) | [正式运行边界](conversation-task-cutover.md)

本文维护可重复执行的验收入口、指标含义和平台边界。测试结果以当前提交的检查输出为准；
真实 Provider 的响应质量、服务延迟和移动系统调度行为需要在对应环境另外验证。

## 完整应用流程

[应用组合测试](../../test/data/repositories/conversation_task_application_test.dart)使用临时文件数据库、
实际消息/任务/证据 repository、`ComposeChatTurn`、`PrepareConversationContext`、
`PrepareTextGeneration`、应用任务组合根和启动恢复用例。测试覆盖：

- 接受与回执 → 持久审批 → 重建应用 → 审批通过 → 外部 job → 再次重建 → 验证 → 唯一终态；
- 等待审批跨越 90 天仍可查询和审批，等待释放执行槽，后台活跃时直接回复和状态请求可用；
- 外部服务已创建 job，但保存句柄的事务被注入故障：重开后按原幂等键找回 job，不再创建；
- 调度器停止后提交取消请求，重开后完成对账，再原子保存唯一取消回复；
- 严格验证抑制无依据的完成声明，终态润色不可用时保留经过验证的结果并本地化回退；
- 重启后从真实 SQL 检查孤立回执、重复终态和缺失终态结果均为零。

[共享夹具](../../test/support/conversation_task_app_harness.dart)在每次重启时关闭数据库连接，重建
repository、Provider、客户端、runner、scheduler 和前台 registry。只有受控时钟和模拟外部服务
的独立磁盘账本跨重启保留；不能用旧应用对象中的 job 列表证明恢复。Provider、外部服务、
安全密钥存储替身不访问网络或用户数据。Bot 和会话在临时库中预置，工具使用受审批保护的外部读取。

[聊天页面验收](../../test/ui/features/chat/views/conversation_task_acceptance_test.dart)与
[原生集成入口](../../integration_test/conversation_tasks_test.dart)运行同一交互场景：实际发送、
审批按钮、普通聊天、状态卡片与润色回退、重建依赖、唯一 verified 结果、退出和重新进入页面。
历史回执与状态消息保持原快照，新终态独立出现，输入框不受后台生命周期阻塞。

## 行为与故障证据矩阵

| 边界 | 必须保持的行为 | 自动化入口 |
| --- | --- | --- |
| 模型与映射 | 终态不可逆、无任务 timedOut；快照和分段预算有界；DTO 无损 | [领域模型](../../test/domain/models/conversation_task_test.dart)、[预算](../../test/domain/models/task_segment_limits_test.dart)、[DTO](../../test/data/models/conversation_task_record_test.dart)、[schema](../../test/data/services/conversation_task_schema_test.dart) |
| 前台 | 一个主回复回合分流；工具可用不强制执行；完整回复；回执安全兜底 | [dispatcher](../../test/domain/use_cases/conversation_turn_dispatcher_test.dart)、[回执](../../test/domain/services/task_acknowledgement_policy_test.dart)、[协议](../../test/data/services/ai/turn_routing_protocol_test.dart) |
| 接受事务前后 | 未提交则无任务/回执；重复原始输入复用身份；外键提交失败回滚 | [任务 repository](../../test/data/repositories/sqlite_conversation_task_repository_test.dart) |
| 工具请求与结果之间 | 先保存意图；只读/幂等调用可重试；未知写入先对账；旧回调受 lease 限制 | [runner 恢复](../../test/domain/use_cases/conversation_task_runner_recovery_test.dart) |
| job 创建与句柄之间 | 对账找到原 job 或等待确认；不盲目重放 | [应用组合](../../test/data/repositories/conversation_task_application_test.dart)、[调度恢复](../../test/domain/use_cases/conversation_task_scheduling_recovery_test.dart) |
| 检查点前后 | 只从提交边界恢复；工具/证据/步骤一致；损坏投影可重建 | [进度事务](../../test/data/repositories/sqlite_conversation_task_progress_test.dart)、[跨分段证据](../../test/domain/use_cases/conversation_task_runner_evidence_test.dart) |
| 审批与取消前后 | 决定与状态原子提交；取消意图不丢失；不可回滚影响如实说明 | [命令事务](../../test/data/repositories/sqlite_conversation_task_commands_test.dart)、[终态恢复](../../test/domain/use_cases/conversation_task_terminal_recovery_test.dart) |
| lease、并发、退避 | 同会话与 Provider 上限；过期接管；旧持有者不能写；重开后按到期时间运行 | [scheduler](../../test/domain/use_cases/conversation_task_scheduler_test.dart)、[恢复](../../test/domain/use_cases/conversation_task_scheduling_recovery_test.dart)、[保护](../../test/data/repositories/conversation_task_scheduling_guards_test.dart) |
| 分段与无进展 | 超过旧总预算仍继续；单次超时有界恢复；无进展最终安全失败 | [runner](../../test/domain/use_cases/conversation_task_runner_test.dart)、[终态投递](../../test/data/repositories/conversation_task_terminal_delivery_test.dart) |
| 验证与终态事务前后 | 同任务有效证据、写后验证、冻结策略；结果原子且唯一；失败不通知 | [finalizer](../../test/domain/use_cases/finalize_conversation_task_test.dart)、[终态事务](../../test/data/repositories/sqlite_conversation_task_terminal_test.dart)、[投递](../../test/data/repositories/conversation_task_terminal_delivery_test.dart) |
| 状态查询与润色 | 多任务不猜测选择；先提交确定性卡片；最多一次修复；过期版本拒绝 | [状态请求](../../test/domain/use_cases/conversation_turn_status_test.dart)、[呈现](../../test/domain/use_cases/present_conversation_task_progress_test.dart)、[文案](../../test/domain/services/task_progress_narration_test.dart) |
| 页面、键盘与无障碍 | 所有状态/等待/终态、宽度、键盘与语义；重入读取；命令错误可见 | [任务卡片](../../test/ui/features/chat/views/conversation_task_card_test.dart)、[ViewModel](../../test/ui/features/chat/view_models/conversation_tasks_view_model_test.dart)、[完整页面](../../test/ui/features/chat/views/conversation_task_acceptance_test.dart) |
| 启动与生命周期 | 恢复先于就绪；挂起释放执行；恢复后扫描；关闭不能重启 | [启动](../../test/ui/features/app/view_models/conversation_task_startup_test.dart)、[页面切换](../../test/ui/features/chat/views/chat_task_flow_test.dart) |
| 正式数据库与备份 | 只接受当前 schema；拒绝旧库/伪装版本；有效备份恢复 | [切换边界](../../test/data/services/database_cutover_test.dart)、[数据库服务](../../test/data/services/database_service_test.dart) |

故障注入使用真实 SQLite 事务中断与外部服务账本。移除注入故障后关闭并重新打开数据库；
接受、检查点和终态的提交前/后两侧分别保留断言，不以“没有异常”代替数据一致性检查。

## 指标读取与解释

生产组合根把 dispatcher、状态呈现、调度和终态指标接到同一个
[ConversationTaskTelemetry](../../lib/domain/use_cases/conversation_task_telemetry.dart)。
读取 `dependencies.conversationTasks.telemetry.snapshot()` 得到不可修改的固定键数值快照。
不保存任务 ID、用户内容、参数、凭据、Provider 响应或不断增长的事件列表，也不会自动上传。

| 指标组 | 含义与边界 |
| --- | --- |
| `foreground.*` | 分流次数、主回复调用次数、直接回复首字符/完整提交、回执提交耗时及回退次数。耗时从 dispatcher 接收输入开始，累计微秒；重试不代表新增任务。 |
| `progress.*` | 卡片条数、确定性卡片落库耗时、润色耗时、回退比例及过期润色次数。`cardReadyUs` 表示可呈现数据已提交，不等于屏幕绘制完成。 |
| `scheduling.*` | 排队、分段执行、等待累计微秒；分段、恢复、重试、lease 过期、无进展分段、对账失败和调度异常计数。执行时间包含该分段内的异步请求，并非 CPU 时间。 |
| `terminal.*` | 实际提交次数及成功/失败/取消分布；终态处理耗时、失败处理耗时、取消请求至提交耗时、接受至终态耗时、无进展终结、润色失败/回退、证据覆盖率与严格模式抑制数。 |
| 原生测试 `ui.*` | 提交到审批卡片绘制、状态请求到卡片绘制的 Stopwatch 样本，写入 integration binding 的 `reportData`。这是受控服务验收样本，不是线上性能基准。 |

进程级累计值在重建应用后重置；单任务的分段、恢复、重试和等待事实仍可由持久事件查询。
耗时值为累计和，比较平均延迟时需同时使用对应样本数；零耗时在可控时钟测试中合法。
终态证据分母包括应验证但候选遗漏的要求。证据覆盖和抑制计数仅在终态事务实际成功后累计，
失败重试或幂等复用不会再次累计结果。回退次数记录文案尝试，可能包含提交失败前的尝试。
[指标测试](../../test/domain/use_cases/conversation_task_telemetry_test.dart)覆盖事务失败后重试与有界导出。

孤立回执不能通过“计数器初值为零”证明。验收直接查询 `messages LEFT JOIN conversation_tasks`，
并检查终态唯一键、缺失结果和外键；见夹具 `integrity()`。存储计数另见
[TaskPersistenceMetrics](../../lib/data/services/task_persistence_metrics.dart)，不把零值当作绕过事务的依据。

## 安全抽查

- 应用组合验收读取任务、事件、检查点、工具关联、证据与消息，检查测试凭据、后台 reasoning
  和中间草稿均未出现；工具原始输出不直接作为普通聊天结果。
- [进度事务](../../test/data/repositories/sqlite_conversation_task_progress_test.dart)与
  [runner 证据](../../test/domain/use_cases/conversation_task_runner_evidence_test.dart)拒绝不安全、
  跨任务、被修改或不完整的证据；不以净化后的值冒充原证据。
- [Bot 导出](../../test/domain/models/bot_export_document_test.dart)禁止导出密钥。
  接受快照只保存配置摘要；缺省参数与数据库中的空对象有相同摘要，真实参数变化仍要求用户处理，
  见[配置摘要测试](../../test/domain/services/task_provider_configuration_test.dart)。
- 指标只导出固定数值，未新增原始文本日志；更完整的信任边界见[事实依据协议](conversation-loop-grounding.md)。

## 可重复检查与平台边界

```sh
dart tool/check_format.dart
flutter analyze --no-pub
flutter test test/architecture/ --no-pub
flutter test --no-pub
flutter test integration_test/conversation_tasks_test.dart -d linux --no-pub
flutter test integration_test/desktop_workflow_test.dart -d linux --no-pub
flutter build linux --release --no-pub
```

原生 Linux 集成需要可用显示服务和 Linux 构建依赖；所有任务数据写入临时目录。
同一工作区的原生集成与 release 构建须串行运行，二者共享平台生成文件。后台测试替身不能
调用带 WidgetTester 异步 guard 的 `expect()`；使用同步断言或检查错误，避免绘制期间的测试
框架冲突被误当作工具失败并触发退避。
Linux 原生运行覆盖真实 Flutter 引擎、SQLite FFI、页面与按钮交互；恢复通过关闭并重建完整
应用依赖模拟，未将其等同于操作系统强杀或实网 Provider 验证。
Android、iOS、macOS、Windows 和 Web 必须在对应运行环境另做验收，不能从 Linux 或
Widget 测试推断通过。移动端挂起/终止期间不承诺持续执行；恢复到前台后按持久检查点和
lease 扫描继续、等待用户或安全终结。
