# Stars

[English](../README.md) | 简体中文 | [文档导航](README.md)

Stars 是一款使用 Flutter 构建的跨平台 AI 聊天客户端。它为桌面端和移动端提供响应式体验，
支持连接多种 AI 服务，并使用本地 SQLite 数据库存储助手、会话、消息和偏好设置。

## 功能特性

- **支持多种 AI 服务**：可接入 OpenAI、Anthropic、Gemini、DeepSeek、Ollama、
  OpenRouter、Mistral、Cohere、Perplexity 等众多服务。
- **自定义助手**：可以为每个助手单独配置服务商、模型、接口地址、API 密钥和系统提示词。
- **流式会话**：在专为长对话设计的聊天界面中，实时接收生成内容。
- **本地数据存储**：使用设备上的 SQLite 数据库保存助手、会话、消息和个人设置。
- **响应式界面**：针对 Windows、macOS、Linux、Android 和 iOS 提供适配布局。
- **MCP 工具**：连接 HTTPS Streamable HTTP 服务器，或在桌面端运行可信的 stdio
  服务器；渐进发现工具，并将访问令牌和进程环境变量保存在操作系统安全凭据存储中。
- **多种显示模式**：支持浅色、深色和高对比度主题，以适应不同环境和无障碍需求。
- **12 种界面语言**：可在个人设置中切换英文、简体中文、繁体中文、日语、法语、
  德语、韩语、俄语、西班牙语、印地语、巴西葡萄牙语和意大利语。

完整的服务商注册列表请参阅
[`provider_catalog.dart`](../lib/domain/models/provider_catalog.dart)。

## 快速开始

### 环境要求

- 安装 `.fvmrc` 固定的 [Flutter 3.44.6](https://docs.flutter.dev/get-started/install)
  （包含 Dart 3.7 或更高版本）
- 为目标平台配置好 Flutter 桌面端或移动端开发环境
- 准备所选云服务商的 API 密钥，或一个可以访问的 Ollama 等本地服务
- Linux 还需安装用于安全存储 MCP 凭据的 `libsecret-1-dev` 构建依赖和
  `libsecret-1-0` 运行时依赖

### 运行应用

```bash
git clone https://github.com/locallocal/stars.git
cd stars
flutter pub get
flutter run
```

启动 Stars 后，添加一个助手并填写服务商、模型、接口地址、API 密钥和系统提示词。
服务商凭据会随助手配置保存在本地，请妥善保护设备和应用数据。

## 开发

安装依赖并运行项目检查：

```bash
flutter pub get --enforce-lockfile
dart run tool/sync_localizations.dart --check
dart run intl_utils:generate
dart run tool/check_format.dart
dart analyze --fatal-infos
flutter test
flutter build linux --release
```

`intl_utils` 是项目唯一的本地化生成器。`lib/generated/` 下的生成文件会提交到仓库，
但不参与格式化；重新生成后应同时检查它们与语言目录的 Git 差异。只格式化本次修改的
非生成 Dart 文件，例如：

```bash
dart format lib/ui/features/example.dart test/example_test.dart
```

每种语言必须包含与 `lib/l10n/intl_en.arb` 相同的消息键和占位符。
`dart run tool/sync_localizations.dart --write` 可机械补齐英文回退文本，发布前应替换为对应
语言的翻译。

`build/` 和 `.dart_tool/` 是已忽略的本地缓存。缓存异常或磁盘占用过高时先运行
`flutter clean`；只有需要彻底重建依赖或 build hook 时才删除 `.dart_tool/`，之后用
`flutter pub get --enforce-lockfile` 恢复。

## 项目架构

Stars 采用分层 Flutter 架构：

```text
lib/
├── data/       # SQLite 仓库、服务商集成和数据模型
├── domain/     # 业务模型、仓库接口和用例
├── ui/         # 功能视图、视图模型、依赖注入和组件
└── l10n/       # 本地化资源
```

有关项目的依赖规则和设计决策，请参阅[架构文档](architecture.md)；其他长期规范和实现
参考见[文档导航](README.md)。

## 参与贡献

欢迎参与贡献。请先阅读[贡献指南](../CONTRIBUTING.md)和
[行为准则](../CODE_OF_CONDUCT.md)，再提交范围明确的 Pull Request。安全问题请按
[安全策略](../SECURITY.md)私下报告；用户可见变更记录在[变更日志](../CHANGELOG.md)。

## 许可证

Stars 仅按 [GNU Affero General Public License v3.0](../LICENSE)（`AGPL-3.0-only`）
授权，版权说明见 [`NOTICE`](../NOTICE)。如果修改 Stars 并通过网络向用户提供该版本，
请同时核对许可证第 13 条关于源代码提供的要求。
