# Windows/Linux 桌面端样式升级 Spec

## Why
当前项目已经具备基础桌面端分栏能力，但整体视觉仍偏向移动端页面横向拼接，与参考图中的桌面工作台风格差距较大。需要在不改变现有业务流程的前提下，统一 Windows/Linux 桌面端的布局结构、视觉语言和交互表现。

## What Changes
- 重构桌面端主框架为窄导航栏 + 列表面板 + 详情工作区的三栏布局
- 统一 Chats 和 Bots 列表页的桌面面板样式
- 重构聊天详情页为桌面内容画布，补齐标题区、消息流容器和底部固定输入区
- 引入桌面端样式 token，统一背景、圆角、间距、边框和悬停/选中态
- 优化空状态、状态卡片和消息流宽度限制，提升桌面阅读体验

## Impact
- Affected specs: 桌面布局、聊天页展示、智能体列表展示、桌面交互反馈
- Affected code: `lib/main.dart`, `lib/pages/desktop_layout.dart`, `lib/pages/chats.dart`, `lib/pages/bots.dart`, `lib/pages/chat.dart`, `lib/pages/chat/message_list.dart`, `lib/pages/chat/message_input.dart`, `lib/utils/theme.dart`

## ADDED Requirements
### Requirement: 桌面端三栏工作台布局
系统 SHALL 在 Windows/Linux 桌面端提供窄导航栏、列表面板和详情工作区组成的三栏布局，并保持现有聊天与智能体联动能力。

#### Scenario: 打开桌面端首页
- **WHEN** 用户在 Windows/Linux 平台启动应用并进入主页面
- **THEN** 页面展示左侧窄导航栏、中间列表面板和右侧详情工作区
- **AND** Chats、Bots、Profile 的一级入口可被访问

#### Scenario: 切换一级导航
- **WHEN** 用户点击左侧导航项
- **THEN** 中间列表面板与右侧详情区按模块切换
- **AND** 切换过程不出现移动端整页跳转感

### Requirement: 桌面端列表面板样式统一
系统 SHALL 为 Chats 与 Bots 页面提供统一的桌面列表面板样式，包括标题区、主操作按钮、搜索框、列表项悬停态与选中态。

#### Scenario: 查看 Chats 或 Bots 列表
- **WHEN** 用户进入 Chats 或 Bots 模块
- **THEN** 中间区域展示白色圆角面板
- **AND** 面板顶部包含标题与主操作入口
- **AND** 列表项具备清晰的 hover 与选中反馈

### Requirement: 桌面端聊天详情工作区
系统 SHALL 将聊天详情页呈现为桌面工作画布，而非移动端页面放大版，并为消息内容提供最大宽度约束。

#### Scenario: 选中聊天
- **WHEN** 用户在列表中选择一个聊天
- **THEN** 右侧详情区展示桌面化聊天工作区
- **AND** 工作区包含顶部标题信息、中部消息流与底部输入区
- **AND** 消息区域的正文宽度受到约束，避免超宽排版

### Requirement: 状态卡片与空状态桌面化
系统 SHALL 使用独立的状态卡片与桌面空状态样式来展示过程信息和未选中场景。

#### Scenario: 展示过程信息
- **WHEN** 聊天中出现已编辑文件、运行命令、耗时或工具调用记录
- **THEN** 这些内容以独立状态卡片样式展示

#### Scenario: 未选中聊天或智能体
- **WHEN** 右侧详情区没有有效选中项
- **THEN** 页面展示桌面风格空状态，而不是仅显示简单图标和一行文本

### Requirement: 桌面端输入区样式升级
系统 SHALL 为桌面端聊天输入区提供固定底部、白色圆角、大输入框和轻量操作按钮的样式。

#### Scenario: 桌面端输入消息
- **WHEN** 用户在桌面端聚焦输入框并准备发送消息
- **THEN** 底部输入区保持固定并与详情区样式统一
- **AND** 焦点状态具有清晰但克制的高亮反馈

## MODIFIED Requirements
### Requirement: 桌面端布局入口
系统现有的桌面端布局入口保持不变，但其呈现方式从“移动端页面横向拼接”升级为“桌面工作台三栏布局”。

#### Scenario: 保持现有业务流程
- **WHEN** 用户执行选择聊天、新建聊天、选择智能体、编辑智能体等现有操作
- **THEN** 原有流程和状态联动继续可用
- **AND** 仅视觉结构和桌面交互表现发生升级

## REMOVED Requirements
### Requirement: 无
**Reason**: 本次调整以样式升级和容器重构为主，不移除既有业务能力。
**Migration**: 无需迁移。
