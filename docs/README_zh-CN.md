# Stars

[English](../README.md) | 简体中文

Stars 是一款使用 Flutter 构建的跨平台 AI 聊天客户端。它为桌面端和移动端提供响应式体验，
支持连接多种 AI 服务，并使用本地 SQLite 数据库存储助手、会话、消息和偏好设置。

## 功能特性

- **支持多种 AI 服务**：可接入 OpenAI、Anthropic、Gemini、DeepSeek、Ollama、
  OpenRouter、Mistral、Cohere、Perplexity 等众多服务。
- **自定义助手**：可以为每个助手单独配置服务商、模型、接口地址、API 密钥和系统提示词。
- **流式会话**：在专为长对话设计的聊天界面中，实时接收生成内容。
- **本地数据存储**：使用设备上的 SQLite 数据库保存助手、会话、消息和个人设置。
- **响应式界面**：针对 Windows、macOS、Linux、Android 和 iOS 提供适配布局。
- **多种显示模式**：支持浅色、深色和高对比度主题，以适应不同环境和无障碍需求。
- **中英文界面**：可在个人设置中切换英文和简体中文。

完整的服务商注册列表请参阅
[`ai_provider_repository_impl.dart`](../lib/data/repositories/ai_provider_repository_impl.dart)。

## 快速开始

### 环境要求

- 安装包含 Dart 3.7 或更高版本的
  [Flutter](https://docs.flutter.dev/get-started/install)
- 为目标平台配置好 Flutter 桌面端或移动端开发环境
- 准备所选云服务商的 API 密钥，或一个可以访问的 Ollama 等本地服务

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
flutter pub get
dart analyze
flutter test
dart format --output=none --set-exit-if-changed .
```

修改代码后，可使用以下命令格式化项目：

```bash
dart format .
```

## 项目架构

Stars 采用分层 Flutter 架构：

```text
lib/
├── data/       # SQLite 仓库、服务商集成和数据模型
├── domain/     # 业务模型、仓库接口和用例
├── ui/         # 功能视图、视图模型、依赖注入和组件
└── l10n/       # 本地化资源
```

有关项目的依赖规则和设计决策，请参阅[架构文档](architecture.md)。

## 参与贡献

欢迎参与贡献。请为改动创建范围明确的分支，在适用时补充测试，运行上述检查，
并通过 Pull Request 清楚说明要解决的问题和采用的方案。
