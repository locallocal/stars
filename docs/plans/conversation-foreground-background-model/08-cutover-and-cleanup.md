# 08：旧路径清理与正式切换

[总计划](README.md) | [上一阶段](07-chat-ui-and-task-actions.md) | [下一阶段：完整验收](09-verification-and-documentation.md)

前置依赖：阶段 01—07 的退出条件全部满足。对应目标规格第 9.4、10.2、11、14 节。

目标：新任务路径完成闭环后，消除旧运行语义和数据库兼容逻辑，避免两套生命周期共同控制消息。

## 实现步骤

1. 复核生产调用链只包含前台 dispatcher 与后台任务执行链：新任务由任务 repository 接受、
   scheduler 推进、任务恢复器恢复、统一终态用例提交。移除开发期间的临时注入、实验入口和
   测试替身在生产组合中的残留；不增加旧数据兼容开关。
2. 删除旧 `RecoverAgentRuns` 及专用 recovery repository、DI 注册和旧消息恢复提交逻辑。
   工具证据、写后验证和 grounded answer 等仍被新实现使用的能力继续保留。
3. 移除后台对旧 `AgentRunLimits`、任务级 deadline、审批超时、`timedOut`/`limitExceeded`
   终态映射的依赖，以及旧 Agent Loop 的 partial 消息保存与 ViewModel 最终提交路径。
   若旧 coordinator 已无调用者，删除其未复用部分；不要仅靠包一层新类保留整套旧生命周期。
4. 清理 registry/页面对后台的停止和导航限制，确保后台 ownership 只在应用级调度器。
   `runId` 或前台取消类型如仍服务独立前台/媒体流程，按真实调用关系处理，不做全仓字符串删除。
5. 完成新 schema 的唯一新建入口，删除旧版本升级、字段回填、双读 DTO 和旧 run 专用表。
   清理现有数据库兼容检查、旧备份恢复或准备路径中任何能绕过版本边界继续打开旧库的逻辑；
   保留适用于新 schema 的完整性检查与有效备份能力。
6. 更新数据库 fixture 和测试支持代码，全部从新建 schema 启动；删除“升级旧库后继续运行”的
   过时预期。旧 run 专用测试由新任务恢复测试替代，共享证据和前台功能回归测试保留。
7. 做范围核对：项目中其他工具、文件/附件、媒体消息和安全配置功能不能因清理被误删。
   开发测试需要重建数据库时只操作明确的测试实例；本计划不提供用户历史导出或数据迁移。

## 主要清理入口

| 边界 | 现有入口 |
| --- | --- |
| 旧恢复用例与契约 | [recover_agent_runs.dart](../../../lib/domain/use_cases/recover_agent_runs.dart)、[agent_run_recovery_repository.dart](../../../lib/domain/repositories/agent_run_recovery_repository.dart) |
| 旧恢复实现 | [sqlite_agent_run_recovery_repository.dart](../../../lib/data/repositories/sqlite_agent_run_recovery_repository.dart) |
| 旧消息保存 | [chat_generation_persistence.dart](../../../lib/ui/features/chat/view_models/chat_generation_persistence.dart)、[agent_run_persistence.dart](../../../lib/domain/use_cases/agent_run_persistence.dart) |
| 数据库与启动 | [database_service.dart](../../../lib/data/services/database_service.dart)、[app_dependencies.dart](../../../lib/ui/core/dependency_injection/app_dependencies.dart) |
| 旧恢复测试参考 | [agent_run_recovery_integration_test.dart](../../../test/data/repositories/agent_run_recovery_integration_test.dart) |

这些链接记录拆分时的清理入口；实施删除/移动文件时，同步更新或移除本目录对应链接。

## 验证与退出条件

- [ ] 所有新任务只会被新恢复器和 scheduler 处理，不存在旧恢复器替它们提交失败消息的入口。
- [ ] 后台没有旧总 deadline、审批自动失败、partial 最终回答或页面持有执行状态的路径。
- [ ] 新版本直接创建目标 schema，不迁移、不回填、不双读旧数据，旧数据库不能直接继续使用。
- [ ] 被删代码已无调用者；保留的前台、媒体、工具和证据能力有相关回归覆盖。
- [ ] 新建数据库、应用启动、正常聊天、任务完成与重启恢复在生产依赖组合下通过冒烟验证。
- [ ] 无临时兼容 DTO、生产 fake 或过时测试预期残留，静态分析与架构测试通过。
