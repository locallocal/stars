# 04：有界执行分段与长工具协议

[总计划](README.md) | [前台分流（已实现）](../../reference/conversation-turn-dispatch.md) | [下一阶段：调度与恢复](05-scheduling-and-recovery.md)

前置依赖：阶段 01、02，以及阶段 03 确定的任务输入契约。对应目标规格第 5、6、8.1、10、11 节。

目标：将一次长 Agent Run 拆为可持久恢复的执行分段，返回明确的后续动作，交由调度器安排。

## 实现步骤

1. 从 `AgentRunCoordinator` 拆出规划、执行、观察、验证准备和合成能力，建立
   `ConversationTaskRunner`。输入使用已接受任务、计划、检查点和 lease；每次调用只推进
   一个有界分段。返回完成候选、等待审批、等待外部 job、退避、继续分段或待安全终结等类型化结果。
2. 使用冻结上下文建立新的 Provider session，不保存不可序列化的 session，也不从后续普通聊天
   偷读新目标。从检查点恢复计划版本、下一步骤、工具尝试和证据游标。
3. 每次计划创建/修订、步骤开始/完成、工具排队/开始/结束、验证开始都通过阶段 02 落库。
   更新进度计数、最近有意义进展时间和摘要哈希；动态计划更新 `planRevision` 与总步骤数。
4. 从后台执行路径移除 `totalTimeout`、整体 `synthesisTimeout` 延长和审批自动超时失败。
   使用任务快照中的 `TaskSegmentLimits`，不读取当前前台 `AgentRunLimits` 的短预算。
5. 分段预算耗尽且有进展时先保存检查点再让出执行权。模型回合、工具尝试和恢复累计值保留在
   任务进度中；分段计数在新分段重置。无进展判定须同时检查摘要、证据、外部 job 状态和用户输入，
   避免把正常审批/退避等待误算为失败；达到阈值输出 `task_no_progress`。
6. 实现错误分类与重试决策：不可恢复认证/权限/参数错误立即停止当前路径；普通尝试超时记录
   失败并决定重试、重规划、等待或暂停。连续工具失败达到阈值停止当前执行路径并重规划，
   不直接把整个任务判为失败。写操作重试必须有可靠幂等保证或已完成对账。
7. 定义 `ToolStartResult`：同步完成返回 `ToolCompleted`，长任务返回 `ToolJobStarted`。
   工具适配器提供 start/poll/cancel/reconcile，保存外部 job ID 和安全恢复句柄；超过普通
   单次超时的任务必须使用此协议。轮询事件落库，轮询间和退避间返回调度器释放资源。
8. 审批用持久请求替代长时间挂起的内存 Future。写入请求和 `waitingForUser` 后结束当前分段，
   后续根据落库决定恢复。runner 检查取消和 lease 有效性，不能由页面销毁决定任务终结。
9. 分段只产出检查点、证据和受控候选，不向聊天时间线发布规划、工具观察或部分答案；最终提交
   由阶段 06 的验证与终态流程统一处理。

## 默认预算核对

实现值以规格第 6.2 节为准，本表用于阶段测试核对。

| 类别 | 默认值 |
| --- | --- |
| 分段模型回合 / 工具调用 | 32 / 48 |
| 同一调用额外重试 / 连续工具失败 | 4 / 8 |
| 分段可信性修复 / 计划修订 | 3 / 8 |
| 连续无进展分段 | 8 |
| Provider / 普通工具 / 副作用对账单次超时 | 各 15 分钟 |
| 外部 job 单次轮询超时 | 5 分钟 |
| 初始 / 最大单次退避 | 15 秒 / 30 分钟，带随机抖动的指数退避 |

这些预算不限制任务总时长、总分段数或总恢复次数；合成与验证模型请求使用 Provider 单次超时。

## 代码落点

- 新增 `lib/domain/use_cases/conversation_task_runner.dart`，协调组件按阶段与职责拆分。
- 提取入口：[agent_run_coordinator.dart](../../../lib/domain/use_cases/agent_run_coordinator.dart)、
  [agent_run_persistence.dart](../../../lib/domain/use_cases/agent_run_persistence.dart)、
  [agent_run_evidence.dart](../../../lib/domain/use_cases/agent_run_evidence.dart)、
  [agent_run_grounded_answer.dart](../../../lib/domain/use_cases/agent_run_grounded_answer.dart)。
- 定向测试参考：[agent_run_loop_test.dart](../../../test/domain/use_cases/agent_run_loop_test.dart)；
  新分段测试使用 fake clock、Provider session factory、tool executor 和 repository。

## 验证与退出条件

- [ ] 超过旧总时限/旧调用数仍可推进；达到新分段上限时按进展保存检查点并继续。
- [ ] 无进展达到规定分段数才产生安全失败原因；正常等待不增加无进展计数。
- [ ] 单次超时、不可恢复错误、重规划和退避行为有确定性测试，不靠真实等待数小时。
- [ ] 从检查点重建 session 后继续同一任务；已成功的工具尝试不会重做。
- [ ] 长 job、审批和退避会让出 runner；检查点与日志不含 reasoning 或凭据。
- [ ] 中间文本不会写入普通助手消息，结果候选保留供阶段 06 验证。
