# Stars 文档

本目录只保留需要随代码持续维护的文档。项目介绍和开发入口以仓库根目录的
[英文 README](../README.md) 为准；中文用户可从[简体中文 README](README_zh-CN.md)
开始阅读。

## 文档导航

| 分类 | 文档 | 用途 |
| --- | --- | --- |
| 项目入口 | [简体中文 README](README_zh-CN.md) | 功能、环境要求、运行方式和贡献入口 |
| 架构 | [应用架构](architecture.md) | 分层职责、依赖方向、代码规模门禁和 Review 清单 |
| 桌面规范 | [桌面端界面规范](specs/desktop-ui.md) | 布局、断点、视觉、可访问性和验收基线 |
| 桌面规范 | [桌面组件矩阵](specs/desktop-components.md) | 组件、主题 token、通知和视觉回归的唯一入口 |
| 功能规范 | [会话事实化后续工作](specs/conversation-grounding-future-work.md) | 已交付能力之外、尚未排期的可信性扩展 |
| 功能设计 | [Provider 原生工具证据归一化](specs/provider-native-tool-evidence-normalization.md) | FUT-GRD-001 的架构、分阶段计划与验收门禁 |
| 实现参考 | [Skill 脚本沙箱](reference/skill-script-sandbox.md) | 安全边界、执行协议、授权、部署与排障 |
| 实现参考 | [会话 Loop 的事实依据与防幻觉协议](reference/conversation-loop-grounding.md) | 工具证据、声明门禁、跨轮信任与落地验收标准 |

## 代码事实来源

容易快速变化的清单不在文档中手工复制，直接以代码和自动化测试为准：

| 内容 | 事实来源 |
| --- | --- |
| 供应商入口与默认地址 | [`provider_catalog.dart`](../lib/domain/models/provider_catalog.dart) |
| 内置模型与能力 | [`built_in_model_catalog.dart`](../lib/data/services/ai/built_in_model_catalog.dart) 及其测试 |
| Provider 适配器 | [`lib/data/services/ai/`](../lib/data/services/ai/) |
| 当前数据库结构 | [`database_service.dart`](../lib/data/services/database_service.dart) 及 Schema 测试 |
| 架构与发布门禁 | [`test/architecture/`](../test/architecture/) |
| 用户可见变更 | [`CHANGELOG.md`](../CHANGELOG.md) |

## 维护规则

- 文档描述当前行为或长期约束，不保留已经完成的方案草稿、审计报告、任务清单和带日期的
  临时调研快照；这些过程信息由 Issue、Pull Request 和 Git 历史承载。
- 功能落地时，把仍然有效的安全边界、操作协议和验收标准整理进对应的长期文档，再删除
  过程稿。
- 会频繁变化的供应商、模型、字段和文件列表应链接到代码事实源，避免维护第二份清单。
- 重命名或移动文档时同步更新仓库内链接；删除文档前确认其长期结论已经进入代码、测试或
  当前文档。
- 新增长期文档时归入 `specs/`（规范）或 `reference/`（实现参考），并在本页登记。
