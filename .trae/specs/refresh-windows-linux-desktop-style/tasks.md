# Tasks

- [x] Task 1: 抽离桌面端样式基础能力
  - [x] SubTask 1.1: 在桌面端相关模块中梳理统一的颜色、圆角、间距和边框常量
  - [x] SubTask 1.2: 为桌面容器、列表面板、状态卡片和输入区确定可复用样式结构

- [x] Task 2: 重构桌面端主框架布局
  - [x] SubTask 2.1: 调整 `lib/pages/desktop_layout.dart`，实现窄导航栏 + 列表面板 + 详情工作区的三栏结构
  - [x] SubTask 2.2: 保持 Chats、Bots、Profile 切换及现有状态联动逻辑正常
  - [x] SubTask 2.3: 优化未选中时的桌面空状态展示

- [x] Task 3: 统一 Chats 与 Bots 的桌面列表面板
  - [x] SubTask 3.1: 将列表页从移动端 `Scaffold/AppBar` 视觉调整为桌面白色圆角面板
  - [x] SubTask 3.2: 统一标题区、搜索框、主操作按钮和列表项样式
  - [x] SubTask 3.3: 补齐 hover、选中态和桌面空状态视觉反馈

- [x] Task 4: 重构聊天详情工作区
  - [x] SubTask 4.1: 调整 `lib/pages/chat.dart` 的桌面端容器层级，形成标题区、消息区和输入区
  - [x] SubTask 4.2: 为消息流增加最大宽度限制和更适合桌面的留白
  - [x] SubTask 4.3: 将过程信息样式整理为状态卡片语义

- [x] Task 5: 升级桌面端输入区样式
  - [x] SubTask 5.1: 调整 `lib/pages/chat/message_input.dart` 的桌面端输入容器、圆角和按钮布局
  - [x] SubTask 5.2: 确保输入焦点、发送按钮和辅助操作的视觉反馈符合 spec

- [x] Task 6: 验证与回归检查
  - [x] SubTask 6.1: 运行格式化与静态检查，确认无新增编译问题
  - [x] SubTask 6.2: 验证 Windows/Linux 桌面端的聊天、智能体和详情联动流程
  - [x] SubTask 6.3: 确认移动端布局与交互无明显回归

# Task Dependencies

- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 1]
- [Task 4] depends on [Task 1] and [Task 2]
- [Task 5] depends on [Task 4]
- [Task 6] depends on [Task 2], [Task 3], [Task 4], and [Task 5]
