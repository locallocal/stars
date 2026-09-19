# 会话任务交互与状态展示

[文档导航](../README.md) | [目标规格](../specs/conversation-foreground-background-model.md) |
[前台分流](conversation-turn-dispatch.md) | [调度恢复](conversation-task-scheduling.md) |
[终态验证](conversation-task-terminal-results.md)

生产文本发送已接入前台 dispatcher；后台任务由应用级 scheduler 执行。前台接受、任务执行、
状态查询和唯一终态提交组成完整流程。旧 coordinator、旧恢复和可选 dispatcher 回退已删除，
生产组合与数据库边界见[正式运行边界](conversation-task-cutover.md)。

## 生命周期与依赖组合

[createAppConversationTasks](../../lib/ui/core/dependency_injection/app_dependencies_tasks.dart)
组装 repository、dispatcher、runtime factory、scheduler、recovery、finalizer、状态呈现和用户命令。
clock、身份生成器、Provider factory、工具 registry 和执行 adapter 都可注入。启动先恢复持久任务，
再扫描调度；应用挂起时停止调度，恢复后重新扫描。页面不取得 runner、不轮询数据库。

[ChatGenerationViewModel](../../lib/ui/features/chat/view_models/chat_generation_view_model.dart)
在生产文本路径只协调前台提交、直接回复流、重试和取消。registry 的阻塞状态只涵盖前台/媒体交互。
任务与回执事务成功后释放输入框；取消前台 Provider 请求不会变成后台任务取消。
页面保存附件期间也防止重复提交，已提交轮次的收尾保留用户后来输入的新草稿。

[ConversationTasksViewModel](../../lib/ui/features/chat/view_models/conversation_tasks_view_model.dart)
订阅已提交摘要，并暴露不可变状态和领域命令。Data 先订阅提交事件，再读取初始数据库快照，
按每任务 revision 合并，避免初始加载漏掉接受或进度变化。页面销毁只释放订阅；重入读取持久事实。

## 独立任务页面

会话工具栏的“任务”入口位于“清空会话记录”右侧；会话列表项的菜单也提供入口，移动端可通过
会话列表滑动操作打开。桌面任务页沿用会话数据目录的工作区、内容宽度与留白，切换回聊天保留草稿。
聊天输入区不再放置任务面板，消息旁不再提供“查看状态”按钮。

[ConversationTasksScreen](../../lib/ui/features/chat/views/conversation_tasks_screen.dart)负责页面订阅生命周期与
审批、取消、恢复和重试的交互；[ConversationTasksPage](../../lib/ui/features/chat/views/conversation_tasks_page.dart)
只展示 ViewModel 状态。列表包含当前会话的全部活动及历史任务，支持按标题、短 ID/完整 ID、当前
步骤与工具名称搜索。默认按创建时间从早到晚排列，可切换为从晚到早；状态更新时间不会改变排序。
搜索与排序在实时更新和刷新时保留，加载失败可刷新恢复。
排序按钮与搜索框保持同高；顶部不放刷新按钮。刷新位于每张任务卡片的操作行，与取消、恢复或重试
按钮使用相同尺寸及样式，重新读取当前会话的持久摘要；刷新期间禁用重复点击。首次加载失败时，
错误提示内提供重试入口。

等待卡片按持久化原因显示具体障碍：工具不可用时列出工具名，凭据、供应商配置、智能体缺失及
外部结果待核对分别提示处理方式。审批卡片展示检查点中的完整待执行参数，长命令不会被短摘要截断。

摘要携带持久化创建时间；旧状态消息缺少该字段时使用其原更新时间，读取兼容且不修改原消息。

任务摘要显示输入、输出 Token 统计，收起时仍可查看。与消息执行状态共用统计组件、输入/输出图标、
字号、间距及次级文字颜色，窄屏自然换行，不增加边框或内部滚动区。统计累计已保存的接受回执、
后台模型调用及终态润色用量；同次调用的流式更新合并后只计一次，各轮调用和失败重试分别累加。
后台调用用量与进度事件在同一事务中写入现有用量表，投影可重建，刷新和重启不会重复累计。
终态消息仅记录自身的润色用量，避免重复计算任务总用量。只统计供应商已返回且成功保存的数据，
未记录的历史用量不估算；无记录显示 `—`，明确返回零用量则显示 `0`。无需数据库迁移。

任务项展开后显示执行状态与执行流程，两个区域均无包裹边框、支持独立折叠，标题与任务摘要左对齐。
执行状态先汇总已完成、进行中、需关注及已停止的调用数量，再列出各次调用；状态徽标与消息共用。
任务内调用徽标使用与任务状态一致的语义配色及淡色底：成功与结果复用为绿色、执行中为蓝色、
待审批与中断为琥珀色、失败与拒绝及超时为红色，已请求、取消、跳过及未知状态使用中性色。
徽标前景与背景按明暗主题统一生成，并保留具体状态文字。
工具和命令统一为调用记录，收起时显示名称或命令预览、来源、耗时及重试次数；按需展开查看完整命令、
工作目录、其他参数、结果与错误。命令结果保留退出码、stdout 和 stderr。各字段可选择文本或一键复制，
复制操作反馈成功或失败。长输出自然展开，只随外层任务列表滚动，任务内不创建滚动区域或滚动条。

执行流程按事件序号从新到旧排列，按本地日期分组，以时间线串联事件。默认显示关键进展，切换“全部记录”
可查看检查点等完整流水。实时刷新保留区域与调用的展开选择，以及流程筛选；收起区域不会接收键盘焦点或
暴露隐藏内容的读屏节点。明暗主题共用 shadcn 语义颜色与排版，窄屏文字和操作自然换行。
流程图标与任务状态徽标共用配色：执行为蓝色、成功为绿色、失败为红色、等待与重试为琥珀色、
暂停为紫色、取消请求为橙色，排队与已取消为中性色。验证完成按实际验证结论着色，终态按已提交的
任务结果着色；结论缺失时保持中性。事件文字与图标形状保留，颜色作为辅助提示。

[GetConversationTaskExecution](../../lib/domain/use_cases/get_conversation_task_execution.dart)
校验会话和 bot 归属，从任务自己的执行快照生成只读详情，保留跨执行段和重试的独立 attempt。
ViewModel 在展开时加载，依据已提交 revision 刷新，合并读取期间到达的新进度；收起后保留缓存，
加载失败可单独重试，页面销毁后的迟到结果不触发更新。

工具参数与结果详情随原有工具事务持久化到 `arguments_summary` 和 `detail`；简短的
`result_summary` 继续用于进度与证据。结构化数据在落库前脱敏，参数最多保留 64,000 字符，
输出详情最多保留 32,000 字符，超限输出带截断标记。步骤事件保存当时的步骤摘要，计划调整
不会改写旧事件。此改动无需数据库迁移；旧记录展示已有状态与摘要，未保存的历史命令/输出无法补回。

## 状态选择与确定性卡片

[SelectConversationTask / PresentConversationTaskProgress](../../lib/domain/use_cases/present_conversation_task_progress.dart)
负责选择、保存状态消息和启动可选润色：

| 输入 | 选择结果 |
| --- | --- |
| 显式任务 ID | 验证会话归属；只读该任务或显示未找到 |
| 无 ID、一个活动任务 | 直接展示该任务 |
| 无 ID、多个活动任务 | 展示短 ID、标题和状态，可通过任务页管理 |
| 无活动任务 | 展示最近终态；没有任务则显示本地化说明 |

结构化引用直接调用领域查询；自然语言问题由前台模型返回 `TaskStatusRequest`，随后读取
相同的持久化事实，不启动工具循环。任务页展示当前快照，时间线卡片保留查询当时的版本。
打开任务页、搜索、排序和刷新只读取摘要，不创建状态消息或调用模型。

[ConversationTaskCard](../../lib/ui/features/chat/views/conversation_task_card.dart)呈现状态、执行阶段、
已完成/总步骤、当前步骤、最近工具、审批与时间、等待原因、恢复次数、验证状态和更新时间。
步骤使用 `3/5`，不推断百分比、完成时间或剩余时间。桌面使用 shadcn 语义 token，动作可用键盘
访问，状态带文字和屏幕阅读标签；窄屏工具栏与动作换行，任务列表使用独立滚动区域。

## 同一 revision 的卡片与文字

确定性状态消息先提交，再执行可选润色。消息保存 `taskId`、`summaryRevision`、完整净化摘要及
最终文本；多任务选择消息保存各候选的摘要。序列化与读取由
[TaskSummaryRecord](../../lib/data/models/task_summary_record.dart)负责，schema 版本以
[DatabaseService](../../lib/data/services/database_service.dart)为准。新建 schema 不迁移旧数据库。

[NarrateConversationTaskProgress](../../lib/domain/use_cases/narrate_conversation_task_progress.dart)
只发送净化摘要、语言和应用允许的表达。每次最多两秒；格式或事实不合格最多修复一次，供应商
不可用、错误或超时直接回退。取消、关闭 Provider session 不影响正在执行的任务。

[TaskProgressNarrationPolicy](../../lib/domain/services/task_progress_narration_policy.dart)校验完整 JSON
身份、revision 和全文语法；当前允许单行距/双行距的完整事实表达，模型只能选择这些表达。
这种有界润色不会自由改写数字、工具、审批或终态。输入中没有完整对话、原始参数/工具输出、
密钥或 reasoning；应用支持语言的词汇与确定性回退集中在
[TaskProgressStrings](../../lib/domain/services/task_progress_strings.dart)。

润色通过[状态存储命令](../../lib/data/services/conversation_task_store_status.dart)更新原消息，
事务检查原消息身份、卡片内容和当前任务 revision。任务已推进或消息已变化则丢弃迟到文字，
保留原来的卡片/文本，不产生额外回复。提交通知使消息缓存失效，页面使用新的持久消息内容，
并保留当前阅读位置。状态与回执属于操作消息，不显示模型事实已验证标记。

## 持久命令与安全重试

- 审批/拒绝、取消和配置恢复使用当前摘要 revision 执行领域命令，先落库后更新展示。
  重复或过期动作返回可恢复错误；长期等待及重启后的审批仍有效。
- `cancelRequested` 显示正在取消；取消对账及唯一终态提交后才显示已取消。
- 凭据/必要配置等待明确提示先更新配置，再执行“重新检查并继续”。普通聊天不修改任务目标。
- 创建失败的“重试发送”复用原输入、turn、冻结计划和接受身份；状态保存失败只重试原状态消息，
  不再次分流。取消的前台请求不提供重放令牌。
- 终态重试先由[PrepareConversationTaskRetry](../../lib/domain/use_cases/prepare_conversation_task_retry.dart)
  验证会话/bot 归属、`canRetry` 和副作用状态必须为 `none`。对账完成的外部写入也不能自动重放。
  用户检查可编辑输入和当前模型/验证策略后创建新 turn、新任务，并通过不可变 `retryOfTaskId`
  关联旧任务；旧附件不会盲目继承。确认期间策略变化要求重新检查。
  dispatcher 要求重新生成后台计划，接受事务再次检查重试资格，旧终态保持不变。
- 删除有活动任务的会话前说明影响；请求取消后保留会话、证据和任务，待对账结束再删除。
  bot 有活动任务时禁止删除，并显示具体原因。数据库重复执行删除保护。

## 指标与验证

`PresentConversationTaskProgress.narrate.metrics` 暴露卡片可用延迟（查询至确定性消息提交）、
润色总延迟、请求数、模型调用数、修复数、回退数、迟到丢弃数与 `fallbackRatio`。
这些是进程内累计值；首帧绘制及真实模型语言质量仍属于产品验收测量。

- [生产组合根与聊天页面流程](../../test/ui/features/chat/views/chat_task_flow_test.dart)：后台继续聊天、
  页面重建、同消息润色刷新、唯一终态及时间线顺序；实际 SQLite/dispatcher/runner/scheduler/finalizer，
  外部 Provider 与工具通过构造注入替代，不访问外部服务。
- [前台生命周期](../../test/ui/features/chat/view_models/chat_foreground_dispatch_test.dart)：重复提交、
  取消、接受后释放输入、原身份重试、状态保存恢复和非阻塞润色。
- [任务 ViewModel](../../test/ui/features/chat/view_models/conversation_tasks_view_model_test.dart)：重入、
  全部历史任务、搜索排序、持久取消、过期命令、长时间审批及数据库重启、配置恢复和重试去重。
- [任务页](../../test/ui/features/chat/views/conversation_tasks_page_test.dart)与
  [页面导航](../../test/ui/features/chat/views/conversation_tasks_navigation_test.dart)：搜索、排序、刷新、
  明暗主题和窄屏布局、工具栏与会话列表入口、返回后草稿保留。
- [卡片与重试对话框](../../test/ui/features/chat/views/conversation_task_card_test.dart)：所有生命周期状态、
  手机/桌面宽度、键盘、语义标签与历史卡片动作限制。
- [状态持久化](../../test/domain/use_cases/present_conversation_task_progress_test.dart)、
  [润色策略](../../test/domain/services/task_progress_narration_test.dart)、
  [Provider 边界](../../test/data/services/ai/task_progress_polisher_test.dart)、
  [任务重试](../../test/domain/use_cases/conversation_task_retry_test.dart)：选择、事务回滚、重启读取、
  版本隔离、事实伪造、一次修复、超时/失败回退、多语言和禁止副作用重放。
