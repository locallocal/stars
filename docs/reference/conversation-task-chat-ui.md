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
订阅已提交摘要，并暴露不可变状态和领域命令。Data 按数据库实例与会话缓存列表快照，首次加载
合并并发读取，并按每任务 revision 合并读取期间的提交事件。页面销毁只释放订阅；重入复用缓存，
包括空列表。页面关闭期间的任务提交也会增量更新缓存，不重新读取全部历史任务。
缓存按最近访问保留至多 32 个会话，仍有订阅或加载中的会话不会被淘汰；数据库重新打开后重新加载。
清空记录、删除会话或机器人在事务提交后清理对应缓存并通知页面，迟到的旧读取不能恢复已删除任务。

## 独立任务页面

会话工具栏的“任务”入口位于“清空会话记录”右侧；会话列表项的菜单也提供入口，移动端可通过
会话列表滑动操作打开。桌面任务页沿用会话数据目录的工作区、内容宽度与留白，切换回聊天保留草稿。
聊天输入区不再放置任务面板，消息旁不再提供“查看状态”按钮。

[ConversationTasksScreen](../../lib/ui/features/chat/views/conversation_tasks_screen.dart)负责页面订阅生命周期与
审批、取消、恢复和重试的交互；[ConversationTasksPage](../../lib/ui/features/chat/views/conversation_tasks_page.dart)
只展示 ViewModel 状态。列表包含当前会话的全部活动及历史任务，支持按标题、短 ID/完整 ID、当前
步骤与工具名称搜索。默认按创建时间从晚到早排列，可切换为从早到晚；状态更新时间不会改变排序。
搜索与排序在实时更新和刷新时保留，加载失败可刷新恢复。
排序按钮与搜索框保持同高；顶部不放刷新按钮。刷新位于每张任务卡片的操作行，与取消、恢复或重试
按钮使用相同尺寸及样式，显式刷新才重新读取当前会话的持久摘要；刷新期间保留列表、筛选、排序及页码，
显示 shadcn 进度条并禁用重复点击。刷新失败保留已有快照，下次可重试。首次加载失败时，
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

## 状态查询与自然语言回复

[SelectConversationTask / PresentConversationTaskProgress](../../lib/domain/use_cases/present_conversation_task_progress.dart)
负责选择任务事实，调用模型生成回复，再保存完整消息：

| 输入 | 交给模型的事实 |
| --- | --- |
| 显式任务 ID | 验证会话归属；只读该任务，未找到时传空结果和请求的 ID |
| 无 ID、一个活动任务 | 该任务查询时的进度摘要 |
| 无 ID、多个活动任务 | 所有候选的摘要，不替用户猜选某个任务 |
| 无活动任务 | 最近终态；没有历史任务则传空结果 |

结构化引用直接调用领域查询；自然语言问题由前台模型返回 `TaskStatusRequest`，随后读取
相同的持久化事实，不启动工具循环。查询结果与用户原问题一起发送给当前 Bot 的独立模型会话。
模型用用户语言自行组织回答，说明与问题有关的实际进展、障碍或需要用户做的事；没有固定句式、
文案候选表或字段拼接回退。多个任务或空结果也由模型结合原问题说明，不凭空选择或补全进度。

聊天通过现有 `MessageList` 消息气泡呈现可选择的 Markdown 文本，沿用 shadcn 主题、复制和
键盘操作，不再附加完整查询字段卡片。任务页的
[ConversationTaskCard](../../lib/ui/features/chat/views/conversation_task_card.dart)继续展示结构化状态、
步骤、审批、等待原因与时间。打开任务页、搜索、排序和刷新只读取摘要，不调用模型。

## 查询快照与消息提交

[NarrateConversationTaskProgress](../../lib/domain/use_cases/narrate_conversation_task_progress.dart)
只发送净化摘要、用户原问题、目标语言和可选任务引用；不发送完整对话、原始工具参数/输出、
凭据或 reasoning。失败/取消摘要包含已记录的原因、已完成工作和副作用状态，帮助模型作具体说明。
提示词要求区分工具成功与任务完成，不推断完成百分比或剩余时间，将记录中的文字视为数据。

[TaskProgressNarrationPolicy](../../lib/domain/services/task_progress_narration_policy.dart)只检查回复是否
为非空、有界的自然语言内容，拒绝 JSON 或整段代码围栏；它不以固定文案白名单判定答案，也不
声称能证明自由文本中的事实。回复再经过敏感信息净化，状态消息不显示事实已验证标记。
每次调用最多 15 秒；输出格式不合格最多修复一次，供应商失败或超时直接进入现有可重试错误状态。
生成失败不保存查询结果、固定摘要或半段正文作为助手回答。

生成期间沿用前台等待和取消状态，后台任务继续执行；取消回复不会取消后台任务。只有模型回复
完整后才通过[状态存储命令](../../lib/data/services/conversation_task_store_status.dart)保存，消息携带
查询时的净化摘要及 revision。生成期间任务可继续推进，历史回复仍与原查询快照对应，不冒充实时
观测。同一 turn 的并发请求共用一次生成；数据库以原消息身份防止重复提交或覆盖已有回复。
序列化与读取由[TaskSummaryRecord](../../lib/data/models/task_summary_record.dart)负责。
提交通知使消息缓存失效，页面使用持久消息内容并保留当前阅读位置。

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

`PresentConversationTaskProgress.narrate.metrics` 记录回复提交延迟、生成总延迟、请求数、
模型调用数、格式修复数、失败数与 `failureRatio`；沿用的 `cards` / `cardLatency` 字段统计完整状态回复。
这些是进程内累计值；首帧绘制及真实模型语言质量仍属于产品验收测量。

- [生产组合根与聊天页面流程](../../test/ui/features/chat/views/chat_task_flow_test.dart)：后台继续聊天、
  页面重建、模型生成的进度回复、唯一终态及时间线顺序；实际 SQLite/dispatcher/runner/scheduler/finalizer，
  外部 Provider 与工具通过构造注入替代，不访问外部服务。
- [前台生命周期](../../test/ui/features/chat/view_models/chat_foreground_dispatch_test.dart)：重复提交、
  取消、接受后释放输入、原身份重试、状态保存恢复、生成失败重试和取消回复。
- [任务 ViewModel](../../test/ui/features/chat/view_models/conversation_tasks_view_model_test.dart)：重入、
  全部历史任务、搜索排序、持久取消、过期命令、长时间审批及数据库重启、配置恢复和重试去重。
- [任务列表缓存](../../test/data/repositories/sqlite_conversation_task_list_cache_test.dart)：重复打开的读库次数、
  空列表缓存、并发读取合并、后台增量更新、刷新失败恢复、删除期间的迟到读取、容量淘汰与数据库隔离。
- [任务页](../../test/ui/features/chat/views/conversation_tasks_page_test.dart)与
  [页面导航](../../test/ui/features/chat/views/conversation_tasks_navigation_test.dart)：搜索、排序、刷新、
  明暗主题和窄屏布局、工具栏与会话列表入口、返回后草稿保留。
- [卡片与重试对话框](../../test/ui/features/chat/views/conversation_task_card_test.dart)：所有生命周期状态、
  手机/桌面宽度、键盘、语义标签与历史卡片动作限制。
- [状态持久化](../../test/domain/use_cases/present_conversation_task_progress_test.dart)、
  [润色策略](../../test/domain/services/task_progress_narration_test.dart)、
  [Provider 边界](../../test/data/services/ai/task_progress_polisher_test.dart)、
  [任务重试](../../test/domain/use_cases/conversation_task_retry_test.dart)：选择、事务回滚、重启读取、
  查询快照绑定、自由措辞、一次格式修复、超时/失败处理、多语言和禁止副作用重放。
- [进度消息展示](../../test/ui/features/chat/views/task_progress_message_test.dart)：明暗主题、桌面/窄屏、
  可选择正文、隐藏查询字段和严格模式下的操作消息语义。
