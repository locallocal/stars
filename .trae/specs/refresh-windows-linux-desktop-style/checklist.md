- [x] 已创建桌面端三栏布局，并保留 Chats / Bots / Profile 的可用导航
- [x] Chats 与 Bots 列表页已统一为桌面面板样式
- [x] 右侧聊天详情区已具备桌面标题区、消息区和底部输入区结构
- [x] 消息流已增加最大宽度限制，桌面阅读体验优于当前实现
- [x] 过程信息已支持独立状态卡片样式或等效桌面化展示
- [x] 未选中聊天或智能体时，右侧已展示桌面风格空状态
- [x] 桌面端输入区已升级为白色圆角固定底部样式，并具备焦点反馈
- [x] 现有的新建聊天、选择聊天、选择智能体、编辑智能体流程仍可正常工作
- [x] 格式化和静态检查已完成，未引入新的明显错误
- [x] 移动端布局与交互未出现明显回归

## 验证记录（2026-07-11）

- 代码核验范围：`lib/main.dart`、`lib/pages/desktop_layout.dart`、`lib/pages/chats.dart`、`lib/pages/bots.dart`、`lib/pages/chat.dart`、`lib/pages/chat/message_list.dart`、`lib/pages/chat/message_input.dart`、`lib/utils/theme.dart`、以及新建聊天/编辑智能体相关页面。
- 格式化检查：运行 `dart format --output=none --set-exit-if-changed lib`，输出 `Formatted 101 files (1 changed)`，说明检查已执行并对生成文件做了一次格式化。
- 静态检查：运行 `flutter analyze`，结果为 45 条 `info` 级 lint，未出现 `error` 或 `warning` 级问题。
- 补充验证：运行 `flutter test` 时，现有 `test/widget_test.dart` 仍是旧的 `Counter increments smoke test`，与当前应用入口不匹配并停在加载阶段，因此未将该测试作为本 checkpoint 的通过前提。
