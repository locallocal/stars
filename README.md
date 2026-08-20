<p align="center">
  <img src="assets/icon/app_icon.png" alt="Stars app logo" width="128" height="72">
</p>

# Stars

[English](README.md) | [简体中文](docs/README_zh-CN.md)

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
- **MCP Tools** — connect HTTPS Streamable HTTP servers or run trusted desktop
  stdio servers, discover Tools progressively, and keep access tokens and
  process environment variables in the operating system credential store.
- **Responsive UI** — use layouts tailored for Windows, macOS, Linux, Android,
  and iOS.
- **Light, dark, and high-contrast themes** — adapt the interface to different
  environments and accessibility preferences.
- **12 interface languages** — switch between English, Simplified Chinese,
  Traditional Chinese, Japanese, French, German, Korean, Russian, Spanish,
  Hindi, Brazilian Portuguese, and Italian from profile settings.

The complete provider registry is available in
[`ai_provider_repository_impl.dart`](lib/data/repositories/ai_provider_repository_impl.dart).

## Getting Started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) 3.44.6 (pinned in
  `.fvmrc`) with Dart 3.7 or later
- A configured desktop or mobile Flutter toolchain for your target platform
- An API key for your chosen cloud provider, or a reachable local service such
  as Ollama
- On Linux, the `libsecret-1-dev` build package and `libsecret-1-0` runtime
  package for secure MCP credential storage

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
flutter pub get --enforce-lockfile
dart run tool/sync_localizations.dart --check
dart run intl_utils:generate
dart run tool/check_format.dart
dart analyze --fatal-infos
flutter test
flutter build linux --release
```

`intl_utils` is the only localization generator. Generated files under
`lib/generated/` are committed and intentionally excluded from the formatter.
After regenerating, review their Git diff together with the catalog changes.
Format only changed, non-generated Dart files, for example:

```bash
dart format lib/ui/features/example.dart test/example_test.dart
```

Every locale must contain the same message keys and placeholders as
`lib/l10n/intl_en.arb`. When bootstrapping untranslated messages,
`dart run tool/sync_localizations.dart --write` adds explicit English
fallbacks; replace them with translations before release.

### Local disk caches

`build/` and `.dart_tool/` are generated and ignored by Git. If local caches
become stale or disk usage is too high, run `flutter clean`; remove
`.dart_tool/` only when deeper dependency/build-hook cleanup is needed, then
restore it with `flutter pub get --enforce-lockfile`.

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

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) and the
[Code of Conduct](CODE_OF_CONDUCT.md), then open a focused pull request. Report
vulnerabilities privately according to [SECURITY.md](SECURITY.md). User-visible
changes are tracked in [CHANGELOG.md](CHANGELOG.md).

## License

Stars is licensed under the [GNU Affero General Public License v3.0 only](LICENSE)
(`AGPL-3.0-only`). See [NOTICE](NOTICE) for copyright information. If you
modify Stars and let users interact with that version over a network, review
the source-code offer requirements in section 13 of the license.
