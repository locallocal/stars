# 06：跨分段验证与整体终态回复

[总计划](README.md) | [调度与恢复（已实现）](../../reference/conversation-task-scheduling.md) | [下一阶段：会话交互](07-chat-ui-and-task-actions.md)

前置依赖：阶段 02、04、05。对应目标规格第 8、9、12、13 节。

目标：把多分段执行收敛为一个可信的整体结果；失败和取消也有友好、客观且可审计的终态回复。

## 实现步骤

1. 让工具执行与证据查询以 `taskId` 为验证作用域，跨 `segmentId` 汇总成功、有效的证据。
   拒绝其他任务、未成功尝试或无效证据；保留现有证据摘要/完整性检查和写后读取验证规则。
2. 将创建时保存的 `VerificationPolicySnapshot` 贯穿候选合成、声明验证、可信状态与严格模式。
   用户运行中修改设置只影响新任务；证据积累与验证结论不由 UI 当前开关决定。
3. 接通成功路径：汇总证据 → `GroundedAnswerCandidate` → `GroundedAnswerValidator` →
   `StrictGroundingPolicy` → 最终消息。关键声明无法证明时按现有策略抑制，输出可验证的整体
   部分结果或安全失败说明；不先发送未经验证答案再更正。
4. 从已提交事件和对账事实生成失败/取消的 `TaskTerminalSummary`，包含稳定原因码、安全原因、
   已完成内容、保留产物、副作用状态、重试可能性、建议动作和取消来源。摘要不直接带异常堆栈、
   Provider 原始响应、敏感路径或参数；结果产物通过受控引用呈现。
5. 实现 `NarrateConversationTaskTerminal` 和 `TaskTerminalNarrationPolicy`。模型只改写安全摘要，
   不改变终态、完成内容、副作用或下一步；Provider 不可用或润色不合格立即使用本地化兜底。
   终态润色不套用状态润色的单次修复流程，不额外拖延终结。
6. 失败回复明确未完成、原因、保留内容与可行下一步。取消回复在已停止/对账后说明取消结果，
   如有不可回滚影响必须如实说明；`cancelRequested` 只能呈现“正在取消并核对执行状态”。
7. 接通阶段 02 的终态事务：保存 `taskId:result`、`terminalOutcome`、安全终态摘要和任务终态，
   同时更新对应事件/投影。模型生成在事务外进行，提交使用 `expectedRevision` 和有效执行所有权；
   冲突时重读事实，不能将过期成功草稿覆盖新的取消决定。
8. 区分消息信任语义：回执、状态和等待审批是操作信息；只有 directReply 与 taskResult 进入
   回答可信状态计算。失败中的部分事实仍需证据验证，取消确认本身不能因缺少外部证据被标为
   “验证失败”。
9. 提交后通知会话与预览更新，以稳定消息 ID 去重；结果按数据库提交序列加入时间线，
   不挪回原请求旁。重新启动或重新进入页面时可通过持久消息恢复同一终态显示。

## 代码落点

| 类型 | 入口 |
| --- | --- |
| 证据与候选 | [tool_evidence.dart](../../../lib/domain/models/tool_evidence.dart)、[grounded_answer.dart](../../../lib/domain/models/grounded_answer.dart)、[grounded_answer_validator.dart](../../../lib/domain/services/grounded_answer_validator.dart) |
| 复用验证策略 | [answer_trust_policy.dart](../../../lib/domain/services/answer_trust_policy.dart)、[strict_grounding_policy.dart](../../../lib/domain/services/strict_grounding_policy.dart)、[post_write_verification_policy.dart](../../../lib/domain/services/post_write_verification_policy.dart) |
| 新终态表达用例 | `lib/domain/use_cases/narrate_conversation_task_terminal.dart`、`lib/domain/services/task_terminal_narration_policy.dart` |
| 最终事务与消息 | 阶段 02 新增的任务 repository，以及 [message.dart](../../../lib/domain/models/message.dart) |

## 验证与退出条件

- [ ] 同任务跨分段证据能支撑最终声明；跨任务、失败尝试或无效证据被拒绝。
- [ ] 运行中修改验证设置不改变已接受任务策略；严格模式成功/失败均有定向测试。
- [ ] 不可恢复失败、无进展失败和用户取消都得到恰好一条友好终态消息。
- [ ] 虚假完成、虚假回滚、弱化失败或未经证实的保留内容被策略拒绝并即时兜底。
- [ ] 终态保存前后崩溃、重复回调、取消与成功竞争均只有一个结果和一个一致终态。
- [ ] 取消操作事实和失败中的事实内容正确区分验证语义；时间线没有中间结果泄露。

记录终态回复提交延迟、润色失败/兜底比例、证据覆盖和严格模式抑制数量。
