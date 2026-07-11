# Windows/Linux/macOS 桌面端样式对齐参考图 Spec

## Why
当前项目已具备桌面端三栏布局基础，但视觉效果仍偏向 Flutter 默认页面拼接，与参考图中的桌面工作台风格差距明显。参考图呈现出更轻、更克制的桌面应用观感，包括浅灰工作区、窄侧边导航、白色圆角内容面板、居中的聊天画布和吸底输入区。

现有仓库虽然已将 `Windows`、`Linux`、`macOS` 都纳入桌面布局判断，但旧 spec 主要聚焦 `Windows / Linux`，对 `macOS` 的目标样式和边界没有定义清楚。本次需要补齐一份三平台统一 spec，作为后续实现和验收依据。

## What Changes
- 为 `Windows`、`Linux`、`macOS` 统一定义桌面端视觉目标，整体样式向参考图对齐
- 将桌面主框架明确为“窄导航栏 + 列表面板 + 详情工作区”的三段式布局
- 统一 Chats、Bots、Profile 等桌面模块的容器、间距、圆角、边框和状态反馈
- 重定义聊天详情页的标题区、消息流、状态卡片和底部输入区的桌面化表现
- 明确三平台的一致部分与差异部分，避免实现过程中出现平台分叉

## Impact
- Affected specs: 桌面主框架、会话列表、智能体列表、聊天详情、桌面输入区、桌面空状态
- Affected code: `lib/main.dart`, `lib/utils/utils.dart`, `lib/pages/desktop_layout.dart`, `lib/pages/chats.dart`, `lib/pages/bots.dart`, `lib/pages/chat.dart`, `lib/pages/chat/message_list.dart`, `lib/pages/chat/message_input.dart`, `lib/utils/theme.dart`
- Out of scope: Android/iOS/Web 样式同步、业务流程改造、数据结构变更、像素级复刻参考图中的品牌文案与素材

## ADDED Requirements
### Requirement: 三平台统一采用参考图风格的桌面工作台布局
系统 SHALL 在 `Windows`、`Linux`、`macOS` 平台提供与参考图一致方向的桌面工作台布局，而不是移动端页面的放大版。

#### Scenario: 桌面端首次进入主界面
- **WHEN** 用户在 `Windows`、`Linux` 或 `macOS` 启动应用并进入桌面主界面
- **THEN** 页面呈现浅灰工作区背景
- **AND** 左侧存在窄导航栏，中间存在列表面板，右侧存在主内容工作区
- **AND** 整体视觉密度、留白节奏、圆角语言应明显接近参考图

### Requirement: 左侧导航栏样式与参考图对齐
系统 SHALL 将左侧导航栏调整为更窄、更轻的桌面侧栏，承担一级模块导航与账户入口能力。

#### Scenario: 展示一级导航
- **WHEN** 用户查看桌面端左侧导航栏
- **THEN** 顶部展示应用名或品牌区域
- **AND** 中部展示 Chats、Bots、Profile 等一级入口
- **AND** 底部展示账户或设置入口
- **AND** 选中项使用浅色胶囊高亮，而非厚重的默认侧栏样式

### Requirement: 列表面板统一为白色桌面卡片
系统 SHALL 将 Chats 与 Bots 列表区统一为独立白色圆角面板，以匹配参考图中的中间列结构。

#### Scenario: 进入 Chats 或 Bots
- **WHEN** 用户切换到 Chats 或 Bots 模块
- **THEN** 中间区域展示白色圆角列表面板
- **AND** 面板顶部包含标题、主操作按钮和必要的搜索区域
- **AND** 列表项具备 hover、选中、聚焦等桌面态反馈

### Requirement: 聊天详情区采用居中内容画布
系统 SHALL 将右侧聊天详情区调整为居中内容画布，消息流、状态卡片和输入区均以参考图中的轻量桌面语义呈现。

#### Scenario: 打开一个聊天
- **WHEN** 用户在桌面端选中某个聊天
- **THEN** 右侧展示带最大宽度限制的内容画布
- **AND** 顶部为标题与上下文区
- **AND** 中部为消息流与状态卡片区
- **AND** 底部为吸附式输入区

#### Scenario: 消息内容排版
- **WHEN** AI 或用户消息在详情区显示
- **THEN** 正文宽度受到约束，避免整屏铺开
- **AND** 系统过程信息与普通消息具有清晰的视觉层级区分

### Requirement: 状态卡片样式与参考图一致
系统 SHALL 将“已编辑文件”“运行命令”“正在思考”“耗时”“工具调用”等过程信息展示为独立状态卡片或轻量标签。

#### Scenario: 展示过程信息
- **WHEN** 聊天中产生文件编辑、命令执行、工具调用或状态说明
- **THEN** 这些内容以白底、浅边框、圆角卡片或轻量标签显示
- **AND** 卡片支持主文案、次文案、图标和状态色

### Requirement: 输入区采用大圆角吸底样式
系统 SHALL 为桌面端输入区提供参考图风格的吸底输入容器。

#### Scenario: 用户准备输入消息
- **WHEN** 用户在桌面端聚焦输入框
- **THEN** 底部输入容器保持白底、大圆角、轻阴影或浅边框
- **AND** 左侧可承载附件或快捷操作
- **AND** 右侧发送、语音、模型等操作按钮保持轻量样式

### Requirement: 未选中状态采用桌面空态
系统 SHALL 在未选中聊天、未选中智能体或无数据时，展示与参考图一致风格的桌面空状态。

#### Scenario: 没有选中项
- **WHEN** 右侧详情区没有可展示的聊天或智能体
- **THEN** 页面展示具有留白、简洁文案和可选主操作按钮的桌面空态
- **AND** 不再仅显示单个图标与一行提示文字

### Requirement: 三平台共享统一桌面样式 Token
系统 SHALL 为 `Windows`、`Linux`、`macOS` 共享一套桌面端样式 token，保证视觉一致性。

#### Scenario: 应用桌面样式常量
- **WHEN** 开发者实现桌面端容器、列表项、输入区和状态卡片
- **THEN** 应优先使用统一的颜色、圆角、边框、阴影和间距 token
- **AND** 避免在各页面散落独立魔法值

## MODIFIED Requirements
### Requirement: 桌面端平台范围
系统现有的桌面布局范围从“主要为 Windows/Linux 设计，macOS 未明确约束”修改为“Windows、Linux、macOS 三平台统一纳入本次样式对齐范围”。

#### Scenario: 桌面平台判断
- **WHEN** 应用使用现有桌面平台判定逻辑进入桌面布局
- **THEN** `Windows`、`Linux`、`macOS` 都应使用同一套桌面布局结构
- **AND** 除平台系统字体、窗口阴影和标题栏保留差异外，内容区视觉目标保持一致

### Requirement: 桌面端视觉验收标准
系统现有的桌面验收标准从“Windows/Linux 明显接近参考图”修改为“三平台内容区均需明显接近参考图”。

#### Scenario: 进行验收
- **WHEN** 团队在 `Windows`、`Linux`、`macOS` 上查看桌面端页面
- **THEN** 左导航、列表面板、详情画布、状态卡片和输入区在三平台上应保持统一风格
- **AND** 不允许出现某一平台仍保持明显移动端放大样式

## REMOVED Requirements
### Requirement: macOS 暂不调整
**Reason**: 当前代码已经将 `macOS` 纳入桌面布局入口，如果 spec 不覆盖 `macOS`，后续实现与验收会长期处于不一致状态。
**Migration**: 将此前仅针对 `Windows/Linux` 的桌面样式要求整体提升为三平台共享要求。

## Design Notes
### 参考图核心特征
- 外层背景为低饱和浅灰工作区
- 左侧为窄导航栏，顶部品牌、底部账户，中部是轻量图标菜单
- 中间列表区为白色圆角卡片，顶部标题与操作区清晰
- 右侧聊天区是居中的内容画布，而非整屏聊天气泡
- 文件、命令、处理状态等过程信息采用轻量卡片展示
- 底部输入区为吸附式白色大圆角输入框

### 建议样式 Token
- App Background: `#F3F5F7`
- Panel Background: `#FFFFFF`
- Secondary Surface: `#F7F8FA`
- Primary Text: `#1F2329`
- Secondary Text: `#6B7280`
- Divider: `#E5E7EB`
- Hover Background: `#F3F4F6`
- Selected Background: `#E8F0FE`
- Radius XL: `24`
- Radius L: `20`
- Radius M: `16`
- Control Height: `40-48`

### 平台差异边界
- `Windows`: 允许保留系统窗口阴影与标题栏习惯，但内容区样式需对齐参考图
- `Linux`: 不强依赖特定窗口管理器外观，重点约束应用内容区结构与留白
- `macOS`: 保留系统字体与窗口行为习惯，但侧栏、面板和输入区的内容样式需与参考图统一
- 本次 spec 默认约束应用内容区，不强制要求自定义原生窗口标题栏
