# DevZoft AI

DevZoft AI is a local-first, cross-platform AI assistant built with Flutter. It connects directly to [OpenRouter](https://openrouter.ai/) so users can discover models, switch providers, and chat with AI using their own API key.

The application has no mandatory account or backend. API requests go from the Flutter app directly to OpenRouter, while conversations and credentials remain on the user's device.


## Features

### Implemented

- OpenRouter API key setup, verification, secure storage, update, and deletion
- Dynamic model catalogue loading
- Model search and category/free-model filters
- Favourite model selection
- Model details and OpenRouter endpoint discovery
- Chat Completions and Responses API streaming adapters
- Streaming chat with cancellation and persisted assistant responses
- Local Drift/SQLite conversation and message storage
- Conversation history, default model selection, and theme settings
- Material 3 light, dark, and system themes
- Responsive application shell for mobile and desktop layouts

### Planned in the PRD

- Catalogue caching and offline stale-data fallback
- Rich Markdown rendering and code copy controls
- Conversation renaming, pinning, search, export, and automatic titles
- Retry, regenerate, edit-message, and interruption improvements
- Full model compatibility and endpoint filtering
- Expanded chat preferences and key usage information

## Supported Platforms

- Android
- iOS
- Windows
- macOS
- Linux

## Tech Stack

- Flutter and Dart
- Riverpod for state management
- go_router for navigation
- Drift/SQLite for local conversations
- flutter_secure_storage for API credentials
- SharedPreferences for lightweight settings
- HTTP and Server-Sent Events for OpenRouter requests
- Google Fonts, with Inter for UI text
- Material 3

## Architecture

The project follows a feature-first Clean Architecture structure:

```text
lib/
├── core/
│   ├── constants/
│   ├── router/
│   ├── theme/
│   └── widgets/
├── data/
│   ├── database/
│   └── repositories/
├── features/
│   ├── chat/
│   ├── history/
│   ├── models/
│   ├── onboarding/
│   └── settings/
├── models/
├── services/
└── shared/
```

- `features/`: Screens and feature-specific providers
- `core/`: Routing, theme, constants, and shared widgets
- `services/`: OpenRouter, secure key, storage, and streaming integrations
- `data/`: Drift database and repositories
- `models/`: Application domain models

## Getting Started

### Practical first-run requirement

The app may look for a valid OpenRouter API key before allowing access to chat. You will need:

- Flutter SDK
- Dart SDK included with Flutter
- Platform tooling for the target device or desktop OS
- An OpenRouter account and API key

### Install and run

```bash
flutter pub get
flutter run
```

When the app starts, open Settings or complete onboarding and enter an OpenRouter API key. The key is checked through `GET /api/v1/models` before it is saved.

## OpenRouter Integration

The base API URL is:

```text
https://openrouter.ai/api/v1
```

The app currently integrates these endpoints:

| Endpoint | Purpose |
| --- | --- |
| `/models` | Validate API keys and fetch the model catalogue |
| `/chat/completions` | Chat Completions requests and SSE streaming |
| `/responses` | Responses API requests and SSE streaming |
| `/key` | Fetch API key information |
| `/credits` | Fetch account credit information |
| `/models/{author}/{slug}/endpoints` | Discover model endpoints |

API credentials are held with `flutter_secure_storage` and are not written to plain-text preferences or logged.

## Local Data

Drift creates a local SQLite database named `devzoft_ai.sqlite`.

The database includes:

- `conversations`: id, title, model ID, timestamps, and pinned state
- `messages`: id, conversation ID, role, content, timestamp, and status

Conversations remain on the device. They are not uploaded by the application.

## Development

Install dependencies:

```bash
flutter pub get
```

Regenerate Drift code after database or DAO changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Format and analyze:

```bash
dart format .
flutter analyze
```

Run tests:

```bash
flutter test
```

## Security

- Keep API keys out of source control and command history.
- Never commit a real OpenRouter key.
- The app sends keys only through authorization headers.
- Secure storage reduces exposure but cannot guarantee protection on a compromised or rooted device.
- User chat data remains local unless the user explicitly exports or shares it.

## Project Information

- Product: DevZoft AI
- Version: 1.0.0
- Developer: Amal K P

