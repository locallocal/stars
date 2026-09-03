# Stars 桌面端界面规范

[返回文档导航](../README.md)

## 1. 状态与范围

本文档是 Windows、Linux 和 macOS 当前桌面界面的实现与验收基线，不再描述历史
页面路径、第三方侧栏或移动页面横向拼接方案。桌面代码位于：

- 应用壳：`lib/ui/features/app/views/desktop_layout.dart` 及同 library 的 part 文件；
- 会话：`lib/ui/features/chats/`、`lib/ui/features/chat/`；
- Bot：`lib/ui/features/bots/`；
- 共享组件：`lib/ui/core/widgets/desktop_chat_primitives.dart`；
- 语义颜色与尺寸：`lib/utils/theme.dart`、`lib/utils/desktop_theme_spec.dart`；
- 组件选型：[`desktop-components.md`](desktop-components.md)。

平台能力由 `isDesktopPlatform` 判断；窗口适配只能由 `LayoutBuilder`、约束和 breakpoint
决定。不得把平台类型与窗口宽度重新合并为同一个布尔值。

## 2. 产品方向

Stars 桌面端采用紧凑、连续的工作台布局：结构面板之间以分隔线和语义表面区分，外壳
不增加卡片式留白。目标是提高长会话、Bot 配置和工具执行信息的可读性，并保持鼠标、
键盘和辅助技术的一致操作体验。

当前方向不再使用旧稿的大圆角卡片拼接。稳定基线为：

- shell gap 与 shell padding 为 `0`；
- workspace 与 sidebar 为连续直角结构；
- 一级容器圆角 `8px`，列表项/输入/小控件圆角 `6px`；
- 结构面板无阴影，只有 overlay、popover、toast 等浮层使用弱阴影；
- 色彩来自 `StarsDesktopTokens`，尺寸和形状来自 `StarsDesktopThemeSpec`。

## 3. 信息架构

### 3.1 桌面壳

主工作区包含：

1. 顶部 50px toolbar；
2. 可调整宽度的左侧上下文栏；
3. 自适应详情工作区；
4. 聊天场景下按需出现的上下文 inspector。

默认尺寸：

| 区域 | 默认值 | 约束 |
| --- | ---: | ---: |
| Sidebar | 300px | 240–360px |
| Inspector | 360px | 280–420px |
| 详情区 | 自适应 | 最小 560px |
| 内容正文 | 最大 920px | 居中 |
| 消息气泡 | 最大 552px | 随详情区收缩 |

拖动分隔条拥有 6px 命中宽度。宽度状态由 `DesktopLayout` 持有，不写入业务模型。

### 3.2 Sidebar

Sidebar 顶部展示品牌、新建会话和 Bot 入口，中部始终保留会话列表，底部提供账户与
设置入口。列表选择、hover、pressed、focus 状态统一调用
`StarsDesktopThemeSpec.listItemDecoration`；不使用第三方 sidebar 组件。

### 3.3 Workspace

Workspace 使用 `IndexedStack` 保留功能页状态。会话详情、Bot 详情、Skill、MCP 与设置
共享同一语义表面；未选择实体时使用 `DesktopEmptyStateCard`。嵌入式详情不得再创建
移动端 AppBar 或第二层桌面 shell。

### 3.4 Inspector

宽屏时 inspector 作为 docked panel；中等宽度时作为 overlay。聊天侧栏和 inspector
overlay 必须保持单一活动状态，支持 Escape、关闭按钮、遮罩点击和焦点恢复。

## 4. Breakpoint 行为

当前断点以可用宽度为准：

| 宽度 | Sidebar | Inspector |
| --- | --- | --- |
| `< 960px` | overlay | overlay（可用时） |
| `960–1199px` | docked，压缩到 260–280px | overlay |
| `1200–1499px` | docked，使用用户调整宽度 | overlay |
| `>= 1500px` | docked | 可 docked |

`>= 800px` 且存在活动 Bot 时才提供 inspector。breakpoint 变更时必须关闭已不适用的
route/overlay，避免不可见焦点和重复导航栈。

## 5. 组件与视觉规则

### 5.1 语义 token

业务视图不得声明产品颜色。下列语义全部从 `StarsDesktopTokens` 派生：窗口、内容、
sidebar、raised surface、控件、hover、pressed、selected、separator、三级文字、focus、
success、warning、danger 与 scrim。

light、dark、high contrast 都必须有确定值；系统 high-contrast 状态可覆盖普通主题。

### 5.2 形状和间距

| 语义 | 规格 |
| --- | --- |
| Panel / container / status | 8px radius |
| Item / input / control / selection | 6px radius |
| Toolbar | 50px height |
| 桌面表单字段 | 48px height |
| 列表项 | 最小 44px height |
| 工作区 padding | 24px |
| 表单页 padding | 32/28/32/48px |

圆角、padding、宽度和高度优先增加到 `StarsDesktopThemeSpec`，不得散落同语义魔法值。

### 5.3 交互组件

组件必须遵守[桌面组件矩阵](desktop-components.md)：

- 文本按钮使用对应 variant 的 `ShadButton`；
- icon action 使用 44×44 命中区的 `StarsDesktopIconAction`；
- 菜单使用 `StarsDesktopMenu` 或 `StarsContextMenu`；
- 图标使用 Lucide；
- 临时通知只经 `showStarsNotice`；
- 可恢复错误优先使用 `StarsInlineErrorAlert`；
- overlay/dialog/sheet 维持同一 Shad theme stack。

## 6. 会话体验

### 6.1 消息流

正文最大宽度为 920px；用户气泡最大宽度为 552px。文本、Markdown、推理、工具调用、
命令和文件状态应保持清晰的层级，不用强阴影或高饱和色块区分。工具和状态信息使用
共享 status decoration，并提供名称、状态、耗时及风险/审批信息。

### 6.2 输入区

输入区固定在会话详情底部，使用共享 input radius、边框、focus ring 和语义表面。附件、
模型选择、发送/停止必须可通过键盘到达；窄宽度允许控件收缩或进入菜单，但不能溢出。

### 6.3 空态与加载

无选中会话/Bot 时使用共享空态；加载使用 `ShadProgress`。空态操作应直接进入新建或
选择流程，不创建无效 route。

## 7. 可访问性与输入方式

- icon action 的视觉图标不小于 16px，实际命中区为 44×44；
- 所有 icon-only action 同时提供 Tooltip、Semantics label 和 Focus；
- focus ring 在普通模式至少 1.5px，高对比模式 2px；
- context menu 必须提供键盘入口；Escape 关闭最上层 overlay；
- 文本高度不能依赖单一平台字体，必须允许本地化换行；
- 减少透明度和高对比偏好由语义 token 统一处理。

## 8. 架构约束

View 只负责布局、焦点、动画、路由与弹层；异步命令和状态位于 ViewModel/Use Case。
平台选择器、分享、相册、外链和安全存储只能经 domain contract 与 data 实现访问。
生产 data 实现只允许在 `AppDependencies` 组合根装配。

这些约束由 `test/architecture/model_layering_test.dart` 检查。桌面视图还会被扫描以禁止
Material 菜单、Material 产品图标、临时颜色/圆角、直接 Sonner/SnackBar 和旧 token
别名。

## 9. 验收矩阵

视觉基线位于 `test/ui/goldens/desktop_visual_matrix/`，固定覆盖：

- 宽度：1024、1280、1600；
- 外观：light、dark、high contrast；
- 语言：`zh_CN`、`en`；
- 场景：桌面壳、会话列表、Bot grid、Bot 表单、长消息/工具状态、设置页。

共 18 张组合图、108 个场景组合。更新前必须人工查看差异，并在固定 Flutter SDK 和
Linux 字体环境运行：

```bash
flutter test test/ui/desktop_visual_regression_test.dart --update-goldens
flutter test test/ui/desktop_visual_regression_test.dart
```

完整桌面流程位于 `integration_test/desktop_workflow_test.dart`：

```bash
flutter test integration_test/desktop_workflow_test.dart -d linux
```

## 10. 完成标准

桌面变更只有在以下条件全部满足时才完成：

1. 三种桌面平台共享同一组件与 token 体系；
2. 960/1200/1500 附近没有溢出、双层滚动或不可见焦点；
3. 新建会话、选择会话、发送/停止、Bot 新增/编辑/删除流程无回归；
4. 移动端外观与交互无回归；
5. 架构测试、widget tests、视觉矩阵和 Linux 集成流程通过；
6. 新增视觉语义已进入共享 spec，而不是业务文件的局部常量。
