# Stars Flutter 桌面端 Apple 风格设计规范

> 状态：桌面端重设计基线
>
> 更新日期：2026-07-14
>
> 适用平台：macOS、Windows、Linux
>
> 产品范围：聊天、智能体、我的/设置，以及与对话直接相关的上下文能力
>
> 文档关系：本文是当前桌面视觉与交互标准；`docs/specs/windows_linux_desktop_style_adjustment_spec.md` 仅保留为历史实现背景，发生冲突时以本文为准。

本规范以 Apple 的桌面设计原则和当前 Liquid Glass 层级语义为灵感，定义 Stars 自有的桌面视觉与交互语言。目标不是逐像素复制 macOS 或某一款 Apple App，而是让 Stars 具备清晰、克制、直接、可适应的原生桌面秩序感。

Stars 是跨平台 Flutter AI 聊天助手，不是项目管理或代码任务工作台。本文只描述仓库已经具备或明确承接的业务：聊天、智能体配置、个人设置、Markdown 与媒体回复、附件、联网搜索、深度思考、生成参数、流式响应，以及当前智能体上下文。项目树、Git、Pull Request、后台进程等能力不属于本期规范。

## 1. 设计定位

### 1.1 一句话目标

Stars 桌面端是一款具有 macOS 原生秩序感的 AI 工作空间：侧边栏组织聊天与智能体，中央专注内容，检查器提供上下文，输入区随时可达。

### 1.2 Apple 风格在 Stars 中的含义

- **内容优先**：界面服务于阅读、输入和配置；容器与装饰主动退后。
- **清晰层级**：优先使用排版、间距、材质和分隔线建立层级，阴影只表达真实悬浮。
- **熟悉行为**：菜单、窗口、焦点、快捷键和右键操作遵循所在桌面平台的习惯。
- **直接操作**：选择、搜索、拖放、调整栏宽和上下文操作都应可预测，并尽量可撤销。
- **渐进披露**：高频动作直接可见，低频动作进入菜单、popover 或 inspector。
- **安静而有品牌感**：保留 Stars 图标与蓝色识别，但不让品牌色压过内容。
- **完整适应**：亮色、暗色、高对比度、减少动态效果和减少透明度都是正式界面状态。

### 1.3 明确边界

- 不绘制假的 macOS 红黄绿窗口按钮；Windows/Linux 保留各自的原生窗口装饰。
- 不复制 Apple Logo、Finder 图标、系统设置页面或 Apple 专属文案。
- 不把放大的 iOS 控件当作 macOS 控件；桌面端不使用移动端 `BottomNavigationBar`、全屏 `Drawer` 或大号 `FloatingActionButton`。
- 不随应用打包 SF Pro、SF Mono 或 SF Symbols。仅在平台和授权允许时调用系统能力，其他平台使用合法的系统字体和项目图标。
- 不承诺 Flutter 能像素级复刻原生 Liquid Glass。Stars 追求语义等价、视觉近似、稳定降级。
- 对外可称“Apple-inspired”或“macOS 风格”，不称“Apple 原生复刻”。

## 2. 产品信息架构

### 2.1 一级入口

桌面端只保留三个稳定入口：

1. **聊天**：搜索、新建、选择和删除会话；详情区显示对话。
2. **智能体**：搜索、添加、选择、编辑和删除智能体；可从智能体发起聊天。
3. **我的**：个人信息、主题、语言、字号、帮助、反馈、关于、协议与隐私。

不要把不存在的“任务、项目、站点、插件、Pull Request”放入导航或验收标准。

### 2.2 核心桌面流程

```text
聊天：侧边栏选择/新建会话 → 中央阅读与继续对话 → 可选检查当前智能体
智能体：侧边栏选择/添加智能体 → 中央查看或编辑配置 → 保存或发起聊天
我的：侧边栏选择设置分区 → 中央编辑设置 → 修改立即反馈并持久化
```

### 2.3 基础组件树

```text
StarsDesktopShell
├── PlatformWindowChrome
├── UnifiedWindowToolbar
├── ResizableDesktopBody
│   ├── DesktopSidebar
│   │   ├── PrimaryNavigation
│   │   ├── SidebarSearch
│   │   ├── ChatList / BotList / ProfileNavigation
│   │   └── ProfileFooter
│   ├── DetailWorkspace
│   │   ├── ConversationView + ChatComposer
│   │   ├── BotEditor
│   │   └── ProfileView
│   └── ContextInspector（按需）
└── DesktopOverlayHost
    ├── Menu / ContextMenu / Popover
    ├── Sheet / Dialog
    └── Toast / Progress
```

## 3. 窗口与平台壳层

### 3.1 macOS

- 使用系统菜单栏承载“Stars、文件、编辑、视图、窗口、帮助”等命令，不在 Flutter 内容区再画一行“文件 / 编辑 / 视图 / 帮助”。
- 标题栏与工具栏可形成统一视觉区域，但交通灯、窗口拖拽、全屏和双击标题栏行为仍由系统窗口层管理。
- 工具栏 leading 内容必须避开交通灯安全区；按钮区域不可误判为窗口拖拽区。
- 支持系统窗口缩放、最小化、全屏、活动/非活动窗口状态。窗口失焦时降低强调色和材质高光，但保留选择上下文。
- 菜单栏、按钮和快捷键必须共享同一套 action 定义，不能出现菜单可用而页面按钮失效的情况。

### 3.2 Windows 与 Linux

- 保留 Windows 标题栏按钮和 Linux 窗口管理器装饰，不伪造 macOS 交通灯或全局菜单栏。
- 内容层沿用 Stars 的 Apple-inspired 排版、间距和材质层级；系统级窗口行为仍服从所在平台。
- 快捷键显示 `Ctrl`，不显示 `⌘`；设置、菜单和文件选择器优先使用平台可理解的行为。

### 3.3 当前实现边界

仓库当前没有 `macos_ui`、`window_manager` 或等价的原生材质/标题栏集成依赖。因此：

- **必须可交付的基线**：使用原生窗口装饰 + Flutter 内部的实色语义表面。
- **可选的 macOS 增强**：通过 Runner 原生改造或经评估的桌面插件接入统一标题栏、系统材质和窗口状态。
- 未完成原生接入前，不用 `BackdropFilter` 假装实现窗口后方壁纸模糊，也不使用截图作为背景。

## 4. 自适应桌面骨架

### 4.1 标准结构

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ 原生标题栏 / 统一工具栏：侧栏、上下文标题、搜索、检查器、主要动作       │
├──────────────────┬───────────────────────────────────┬───────────────────┤
│ Desktop Sidebar  │ Detail Workspace                  │ Inspector         │
│                  │                                   │ （按需显示）      │
│ 聊天 / 智能体    │ 对话 / 智能体编辑 / 设置          │ 当前智能体与环境  │
│ 搜索与列表       │                                   │                   │
│                  │       Anchored Chat Composer      │                   │
│ 我的             │                                   │                   │
└──────────────────┴───────────────────────────────────┴───────────────────┘
```

侧边栏和 docked inspector 是窗口结构的一部分，使用分隔线连接；不要把它们做成四周留白、20px 以上圆角的大型悬浮卡片。

### 4.2 推荐尺寸

以下均为 Flutter logical pixels，是 Stars 的目标 token，不宣称为 Apple 官方尺寸：

| 区域 | 默认值 | 可调范围/约束 |
| --- | ---: | --- |
| 推荐窗口 | `1280 × 800` | 最低可用目标 `800 × 600` |
| 统一工具栏视觉高度 | `50` | `48–54`；系统标题栏安全区另算 |
| 侧边栏 | `300` | `240–360`，可拖动并记忆 |
| Docked inspector | `320` | `280–380`，可拖动并记忆 |
| 详情区最小宽度 | `560` | 不足时先隐藏 inspector，再收起侧边栏 |
| 内容布局上限 | `920` | 代码、媒体和宽表格可使用 |
| 正文阅读宽度 | `760–820` | 在 `920` 内容轴内对齐 |
| Composer | 与内容轴一致 | 默认约 `56–64` 高；最大 `180` 后内部滚动 |
| 分栏拖拽命中区 | `6` | 视觉分隔线仅一物理像素 |

### 4.3 响应式规则

- `>= 1500`：侧边栏、详情区同时显示；用户打开 inspector 时以 docked 形式显示。
- `1200–1499`：侧边栏与详情区常驻；inspector 由工具栏按钮打开为 trailing overlay。
- `960–1199`：侧边栏可缩到 `260–280`；inspector 默认关闭并以 overlay 呈现。
- `800–959`：主详情优先；侧边栏使用临时覆盖层，打开后点击遮罩或按 `Esc` 关闭。
- `< 800`：进入单栏紧凑桌面模式，使用工具栏返回/切换层级；仍不显示移动端底部导航。
- 高度 `< 680` 时优先压缩上下留白、限制 Composer 展开高度，不隐藏发送、停止和附件入口。

### 4.4 状态记忆

应持久化或在会话内保存：

- 窗口尺寸、位置与全屏状态。
- 侧边栏和 inspector 的宽度、显隐与折叠状态。
- 聊天列表、智能体列表、对话和 inspector 的独立滚动位置。
- 当前一级入口、选中会话/智能体、未发送输入和输入焦点上下文。

恢复状态时必须 clamp 到当前屏幕与最小宽度范围，不能把窗口恢复到不可见屏幕。

## 5. 层级与材质

### 5.1 四层模型

1. **Content Layer**：对话正文、列表内容、表单、代码、媒体和实际文本输入；以不透明表面保证可读性。
2. **Structural Layer**：docked sidebar、docked inspector、固定分隔线；使用实色或极轻的系统材质。
3. **Glass Control Layer**：统一工具栏、浮动控件组、overlay inspector、Composer 外壳；在能力可靠时可使用 regular glass。
4. **Transient Layer**：menu、popover、sheet、dialog、拖拽预览；具有更明确的边界和层级。

Liquid Glass 在 Stars 中是“导航与控制层材质”，不是全局磨砂皮肤。内容层不得使用玻璃背景。

### 5.2 材质规则

- 首屏最多保留 1–2 个常驻 glass 区域；同一像素不得叠加两层 blur。
- 同一控件组只模糊一次。工具栏内每个按钮、侧边栏每一行不能各自创建 `BackdropFilter`。
- Docked inspector 使用稳定的不透明表面；只有临时覆盖状态才允许材质、圆角和阴影。
- Composer 外壳可使用轻材质，但多行文本区必须有高不透明或完全不透明底色。
- 代码块、表格、消息、媒体、设置分组和智能体配置区不是 glass。
- 透明效果无法保证对比度或性能时，直接使用实色 fallback，不增加更强 blur。
- 开启减少透明度、高对比度或窗口失焦时，材质自动提高不透明度并增强分隔线。
- 禁止全窗 blur、彩色玻璃、光斑、霓虹、渐变描边、流体 shader 和“果冻”形变。

### 5.3 阴影

- 常驻结构栏不用阴影，只用 hairline separator。
- 仅 popover、menu、dialog、拖拽物、临时 inspector 等真正悬浮层使用一层柔和阴影。
- 暗色模式主要通过表面明度表达层级，不依赖黑色重阴影。

## 6. 语义颜色

颜色必须通过主题语义访问。下表为 Flutter 无法获取系统动态色时的回退值；macOS 原生增强应优先读取系统外观和用户 accent。

| Token | Light fallback | Dark fallback | 用途 |
| --- | --- | --- | --- |
| `windowBackground` | `#F5F5F7` | `#1C1C1E` | 窗口底色 |
| `contentBackground` | `#FFFFFF` | `#18181A` | 对话、表单主画布 |
| `sidebarOpaque` | `#F0F0F2` | `#242426` | 侧边栏实色回退 |
| `raisedSurface` | `#FFFFFF` | `#2C2C2E` | popover、menu、dialog |
| `controlFill` | `rgba(120,120,128,.12)` | `rgba(255,255,255,.08)` | 中性控件与输入底 |
| `hoverFill` | `rgba(0,0,0,.05)` | `rgba(255,255,255,.07)` | hover |
| `pressedFill` | `rgba(0,0,0,.09)` | `rgba(255,255,255,.11)` | pressed |
| `selectedFill` | `accent @ 12%` | `accent @ 22%` | 选中行 |
| `separator` | `rgba(60,60,67,.18)` | `rgba(255,255,255,.14)` | hairline |
| `primaryText` | `#1D1D1F` | `#F5F5F7` | 标题与正文 |
| `secondaryText` | `#6E6E73` | `#AEAEB2` | 描述与次级信息 |
| `tertiaryText` | `#8E8E93` | `#8E8E93` | placeholder 与弱元信息 |
| `accent` | `#007AFF` | `#0A84FF` | 焦点、链接、主操作 |
| `success` | `#248A3D` | `#30D158` | 成功 |
| `warning` | `#C93400` | `#FF9F0A` | 警告 |
| `danger` | `#D70015` | `#FF453A` | 错误与删除 |

规则：

- 系统 accent 优先于固定蓝色；fallback 蓝与 Stars 品牌兼容。
- Stars 深海军蓝与星芒色主要保留在应用图标、品牌入口和少量品牌时刻，不作为大面积界面背景。
- 同一操作组最多一个 accent 填充主按钮。
- 选中、成功、失败和警告必须同时有形状、图标或文字，不得只靠颜色表达。
- 状态色不用于长段正文；危险色只用于破坏性动作和真实错误。
- 正文对比度目标至少 `4.5:1`；大号或粗体文字至少 `3:1`。高对比度状态还需增强边界与焦点环。

## 7. 排版、图标与密度

### 7.1 字体

- macOS 默认使用系统字体，不硬编码 `SF Pro`；中文自然回退到平台中文系统字体。
- Windows 使用平台系统字体，如 Segoe UI 与 Microsoft YaHei UI。
- Linux 使用平台可用的 Noto Sans、Ubuntu 或系统 sans-serif。
- 等宽字体按平台回退到系统等宽字体；不得随应用打包受限的 Apple 字体。
- 用户已提供 `12–24` 字号设置。UI chrome 可有限缩放，聊天正文和编辑内容必须完整响应字号变化。

建议层级：

| 层级 | 字号 | 字重 | 行高 |
| --- | ---: | ---: | ---: |
| 详情标题 | `17` | `600` | `1.30` |
| 工具栏/窗口标题 | `13–15` | `500–600` | `1.35` |
| 聊天正文 | `14–16` | `400` | `1.55–1.65` |
| 列表与控件 | `13–14` | `400–500` | `1.35–1.45` |
| 分区标题 | `12` | `600` | `1.35` |
| 元信息 | `11–12` | `400` | `1.40` |
| 代码 | `13–14` | `400` | `1.50` |

不使用营销式超大标题、负字距或全大写导航。单一区域通常不超过两种字重。

### 7.2 图标

- 统一使用一套细节、端点和视觉重量一致的线性图标；目标视觉尺寸 `16–18`。
- 允许提供方 Logo 保留品牌色，其余功能图标默认使用语义前景色。
- macOS 可在授权和技术条件允许时映射系统 symbol；Windows/Linux 必须有等义 fallback。
- 不混用粗重 Material 图标、Cupertino 图标和自绘图标，也不使用机器人头像代表所有智能体。
- 图标按钮必须同时提供 tooltip 与无障碍名称；含义不明确时直接使用短文本。

### 7.3 间距和圆角

基础间距采用 `4px` 网格：`4 / 8 / 12 / 16 / 20 / 24 / 32`，紧凑控件内部允许 `6 / 10`。

| Token | 值 | 用途 |
| --- | ---: | --- |
| `radiusInline` | `4–5` | 行内代码、小标签 |
| `radiusControl` | `7–8` | 按钮、输入框、选中行 |
| `radiusContainer` | `10–12` | 状态块、menu、popover |
| `radiusComposer` | `14–16` | Composer 外壳 |
| `radiusWindow` | 系统管理 | 不由内容层模拟 |

胶囊只用于分段控件、过滤标签和圆形/胶囊强动作；普通列表行、设置分组和每个按钮不应全部胶囊化。

### 7.4 控件密度

- 标准控件视觉高度 `28–32`，重点操作 `32–36`。
- 列表行默认 `36–44`，包含两行文字时 `48–56`。
- 图标 glyph 为 `16–18`，可见按钮为 `28–32`；通过透明内边距把自定义按钮命中区扩展到目标 `44 × 44`，同时避免相邻命中区重叠。
- 紧凑不等于拥挤。文字放大或本地化变长时，控件允许增高和换行，不得裁切关键文案。

## 8. 统一工具栏

工具栏是窗口级控制层，不再叠加一条自绘菜单栏和一条页面 AppBar。

推荐结构：

```text
[侧栏] [返回/前进]   [当前聊天或页面标题 · 模型摘要]   [搜索] [检查器] [页面动作]
```

规则：

- 标题始终来自当前上下文：聊天名、智能体名或设置分区；不显示营销副标题。
- 会话标题旁可显示提供方/模型弱摘要，完整信息进入 inspector 或菜单。
- 新建聊天、添加智能体等主要动作随当前入口变化，不同时展示多个蓝色按钮。
- 清空会话等低频或危险操作进入更多菜单；执行前明确对象与后果。
- 工具栏按钮使用一致的 `16–18` 图标、hover、pressed、focus、disabled 和 tooltip。
- 一组相邻图标共享一个控制表面；不要让每个图标都成为独立玻璃胶囊。
- 空白拖拽区只在原生窗口集成完成后启用，并必须排除所有交互控件。

## 9. 侧边栏与列表

### 9.1 结构

侧边栏从上到下为：

1. Stars 品牌入口与全局搜索/快速切换入口。
2. 一级导航：聊天、智能体。
3. 当前入口的标题、搜索和新建/添加动作。
4. 会话列表、智能体列表或“我的”设置导航。
5. 固定在底部的个人资料入口。

### 9.2 视觉

- 整栏只使用一个材质或一个实色 surface；内部不堆卡片。
- 分区标题使用弱化 `12px / 600`，中文不强制大写或增加字距。
- 单行列表高 `36–44`，水平内边距 `8–12`，图标与文字间距 `8–10`。
- 选中行使用轻 accent 混合底与 `7–8` 圆角；非活动窗口降低 accent，但仍保留选中形状。
- hover 只改变轻背景；pressed 再加深一级，状态变化不能改变尺寸。
- 标题单行省略，时间、未读点、提供方或更多按钮保持尾部对齐。
- 更多按钮可在 hover/focus 时增强，但键盘用户必须始终能够到达。
- 列表滚动条遵循平台习惯，不强制常驻粗滚动条。

### 9.3 行为

- 搜索实时过滤但不改变搜索框位置；清空搜索后恢复原选择与滚动位置。
- 方向键移动选择，`Enter` 打开，`Shift`/`Cmd` 多选仅在未来真正支持批量操作后启用。
- 右键菜单只放与当前行相关的高频动作；删除放在末尾并标记危险。
- 上下文菜单中的命令也必须能从主菜单、工具栏或详情页找到，不能成为唯一入口。
- 删除会话或智能体后，选择应移动到合理的相邻项，详情区不能停留在已删除对象上。

## 10. 对话工作区

### 10.1 阅读轴

- 对话区是连续不透明画布，不放进四周留白的大卡片。
- 内容布局最大宽度 `920`；长段正文建议限制在 `760–820`，代码、表格和媒体可扩展到完整内容轴。
- 顶部和底部留白必须考虑工具栏与 Composer，最后一条消息不能被输入区遮挡。
- 用户主动向上滚动后，流式输出不得强制抢回底部；显示“回到最新”入口。

### 10.2 消息

用户消息：

- 右对齐或沿阅读轴右侧对齐，使用中性 control fill 或轻 accent fill。
- 最大宽度约为内容轴 `60–68%`，圆角 `12–14`，内边距 `8–12`。
- 长文本、Markdown、代码或复杂附件可放宽，不为维持气泡造型牺牲可读性。

智能体回复：

- 左对齐，以无外层气泡的文档流呈现；不要把所有回复统一称为“Stars 输出”。
- 默认不重复展示头像；确需区分多智能体时，仅在上下文变化处显示名称或提供方标识。
- 支持可选择的 Markdown、标题、列表、引用、链接、代码、表格和媒体结果。
- 链接使用 accent，但必须保留可识别的 hover/focus 状态，不能只靠颜色。

### 10.3 推理、工具与过程信息

- 推理内容默认折叠为 disclosure group，标题客观描述状态，如“思考完成”“正在处理”。
- 耗时、工具调用、命令执行和文件状态属于消息内的过程区，不扩展成虚构的项目/Git 工作台。
- 过程行使用平面分组、细分隔与弱元信息；失败时提供“重试”或“查看详情”等可恢复动作。
- 流式中使用稳定的文本光标或进度状态，不用循环发光和夸张波纹。

### 10.4 代码与媒体

- 行内代码使用稳定不透明底色和 `4–5` 圆角。
- 代码块提供语言、复制和必要的横向滚动；浅色/暗色均需独立校验对比度。
- 图片、音频、音乐、视频和文件附件在内容轴内展示，保持原始比例并提供明确加载/失败状态。
- 媒体控件遵循平台行为；不可播放时显示文件信息与恢复动作，而不是空白区域。

### 10.5 空、加载与错误

- 未选择会话时使用小型 Stars 图标、简短说明和一个“新建聊天”主动作。
- 加载历史记录使用内联 spinner 或轻量占位，不让详情布局跳动。
- 错误信息说明发生了什么和下一步能做什么；不要使用“你的智能伙伴走神了”等拟人化文案。

## 11. Chat Composer

Composer 是附着在内容区底部的主操作，不再固定为高度 `112–124` 的巨大悬浮卡。

### 11.1 结构

```text
┌──────────────────────────────────────────────────────────────┐
│ 输入消息…                                                    │
│ [附件] [能力/参数] [联网] [深度思考]      [模型摘要] [停止/发送] │
└──────────────────────────────────────────────────────────────┘
```

能力项按当前 provider 实际能力显示，包括：

- 相机、图片和文件附件。
- 联网搜索、深度思考。
- 图像尺寸与风格、视频比例等生成参数。
- 当前模型/提供方摘要。
- 发送、生成中停止。

不要加入当前产品不存在的“权限、Git 环境、任务模式”等控件。

### 11.2 视觉

- 默认一至两行，约 `56–64` 高；随输入增长，达到 `180` 后文本区内部滚动。
- 外壳圆角 `14–16`；文本区使用不透明或高不透明底，不再套第二层粗边框。
- 底部距内容区 `12–16`，宽度与内容轴一致；可轻微悬浮，但只使用一层阴影。
- 发送/停止是唯一强操作。发送使用 accent，停止使用清晰的形状变化，不仅更换颜色。
- focus 使用可见的系统 accent ring，不使用发光描边。
- 附件预览在 Composer 上方或内部稳定展开，移除按钮始终可见且可键盘到达。

### 11.3 行为

- 默认 `Enter` 发送，`Shift+Enter` 换行；若未来提供偏好设置，菜单与 tooltip 必须同步展示当前规则。
- 输入为空且无附件时发送按钮 disabled；生成中同一位置变为停止，不能导致布局跳动。
- `Esc` 优先关闭参数 popover，再取消当前临时状态；不得无提示清空输入。
- 模型、联网、深度思考和生成参数使用 menu/popover，展开时不推挤整个对话布局。
- 发送失败保留文字与附件，并提供重试；发送成功后及时清理已提交附件。
- 输入法组合阶段不得误发送，中文、日文和韩文 IME 必须专项测试。

## 12. 智能体与设置页面

### 12.1 智能体列表与编辑

- 列表项展示头像/提供方 Logo、名称和模型摘要，保持平面 source list 风格。
- “添加智能体”是当前页面的主要动作；编辑页内“保存”是唯一 primary。
- 名称、提供方、API 类型、地址、密钥、模型和系统提示词按语义分组，不把每个字段做成独立卡片。
- 密钥默认隐藏，显示/复制必须是明确动作；错误紧邻字段并说明修复方式。
- provider 或 API 类型改变导致字段变化时，保持焦点可预测，不丢弃已输入数据。
- 删除智能体明确显示对象名称和影响；默认焦点不能落在破坏性按钮。

### 12.2 我的/设置

- 使用侧边导航 + 连续设置画布，内容宽度建议 `680–760`。
- 分组依次为个人信息、外观与语言、帮助与支持、关于与法律信息。
- 主题选项明确为“跟随系统 / 浅色 / 深色”；即时预览但必须持久化。
- 字号设置展示当前值和实际文字预览，支持键盘微调并提供恢复默认。
- Switch 只用于立即生效的持久布尔设置；单选用 radio/segmented control，多选用 checkbox。
- avatar、语言和危险账户动作遵循所在平台的 dialog/sheet 习惯。

## 13. Context Inspector

Inspector 只描述有真实数据来源的上下文：

- 当前可直接展示智能体名称、提供方和模型。
- “本地桌面”“就绪”等当前静态占位文案不等于真实环境状态；接入明确的数据源前不得把它们呈现为事实。
- 本地环境、会话参数和能力状态只在真实接入后加入，并分别提供加载、未知和错误状态。

规则：

- 宽屏为贴边 split inspector，用 hairline 与详情区分隔；不加外边距、巨型圆角或永久阴影。
- 中等窗口为 trailing overlay，宽 `300–360`，此时才使用 `10–12` 圆角、材质和轻阴影。
- 面板可关闭、可调宽、独立滚动，并恢复上次宽度与滚动位置。
- 分区使用 disclosure group；属性名左对齐，值右对齐或在下一行完整显示。
- 工具栏按钮、`Esc` 和“视图”菜单都能控制显隐。
- 当前未实现的 Git、文件变更、提交推送、端口和后台进程不得作为默认内容；未来接入后另行扩展。

## 14. 控件与临时界面

### 14.1 按钮

- `Primary`：accent 填充，每个操作组最多一个。
- `Secondary`：中性 fill 或轻边框。
- `Borderless`：工具栏与列表行内动作。
- `Destructive`：危险色，仅用于明确破坏性动作。
- 所有自定义按钮必须有 default、hover、pressed、focus、disabled 和 loading；状态变化不改变尺寸。

### 14.2 输入与选择控件

- 搜索框和标准输入框高 `28–32`，圆角 `7–8`，中性 fill + 清晰 focus ring，无常驻阴影。
- placeholder 不能代替 label；校验错误紧邻字段。
- Segmented control 只用于 `2–5` 个互斥视图或模式，不代替一级导航。
- Checkbox、radio 和 switch 的语义必须正确，不为追求“苹果感”全部换成 switch。

### 14.3 Menu、popover、dialog 与 sheet

- 轻量选择使用锚定触发器的 menu/popover；阻塞且属于当前窗口的流程使用 dialog 或 sheet。
- Menu 支持方向键、`Enter`、`Esc`；命令名左对齐，主菜单快捷键右对齐。
- Context menu 保持简短，最多约三个逻辑分组；不显示冗余快捷键。
- 打开新窗口或需要后续输入的 macOS 按钮文案可使用省略号语义，但必须与其他平台文案规则一致。
- 危险确认明确对象、后果与不可逆性；取消是安全默认。

### 14.4 反馈

- 短暂成功使用非阻塞 toast；需要用户处理的错误保留在相关区域。
- 超过短暂等待时显示确定或不确定进度；可取消操作提供停止入口。
- loading、错误、空状态和正常内容占用兼容的布局范围，避免界面跳动。

## 15. 桌面交互与快捷键

### 15.1 通用规则

- `Tab` 顺序与视觉顺序一致；`Shift+Tab` 反向移动。
- `Enter`/`Space` 激活控件，方向键遍历菜单、列表和分段控件，`Esc` 关闭最上层临时界面。
- 所有鼠标 hover 动作都必须有键盘等价入口。
- 文本、代码、路径、模型名和错误详情应可选择与复制。
- 滚动区域不抢夺未指向它的滚轮事件；popover 打开时焦点被正确约束，关闭后回到触发器。

### 15.2 建议快捷键

| 命令 | macOS | Windows/Linux |
| --- | --- | --- |
| 新建聊天 | `⌘N` | `Ctrl+N` |
| 搜索当前列表 | `⌘F` | `Ctrl+F` |
| 快速切换 | `⌘K` | `Ctrl+K` |
| 显示/隐藏侧边栏 | `⌃⌘S` | `Ctrl+B` |
| 显示/隐藏 inspector | `⌘⌥I` | `Ctrl+Alt+I` |
| 设置 | `⌘,` | `Ctrl+,` |
| 关闭临时界面 | `Esc` | `Esc` |
| 发送 | `Enter` | `Enter` |
| 输入换行 | `Shift+Enter` | `Shift+Enter` |

快捷键实施前必须检查平台冲突。菜单、tooltip、命令面板与 `Shortcuts/Actions` 使用同一来源，禁止在多个 Widget 中各自硬编码。

## 16. 动效

| 场景 | 建议时长 |
| --- | ---: |
| hover / pressed | `80–120ms` |
| menu / popover | `120–180ms` |
| 侧边栏与 inspector 显隐 | `160–220ms` |
| dialog / sheet | `180–240ms` |

- 进入优先 `easeOutCubic`，退出优先 `easeInCubic`；位移控制在 `4–8px` 并配合淡入淡出。
- 禁止弹跳、大幅缩放、持续脉冲、液态拉伸、blur radius 动画和装饰性循环动画。
- 流式文字本身就是进度反馈，不再叠加吸引注意力的动画。
- `Reduce Motion` 或 Flutter `disableAnimations` 开启时移除位移与尺寸动画，使用即时切换或极短淡化。
- 动效结束后焦点、语义树和可点击区域必须处于最终状态，不能只改变视觉。

## 17. 无障碍与本地化

### 17.1 视觉与输入

- 正文对比度目标 `>= 4.5:1`，大号/粗体文字 `>= 3:1`；亮色和暗色分别测试。
- 高对比度模式增强 separator、focus ring 和 selected，不仅提高文字亮度。
- 不依赖红/绿区分状态；同时使用图标、形状和文本。
- 支持键盘完成新建聊天、搜索、选择、发送、停止、编辑智能体和修改设置。
- 图标按钮使用 `Semantics.label` 与 tooltip；装饰图标从语义树中排除。
- 状态变化用可理解的 live region 播报，避免逐 token 重复朗读流式内容。

### 17.2 文字与布局

- 支持至少 `200%` 的内容文字放大目标；允许控件增高、换行与分栏折叠，禁止裁切。
- 中文、英文和其他已支持语言都要测试长标题、复数、日期和模型名。
- 所有新增桌面文案进入 ARB，不在 Widget 中新增硬编码中文。
- placeholder 只是提示，不承担字段名称；错误文案必须说明如何恢复。

### 17.3 系统状态

- 亮色、暗色、系统主题切换时不闪白、不丢输入。
- 减少透明度时完全移除 blur，改用 `sidebarOpaque`/`raisedSurface`，同时保持尺寸和层级。
- 高对比度可直接走不透明表面。
- 窗口 active/inactive、Retina/非 Retina、Windows `100%/125%/150%` 缩放都要校验。

## 18. Flutter 落地规范

### 18.1 现有代码映射

| 规范区域 | 当前入口 |
| --- | --- |
| 应用与桌面挂载 | `lib/main.dart` |
| 窗口内桌面布局 | `lib/pages/desktop_layout.dart` |
| 主题与桌面组件 | `lib/utils/theme.dart` |
| 聊天/智能体列表 | `lib/pages/chats.dart`、`lib/pages/bots.dart` |
| 对话工作区 | `lib/pages/chat.dart` |
| Composer | `lib/pages/chat/message_input.dart` |
| 消息与过程信息 | `lib/pages/chat/message_list.dart` |
| 智能体编辑 | `lib/pages/add_bot.dart`、`lib/pages/edit_bot.dart` |
| 我的/设置 | `lib/pages/profile.dart` |
| 本地化 | `lib/l10n/` |

### 18.2 Token 架构

继续以 `lib/utils/theme.dart` 为视觉入口，并逐步把 `DesktopThemeTokens` 迁移为语义化 `ThemeExtension`。业务 Widget 中不得散落裸颜色、半径、阴影和动画时长。

```dart
@immutable
class StarsDesktopTokens extends ThemeExtension<StarsDesktopTokens> {
  const StarsDesktopTokens({
    required this.windowBackground,
    required this.contentBackground,
    required this.sidebarSurface,
    required this.primaryText,
    required this.separator,
    required this.accent,
    required this.reduceTransparency,
    required this.highContrast,
  });

  final Color windowBackground;
  final Color contentBackground;
  final Color sidebarSurface;
  final Color primaryText;
  final Color separator;
  final Color accent;
  final bool reduceTransparency;
  final bool highContrast;

  // copyWith / lerp 省略
}
```

材质必须集中到一个 primitive：

```dart
enum StarsGlassRole {
  toolbar,
  sidebar,
  composer,
  popover,
  overlayInspector,
}

class StarsGlassSurface extends StatelessWidget {
  const StarsGlassSurface({
    super.key,
    required this.role,
    required this.child,
  });

  final StarsGlassRole role;
  final Widget child;
}
```

`StarsGlassSurface` 统一解析 brightness、high contrast、reduce transparency、window active、hover 和 pressed。实色状态必须完全不构建 `BackdropFilter`，不能只把 sigma 设为零。

### 18.3 组件与平台能力

- 不直接使用整套 Cupertino Widget 冒充 macOS；建立 `StarsToolbarButton`、`StarsSidebarRow`、`StarsSearchField`、`StarsPopover` 等桌面 primitive。
- macOS 菜单能力允许时使用 `PlatformMenuBar`；窗口标题栏和交通灯交给原生层。
- 使用 `LayoutBuilder` 和约束驱动响应式；不要用设备名称代替实际可用宽度。
- 侧边栏、列表、对话和 inspector 使用独立 `ScrollController`。
- 使用 `Shortcuts`、`Actions`、`FocusTraversalGroup` 统一菜单、按钮和快捷键行为。
- 使用 `Semantics`、`MergeSemantics` 和 `ExcludeSemantics` 准确表达 label、value、selected、expanded 与状态变化。
- Menu/context menu 使用项目统一封装或 `MenuAnchor`，避免各页面出现不同键盘行为。
- hairline 可使用 `BorderSide(width: 0)`；必须在不同 DPR 下做截图校验。
- 现有 `DesktopListPanel`、`DesktopInteractiveListItem` 和 `DesktopEmptyStateCard` 可保留职责，但应按本文 token 重做视觉。

### 18.4 性能边界

- `BackdropFilter` 必须被 `ClipRect`/`ClipRRect` 紧密裁剪，只用于有限的导航或临时控制区域。
- 禁止包住整窗、整个滚动列表或每一个 row/button；同组控件只建立一个合成层。
- 滚动列表使用惰性构建；媒体和复杂消息按需使用 `RepaintBoundary`。
- resize、滚动、流式输出和 Composer 输入同时发生时仍需保持稳定帧率。
- 无法稳定实现原生材质时使用实色 fallback，这属于正确实现，不是降级失败。

### 18.5 测试同步

当前 `test/widget_test.dart` 锁定了旧的 `340` 侧栏、`380` inspector、`42` 菜单栏以及旧浅色 token。实现本文目标值时必须同步更新测试，并补充暗色、响应式、键盘和可访问性测试，不能让文档和代码各自维护一套真相。

## 19. Do / Don't

### Do

- 使用原生窗口装饰、统一工具栏、可调分栏和连续内容画布。
- 以真实的聊天、智能体和我的流程组织界面。
- 使用系统字体、语义色、用户 accent、hairline 和清晰焦点。
- 让用户消息轻量，让智能体回复像可阅读、可选择的文档。
- 让 Composer 紧凑自增长，并保留真实 provider 能力。
- 让 docked inspector 成为结构栏，只在 overlay 状态增加材质和阴影。
- 完整支持键盘、右键、tooltip、亮暗主题、高对比度、减少动态和减少透明度。

### Don't

- 不伪造交通灯、Apple 商标、系统资产或 macOS 全局菜单。
- 不把 iOS 控件放大后当作桌面设计。
- 不把 Stars 写成不存在的项目/Git/任务工作台。
- 不使用卡片套卡片、全窗玻璃、blur 套 blur、彩色渐变玻璃或永久重阴影。
- 不滥用 `20px+` 圆角、胶囊按钮和大面积 accent。
- 不在内容、代码、表格和实际文本输入下使用透明玻璃。
- 不让流式自动滚动抢走用户阅读位置。
- 不在 Windows/Linux 显示 `⌘` 或假的 macOS 窗口行为。

## 20. 验收标准

### 20.1 产品与结构

1. 一级入口只呈现聊天、智能体、我的；没有虚构项目/任务/Git 导航。
2. 选择聊天显示对话，选择智能体显示编辑，选择设置分区显示相应内容。
3. 新建/删除聊天、添加/编辑/删除智能体、修改主题/语言/字号的既有流程可用。
4. Inspector 只显示真实上下文；docked 与 overlay 两种状态行为正确。
5. Composer 完整保留附件、联网、深度思考、生成参数、发送和停止能力。

### 20.2 视觉与平台

6. macOS 没有 Flutter 自绘菜单行或假交通灯；Windows/Linux 没有 macOS 窗口按钮。
7. 内容层稳定不透明；常驻 glass 不超过 1–2 个区域，任一像素没有双层 blur。
8. 侧边栏、详情和 docked inspector 通过材质/明度与 hairline 建立层级，没有大型悬浮卡片堆叠。
9. Light、Dark、High Contrast、Reduce Transparency 下信息层级与可读性完整。
10. 窗口失焦仍能识别当前选择，重新激活不丢输入与焦点上下文。

### 20.3 布局矩阵

必须覆盖：

- `800 × 600`：单栏紧凑桌面流程可完成。
- `960 × 680`：侧边栏可用，inspector 为 overlay。
- `1280 × 800`：侧边栏 + 详情稳定，无重叠。
- `1440 × 900`：完整阅读轴与 overlay inspector 正常。
- `1920 × 1080`：可 dock inspector，正文不无限拉宽。
- macOS Retina 与非 Retina；Windows `100% / 125% / 150%`；主流 Linux 桌面缩放。

### 20.4 交互与无障碍

11. 纯键盘可以完成新建聊天、搜索、选择、发送/停止、编辑智能体和修改设置。
12. hover、pressed、focus、selected、disabled、loading 状态可辨且不引发布局跳动。
13. VoiceOver/屏幕阅读顺序与视觉顺序一致；图标按钮名称明确，状态不重复播报。
14. 内容文字放大至 `200%` 时关键文字不裁切，布局按规则折叠。
15. 正文对比度、焦点、错误与状态表达达到本规范要求，并且不只依赖颜色。
16. 中文/英文长文案、IME 组合输入、复制选择与快捷键均无回归。

### 20.5 性能

17. 滚动长会话、流式输出、展开 Composer 和 resize 同时发生时没有明显掉帧。
18. Reduce Transparency 或实色 fallback 下不创建无意义的 blur 合成层。
19. Composer 不遮挡最后一条消息，流式输出不强制打断用户向上阅读。

## 21. 实施优先级

1. **信息架构纠偏**：文档、文案和组件命名统一为聊天 / 智能体 / 我的。
2. **语义 Token**：先落地 Light/Dark、surface、text、accent、separator、focus、radius 与 motion。
3. **桌面壳层**：移除内容区假菜单，重做统一工具栏、侧边栏和 inspector 结构。
4. **核心工作区**：重做对话阅读轴、消息、过程信息和紧凑自增长 Composer。
5. **表单与设置**：统一智能体编辑、Profile 设置、dialog、popover 和错误状态。
6. **输入与无障碍**：补齐快捷键、焦点、语义、本地化和系统可访问性状态。
7. **macOS 原生增强**：在基线稳定后再评估标题栏、系统材质和窗口状态桥接。

## 22. 设计依据

本文参考 Apple 官方 Human Interface Guidelines，并将其转译为 Stars 的跨平台 Flutter 约束：

- [Designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos/)
- [Windows（Apple HIG 的窗口规范）](https://developer.apple.com/design/human-interface-guidelines/windows)
- [Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars)
- [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars)
- [Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility/)
- [Context menus](https://developer.apple.com/design/human-interface-guidelines/context-menus)

本文中的像素值、断点、组件名和 fallback 色值是 Stars 的项目决策，不是 Apple 官方规格。

## 23. 最终风格一句话

Stars 借鉴 Apple 设计的秩序与 Liquid Glass 的层级语义，而不复制表面效果：内容始终稳定清晰，只有导航、控制和临时层在需要时呈现轻盈材质。
