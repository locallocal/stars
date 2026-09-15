# 会话任务正式运行边界

[文档导航](../README.md) | [目标规格](../specs/conversation-foreground-background-model.md) |
[会话交互](conversation-task-chat-ui.md) | [调度恢复](conversation-task-scheduling.md)

## 唯一生产入口

[AppDependencies](../../lib/ui/core/dependency_injection/app_dependencies.dart) 必须提供完整的
[AppConversationTasks](../../lib/ui/core/dependency_injection/app_dependencies_tasks.dart)。文本输入由
前台 dispatcher 准备上下文并完成三路分流；后台任务由 repository 原子接受，应用级 scheduler
推进，任务恢复器接续检查点，finalizer 提交唯一终态。没有可选 dispatcher 或旧工具循环回退。

前台 ViewModel 只保存直接回复的内存流、取消和原身份重试状态。未完成正文不写消息表，页面关闭
只取消前台请求。任务执行、持久审批与取消属于应用级任务链；registry 只管理前台和独立媒体流程。
后台只有分段预算、单次请求超时及退避，没有任务总 deadline 或审批自动超时失败。

旧运行协调器、旧消息恢复 repository、旧 final answer 检查点及页面内工具审批均已删除。
共享工具执行账本、证据契约、声明验证、写后验证、文件和媒体能力继续使用。Provider 原生工具
归一化保留在 adapter 层；任务 runner 仍拒绝未经应用预先记录调用意图的原生结果，不能据此授予证据。

## 数据库与备份

[DatabaseService](../../lib/data/services/database_service.dart) 只创建当前 schema，当前基线为
**28**。旧版本打开返回 `database_rebuild_required`，更高版本返回
`database_downgrade_not_supported`。不升级、不回填、不自动删除旧库；本版本不提供历史数据迁移。
开发时只对明确的测试实例重建数据库。

- 数据与备份只使用应用自己的 `Documents/Stars` 目录。共享 `Documents/app.db` 及共享备份不会导入。
- `agent_run_answer_checkpoints` 已从 schema 删除，任务检查点和终态消息事务负责恢复。
- DTO 要求当前字段和身份；grounding 只接受当前协议，旧格式或损坏元数据不能产生可信声明。
  历史上下文不再猜测缺失的 turnId。新消息的身份生成仍由消息 repository 提供。
- 主库版本检查先于备份恢复。即使存在有效的新备份，也不能绕过旧主库的版本拒绝。
- 当前库损坏时只恢复清单版本、实际数据库版本、表/索引/触发器及完整性全部通过的当前备份。
  有效备份仍包含会话附件；没有有效备份时保留当前文件并报告恢复失败。

## 验证入口

| 边界 | 自动化覆盖 |
| --- | --- |
| 全新 schema、外键、当前备份及附件恢复、共享目录隔离 | [数据库测试](../../test/data/services/database_service_test.dart) |
| 旧主库、旧备份清单、伪装版本/结构不能越界恢复 | [切换边界测试](../../test/data/services/database_cutover_test.dart) |
| 当前 DTO、旧证据协议与缺失身份拒绝 | [记录映射测试](../../test/data/models/local_records_test.dart) |
| 前台流、取消、导航、销毁和媒体锁 | [前台生命周期测试](../../test/ui/features/chat/view_models/chat_generation_view_model_test.dart) |
| 生产任务组合、普通聊天、页面重建、数据库重启续跑与唯一结果 | [完整任务流程测试](../../test/ui/features/chat/views/chat_task_flow_test.dart) |
| 层次依赖、组件职责、桌面组件和工程配置 | [架构门禁](../../test/architecture/) |

流程测试使用真实临时 SQLite 和生产任务工厂，Provider 用可控测试实现。它验证应用侧组合与恢复，
不依赖在线模型，也不代表所有平台的系统挂起行为已完成实机验收。
