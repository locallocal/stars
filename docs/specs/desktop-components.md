# 桌面组件矩阵

[返回文档导航](../README.md)

本文档定义 Stars 桌面端唯一允许的交互与视觉组件入口。平台能力由
`isDesktopPlatform` 判断，窗口尺寸与布局断点由 `LayoutBuilder`、`MediaQuery`
或 Shad breakpoint 单独决定。

整体布局、视觉规则与验收要求见[桌面端界面规范](desktop-ui.md)。

## 组件选型

| 语义 | 桌面唯一实现 | 约束 |
| --- | --- | --- |
| Primary / Secondary / Destructive button | `ShadButton` 对应 variant | 文本动作直接使用 Shad variant，不在业务页重写产品色 |
| Icon action | `StarsDesktopIconAction` | 44×44 命中区，16–18px Lucide 图标，统一 Tooltip、Focus、Semantics |
| Click / select menu | `StarsDesktopMenu<T>` | 基于 `ShadPopover`，选中态统一使用 Lucide check |
| Secondary-click context menu | `StarsContextMenu` + `ShadContextMenuItem` | 仅用于上下文操作；普通点击菜单不得模拟右键菜单 |
| Dialog / alert / sheet | `ShadDialog`、`showChatShadDialog`、`showChatShadSheet` | 保持同一 Shad overlay stack 与局部主题 |
| Form field | `ShadInput(FormField)`、`ShadTextarea(FormField)` | 单行桌面输入使用 `StarsDesktopThemeSpec.formFieldPadding` 和 48px 外框 |
| Inline error | `StarsInlineErrorAlert` | 可恢复的表单/会话内错误就地显示 |
| Transient notice | `showStarsNotice` | 桌面统一 Sonner；移动端统一 SnackBar，业务页不直接访问二者 |
| Empty / loading state | `DesktopEmptyStateCard`、`ShadProgress` | 不额外创建卡片层级或自定义进度动画 |
| Icons | `LucideIcons` | Material `Icons` 仅保留在明确的移动端分支 |

桌面专用视图不得直接使用 `MenuAnchor`、`MenuItemButton`、Material Icon、产品色或
临时圆角。`test/architecture/model_layering_test.dart` 对上述约束以及旧主题/平台别名
执行静态扫描；通用响应式文件按源码中的 `isDesktop`/`desktopMode` 分支识别，不依赖
`desktop_` 文件名。门禁 fixture 必须保留一个通用文件名的违规样例，防止扫描范围再次退化。

## 主题来源

- `StarsDesktopTokens` 是颜色、对比度和透明度状态的唯一语义来源。
- `StarsDesktopThemeSpec` 只承载稳定尺寸、间距、形状以及从语义 token 派生的样式。
- 业务视图不定义产品颜色和圆角；`Colors.transparent` 是允许的结构性例外。
- 已删除 `DesktopThemeTokens`、`StarsDesktopTheme` compatibility facade，禁止恢复双入口。

## 视觉回归矩阵

`test/ui/desktop_visual_regression_test.dart` 的每张组合图固定包含六个真实场景：

1. 桌面壳；
2. 会话列表；
3. Bot grid；
4. Bot 新增/编辑；
5. 长消息与工具执行状态；
6. 设置页。

矩阵覆盖：

| 维度 | 取值 |
| --- | --- |
| 宽度 | 1024、1280、1600 |
| 外观 | light、dark、high contrast |
| 语言 | `zh_CN`、`en` |

18 张组合基线共覆盖 108 个场景组合，资产位于
`test/ui/goldens/desktop_visual_matrix/`。更新基线前必须人工查看差异，并运行：

```bash
flutter test test/ui/desktop_visual_regression_test.dart --update-goldens
flutter test test/ui/desktop_visual_regression_test.dart
```

完整桌面交互流位于 `integration_test/desktop_workflow_test.dart`，覆盖新增 Bot、
新建会话、发送、取消与删除：

```bash
flutter test integration_test/desktop_workflow_test.dart -d linux
```

不同宿主字体栅格化可能产生像素差异。更新 golden 应固定 Flutter SDK、Linux 测试宿主、
devicePixelRatio=1，并在 Windows/Linux 字体变更时单独审阅，不允许无审查覆盖基线。
