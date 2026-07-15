# Stars Flutter 桌面聊天页 Shadcn 设计规范

> 状态：桌面聊天页目标基线
>
> 更新日期：2026-07-16
>
> 适用平台：macOS、Windows、Linux
>
> 技术基线：Flutter + `shadcn_ui ^0.55.0`
>
> 适用范围：桌面聊天壳层、会话侧栏、对话工作区、Chat Composer、真实上下文 Inspector 与相关临时界面
>
> 文档优先级：本文覆盖原文件中的 Apple / Liquid Glass 设计叙事。与 `docs/specs/windows_linux_desktop_style_adjustment_spec.md` 冲突时，桌面聊天页以本文为准。

本文定义 Stars 桌面聊天页的 shadcn 视觉、布局、交互和 Flutter 落地标准。目标不是把每一块内容都包装成 Shad 组件，而是让主题、控件、状态和交互遵循同一套克制、清晰、可访问的桌面语言。

规范中的等级：

- **必须**：本次桌面聊天页重设计的验收要求。
- **保持**：已有业务语义或平台行为，不得在视觉迁移中回归。
- **可选**：有真实数据或能力支撑时才启用。
- **暂不包含**：不得在界面中伪造入口、状态或数据。

## 1. 设计结论

### 1.1 一句话目标

Stars 桌面聊天页是一块以阅读和输入为中心的 shadcn 工作区：Zinc 中性色建立层级，细边框和小圆角组织结构，真实状态通过一致组件表达，主操作始终清楚可达。

### 1.2 设计原则

- **内容先于容器**：助手回复是连续文档流；普通文本不套 `ShadCard`。
- **语义先于色值**：颜色来自 `ShadThemeData.colorScheme`，业务 Widget 不复制十六进制色值。
- **边框先于阴影**：常驻结构使用 `border` 与 `ShadSeparator`；只有 popover、sheet、dialog 等浮层使用克制阴影。
- **小圆角、紧凑密度**：基础圆角为 `6`，结构卡片不超过 `8–12`；不使用大面积胶囊或巨型悬浮卡。
- **一个操作层级**：每组最多一个 primary；destructive 只用于删除、清空等会移除数据的动作。
- **桌面行为完整**：鼠标、键盘、右键、焦点、快捷键和 IME 都是一等交互。
- **真实能力驱动**：附件、联网、深度思考和生成参数只按当前 Provider 能力显示。
- **渐进迁移**：桌面树使用 Shad；Markdown、媒体、文件选择器及移动端可继续通过 Material bridge 工作。

### 1.3 明确范围

本文包含：

- 聊天状态下可见的统一工具栏与桌面壳层。
- 会话搜索、新建、选择、打开和删除。
- 消息历史、流式回复、推理/过程信息、Markdown 与媒体。
- Chat Composer、附件、联网、深度思考、图像与视频参数。
- 当前智能体的名称、Provider、模型 Inspector。
- 与上述流程直接相关的 context menu、popover、sheet、dialog、toast 和 progress。

本文不定义：

- 智能体编辑页和“我的/设置”页内部布局。
- Android、iOS、Web 的主题与导航；这些平台保持现有 Material 实现。
- 会话重命名、置顶、未读、分组、全文历史搜索或批量操作。
- 消息编辑、重新生成、分支对话或聊天内切换模型。
- 拖放上传、Git、项目、任务、端口、后台进程等当前不存在的能力。
- 自绘窗口按钮、假 macOS 交通灯或 Flutter 内容区里的伪系统菜单栏。

## 2. 当前实现基线与迁移边界

### 2.1 已有事实

- `pubspec.yaml` 已依赖 `shadcn_ui: ^0.55.0`，无需重复引入第二套 UI 库。
- 桌面根树已经是 `ShadApp.custom → MaterialApp bridge → ShadTheme / ShadAppBuilder`。
- Light / Dark 已使用 `ShadZincColorScheme.light()` 与 `ShadZincColorScheme.dark()`。
- `ShadThemeData.radius` 当前为 `6`；用户内容字号支持 `12–24`。
- `StarsDesktopTokens` 已从 Shad color scheme 派生；`DesktopThemeTokens` 是兼容门面。
- 内容轴和输入轴上限均为 `920`；用户消息上限为 `552`。
- 侧栏、Inspector、工具栏与分栏尺寸已有稳定 token。

### 2.2 本次目标迁移

- 本期桌面聊天范围内的全部功能图标统一使用 `LucideIcons`；Provider Logo 与媒体内容可以例外。
- 多行 Composer 首选 `ShadTextarea`，而不是把 `ShadInput` 当作长期多行方案。
- Material `MenuAnchor` / `MenuItemButton` 迁移为 `ShadPopover`、`ShadContextMenuRegion` 或相应 Shad 选择控件。
- 手写分栏逐步收敛到 `ShadResizablePanelGroup` / `ShadResizablePanel`；行为不满足时使用带完整键盘能力的薄适配层。
- 临时 Inspector 通过项目 `showChatShadSheet` 封装展示 `ShadSheet`；危险确认通过 `showChatShadDialog` 展示 `ShadDialog.alert`；短反馈使用 `ShadSonner`。
- `StarsGlassSurface` 不再承担设计语义。聊天页必须使用不透明 Shad surface，不创建 `BackdropFilter`。

### 2.3 兼容规则

- Material bridge 继续服务 `MarkdownBody`、`ListView.builder`、媒体播放器、文件选择器和尚未迁移的移动端 Widget。
- `StarsDesktopTokens` 只能从 `ShadThemeData` 派生颜色，不能形成与 Shad color scheme 并行的第二套真相。
- `DesktopThemeTokens` 可以保留尺寸、间距和兼容方法；颜色最终应直接或间接读取 Shad 语义 token。
- 文档描述的是目标基线。当前代码尚未迁移的组件必须列为实施项，不能被写成“已完成”。

## 3. 信息架构

### 3.1 标准桌面结构

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ Toolbar  [侧栏]  当前智能体 / Provider · Model       [搜索][Inspector][更多] │
├──────────────────┬───────────────────────────────────┬─────────────────────┤
│ Chat Sidebar     │ Conversation Workspace            │ Context Inspector   │
│                  │                                   │ 宽屏、按需           │
│ 导航              │ Message Feed                      │                     │
│ 搜索 + 新建       │                                   │ Name                │
│ 会话列表          │             回到最新               │ Provider            │
│                  │ Chat Composer                     │ Model               │
│ 账户入口          │                                   │                     │
└──────────────────┴───────────────────────────────────┴─────────────────────┘
```

### 3.2 紧凑桌面结构

```text
┌───────────────────────────────────────────────┐
│ [侧栏] 当前智能体             [新建][更多]     │
├───────────────────────────────────────────────┤
│ Message Feed                                  │
│                                               │
│                                  回到最新      │
│ Chat Composer                                 │
└───────────────────────────────────────────────┘

侧栏：左侧 ShadSheet
Inspector：右侧 ShadSheet；不得与侧栏同时打开
```

### 3.3 Flutter 组件树

```text
DesktopChatShell
├── UnifiedChatToolbar
├── ResponsiveChatBody
│   └── ShadResizablePanelGroup
│       ├── ChatSidebar
│       │   ├── PrimaryNavigation
│       │   ├── ChatSearch
│       │   ├── NewChatAction
│       │   └── ChatList
│       ├── ConversationWorkspace
│       │   ├── MessageFeed
│       │   ├── JumpToLatest
│       │   └── ChatComposer
│       └── ContextInspector（宽屏、按需）
└── DesktopOverlayHost（项目封装）
    ├── showChatShadSheet → showShadSheet + ShadSheet
    ├── ShadPopover / ShadContextMenuRegion
    ├── showChatShadDialog → showShadDialog + ShadDialog
    └── ShadSonner
```

壳层只保留一个统一工具栏。`ChatPage` 在嵌入桌面壳层时不得再绘制第二个 AppBar。

## 4. 响应式与可调分栏

### 4.1 自定义 Shad breakpoints

Stars 不直接照搬 shadcn_ui 默认 Web 断点。桌面聊天页把现有 `800/960/1200/1500` 阈值与新增 `1800` 超宽档放入仅包裹 `DesktopChatShell` 的局部 `ShadThemeData.breakpoints`；不得改写应用根 theme 的 breakpoints，以免影响范围外的 Bot、设置、Dialog 与 Sonner 响应式行为。

| Breakpoint | 起点 | 布局 |
| --- | ---: | --- |
| `tn` | `0` | `0–799`：单工作区；侧栏为左 Sheet；Inspector 不可 dock |
| `sm` | `800` | `800–959`：工作区优先；侧栏与 Inspector 均为 Sheet，互斥显示 |
| `md` | `960` | `960–1199`：侧栏 docked，宽 `260–280`；Inspector 为右 Sheet |
| `lg` | `1200` | `1200–1499`：侧栏 docked、可调；Inspector 为右侧 overlay / Sheet |
| `xl` | `1500` | `1500–1799`：Inspector 可按需 docked |
| `xxl` | `1800` | `>=1800`：保持三栏能力，内容轴继续限宽，不随窗口无限扩张 |

`DesktopChatShell` 占满窗口时可用 `ShadResponsiveBuilder` 或 `context.breakpoint` 表达大区间；`0.55.0` 两者读取 MediaQuery 宽度，不代表任意子树的剩余空间。嵌套区域必须用 `LayoutBuilder`，并以 `chatTheme.breakpoints.fromWidth(constraints.maxWidth)` 计算局部 breakpoint。不得用操作系统名称、物理屏幕尺寸或设备类型代替实际可用约束。

### 4.2 核心尺寸

| Token | 默认值 | 约束 |
| --- | ---: | --- |
| 最低完整功能窗口 | `800 × 600` | 单工作区流程必须可完成 |
| Toolbar | `50` | 单一工具栏 |
| Sidebar | `300` | `240–360`；`960–1199` 限为 `260–280` |
| Inspector | `320` | `280–380` |
| Workspace 最小宽度 | `560` | 不足时先关闭 Inspector，再把 Sidebar 改为 Sheet |
| Message / Composer 内容轴 | `920` | 水平居中 |
| 用户消息最大宽度 | `552` | 窄窗时不超过可用轴的 `88%` |
| 分栏命中区 | `6` | 可见分隔线 `1` 或 hairline |
| 控件视觉高度 | `32–36` | 透明命中区至少 `44 × 44` |

### 4.3 分栏行为

- `md` 及以上使用水平 `ShadResizablePanelGroup`，Panel id 必须稳定。
- Shad panel 的比例尺寸由 `目标像素宽度 / 当前 group 可用宽度` 计算，再按像素最小/最大值反算并 clamp。
- Sidebar 与 Inspector 各自保留最近一次会话内宽度；应用重启后的持久化是可选增强，不属于本期完成声明。
- 穿越断点时不丢失最近一次 docked 宽度；返回宽屏后恢复并再次 clamp。
- resize handle 支持鼠标拖动、双击恢复默认、方向键 `8px` 步进、`Shift + 方向键` `24px` 步进和可见 focus ring。
- 高度 `<680` 时缩小上下留白、把 Composer 文本区最大高度降至 `120`；发送、停止与附件入口不能被隐藏。
- `tn <800` 是窗口被异常缩窄时的韧性兜底，不是完整功能尺寸；必须无异常、无横向 overflow 且可继续聊天，但 Inspector 可隐藏。`800 × 600` 起才执行完整功能与 `200%` 文字验收。

### 4.4 Overlay 规则

- `tn/sm` 的 Sidebar 与 Inspector 不得同时打开。
- Sheet 打开后焦点进入面板，`Esc` 关闭，关闭后回到触发按钮。
- Sidebar Sheet 从左侧进入；Inspector Sheet 从右侧进入，桌面模式 `draggable: false`。
- Sheet 宽度统一为 `min(targetWidth, viewportWidth - 32)`；Sidebar target 为 `300`，Inspector target 为 `320`，任何宽度都不能溢出 viewport。
- 从 overlay 断点进入 docked 断点时，先关闭 route，再按原显隐意图渲染 docked panel；从 docked 进入 overlay 时不自动弹出 Sheet，只保留工具栏入口与最近宽度。
- 遮罩可点击关闭，但不能成为唯一关闭方式。

## 5. Shad 视觉系统

### 5.1 Theme 基线

应用根 theme 继续负责 Zinc Light/Dark、High Contrast、文字与 radius。聊天页只从根 theme `copyWith` 局部布局和结构覆盖：

```dart
Widget buildStarsChatThemeScope(BuildContext context, Widget child) {
  final baseTheme = ShadTheme.of(context);
  final chatTheme = baseTheme.copyWith(
    breakpoints: ShadBreakpoints(
      tn: 0,
      sm: 800,
      md: 960,
      lg: 1200,
      xl: 1500,
      xxl: 1800,
    ),
    cardTheme: baseTheme.cardTheme.copyWith(
      shadows: const [],
    ),
    resizableTheme: baseTheme.resizableTheme.copyWith(
      dividerSize: 5,
      dividerThickness: 1,
      resetOnDoubleTap: true,
      showHandle: false,
    ),
  );

  return ShadTheme(data: chatTheme, child: child);
}
```

该片段保留根 theme 已计算的 Zinc、High Contrast 与 text theme；`cardTheme.shadows` 覆盖库默认 Card 阴影。`0.55.0` 的 pointer 宽度为 `dividerSize + dividerThickness`，所以使用 `5 + 1 = 6px` 对齐本文命中区，并隐藏会放大命中区的 handle icon。应用根部继续使用现有 `ShadApp.custom` 和 Material bridge，不重建第二套 App。`showShadDialog/showShadSheet` 不会自动捕获该局部 `ShadTheme`，所以聊天自有 route 必须通过项目 wrapper 在 builder 内重新包裹捕获的 `chatTheme`；范围外页面继续读取根 theme。

### 5.2 语义颜色

| Shad token | 聊天页用途 |
| --- | --- |
| `background / foreground` | 窗口、对话画布与主文本 |
| `card / cardForeground` | 附件、媒体、结构化过程区 |
| `popover / popoverForeground` | Popover、Context Menu、Select |
| `primary / primaryForeground` | 每组唯一的主操作，例如发送、新建聊天 |
| `secondary / secondaryForeground` | 次级按钮、静态能力摘要 |
| `muted / mutedForeground` | 元信息、代码背景、弱提示 |
| `accent / accentForeground` | hover、选中会话、轻量用户消息 |
| `destructive / destructiveForeground` | 删除、清空和真实错误 |
| `border` | Panel、Card、Message、Popover 的结构边界 |
| `input` | Search 与 Composer 输入边界 |
| `ring` | 键盘焦点与高对比度焦点 |

规则：

- 业务 Widget 不直接使用 Apple 蓝或自定义“品牌蓝”作为通用交互色。
- Stars 品牌色主要保留在应用图标和必要品牌资源中。
- 成功、警告可通过 `ShadZincColorScheme.light/dark(custom: {...})` 扩展，并从 `colorScheme.custom` 读取；也可暂由现有 `StarsDesktopTokens` 兼容，不能覆盖 Shad 核心 token。
- 选中会话使用 `accent`，不是 primary 实心按钮。
- 链接必须具有下划线或明确 hover/focus 变化，不能只靠颜色。
- Light、Dark 与 High Contrast 分别校验；状态不得只依赖红、绿或明暗。

### 5.3 表面、边框与阴影

- Window、Sidebar、Workspace 和 docked Inspector 使用不透明表面。
- 常驻 Panel 之间使用 `ShadSeparator` 或 `border`，不使用阴影。
- 普通助手文本没有 Card、边框或独立背景。
- `ShadCard` 只用于真正成组的附件、媒体、代码外围信息或过程详情。
- User message 使用 `accent` surface + `border`；不得使用渐变、发光或透明模糊。
- Popover、Context Menu、Sheet、Dialog 与 Sonner 可使用库默认阴影；聊天内 `ShadCard` 通过局部 theme 固定为无阴影。
- 聊天子树中禁止 `BackdropFilter`、全窗 blur、渐变描边和装饰性玻璃层。

### 5.4 排版

优先使用 `ShadTextTheme` 的语义样式；默认 Geist 负责拉丁文字，中文与其他文字继续使用平台 sans-serif fallback。不得随应用打包受限系统字体。

| 场景 | Shad 样式 | 目标 |
| --- | --- | --- |
| Toolbar 标题 | `h4 / large` | `15–17px / 600`，单行省略 |
| 消息正文 | `p` | 用户设置 `12–24px`，行高 `1.55–1.65` |
| 列表标题 | `small` 定制 | `13–14px / 500–600` |
| 元信息 | `muted` | `12–13px`，行高 `1.4` |
| 按钮与标签 | `small` | `12–14px / 500` |
| 代码 | 等宽 fallback | 从消息正文派生为约 `0.9em`，行高 `1.5`，继续响应系统文字缩放 |

UI chrome 可在可读范围内 clamp；消息正文、Markdown、代码和 Composer 必须完整响应用户字号。`200%` 指相对于用户当前选择字号继续缩放；布局可折叠或增高，但不能裁切内容。单一区域通常只使用 regular 与 semibold 两种字重。

### 5.5 图标

- 本期桌面聊天范围内的全部功能图标迁移到 `LucideIcons`，目标 glyph `16–18`。
- Provider Logo、用户上传头像和媒体品牌资源可以保留原样。
- 不在同一操作组混用 `Icons.*`、Cupertino Icons 与 Lucide。
- 图标按钮同时提供 `ShadTooltip` 与 `Semantics.label`；Tooltip 与 Shad Button 共享同一个 `FocusNode`，才能在键盘 focus 时显示。Tooltip 不能替代无障碍名称。
- 装饰性图标从语义树中排除。

### 5.6 间距、圆角和密度

间距使用 `4px` 网格：`4 / 8 / 12 / 16 / 20 / 24 / 32`。

| Token | 值 | 用途 |
| --- | ---: | --- |
| `radius-sm` | `4` | 行内代码、小状态 |
| `radius-md` | `6` | Button、Input、列表选中行 |
| `radius-lg` | `8` | Card、Popover、Context Menu |
| `radius-xl` | `12` | Composer、Sheet 浮层 |
| `control-h` | `32–36` | 常规桌面控件 |
| `row-h` | `52–60` | 两行会话项 |
| `toolbar-hit` | `44` | 图标按钮命中区 |

普通按钮不做胶囊；圆形按钮仅用于图标本身确有圆形语义的场景。

桌面 chrome 与 Composer 辅助操作显式使用 `ShadButtonSize.sm`，避免 `0.55.0` regular `40px` 默认值突破紧凑规格。`ShadIconButton` 放入 `44 × 44` 外层命中盒，视觉按钮 `32–36`；会话头像显式使用 `ShadAvatar(size: Size.square(32))`。

## 6. 统一工具栏

### 6.1 结构

```text
[Sidebar] [Bot Avatar] [Bot Name] [Provider · Model]
                                      [Search] [Inspector] [More]
```

- 高 `50`，背景使用 `card` 或 `background`，底部一条 `ShadSeparator`。
- 标题左对齐并与当前会话 Bot 绑定；Provider / Model 使用 muted text 或 `ShadBadge.outline`，不使用 Card。
- `tn/sm` 时显示“新建聊天”快捷入口，因为 Sidebar 不常驻。
- Search、Inspector、More 使用 `ShadIconButton.ghost` + `ShadTooltip`。
- 当前选中的 Inspector 按钮使用 secondary variant，不能只换图标颜色。
- 清空会话进入 More，并使用 `showChatShadDialog` + `ShadDialog.alert` 确认；不在工具栏常驻 destructive 按钮。
- 空白区域是否作为窗口拖拽区由宿主平台决定，不由聊天 Widget 假设。

### 6.2 状态

所有按钮具备 default、hover、pressed、focused、selected、disabled。视觉尺寸固定，状态切换不得推动标题或改变工具栏高度。

## 7. 会话侧栏

### 7.1 结构

从上到下：

1. Stars 品牌、聊天/智能体一级入口。
2. “聊天”分区标题与 `ShadButton` 新建动作。
3. `ShadInput` 搜索。
4. 会话列表。
5. `ShadSeparator` 与账户/设置入口。

搜索范围保持当前数据能力：Bot 名和会话最后一条消息。不得写成“全文搜索”。

### 7.2 会话行

- 高 `52–60`，水平 padding `8–10`，圆角 `6`。
- 左侧使用 `ShadAvatar` 或 Provider Logo，建议 `32`。
- 第一行：Bot 名 + 时间；第二行：`Provider · 最后一条消息`。
- 标题、摘要与时间均单行省略；完整时间可在 Tooltip 中展示。
- default 为透明；hover 使用 `accent`；selected 使用稳定 `accent` 并设置 `Semantics.selected`。
- 键盘焦点使用 `ring`，不能用 selected 冒充 focus。
- 更多按钮在 hover / focus-within 时增强；键盘用户始终可到达。

### 7.3 列表交互

- 方向键移动当前项，`Enter` 打开。
- 右键由 `ShadContextMenuRegion` 打开；`Shift+F10` 和菜单键通过项目 `StarsContextMenu` 适配器中的 `Shortcuts/Actions` 打开同一动作集合，并锚定当前焦点行。
- 当前动作只包含“打开”和“删除”；不展示重命名、置顶或批量操作。
- 删除使用 `ShadDialog.alert`，明确 Bot/会话对象；默认焦点放在“取消”。
- 删除选中项后保持现有行为：选中合理相邻项；无相邻项则显示未选择空状态。
- 右键菜单不能破坏工作区已有文本选择。

### 7.4 列表状态

必须区分：

- 初次 loading。
- 正常列表。
- 没有会话。
- 搜索无结果。
- 删除中。
- 删除失败并可重试。
- 列表加载失败并可重试。
- Bot 已删除或配置失效的孤儿会话；明确标记“智能体不可用”，只提供安全删除或修复引导。

“没有会话”和“搜索无结果”使用不同文案与动作。空状态可使用小型 `ShadCard`，但不得用大插画占据整个侧栏。

### 7.5 新建、清空与删除流程

- 新建聊天必须覆盖 Bot loading、无可用 Bot、Bot 加载失败、创建中、创建失败和成功，创建中禁止重复提交。
- 新建成功后选中新会话、更新列表并把焦点送入 Composer；失败时保留用户选择并可重试。
- 清空历史与删除当前会话都使用 `showChatShadDialog` + `ShadDialog.alert`。
- 当前存在可取消请求时，先确认并等待停止终态，再执行清空或删除；不可取消媒体生成期间禁止该动作并说明原因。
- 清空成功后保留当前 Bot，进入空会话状态并聚焦 Composer；失败时保留原消息。
- 删除成功后选择相邻会话；失败时保留当前选择与消息。

## 8. 对话工作区

### 8.1 阅读轴

- Workspace 是连续 `background` 画布，不放进外围大 Card。
- 内容轴最大 `920`，居中；长正文建议占 `760–840`。
- 左右 padding：宽屏 `28`，紧凑 `16`；顶部 `24`，Composer 上方保留实际高度与 `16` 间距。
- 代码、表格和媒体可使用完整 `920`；正文不随超宽窗口拉长。
- 消息历史继续使用惰性 `ListView.builder`；本期不虚构分页能力。

### 8.2 消息类型

#### 用户消息

- 右对齐。
- 最大宽 `552`；复杂附件或长代码可放宽到内容轴。
- 使用 `accent / accentForeground`、`border`、圆角 `8`、padding `12–16`。
- 文本可选择；附件在正文下方稳定排列。

#### 助手消息

- 左对齐，普通 Markdown 直接进入文档流。
- 不为每条普通回复重复头像或 Card。
- 仅在智能体发生变化或空会话欢迎区显示 `ShadAvatar`、名称与 Provider。
- Markdown 必须支持选择、标题、列表、引用、链接、代码、表格和已有媒体类型。

#### 结构化消息

- 图片、文件、音频、音乐、视频和真实过程信息可使用 `ShadCard`。
- Card 内部按“标题 / 元信息 / 内容 / 恢复动作”组织，不嵌套多层 Card。
- 加载、可用、失败、不可播放必须占用稳定布局并提供恢复动作。

### 8.3 Markdown、代码和媒体

- 行内代码使用 `muted` 背景、`radius-sm` 和等宽字体。
- 代码块使用不透明 `muted` 表面与 `border`，头部显示语言和复制按钮。
- 复制使用 `ShadIconButton.ghost`；成功通过 `ShadSonner` 简短反馈。
- Markdown 链接可 Tab 聚焦并由 `Enter` 激活；`http/https` 通过统一 `ExternalLinkAction` 交给默认浏览器，`mailto` 仅在平台 handler 可用时启用。
- `javascript/data/file` 与未知 scheme 不自动打开，只允许复制；打开失败使用 Sonner 说明并保留“复制链接”动作。
- 图片保持比例；预览使用 `ShadDialog`，已有保存、分享、关闭能力继续保留。
- 文件项显示文件名、类型和状态；语义树不朗读完整本地路径。
- 音频/视频控制继续使用现有播放器，但外壳颜色和边框必须读取 Shad token。

### 8.4 推理与过程信息

- 推理内容使用 `ShadAccordion`，流式时标题为“正在思考”，完成后为“思考完成 · 用时”。
- 完成后默认折叠；用户手动展开状态在当前消息生命周期内保持。
- `MessageProcessInfo` 有真实数据时才显示耗时、工具调用、命令执行和文件状态。
- 摘要状态使用 `ShadBadge.secondary / outline / destructive`；不能把“本地”“就绪”等静态占位当事实。
- 普通过程行保持平面，只有一组内容需要边界时才使用一个 Card。
- 流式 token 不逐字触发屏幕阅读器；只播报开始、完成、失败和取消。

### 8.5 消息操作

- 现有复制能力在桌面端提供 hover / focus-within 操作栏与右键入口。
- 操作栏至少包含复制；只有真实 service action 存在时才增加其他按钮。
- 不展示尚未实现的编辑、重新生成、分支或切换模型。
- hover 才出现的操作必须可通过 Tab、`Shift+F10` 或菜单键到达。

### 8.6 滚动与流式

- 当距底部不超过 `96` 时保持自动跟随。
- 用户向上滚动超过阈值后，流式输出不得抢回底部。
- 此时显示 `ShadButton.secondary`“回到最新”，位置在 Composer 上方，不能遮挡消息或输入。
- 点击后跳到底部并恢复自动跟随；按钮可键盘聚焦。
- 活动请求期间执行确定的切换规则：可取消的文本生成先确认停止，停止成功后再切换；不可取消的媒体生成阻止切换并说明原因。
- 请求始终绑定发起时的 chat id；即使发生异常回调，也不得把响应写入新会话。

### 8.7 历史加载状态

- 首次加载使用占位或不确定进度，并保持 Message Feed 尺寸稳定。
- 必须区分 loading、success-empty、success-content、error-retry。
- 加载失败使用 `ShadAlert.destructive` 和“重试”，不能退化为永久 spinner。
- 重新加载时保留当前会话上下文，不把历史错误误报为发送失败。

## 9. 空状态

必须区分三个场景：

1. **未选择会话**：Stars 图标 `48–56`、简短说明、一个“新建聊天”primary。
2. **已选择但没有消息**：`ShadAvatar`、Bot 名、简短 greeting；新建成功时焦点进入 Composer，选择已有空会话时保留列表焦点。
3. **会话搜索无结果**：搜索图标、当前搜索范围说明、清空搜索 secondary。

空状态使用 `background` 上的紧凑内容组；不使用 `128px` 头像、大插画或四周留白的巨型 Card。

## 10. Chat Composer

### 10.1 结构

```text
┌──────────────────────────────────────────────────────────────────┐
│ ShadTextarea：输入消息…                                          │
│                                                                  │
│ [Provider · Model] [联网] [深思] [图像/视频参数]  [附件] [发送/停止] │
└──────────────────────────────────────────────────────────────────┘
```

- 最大宽 `920`，与消息轴对齐。
- 外壳使用 `card`、`border`、`radius-xl 12`，不使用常驻阴影。
- 文本区最小 `44`、最大 `160`；高度 `<680` 时最大 `120`，超出后内部滚动。
- 底部工具栏可换行，但发送/停止始终位于右侧固定操作区。
- 工具过宽时，低频生成参数收入“更多能力” `ShadPopover`，不能挤掉主操作。

### 10.2 输入组件

- 首选 `ShadTextarea(resizable: false, minHeight: 44, maxHeight: compactHeight ? 120 : 160)`，显式覆盖 `0.55.0` 的 `80/500` 默认值，并由内容驱动高度。
- 若 `0.55.0` 在自动增高、输入法或光标滚动上无法满足契约，可暂时保留多行 `ShadInput` 适配器；行为契约优先。
- placeholder 只做提示，不承担状态或错误说明。
- focus 使用 `ring`；不使用发光描边。

### 10.3 能力控件

控件必须严格按 Provider 能力出现：

- 相机、图库/图片和文件附件；入口还必须满足当前桌面平台支持条件。
- 联网搜索。
- 深度思考。
- 图像风格与尺寸。
- 视频比例。

规则：

- Provider / Model 是只读摘要，使用 muted text 或 `ShadBadge.outline`；当前产品不提供聊天内模型切换。
- 联网与深度思考使用 `ShadButton.outline` / `secondary` 表达关闭与开启，而不是无标签图标。
- 图像与视频参数使用 `ShadPopover`；有限互斥选项可在 Popover 内使用 `ShadSelect`。
- 附件入口使用 `ShadIconButton.outline` + Tooltip + Semantics。
- Provider 能力变化后隐藏不支持的控件，并清理或明确提示已失效参数。

### 10.4 发送与停止

- 发送使用 `ShadButton`；停止使用带 `LucideIcons.square` 与文字的 `ShadButton.secondary`，因为部分回复会被保留，不把停止伪装成数据删除。
- 两者固定在同一位置、同一 `96 × 36` 尺寸，状态切换不引发布局跳动。
- 输入为空且无附件时发送 disabled。
- 只有可取消的文本流式请求显示“停止”；不可取消的图片、音频、音乐或视频生成显示明确 progress，不能提供无效停止按钮。
- “正在停止”时按钮保持原位、disabled，并防止重复点击。

### 10.5 键盘与 IME

- 只有无修饰键的 `Enter` 发送。
- `Shift/Alt/Ctrl/Meta + Enter` 交给文本输入处理，其中 `Shift+Enter` 明确为换行。
- IME composing 有效时 `Enter` 只能提交候选词，不发送消息。
- 发送成功后 Composer 保持焦点。
- `Esc` 不清空草稿，也不静默停止生成。

### 10.6 附件

- 相机、图库/图片、文件三路动作保留独立语义，不合并成含糊的“上传”；只显示 Provider 与平台共同支持的动作。
- 附件状态包含 picking、cancelled、ready、permission-denied、missing、read-error、copy-error、type/size/count-rejected、provider-rejected、unsupported、removed。
- 用户取消系统文件选择器不是错误。
- 预览位于 Composer 上方或外壳顶部，具有文件名、类型、状态和可键盘到达的移除按钮。
- 上传或读取进度使用 `ShadProgress`；只有底层提供真实字节进度时才显示百分比，否则使用 indeterminate，禁止伪造进度。
- 权限、文件读取、类型/大小/数量和 Provider 拒绝分别给出可恢复说明；失败使用内联错误，不只发瞬时 toast。
- 当前不定义拖放上传入口。

### 10.7 错误恢复与草稿

- 每个 chat id 的内存草稿继续独立保存；跨应用重启持久化为可选增强。
- 发送失败时只保留一份可恢复内容：
  - 用户消息尚未持久化：保留 Composer 草稿与附件。
  - 用户消息已经持久化：在失败回合提供重试，不再把同一内容回填 Composer。
- 不得同时留下已持久化用户消息和同内容草稿，避免重试生成重复消息。
- 活动文本请求切换会话时，使用 `showChatShadDialog` + `ShadDialog.alert` 确认“停止生成并切换”，安全默认是留在当前会话；停止确认成功后才导航。
- 当前不可取消的媒体生成期间阻止切换，并以内联说明或 Sonner 告知原因；未来若引入后台任务管理，再另行放开。
- 无论 UI 是否仍挂载，请求结果只能写入发起时的 chat id，禁止静默串线。

## 11. 生成状态模型

请求生命周期状态必须互斥：

```text
idle
  → submitting / connecting
  → active
  → completed
  ↘ stopping → cancelled
  ↘ failed / empty-response
```

| 生命周期状态 | UI 表达 |
| --- | --- |
| `idle` | Composer 可输入；满足条件时发送可用 |
| `submitting/connecting` | 稳定的内联 progress；不同时显示 typing 和 streaming |
| `active` | 根据真实活动标志显示推理、工具或正文流；可取消时显示停止 |
| `stopping` | 原位“正在停止…”，防重复操作 |
| `completed` | 结束 progress，播报完成 |
| `cancelled` | 以 `hasPartialContent` 标志决定是否保留部分回复；有内容时标记“已停止”，无内容时不创建空消息 |
| `failed` | `ShadAlert.destructive` + 可恢复动作 |
| `empty-response` | 明确说明未收到内容并允许重试 |

`active` 内的活动是正交标志，不强行互斥：

- `reasoningActive`：推理内容仍在追加。
- `toolingActive`：存在正在执行的真实工具/命令/文件活动。
- `contentStreaming`：正文或媒体元信息正在返回。

Provider 可以同时回调推理、过程与正文；消息区分别承载真实内容，但顶部只显示一个稳定的生命周期 indicator，避免多套 spinner 竞争。

补充失败规则：

- 流式中途失败时保留已有部分回复，标记“生成中断”，并把重试动作绑定到该回合。
- 停止失败或超时后显示内联错误；若请求仍活跃，恢复可停止状态，不能假装已经取消。
- 数据库持久化失败与 Provider 生成失败分开表达；内容仍在内存时提供“重试保存”或明确恢复路径。

### 11.1 请求身份、终态与所有权

- 每轮生成创建稳定 `runId`，并与发起时的 `chatId` 一起进入所有 callback、状态事件和持久化命令。
- 每个 turn 和消息还必须有稳定 `turnId/messageId`；推荐以 `runId + role` 派生助手消息唯一键，用户消息在发送 intent 创建时即分配 id。
- 所有事件由单一 reducer 校验 `chatId + runId == activeRun`；旧请求迟到的 token、error 或 complete 直接忽略，不能污染同一会话的新一轮生成。
- completed、cancelled、failed、empty-response 是带类型的终态，处理必须幂等；禁止通过 `"Request cancelled"` 等错误字符串推断取消。
- SQLite 增加 message 唯一键并做版本化 migration / backfill；用户消息与助手终态在事务中 insert-or-update。没有唯一约束时不得把 `ConflictAlgorithm.replace` 当作幂等保障。
- “重试保存”、迟到 complete 和终态重放必须 upsert 同一 `messageId`，不能重复插入消息。
- 终态内容完成持久化、状态播报和必要错误处理后，Composer 生命周期回到 `idle`；消息本身保留对应终态标签。
- 生成 owner 必须提升到不会随 `ChatPage` 重建而丢失的 chat-scoped controller / service。`ChatPage` 只订阅状态并派发 intent，不能独自拥有 Provider callback 生命周期。
- 会卸载或替换当前 `ChatPage` 的行为——切换会话、进入智能体/设置、新建、删除、清空和应用可控制的关闭/退出——都经过同一 run guard。操作系统强制终止只做 best effort；意外卸载时 owner 仍只向原 chat id 持久化。

### 11.2 Provider 取消契约

- Provider 必须显式暴露当前 run 的 `supportsCancellation`；不能用 `supportStreamResponse()` 代替取消能力。
- 当前同步 `void cancelRequest()` 不足以支撑 `stopping`。目标契约必须返回可等待结果或发出带类型 terminal event，使 UI 能区分 cancelled、failed 与 timeout。
- `stopping` 在收到 cancelled 终态后才算成功；超时后按“请求仍可能活跃”处理，并继续依靠 `runId` 过滤迟到事件。
- 在该契约完成前，停止成功/失败、停止后导航及其验收不得标记为已实现。

## 12. Inspector 与临时界面

### 12.1 Context Inspector

- 只显示当前真实字段：Bot 名称、Provider、Model。
- `xl` 及以上可 docked；更窄时使用右侧 `ShadSheet`。
- docked 形式使用 `background/card` + 左侧 `ShadSeparator`，无圆角与阴影。
- Sheet 形式最大宽 `380`，有标题、关闭按钮和独立滚动。
- 没有当前 Bot 时 Inspector 入口 disabled 或隐藏。

### 12.2 Popover 与 Context Menu

- 附件与能力参数使用锚定 `ShadPopover`。
- 会话和消息上下文动作使用项目 `StarsContextMenu` 适配器：pointer 分支组合 `ShadContextMenuRegion`，keyboard 分支用 `Shortcuts/Actions` 与受控 `ShadContextMenu(controller:, anchor:, items:)` 锚定焦点 Widget。`0.55.0` 的 Region 本身不提供 `Shift+F10` / Menu 键能力；plain `ShadPopover` 也不能直接承载依赖 `ShadContextMenuState` 的 `ShadContextMenuItem`。
- 菜单支持方向键、`Enter`、`Esc`；关闭后焦点回到触发器。
- 触发控件若不是 Shad Button，必须确保 hover detector 与 focus 行为完整。
- Context Menu 最多三个逻辑组；destructive 项位于末尾。

### 12.3 Dialog、Sheet 与 Sonner

- 危险确认：`showChatShadDialog` + `ShadDialog.alert`。
- 图片预览或需要更丰富内容的阻塞流程：`showChatShadDialog` + `ShadDialog`。
- 侧栏和 Inspector：`showChatShadSheet` + `ShadSheet`。
- 复制成功等短暂反馈：`ShadSonner` + `ShadToast`。
- 必须处理的错误保留在列表、消息或 Composer 内；Sonner 不能成为唯一错误载体。
- `showChatShadDialog/showChatShadSheet` 捕获当前 `chatTheme`，在 route builder 内重新包裹 `ShadTheme`，并传本地化 `barrierLabel`。
- Dialog / Sheet 统一传自定义 `closeIcon`：`44 × 44` 命中区、Lucide 图标、共享 FocusNode 的 Tooltip 与 `Semantics.label`，不直接使用库默认 `20 × 20` 无标签关闭按钮。

## 13. 键盘、焦点与快捷键

| 命令 | macOS | Windows / Linux |
| --- | --- | --- |
| 新建聊天 | `⌘N` | `Ctrl+N` |
| 聚焦会话搜索 | `⌘F` | `Ctrl+F` |
| 搜索别名 | `⌘K` | `Ctrl+K` |
| 显示/隐藏侧栏 | `⌃⌘S` | `Ctrl+B` |
| 显示/隐藏 Inspector | `⌘⌥I` | `Ctrl+Alt+I` |
| 设置 | `⌘,` | `Ctrl+,` |
| 发送 | `Enter` | `Enter` |
| 换行 | `Shift+Enter` | `Shift+Enter` |
| 上下文菜单 | `Shift+F10` / Menu | `Shift+F10` / Menu |
| 关闭最上层临时界面 | `Esc` | `Esc` |

`Ctrl/Cmd+K` 当前只是搜索别名，不得在文案中称为尚未实现的“命令面板”或“快速切换器”。

### 13.1 Esc 优先级

1. IME 候选与输入法自身状态优先。
2. 其余应用自有 overlay 严格按实际 overlay 栈 LIFO 关闭最上层，不按组件类型猜测层级。
3. 没有 overlay 且焦点位于非空会话搜索框时，第一次 `Esc` 清空搜索并保持焦点。
4. 其他情况下由页面忽略或交给宿主窗口。

`Esc` 不清空 Composer 草稿、不删除附件、不停止生成。系统文件选择器、平台分享面板等系统 overlay 服从平台自身规则。

### 13.2 焦点规则

- Tab 顺序与视觉顺序一致，`Shift+Tab` 反向。
- 新建会话完成后把焦点移到 Composer；切换已有会话时列表焦点保持，便于连续浏览。
- Dialog、Sheet、Popover 关闭后焦点回到原触发器。
- hover-only 操作在 focus-within 时可见。
- 所有可点击图标具有至少 `44 × 44` 命中区。
- resizer、回到最新、删除确认和媒体操作必须可纯键盘完成。

快捷键、工具栏、Context Menu 与 Tooltip 应共享同一套 `Actions/Intents`，禁止在多个 Widget 中分别硬编码业务动作。

## 14. 无障碍与本地化

### 14.1 语义

- 图标按钮提供 Tooltip 和 `Semantics.label`，并按控件类型暴露 enabled、selected、expanded 等可用状态；生成中通过可理解的 `Semantics.value` / 状态标签与 `liveRegion` 播报。
- 会话行语义包含 Bot 名、摘要、时间和 selected。
- 项目 wrapper 必须在 `ShadAccordion` 标题外补 `Semantics(expanded: ...)`；`0.55.0` 组件本身不自动提供该语义。过程状态同时使用文字与图标。
- 流式 token 不逐字播报，只播报状态迁移。
- 装饰图标、重复头像与视觉分隔从语义树排除。
- 媒体和附件使用可理解描述，不朗读本地完整路径、API Key 或敏感数据。

### 14.2 视觉

- 正文对比度目标 `>=4.5:1`，大号或粗体文字 `>=3:1`。
- focus ring 在 Light、Dark 与 High Contrast 下都可见。
- 状态不能只依靠颜色；必须同时有图标、形状或文字。
- 内容字号 `200%` 时关键文字不裁切，Composer 内滚且主操作仍可见。

### 14.3 本地化

- 所有新增或现有硬编码的桌面聊天可见文案进入 ARB。
- `message_list.dart`、`chat.dart` 中的硬编码中文属于明确迁移项。
- 中文、英文及现有语言都要测试长 Bot 名、长模型名、时间、复数与错误文案。
- 使用 `EdgeInsetsDirectional` 与方向无关的布局语义，避免未来 RTL 被硬编码 left/right 阻塞。

## 15. 动效与性能

### 15.1 动效

| 场景 | 时长 |
| --- | ---: |
| hover / pressed | `80–120ms` |
| Popover / Context Menu | `120–160ms` |
| Sheet / Sidebar | `200–250ms` |
| 状态淡化 | `120–180ms` |

- 优先使用 Shad 组件默认动效；上表是自定义动效的目标范围，其中 Sheet 接受 `0.55.0` 默认 enter `250ms` / exit `200ms`，不重复覆盖。
- 禁止弹跳、持续脉冲、流体形变、blur 动画和装饰性循环动画。
- `MediaQuery.disableAnimations` 为 true 时移除非必要位移与尺寸动画。
- 流式文本本身就是进度，不叠加逐 token 动画。

### 15.2 性能

- 消息与会话列表使用惰性构建。
- 复杂 Markdown、图片和媒体按需使用 `RepaintBoundary`，避免整个列表重绘。
- Popover、Sheet 和 Dialog 关闭后及时 dispose controller / focus node。
- 不在每条消息、每个按钮或每个列表行创建昂贵合成层。
- 性能验收使用 Flutter profile mode：`1280 × 800`、500 条消息、模拟 `20 token/s`，持续滚动、resize 与 Composer 增高 30 秒；记录参考机器和 Flutter 版本，预热后 missed-frame 比例目标 `<1%`，且无 `>100ms` 的 UI 卡死。
- 本期历史数据仍一次性从 SQLite 加载；不要在文档中声称已分页。

## 16. Shad 组件映射

| 区域 | 目标组件 | 使用约束 |
| --- | --- | --- |
| 应用主题 | `ShadApp.custom`、`ShadThemeData`、`ShadZincColorScheme` | 保留 Material bridge 与 `ShadAppBuilder` |
| 响应式 | `ShadBreakpoints`、`ShadResponsiveBuilder` | 全窗用 MediaQuery breakpoint；子树用 `LayoutBuilder + fromWidth` |
| 分栏 | `ShadResizablePanelGroup`、`ShadResizablePanel` | 补键盘、像素 clamp 与 controller 同步适配 |
| 分隔 | `ShadSeparator` | 常驻结构不用阴影 |
| 搜索 | `ShadInput` | 仅搜索 Bot 名与最后消息 |
| Composer | `ShadTextarea` | 显式 `resizable: false`、`minHeight: 44`、`maxHeight: 120/160`；行为不满足时允许适配 |
| 主次操作 | `ShadButton` variants | 桌面 chrome 使用 `ShadButtonSize.sm`；每组最多一个 primary |
| 图标操作 | `ShadIconButton` + `ShadTooltip` | `44 × 44` 外层命中盒；共享 FocusNode 与 Semantics |
| 头像 | `ShadAvatar` | 会话行显式 `size: Size.square(32)`；Provider Logo 可用现有资源 |
| 状态摘要 | `ShadBadge` | 仅真实状态 |
| 附件/媒体/结构区 | `ShadCard` | 局部 theme 无阴影；不用于普通助手文本 |
| 推理详情 | `ShadAccordion` | 完成后默认折叠 |
| 参数与能力 | `ShadPopover`、可选 `ShadSelect` | 不推挤对话布局 |
| 右键菜单 | `StarsContextMenu` → `ShadContextMenuRegion` / 受控 `ShadContextMenu` / `ShadContextMenuItem` | 项目适配 `Shift+F10`、Menu 键、锚点与焦点恢复 |
| Sidebar / Inspector overlay | `showChatShadSheet` → `showShadSheet` + `ShadSheet` | 捕获局部 theme；桌面 `draggable: false` |
| 危险确认 | `showChatShadDialog` → `showShadDialog` + `ShadDialog.alert` | 捕获局部 theme；安全默认焦点 |
| 图片预览 | `showChatShadDialog` → `showShadDialog` + `ShadDialog` | 保存、分享、关闭 |
| 内联错误 | `ShadAlert.destructive` | 带恢复动作 |
| 上传/连接进度 | `ShadProgress` | 确定/不确定按真实进度 |
| 短反馈 | `ShadSonner`、`ShadToast` | 不承载必须处理的错误 |
| 图标 | `LucideIcons` | Provider Logo 例外 |

## 17. Flutter 文件映射与实施规则

### 17.1 当前入口

| 区域 | 文件 |
| --- | --- |
| 桌面根主题与挂载 | `lib/main.dart` |
| Shad theme、语义 token、尺寸 | `lib/utils/theme.dart` |
| 桌面工具栏、侧栏、Inspector、分栏 | `lib/pages/desktop_layout.dart` |
| 会话列表 | `lib/pages/chats.dart` |
| 会话行与右键动作 | `lib/pages/chats/chat_item.dart`、`lib/pages/chats/chat_list_builder.dart` |
| 对话状态与滚动 | `lib/pages/chat.dart` |
| Composer | `lib/pages/chat/message_input.dart` |
| 消息与过程信息 | `lib/pages/chat/message_list.dart` |
| 空会话欢迎区 | `lib/pages/chat/welcome_view.dart` |
| 新建与清空 | `lib/pages/chats/new_chat_dialog.dart`、`lib/pages/chat/clear_chat_dialog.dart` |
| 附件选择与预览 | `lib/pages/common/attachment.dart`、`lib/pages/chat/attachments.dart` |
| Typing 与媒体 | `lib/pages/chat/typing_indicator.dart`、`lib/pages/chat/audio_player_widget.dart`、`lib/pages/chat/video_player_widget.dart` |
| Provider 状态与取消契约 | `lib/services/providers/providers.dart` 及各 Provider 实现 |
| 会话/消息加载与持久化 | `lib/services/chat_service.dart`、`lib/services/message_service.dart`、`lib/services/database_service.dart` |
| Chat、Message、过程数据模型 | `lib/model/model.dart` |
| 本地化 | `lib/l10n/` |
| Widget tests | `test/widget_test.dart` 及新增 chat tests |

### 17.2 架构规则

- Zinc、High Contrast、文字等根主题只在 `buildStarsShadTheme` 定义一次；项目 `StarsChatThemeScope` 只用根 theme `copyWith` 局部 breakpoints、Card shadow 和 Resizable 参数。
- `StarsDesktopTokens` 作为 Material 兼容层时必须从当前 Shad theme 派生。
- 尺寸 token 集中管理；业务 Widget 不散落 `16` 圆角、Zinc 色值或动画时长。
- `ShadAppBuilder` 必须包住桌面内容，保证 Tooltip、Popover、Sheet 与 Toast 的 overlay 正常。
- 项目 `showChatShadDialog/showChatShadSheet` 负责 route 内重包局部 theme、本地化 barrier label 和可访问关闭按钮。
- 项目 `StarsContextMenu` 负责右键与键盘打开同一动作集合；不能假设 `ShadContextMenuRegion` 内建键盘触发。
- desktop / mobile 分支保持明确；桌面迁移不得改变移动端主题、底部导航与输入行为。
- `ScrollController`、`FocusNode`、`ShadPopoverController` 等由拥有者创建并 dispose。
- Provider 能力判断只来自 Provider API，不在 UI 里复制 provider 名称白名单。
- 新增 chat-scoped generation controller，统一管理 `chatId/runId`、typed terminal event、取消能力、callback reducer 与持久化；`ChatPageState` 不再是唯一 owner。
- `ShadResizablePanel` 的比例只在注册时进入 controller；窗口宽度改变后，适配层必须保存像素宽度、重新 clamp，并显式同步或重建 `ShadResizableController`，不能只更新 Widget 的 `minSize/maxSize/defaultSize`。

### 17.3 实施顺序

1. **主题收口**：自定义 breakpoints，确认 Zinc、radius、文字和语义 token。
2. **图标与基础控件**：桌面聊天范围迁移到 Lucide、Shad Button/Input/Tooltip/Semantics。
3. **壳层与分栏**：单工具栏、响应式 Sidebar/Inspector、Resizable 键盘能力。
4. **消息流**：普通助手文档流、用户消息、结构化 Card、消息操作。
5. **Composer**：Textarea、Popover、附件、生命周期状态与正交活动状态、错误恢复。
6. **临时层与反馈**：Context Menu、Dialog、Sheet、Sonner、Progress。
7. **本地化、无障碍与测试**：移除硬编码文案并覆盖边界状态。

## 18. 验收标准

### 18.1 布局矩阵

必须覆盖：

| 尺寸 | 预期 |
| --- | --- |
| `799 × 600` | 仅做 `tn` 韧性与断点 smoke：无异常、无横向 overflow、仍可聊天 |
| `800 × 600` | 单工作区；Sidebar/Inspector 为 Sheet；所有核心动作可达 |
| `960 × 680` | Sidebar docked `260–280`；Inspector 为 Sheet |
| `1280 × 800` | Sidebar 默认宽；消息轴与 Composer 对齐 |
| `1500 × 900` | Inspector 可 docked；详情仍满足 `560` 最小宽度 |
| `1920 × 1080` | 内容轴不无限拉宽，三栏稳定 |

额外覆盖精确边界：`799/800`、`959/960`、`1199/1200`、`1499/1500`。交叉场景至少包括：高度 `<680`、`800 × 600 + 200%` 文字、Dark + High Contrast、长英文 + `960` 宽、Windows `125%/150%`、非整数 DPR 与 `disableAnimations=true`。

### 18.2 功能与状态

1. 未选择会话、空会话和搜索无结果有不同界面。
2. 搜索只承诺 Bot 名与最后消息，清空后恢复列表。
3. 新建聊天、清空历史和删除会话的 loading、失败、防重复、成功焦点与相邻选择规则完整。
4. Bot 被删除或配置失效的孤儿会话有明确状态和安全恢复动作。
5. Provider 能力控件准确显示；不支持的入口不存在。
6. `Enter`、修饰键换行、IME composing、disabled send 全部正确。
7. 发送/停止同位同尺寸；`supportsCancellation` 不成立时不显示假停止按钮。
8. 生命周期状态互斥；推理、工具与正文流作为正交活动可并存，界面不显示竞争 indicator。
9. 中途失败、停止失败/超时和持久化失败保留真实内容，重试不会生成重复用户消息。
10. 用户上滚后流式不抢回底部；“回到最新”恢复跟随。
11. 切会话、切一级入口、清空、删除和应用可控制的关闭/退出都经过统一 run guard。
12. `chatId + runId` 过滤迟到事件；`turnId/messageId`、数据库唯一键、事务 upsert 与 typed terminal outcome 共同保证幂等，响应不会串会话、串轮次或重复落库。
13. Markdown 链接的键盘激活、scheme 白名单、复制和打开失败状态通过测试。

### 18.3 视觉与组件

14. Light、Dark 与 High Contrast 均使用 Shad 语义 token。
15. 桌面聊天范围内全部功能图标统一为 Lucide，Provider Logo 除外。
16. 普通助手文本外层没有 `ShadCard`。
17. Model 摘要、typing indicator、普通过程行不被卡片化。
18. 常驻结构与聊天 Card 无阴影，聊天子树无 `BackdropFilter`。
19. 所有应用自有 overlay 都能以 `Esc` 关闭并恢复焦点；系统文件选择器和分享面板遵循平台规则。
20. 发送、停止、删除和错误状态不只靠颜色区分。

### 18.4 键盘、无障碍与本地化

21. 纯键盘可完成搜索、新建/选择/删除会话、发送、停止、附件和参数选择。
22. 会话 Context Menu 可由右键、`Shift+F10` 和菜单键打开。
23. 分栏可拖动、双击复位、方向键调整。
24. Semantics 覆盖会话 selected、Accordion expanded、生成状态 value/live region 和图标名称。
25. 正文放大至 `200%` 时不裁切，主操作仍可达。
26. 所有可见桌面聊天文案进入 ARB，中文和最长英文文案无 overflow。

### 18.5 性能与回归

27. `flutter analyze` 与 `flutter test` 通过。
28. 新增 ChatPage、MessageInput、MessageList 的 Widget tests。
29. 至少以 fake Provider 覆盖完整生成状态、取消契约和迟到 callback，并测试消息表 migration/backfill 与重复终态 upsert。
30. 性能场景按 `15.2` 的 profile-mode 基线记录并达标。
31. macOS、Windows、Linux 的原生窗口行为不回归。
32. Android、iOS 与 Web 的现有 Material 主题和导航不受本次桌面迁移影响。

## 19. Do / Don't

### Do

- 使用 Zinc 语义色、细边框、小圆角和明确 focus ring。
- 让助手回复保持文档流，只把真正成组的内容放进 Card。
- 使用 Shad Button、Textarea、Popover、Context Menu、Sheet、Dialog 与 Sonner 表达对应语义。
- 保留 Provider 能力判断、IME、安全错误恢复和滚动跟随规则。
- 用 Lucide 统一桌面功能图标。
- 把聊天响应式阈值集中进局部 `ShadBreakpoints`。

### Don't

- 不继续使用 Apple / Liquid Glass、模糊材质或玻璃 primitive 作为聊天页设计基础。
- 不为展示“shadcn”而把每条消息、每个状态和每个控件都卡片化。
- 不混用 Material Menu、Material Icons、Cupertino Icons 与 Shad 控件。
- 不用渐变、发光、厚阴影、大胶囊和过度动画制造层级。
- 不把 Provider / Model 摘要伪装成可切换控件。
- 不声称支持全文搜索、重命名、重新生成、拖放、分页或持久化栏宽。
- 不让瞬时 toast 代替可恢复错误。
- 不因桌面重设计改变移动端。

## 20. 最终风格一句话

Stars 桌面聊天页以 shadcn 的方式保持安静而精确：中性表面承载内容，边框与间距建立秩序，组件只在语义需要时出现，所有真实状态都能被看见、理解并操作。
