# 07：会话交互与任务状态展示

[总计划](README.md) | [上一阶段](06-verification-and-terminal-results.md) | [下一阶段：旧路径清理](08-cutover-and-cleanup.md)

前置依赖：阶段 03、05、06。对应目标规格第 4、7、10.3、11、12、13 节。

目标：接通完整用户流程，让后台执行期间继续聊天、查询事实进度和处理任务动作。

## 实现步骤

1. 将 `ChatGenerationViewModel` 收缩为前台生命周期协调器，发送命令接入 dispatcher；移出
   长工具执行、恢复和任务终态提交。`ChatGenerationRegistry` 只管理前台会话交互。
   `_isTyping` 只反映前台分流/直接回复，任务回执事务成功后立即释放输入。
2. 新增 `ConversationTasksViewModel`，通过领域用例订阅 repository 已提交摘要，向 View 暴露
   不可变状态和任务命令。页面重入先读取持久快照；页面退出、导航或布局变化不取消后台任务。
3. 实现任务选择：有明确 ID 时校验会话归属并读取；无 ID 且只有一个活动任务时选中；多个候选
   展示短 ID、标题与状态供选择；无活动任务时呈现最近终态或无任务说明。卡片/结构化引用
   直接查询，普通自然语言由前台分流识别，不启动新的 Agent Loop。
4. 状态查询取得 `ConversationTaskProgressSummary` 后立即展示确定性卡片，涵盖生命周期、
   阶段、步骤数、当前步骤、最近工具、审批、更新时间、等待原因、恢复和验证状态。
   步骤数显示为“3/5”，不转换成未经确认的百分比或剩余时间。
5. 实现 `NarrateConversationTaskProgress` 与 `TaskProgressNarrationPolicy`，只发送同一份净化摘要、
   当前语言和必要语气上下文。校验模型返回的 `summaryRevision`、任务 ID、数值、工具、审批及
   终态声明；不合格最多修复一次，再失败或 Provider 不可用时使用确定性本地化文案。
6. 卡片和文字固定关联同一摘要 revision；若任务期间继续推进，旧润色不能覆盖新版本卡片。
   持久化状态消息的 `taskId`、`summaryRevision`、卡片摘要及最终文本，文字到达后更新同一消息，
   不额外插入一个不同事实版本的回复。操作消息不显示“已验证的模型事实”标记。
7. 接入审批、取消、创建失败重试和允许的任务重试动作。审批/取消先执行持久命令再更新展示；
   cancelRequested 显示正在取消，只有终态提交后才显示已取消。终态任务的重试应显式创建
   新任务并关联原任务，执行前重新确认适用的输入与策略，不改写旧终态或盲目重放副作用。
8. 会话删除有活动任务时提示影响并走取消/对账流程；bot 删除受相关任务约束。普通后续聊天
   不视为修改目标或补充任务输入，显式必要输入/审批通过任务命令处理。
9. 使用 shadcn 风格语义 token、紧凑层级、键盘可操作动作和屏幕阅读标签，覆盖不同宽度；
   状态不只依靠颜色表达。时间线按提交序列展示回执、状态和唯一终态消息。
10. 在 `AppDependencies` 完成 repository、dispatcher、runner、scheduler 和 recovery 组装，
    启用完整启动顺序。View 不获取 runner、不轮询数据库；运行所需 clock、ID generator、
    Provider session factory 和 tool executor 可构造注入。

## 代码落点

- 前台协调：[chat_generation_view_model.dart](../../../lib/ui/features/chat/view_models/chat_generation_view_model.dart)、
  [chat_generation_registry.dart](../../../lib/ui/features/chat/view_models/chat_generation_registry.dart)。
- 页面入口：[chat_send_commands.dart](../../../lib/ui/features/chat/views/chat_send_commands.dart)、
  [chat.dart](../../../lib/ui/features/chat/views/chat.dart)。
- 新增 `conversation_tasks_view_model.dart`、任务状态卡片与动作组件；业务逻辑放入 Domain
  查询、润色、审批、取消用例，不继续增加 View 的职责。
- 依赖组合：[app_dependencies.dart](../../../lib/ui/core/dependency_injection/app_dependencies.dart)、
  [app_dependencies_chat.dart](../../../lib/ui/core/dependency_injection/app_dependencies_chat.dart)。
- UI 基线：[桌面组件矩阵](../../specs/desktop-components.md)、[桌面端界面规范](../../specs/desktop-ui.md)。

## 验证与退出条件

- [ ] 后台运行时可继续聊天，前台重复提交仍被保护；新消息不取消或改写既有任务。
- [ ] 页面销毁/重建与布局切换后任务继续，重入显示持久进度与结果，后台更新不改变 typing。
- [ ] 单任务、多任务、无任务和显式引用查询都走正确选择流程；卡片先显示，润色不阻塞查询。
- [ ] 润色伪造事实、revision 过期、修复失败和 Provider 不可用覆盖到一致的卡片/文本回退。
- [ ] 审批长时间等待及重启后仍可处理；取消、重试、会话/bot 删除不会产生孤儿任务或重复副作用。
- [ ] Widget 测试覆盖键盘、语义标签、不同宽度和所有终态；ViewModel 测试覆盖前后台独立生命周期。

记录卡片首屏、状态润色延迟和回退比例。本阶段退出后，用户可用的完整前后台流程才具备切换条件。
