# Stars

Stars is a cross-platform AI chat client built with Flutter. It provides a
responsive experience for desktop and mobile devices, connects to a broad range
of AI providers, and keeps bots, conversations, messages, and preferences in a
local SQLite database.

## Features

- **Multi-provider AI access** — use OpenAI, Anthropic, Gemini, DeepSeek,
  Ollama, OpenRouter, Mistral, Cohere, Perplexity, and many other supported
  services.
- **Custom assistants** — configure each bot with its own provider, model,
  endpoint, API key, and system prompt.
- **Streaming conversations** — receive generated responses as they arrive in
  a chat interface designed for long-running conversations.
- **Local persistence** — store bots, chats, messages, and profile settings in
  SQLite on the device.
- **Responsive UI** — use layouts tailored for Windows, macOS, Linux, Android,
  and iOS.
- **Light, dark, and high-contrast themes** — adapt the interface to different
  environments and accessibility preferences.
- **English and Simplified Chinese** — switch the application language from
  the profile settings.

The complete provider registry is available in
[`ai_provider_repository_impl.dart`](lib/data/repositories/ai_provider_repository_impl.dart).

## Getting Started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) with Dart 3.7 or
  later
- A configured desktop or mobile Flutter toolchain for your target platform
- An API key for your chosen cloud provider, or a reachable local service such
  as Ollama

### Run the application

```bash
git clone https://github.com/locallocal/stars.git
cd stars
flutter pub get
flutter run
```

After launching Stars, add a bot and enter its provider, model, endpoint, API
key, and system prompt. Provider credentials are stored locally with the bot
configuration, so protect access to your device and application data.

## Development

Install dependencies and run the standard checks:

```bash
flutter pub get
dart analyze
flutter test
dart format --output=none --set-exit-if-changed .
```

To format the project after making changes, run:

```bash
dart format .
```

## Architecture

Stars follows a layered Flutter architecture:

```text
lib/
├── data/       # SQLite repositories, provider integrations, and data models
├── domain/     # Business models, repository contracts, and use cases
├── ui/         # Feature views, view models, dependency injection, and widgets
└── l10n/       # Localization resources
```

See [Architecture](docs/architecture.md) for the dependency rules and design
decisions used by the project.

## Contributing

Contributions are welcome. Create a focused branch, keep changes covered by
tests where practical, run the checks above, and open a pull request with a
clear description of the problem and solution.
