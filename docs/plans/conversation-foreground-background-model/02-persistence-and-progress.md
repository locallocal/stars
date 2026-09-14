# 02：事务持久化与进度事实

[总计划](README.md) | [上一阶段](01-domain-and-schema.md) | [下一阶段：前台三路分流](03-foreground-dispatch.md)

前置依赖：阶段 01。对应目标规格第 4.3、5.3、7、9、10、12、13 节。

目标：让任务是否存在、推进到哪里、是否等待审批和是否终态，都能仅凭数据库回答。

## 实现步骤

1. 实现 SQLite 任务 repository、DTO 映射与事务服务。将用户消息与任务接受的责任分开：
   接受事务引用已保存的用户消息，不重新创建用户输入。
2. 实现 `createWithAcknowledgement`：同事务写入任务、策略/上下文快照、初始计划、初始事件、
   进度投影和 `taskId:ack`。重复同一输入返回既有接受结果或明确冲突；提交前不发布 watch 通知。
3. 实现 `appendProgress`：校验 revision 和执行更新所需 lease，同事务追加事件，更新任务、
   投影以及该事件涉及的工具执行、审批、检查点或 job 状态。事件序号单调递增且唯一，
   不能发生仅事件写入成功、投影仍停留在旧版本的部分提交。
4. 先支持工具记录的完整生命周期：调用前保存调用 ID、幂等键、工具名与安全用途；调用后保存
   终态、耗时、净化摘要和证据引用。重试作为可审计尝试保存，不覆盖之前的失败事实。
5. 实现审批和取消命令的事务入口。审批请求与 `waitingForUser` 同事务，审批决定先保存操作者、
   决定及时间再允许恢复；取消先保存 `cancelRequested`。外部调用和模型润色不放在数据库事务内。
6. 实现 `getProgressSummary` 与 `GetConversationTaskProgress`，在同一一致性快照汇总任务、
   计划、事件、工具、审批、检查点和验证状态，输出稳定 `summaryRevision` 与净化字段。
   实现任务 ID/会话归属检查、活动任务列表和最近终态查询，支持阶段 07 的任务选择规则。
7. 实现 `watchProgress`：订阅时提供已提交快照，后续只通知提交后的变化。实现投影重建，
   由事件、工具和审批事实计算进度，重建结果须与正常写入产生的投影相同。
8. 实现原子终态提交的存储能力：`taskId:result`、任务状态、可选终态摘要及对应进度/事件
   同事务提交。先使用测试消息验证幂等，成功验证与终态文案策略由阶段 06 接入。
9. 实现 lease 获取、续期、释放和调度扫描的原子存储操作；使过期持有者和旧 revision 无法
   覆盖当前状态。调度决策、并发策略和对账流程留给阶段 05。

## 代码落点

| 类型 | 入口 |
| --- | --- |
| 新持久化实现 | `lib/data/repositories/sqlite_conversation_task_repository.dart` 及 `lib/data/models/` 下任务 DTO；事务辅助代码按职责拆分 |
| 汇总用例 | `lib/domain/use_cases/get_conversation_task_progress.dart` |
| 工具执行与证据扩展 | [sqlite_tool_execution_repository.dart](../../../lib/data/repositories/sqlite_tool_execution_repository.dart)、[sqlite_tool_evidence_repository.dart](../../../lib/data/repositories/sqlite_tool_evidence_repository.dart) |
| 现有测试参考 | [sqlite_tool_execution_repository_test.dart](../../../test/data/repositories/sqlite_tool_execution_repository_test.dart)、[database_service_test.dart](../../../test/data/services/database_service_test.dart) |

## 验证与退出条件

- [ ] 回执事务任意写入失败都会整体回滚；提交前后重试都不会重复用户消息、任务或回执。
- [ ] 事件唯一键、revision 冲突、lease 竞争和旧持有者更新拒绝均有 repository 测试。
- [ ] 工具开始/结束、计划修订、审批等待/决定、取消请求均可通过重新打开数据库读回。
- [ ] 状态查询不依赖 runner、ViewModel 或内存事件缓存；并发写入不会产生混合版本摘要。
- [ ] 投影重建覆盖计划修订、工具重试和审批恢复；净化摘要不含凭据、堆栈或原始工具参数。
- [ ] 终态事务回滚与重复提交测试通过；watch 只看到已提交记录。

从本阶段起记录持久化冲突、接受失败和进度更新指标。回执可见但任务不存在的数量必须为零。
