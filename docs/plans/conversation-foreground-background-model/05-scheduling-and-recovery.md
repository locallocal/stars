# 05：调度、恢复与副作用对账

[总计划](README.md) | [上一阶段](04-segment-runner.md) | [下一阶段：验证与终态回复](06-verification-and-terminal-results.md)

前置依赖：阶段 02、04。对应目标规格第 5、6.3、10、11.4、13、15.2 节。

目标：任务在页面外持续推进，进程恢复后可继续执行，并在副作用不确定时安全等待。

## 实现步骤

1. 实现应用级 `ConversationTaskScheduler`，从数据库扫描到期可运行任务，`enqueue` 只负责
   唤醒调度。数据库是队列事实源，漏掉内存通知不能导致已接受任务永久不执行。
2. 调度先获取 lease，再创建 runner 分段；运行期间续期，退出分段时释放。所有执行进展提交
   检查 lease 身份/有效性及 revision，旧持有者的迟到结果不能覆盖接管后的任务。
3. 实现每会话最多一个 running、全局并发和 Provider 并发上限。前台单会话限制独立管理。
   `waitingForUser`、退避和两次 job 轮询之间不占执行槽；持久化下次可运行时间，重启后继续等待。
4. 实现 `RecoverConversationTasks`，扫描 queued、running、paused、cancelRequested 和可继续的
   waitingForUser。区分无效/过期 lease 与仍有效所有权；过期意味着失联，不直接生成失败终态。
   从检查点重建 Provider session，恢复同一任务身份和策略。
5. 按下表处理未完成工具尝试。外部调用发出前必须已有稳定幂等键和调用意图；外部 job 创建成功
   但句柄未落库时，借助幂等键、目标状态或 reconcile 找回执行结果。无法确认时进入明确等待。
6. 实现持久审批决定后的唤醒：仅有有效决定且满足恢复条件的任务可继续。长时间等待和重启
   不使审批自动失败；重复审批及过期 revision 必须被识别。
7. 实现取消协调：先落库 `cancelRequested`，再停止新调用并通知 runner/job；已发出的写操作
   先核对结果。完成停止或对账后向阶段 06 提供取消终态摘要，不能提前标记 cancelled。
   取消与成功结果竞争时通过事务和 revision 产生唯一终态。
8. 处理 bot、Provider、凭据缺失等恢复障碍，给出可操作的等待原因或明确失败原因。为会话/bot
   删除提供用例约束：存在非终态任务时，删除会话先取消和对账；删除 bot 阻止操作或先取消任务。
9. 在依赖组合根准备数据库 → 构造任务依赖 → 恢复 → 启动 scheduler → 展示页面的启动流程。
   应用进程可运行时推进任务；平台不允许执行时保存可恢复状态。过期 lease 的任务查询不得仅因
   数据库旧状态是 running 就宣称正在执行。移动系统终止进程后的持续计算不在承诺范围内。

## 中断尝试的恢复规则

| 已保存或外部可确认的事实 | 恢复动作 |
| --- | --- |
| 调用已有成功终态 | 复用结果与证据，不再次执行 |
| 只读或声明且支持幂等的调用中断 | 使用同一逻辑幂等键，记录新的尝试并重试 |
| 写操作可能已发出 | 查询目标状态或专用 reconcile，确认后决定继续、重试或等待 |
| 外部 job ID/句柄已保存 | 查询现有 job，不重新创建 |
| 外部 job 可能已创建但句柄未保存 | 根据幂等键或外部查询对账；无法确认则等待用户 |
| 对账超时或无法确定副作用 | 退避或 waitingForUser，不盲目重放，不声称已取消或已回滚 |

## 代码落点

- 新增 `lib/domain/use_cases/conversation_task_scheduler.dart`、`recover_conversation_tasks.dart`；
  取消、审批和删除约束按用例职责拆分，工具适配器在 Data 层实现对账协议。
- 启动接入：[app_dependencies.dart](../../../lib/ui/core/dependency_injection/app_dependencies.dart)、
  [app_dependencies_startup.dart](../../../lib/ui/core/dependency_injection/app_dependencies_startup.dart)。
- 被替代路径：[recover_agent_runs.dart](../../../lib/domain/use_cases/recover_agent_runs.dart)。
  本阶段新任务只走新恢复器，阶段 08 在完整接入后移除旧路径。

## 验证与退出条件

- [ ] 同会话串行、跨会话/Provider 限流、等待释放槽位和退避重启恢复均通过 fake clock 测试。
- [ ] 两个 runner 竞争、lease 过期接管和旧 runner 迟到提交不会造成双重推进。
- [ ] 重启后恢复 queued/paused/running，以及有审批决定或取消请求的任务。
- [ ] 工具发出前后、job 创建与句柄保存前后崩溃均不会盲目重复副作用。
- [ ] 取消请求重启后仍有效；对账完成前保持 cancelRequested 或有明确原因的等待状态。
- [ ] 删除会话/bot 的用例不会留下孤儿任务，缺少运行配置时不会复制密钥到任务记录。

记录排队/执行/等待时长、恢复和重试次数、lease 失效、无进展与对账失败指标。
