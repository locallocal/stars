# Stars 架构

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
- `lib/ui/features/*/view_models`：不可变 UI 状态和用户命令。
- `lib/pages`：迁移期间保留的 View 文件位置；不得直接访问数据库或静态数据 Service。

旧 `lib/services` 已完成迁移并删除：静态 CRUD 入口由 Repository 取代，数据库服务改为
实例依赖，AI Provider 通过 `AiProviderRepository` 暴露领域契约，聊天生成状态由
`ChatGenerationViewModel` 管理。生产页面使用 `AppDependencies.production()` 组合的依赖。

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
- Repository 向上只暴露领域模型，不暴露数据库记录。
- ViewModel 对列表状态使用不可变快照，异步异常转换为可呈现状态。
- 删除/更新操作先完成持久化，再发布变更通知。
- Data、Domain、UI 新分层目录启用 `strict-casts`、`strict-inference` 和
  `strict-raw-types`。
- AI 厂商适配器当前保留项目通用 lint；其上层领域契约与 Repository 实现继续使用严格
  分析。新增厂商响应解析优先定义 DTO，避免扩展动态 Map 边界。
