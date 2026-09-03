# Stars 架构

[返回文档导航](README.md)

Stars 采用分层架构与 MVVM。依赖方向固定为：

```text
View -> ViewModel -> Use Case（按需） -> Repository contract
                                      ^
                                      |
                         Repository implementation -> Service
```

## 目录职责

- `lib/domain/models`：不可变领域模型的公共入口。
- `lib/domain/repositories`：UI/业务层依赖的数据契约。
- `lib/domain/use_cases`：跨步骤或可复用业务规则，例如创建会话。
- `lib/data/models`：数据库/API 原始记录与领域模型之间的映射。
- `lib/data/services`：SQLite、HTTP、平台插件等外部系统边界；AI 厂商适配器统一位于
  `lib/data/services/ai`。
- `lib/data/repositories`：缓存、映射、事务协调和变更通知的单一数据源。
- `lib/ui/core/dependency_injection`：唯一的生产依赖组合入口与 `AppScope`。
- `lib/ui/core/widgets`：跨功能复用且不访问数据源的展示与交互组件。
- `lib/ui/features/*/view_models`：不可变 UI 状态和用户命令。
- `lib/ui/features/*/views`：按功能组织的页面与私有组件，只负责渲染、布局、焦点、
  动画、路由和弹窗。

旧 `lib/services` 已完成迁移并删除：静态 CRUD 入口由 Repository 取代，数据库服务改为
实例依赖，AI Provider 通过 `AiProviderRepository` 暴露领域契约，聊天生成状态由
`ChatGenerationViewModel` 管理。生产页面使用 `AppDependencies.production()` 组合的依赖。

旧 `lib/pages` 也已完成迁移并删除。应用入口 `main.dart` 只负责平台初始化和启动；应用
壳、功能页面与组件全部位于 UI 分层目录。相机、相册和文件选择通过
`AttachmentRepository` 注入 ViewModel；消息保存、分享和外链打开通过
`MessageActionRepository` 注入 ViewModel，View 不直接调用平台插件。会话草稿由有界
`ConversationDraftRepository` 管理，并在会话删除时清理。

## 功能开发顺序

1. 在 `domain/models` 定义不可变领域对象。
2. 在 `data/services` 封装外部 API 或本地存储。
3. 在 `domain/repositories` 定义契约，并在 `data/repositories` 实现映射和缓存。
4. 只有复杂或跨 Repository 的逻辑才进入 `domain/use_cases`。
5. 在 `ui/features/<feature>/view_models` 创建 `ChangeNotifier`，通过构造函数注入依赖。
6. View 使用 `ListenableBuilder`，仅保留布局、动画、焦点、路由和弹窗逻辑。
7. 在 `AppDependencies` 注册生产实现，并为 Repository/ViewModel 添加镜像目录单元测试。

## 强制约束

- View 不导入 `sqflite`、HTTP 客户端或旧静态数据 Service。
- 除 `AppDependencies` 组合根外，View 与 ViewModel 不导入 Data 层实现。
- View 不直接导入文件选择、相册保存、系统分享或外链打开插件。
- Repository 向上只暴露领域模型，不暴露数据库记录。
- ViewModel 对列表状态使用不可变快照，异步异常转换为可呈现状态。
- 删除/更新操作先完成持久化，再发布变更通知。
- Data、Domain、UI 新分层目录启用 `strict-casts`、`strict-inference` 和
  `strict-raw-types`。
- 排除生成代码后，单个生产 Dart library/part 文件不超过 800 行；View 文件不超过
  780 行。超出时应按页面壳、section/widget、状态/命令或协调器/策略边界拆分。
- 单个测试入口不超过 1500 行；`test/widget/` 下的 Widget feature group 不超过
  1200 行。共享 fake 与 harness 放在 `test/support`，不要重新聚合到单体入口。
- AI 厂商适配器当前保留项目通用 lint；其上层领域契约与 Repository 实现继续使用严格
  分析。新增厂商响应解析优先定义 DTO，避免扩展动态 Map 边界。

## 职责边界 Review Checklist

行数是触发 review 的信号，不是拆分目标。修改接近门禁的文件时逐项确认：

- View 的页面壳只负责组合布局与路由；可命名的 section、弹窗、菜单和复杂控件进入同
  feature 的独立文件。
- ViewModel 的不可变 snapshot/state 与异步 command 分开；业务策略或跨 Repository
  协调进入 Use Case，而不是继续扩展 ViewModel。
- 构造函数出现超过 8 个直接协作者时，确认是否缺少按工作流组织的 facade/use case；
  不用 service locator 或可空依赖掩盖依赖数量。
- `build` 方法超过约 120 行、包含 3 个以上独立布局分支，或同一层同时处理布局、弹窗和
  命令时，提取有语义名称的 Widget/section。
- 单个测试入口接近 1000 行时按 feature group 拆分；各入口拥有独立 `main()`，只共享
  无状态 harness、fake 和 fixture，以便单独运行及并行定位失败。
- 拆分后至少运行原文件对应的定向测试与 `test/architecture/`；纯粹移动代码但仍共享多
  项职责，不视为完成拆分。

## 自动门禁与例外

上述约束由 `test/architecture/model_layering_test.dart` 自动检查，而不是只依赖代码审查：

- `data`、`domain` 禁止导入 `ui`；领域模型还禁止依赖 Flutter 和 `data`。
- `ui` 禁止导入 `data`，唯一例外是生产组合根
  `lib/ui/core/dependency_injection/app_dependencies.dart`。
- 所有 View 禁止直接导入文件/图片选择、相册保存、系统分享和外链插件。
- 非生成生产 Dart 文件默认保持在 800 行以内，View 保持在 780 行以内。
- 测试入口保持在 1500 行以内，Widget feature group 保持在 1200 行以内。
- 桌面专用视图必须使用共享语义 token、组件、菜单、图标动作和通知入口。

`test/architecture/release_configuration_test.dart` 另行锁定全平台发布标识和安全存储
命名。提交前必须运行整个 `test/architecture/` 目录；新增例外必须先在本文档说明边界和
退出计划，再以最小白名单加入测试。
