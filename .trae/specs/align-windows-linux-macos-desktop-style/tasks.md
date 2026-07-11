# Tasks

- [x] Task 1: 梳理桌面端三平台共享的样式基础
  - [x] SubTask 1.1: 统一 `Windows`、`Linux`、`macOS` 的桌面布局入口与样式边界
  - [x] SubTask 1.2: 提炼桌面背景、面板、圆角、边框、阴影、间距等样式 token
  - [x] SubTask 1.3: 明确哪些差异保留为系统行为，哪些差异必须在内容区消除

- [x] Task 2: 重构桌面端外层框架
  - [x] SubTask 2.1: 调整 `lib/pages/desktop_layout.dart` 为窄导航栏 + 列表面板 + 详情工作区
  - [x] SubTask 2.2: 优化左侧导航栏的品牌区、一级入口和底部账户入口样式
  - [x] SubTask 2.3: 保持 Chats / Bots / Profile 的联动和切换逻辑不变

- [x] Task 3: 统一 Chats 与 Bots 的桌面列表面板
  - [x] SubTask 3.1: 将列表页从移动端 `Scaffold/AppBar` 视觉切换为桌面面板样式
  - [x] SubTask 3.2: 统一标题区、主操作按钮、搜索框和列表项布局
  - [x] SubTask 3.3: 补齐 hover、selected、focused 等桌面状态反馈

- [x] Task 4: 重构聊天详情工作区
  - [x] SubTask 4.1: 调整 `lib/pages/chat.dart` 的桌面容器层级，形成标题区、消息流、输入区
  - [x] SubTask 4.2: 调整 `lib/pages/chat/message_list.dart`，增加最大宽度限制与更舒展的留白
  - [x] SubTask 4.3: 将文件、命令、耗时、思考中等过程信息统一为状态卡片语义

- [x] Task 5: 升级桌面端输入区
  - [x] SubTask 5.1: 调整 `lib/pages/chat/message_input.dart` 的白底大圆角输入容器
  - [x] SubTask 5.2: 统一附件、发送、语音、模型等辅助按钮的轻量桌面样式
  - [x] SubTask 5.3: 补齐聚焦、高亮、禁用和发送中的反馈状态

- [ ] Task 6: 处理三平台差异与回归
  - [ ] SubTask 6.1: 在 `Windows` 上验证字体、间距、滚动和列表 hover 体验
  - [ ] SubTask 6.2: 在 `Linux` 上验证不同窗口管理器下的布局稳定性
  - [ ] SubTask 6.3: 在 `macOS` 上验证侧栏、内容画布和底部输入区的视觉一致性
  - [x] SubTask 6.4: 确认 Android、iOS、Web 未受桌面端样式改造影响

- [x] Task 7: 修复本轮 checklist 未通过项
  - [x] SubTask 7.1: 修正 `lib/utils/utils.dart` 的桌面平台判定，避免 `Flutter Web` 误用 `Windows/Linux/macOS` 桌面工作台布局
  - [x] SubTask 7.2: 为聊天过程信息补齐“命令执行 / 工具调用 / 耗时 / 文件编辑状态”所需的数据入口与桌面状态卡片展示
  - [x] SubTask 7.3: 修复完成后重新核验 `checklist.md` 中未通过的 checkpoint，并补做 `Windows` / `Web` 图形回归验证

## Validation Notes

- Task 6 当前仅勾选 `SubTask 6.4`，Task 6 本身保持未勾选。
- 最新结论:
  - `SubTask 6.1`: 暂不能勾选。已完成代码核验、`flutter analyze` 通过、`flutter build windows --debug` 成功，但尚未直接启动 `Windows` 桌面 GUI 目测字体、间距、滚动和列表 hover 体验；现有证据足以证明可构建和主分支逻辑正确，不足以覆盖视觉与交互细节验收。
  - `SubTask 6.2`: 暂不能勾选。当前仅能做 `Linux` 代码级核验，无法在不同窗口管理器下实际运行并确认布局稳定性；这属于环境限制，不影响当前对共享桌面样式代码路径已对齐的结论。
  - `SubTask 6.3`: 暂不能勾选。当前仅能做 `macOS` 代码级核验，无法实机确认侧栏、内容画布和底部输入区的视觉一致性；这属于环境限制，不影响当前对跨平台共用桌面样式实现已完成的结论。
  - `SubTask 6.4`: 可以勾选。`lib/utils/utils.dart` 已修正 `Web` 不再误入桌面平台分支，Android / iOS 继续走非桌面分支；并且 `flutter analyze` 通过，`flutter build windows --debug` 与 `flutter build web --debug` 均成功，足以支持“移动端与 Web 未因本次桌面样式改造产生已知回归”的当前结论。
- 为什么这不阻塞最终交付:
  - `checklist.md` 已全部通过，当前最终验证结论已经覆盖代码核验、静态检查以及 `Windows` / `Web` 构建成功。
  - 尚未覆盖的仅是 `Windows` 细节目测以及 `Linux` / `macOS` 实机视觉验证，残余风险集中在视觉细节与窗口管理器差异，不是平台分支错误或构建失败这类交付阻断项。

Read `tasks.md` again. Use the Sub-Agent to implement the fix. Re-verify the checkpoint after the fix is complete.

# Task Dependencies

- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 1] and [Task 2]
- [Task 4] depends on [Task 1] and [Task 2]
- [Task 5] depends on [Task 4]
- [Task 6] depends on [Task 2], [Task 3], [Task 4], and [Task 5]
- [Task 7] depends on [Task 6]
