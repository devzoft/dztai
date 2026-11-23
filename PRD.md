# **DevZoft AI**

## **Complete Product Requirements Document (PRD)**

# **DevZoft AI**

## Your AI. Your Models. Your Intelligence.

Flutter

OpenRouter API

Android

iOS

Windows

macOS

Linux

**Product:** DevZoft AI

**Developer:** Amal K P DevZoft

**Version:** 1.0.0

**Document:** Product Requirements and Technical Specification

**Status:** Development specification

# **1. Product Overview**

DevZoft AI is a cross-platform AI assistant application built using Flutter and Dart. It connects directly to OpenRouter, allowing users to access AI models from multiple providers through one application.

The application provides a unified interface for discovering, selecting, and interacting with AI models.

Users bring their own OpenRouter API key. The application stores that key securely on their device and communicates directly with OpenRouter without requiring a dedicated Node.js backend.

The product aims to deliver a premium AI experience with a clean interface, intelligent model discovery, powerful chat functionality, and local conversation management.

## **1.1 Product vision**

Build a professional AI platform where users can access multiple AI models, manage their AI conversations, and switch between providers without changing applications.

## **1.2 Core objectives**

- Connect directly to OpenRouter.
- Discover the complete available AI model catalogue.
- Support multiple AI providers.
- Provide a unified AI chat interface.
- Allow users to configure their own API key.
- Securely store API credentials locally.
- Support streaming responses.
- Provide local chat history.
- Support dark and light themes.
- Work across mobile and desktop platforms.
- Keep the application free of mandatory registration.

## **1.3 Product positioning**

DevZoft AI is a multi-model AI client, not an AI model provider.

OpenRouter handles model routing, provider connections, and API requests.

# **2. Platform and Technology**

| Component               | Technology                       |
| ----------------------- | -------------------------------- |
| Frontend                | Flutter                          |
| Programming language    | Dart                             |
| API gateway             | OpenRouter                       |
| Networking              | HTTP                             |
| Secure credentials      | Flutter Secure Storage           |
| Local database          | SQLite / Drift                   |
| Lightweight preferences | SharedPreferences                |
| Markdown                | flutter_markdown                 |
| Code highlighting       | Syntax highlighting package      |
| State management        | Riverpod                         |
| Navigation              | go_router                        |
| Unique IDs              | UUID                             |
| Theme                   | Material 3                       |
| Architecture            | Feature-first Clean Architecture |

## **2.1 Supported platforms**

**Android**

Android 8.0+

**iOS**

iOS 15+

**Windows**

Windows 10+

**macOS**

macOS desktop

**Linux**

Linux desktop

# **3. Application Architecture**

## **3.1 High-level architecture**

The application communicates directly with OpenRouter.

## **3.2 Architecture principles**

1. No mandatory application account.
2. No Node.js backend.
3. Direct Dart-to-OpenRouter communication.
4. API credentials never hardcoded.
5. Separate UI, business logic, and networking.
6. Reusable services and repositories.
7. Local-first conversation storage.
8. Responsive mobile and desktop layouts.

## **3.3 Request flow**

1. **User enters API key**

   The key is validated and saved using secure local storage.
2. **Application fetches models**

   Flutter requests the OpenRouter model catalogue.
3. **User selects a model**

   The selected model ID is stored locally.
4. **User sends a prompt**

   Dart sends the request to the appropriate OpenRouter endpoint.
5. **OpenRouter routes the request**

   The selected model provider processes the request.
6. **Application displays the answer**

   The response streams into the chat interface and is saved locally.

# **4. Application Navigation**

The application should have a consistent navigation system.

## **Mobile navigation**

- Chat
- Discover
- History
- Settings

## **Desktop navigation**

A persistent left sidebar with:

- DevZoft AI logo
- New chat
- Search conversations
- Recent conversations
- Model discovery
- Settings
- API status
- User-selected model

# **5. Main Features**

## **5.1 Onboarding**

The first launch should introduce the application.

**Requirements:**

- DevZoft AI branding.
- Short product introduction.
- OpenRouter integration explanation.
- API key setup.
- Connection verification.
- Model catalogue loading.
- First chat experience.

Users must be able to configure their own API key without creating a DevZoft account.

## **5.2 API key management**

Critical feature

Users supply their own OpenRouter API key.

**Settings:**

- Add API key.
- Update API key.
- Delete API key.
- Verify API key.
- Show or hide key.
- Connection status.
- Last verification status.

**Storage:** `flutter_secure_storage`.

**Validation endpoint:**

```
GET https://openrouter.ai/api/v1/models
Authorization: Bearer YOUR_API_KEY
```

The application must never print API keys in debug logs or store them in plain-text preferences.

**Security note:** Secure local storage reduces accidental exposure, but cannot guarantee protection on a compromised or rooted device.

## **5.3 AI model discovery**

Core feature

The application must dynamically fetch the OpenRouter model catalogue.

**API endpoint:**

```
GET https://openrouter.ai/api/v1/models
```

Model information should include:

| Field                | Description                  |
| -------------------- | ---------------------------- |
| id                   | Unique model identifier      |
| name                 | Display name                 |
| description          | Model description            |
| provider             | Model provider               |
| context_length       | Maximum context window       |
| pricing.prompt       | Input token price            |
| pricing.completion   | Output token price           |
| architecture         | Supported modalities         |
| supported_parameters | Supported request parameters |

### **Model categories**

**Chat models**

General-purpose conversational AI

**Coding models**

Programming, debugging and development

**Reasoning models**

Complex analysis and problem-solving

**Vision models**

Image understanding and visual analysis

**Image generation**

Supported image generation models

**Audio models**

Speech, audio and transcription

**Video models**

Video understanding and generation

Categories should be derived from model metadata and supported capabilities, not guessed from model names.

### **Model browser functionality**

- Search by model name.
- Search by provider.
- Filter free models.
- Filter paid models.
- Filter by modality.
- Filter by context length.
- Sort alphabetically.
- Sort by pricing.
- View model details.
- Mark favourite models.
- View supported endpoints.
- Refresh catalogue.
- Cache model catalogue locally.

### **Model compatibility**

A model must only be selectable for an operation if its API endpoint and capabilities support that operation.

For the Responses API, retrieve compatible endpoints using OpenRouter's endpoint discovery functionality, rather than assuming every model returned by `/models` supports `/responses`.

## **5.4 AI Chat**

Core feature

The chat interface is the main application experience.

### **Chat functionality**

- Create new conversation.
- Send messages.
- Receive streaming responses.
- Stop generation.
- Regenerate responses.
- Edit user messages.
- Copy AI responses.
- Copy code blocks.
- Markdown rendering.
- Syntax-highlighted code.
- Selectable text.
- Auto-scroll.
- Message timestamps.
- Model information.
- Error messages and retry.

### **Supported request formats**

**Responses API**

```
POST https://openrouter.ai/api/v1/responses
```

Example:

```
{
  "model": "~openai/gpt-sol-latest",
  "input": "What is the meaning of life?"
}
```

**Chat Completions API**

```
POST https://openrouter.ai/api/v1/chat/completions
```

Example:

```
{
  "model": "deepseek/deepseek-chat",
  "messages": [
    {
      "role": "user",
      "content": "Hello!"
    }
  ],
  "stream": true
}
```

The application should implement separate request and response adapters for each API format.

### **Streaming**

Use Server-Sent Events (SSE) where supported.

Requirements:

- Stream text as it arrives.
- Display generation status.
- Support cancellation.
- Handle network interruption.
- Handle provider errors.
- Detect stream completion.
- Save completed responses.
- Avoid duplicate messages after retries.

## **5.5 Conversation history**

Use SQLite/Drift for persistent conversation storage.

Features:

- Save conversations locally.
- Automatically title conversations.
- Rename conversations.
- Delete conversations.
- Search conversations.
- Pin conversations.
- Sort by latest activity.
- Continue previous conversations.
- Clear all history.
- Export conversation.

Suggested database structure:

**conversations**

| Column     | Type    |
| ---------- | ------- |
| id         | TEXT    |
| title      | TEXT    |
| model_id   | TEXT    |
| created_at | INTEGER |
| updated_at | INTEGER |
| is_pinned  | INTEGER |

**messages**

| Column          | Type    |
| --------------- | ------- |
| id              | TEXT    |
| conversation_id | TEXT    |
| role            | TEXT    |
| content         | TEXT    |
| created_at      | INTEGER |
| status          | TEXT    |

All chat history remains on the user's device unless the user explicitly exports or shares it.

## **5.6 Model details**

Each model should have a dedicated details screen.

Display:

- Model name.
- Provider.
- Model identifier.
- Description.
- Context length.
- Input pricing.
- Output pricing.
- Supported modalities.
- Supported parameters.
- Compatible API endpoints.
- Free or paid status.
- Favourite toggle.

## **5.7 Settings**

Settings should include:

| Setting          | Function                                    |
| ---------------- | ------------------------------------------- |
| API key          | Manage OpenRouter key                       |
| Theme            | Light, dark, system                         |
| Default model    | Select default AI model                     |
| Chat preferences | Configure chat behaviour                    |
| Streaming        | Enable or disable streaming where supported |
| History          | Manage local conversations                  |
| Data             | Export and clear data                       |
| About            | Application information                     |
| Developer        | Amal K P DevZoft                            |

# **6. User Interface and Design System**

## **6.1 Design direction**

Premium, minimal, modern and professional.

The design should take inspiration from polished AI productivity applications without copying another product's identity.

**Brand personality:**

- Intelligent
- Minimal
- Professional
- Fast
- Modern
- Developer-friendly

## **6.2 Colour palette**

**Dark theme**

#090B0A

**Light theme**

#F7F8F7

**Primary accent**

#10B981

**Surface**

#202722

## **6.3 Typography**

- Font: Inter.
- Headings: Semibold.
- Body: Regular.
- Code: JetBrains Mono.
- Buttons: Medium.

## **6.4 Responsive behaviour**

| Screen        | Layout                                   |
| ------------- | ---------------------------------------- |
| Mobile        | Bottom navigation, compact chat          |
| Tablet        | Adaptive sidebar                         |
| Desktop       | Persistent sidebar and wide chat         |
| Large desktop | Centered chat with maximum content width |

# **7. API Integration Specification**

## **7.1 OpenRouter endpoints**

| API             | Endpoint                                   | Purpose                          |
| --------------- | ------------------------------------------ | -------------------------------- |
| Models          | `/api/v1/models`                           | Fetch model catalogue            |
| Responses       | `/api/v1/responses`                        | Generate responses               |
| Chat            | `/api/v1/chat/completions`                 | Chat completions                 |
| Key information | `/api/v1/key`                              | Inspect API key usage and limits |
| Credits         | `/api/v1/credits`                          | Inspect account credits          |
| Endpoints       | `/api/v1/models/{author}/{slug}/endpoints` | Discover model endpoints         |

Base URL:

```
https://openrouter.ai/api/v1
```

## **7.2 API client requirements**

Create a reusable HTTP client that handles:

- Authorization headers.
- JSON serialization.
- Response parsing.
- Request timeouts.
- HTTP errors.
- Network errors.
- Rate limits.
- Streaming.
- Cancellation.
- Retry policies.

Never retry payment-related or non-idempotent operations blindly.

## **7.3 Model catalogue caching**

Recommended strategy:

1. Fetch model catalogue on first launch after API key configuration.
2. Save model metadata locally.
3. Display cached models immediately on subsequent launches.
4. Refresh catalogue when requested.
5. Refresh periodically.
6. Show the last successful update time.
7. Keep stale catalogue available when offline.

# **8. Project Folder Structure**

Recommended production Flutter architecture:

```
devzoft_ai/
│
├── android/
├── ios/
├── windows/
├── macos/
├── linux/
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   └── api_constants.dart
│   │   ├── errors/
│   │   ├── network/
│   │   ├── router/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   │
│   ├── data/
│   │   ├── database/
│   │   ├── repositories/
│   │   └── local/
│   │
│   ├── models/
│   │   ├── ai_model.dart
│   │   ├── chat_message.dart
│   │   └── conversation.dart
│   │
│   ├── services/
│   │   ├── openrouter_service.dart
│   │   ├── secure_key_service.dart
│   │   ├── storage_service.dart
│   │   └── streaming_service.dart
│   │
│   ├── features/
│   │   ├── onboarding/
│   │   ├── chat/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   ├── models/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── providers/
│   │   ├── history/
│   │   └── settings/
│   │
│   └── shared/
│       ├── widgets/
│       └── providers/
│
├── test/
├── integration_test/
├── pubspec.yaml
└── README.md
```

# **9. Flutter Dependencies**

Recommended `pubspec.yaml` packages:

```
dependencies:
  flutter:
    sdk: flutter

  flutter_riverpod: ^2.6.1
  go_router: ^15.1.2

  http: ^1.3.0
  flutter_secure_storage: ^9.2.4

  drift: ^2.26.0
  sqlite3_flutter_libs: ^0.5.32
  path_provider: ^2.1.5
  path: ^1.9.0

  flutter_markdown: ^0.7.7
  google_fonts: ^6.2.1
  uuid: ^4.5.1
  shared_preferences: ^2.5.3

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^5.0.0
  drift_dev: ^2.26.0
  build_runner: ^2.4.15
```

These are proposed dependency versions. Resolve and test compatible versions when implementing the project.

# **10. Functional Requirements**

| ID     | Requirement                     | Priority |
| ------ | ------------------------------- | -------- |
| FR-001 | Configure OpenRouter API key    | Critical |
| FR-002 | Securely store API key          | Critical |
| FR-003 | Verify API key                  | Critical |
| FR-004 | Fetch all available models      | Critical |
| FR-005 | Search and filter models        | High     |
| FR-006 | Select AI model                 | Critical |
| FR-007 | Send AI messages                | Critical |
| FR-008 | Stream AI responses             | Critical |
| FR-009 | Stop generation                 | High     |
| FR-010 | Save chat history               | High     |
| FR-011 | Render Markdown                 | High     |
| FR-012 | Copy messages and code          | Medium   |
| FR-013 | Dark and light themes           | High     |
| FR-014 | Export conversations            | Medium   |
| FR-015 | Favourite models                | Medium   |
| FR-016 | Model pricing information       | High     |
| FR-017 | Endpoint compatibility checking | Critical |
| FR-018 | Local model caching             | High     |
| FR-019 | Desktop responsive layout       | High     |
| FR-020 | Error and retry handling        | High     |

# **11. Non-Functional Requirements**

### **Performance**

- Fast initial application startup.
- Avoid blocking the UI during network operations.
- Smooth response streaming.
- Efficient model catalogue caching.
- Paginated or virtualized long conversation lists.

### **Security**

- Secure local API key storage.
- No API key logging.
- No hardcoded API credentials.
- HTTPS requests only.
- Clear API key deletion.
- No unnecessary collection of personal data.

### **Reliability**

- Graceful network error handling.
- Offline access to local chat history.
- Recoverable incomplete conversations.
- Clear rate-limit messages.
- Model availability handling.

### **Accessibility**

- Screen-reader support.
- Keyboard navigation.
- Readable contrast.
- Responsive text sizing.
- Accessible controls.

# **12. Monetization and Cost Model**

DevZoft AI does not need to charge users for model access.

Users pay for their own OpenRouter usage according to the selected model and provider.

Potential future monetization:

- Optional DevZoft AI Pro interface features.
- Custom themes.
- Advanced local organization tools.
- Productivity features.
- Optional integrations.

No mandatory subscription is required for the core application.

# **13. Development Roadmap**

1. **Phase 1: Foundation**
   - Flutter project setup.
   - App architecture.
   - Theme system.
   - Navigation.
   - Secure API key management.
2. **Phase 2: OpenRouter Integration**
   - HTTP client.
   - API key verification.
   - Model catalogue.
   - Model search and filtering.
   - Endpoint discovery.
   - Pricing and model metadata.
3. **Phase 3: AI Chat**
   - Chat screen.
   - Responses API.
   - Chat Completions API.
   - Streaming.
   - Stop generation.
   - Markdown and code rendering.
4. **Phase 4: Local Data**
   - SQLite integration.
   - Conversation history.
   - Search.
   - Rename and delete.
   - Favourites.
   - Export.
5. **Phase 5: Advanced Features**
   - Vision support.
   - Image generation where supported.
   - Audio capabilities.
   - File attachments.
   - Advanced model settings.
6. **Phase 6: Production**
   - Android testing.
   - iOS testing.
   - Windows testing.
   - macOS testing.
   - Linux testing.
   - Performance and security audits.
   - Release builds.

# **14. Testing Strategy**

| Test type         | What to test                 |
| ----------------- | ---------------------------- |
| Unit tests        | Models, parsers, pricing     |
| API tests         | OpenRouter responses         |
| Widget tests      | Chat and model browser       |
| Integration tests | API key to first response    |
| Streaming tests   | SSE parsing and cancellation |
| Database tests    | Conversations and messages   |
| Security tests    | API key handling             |
| Platform tests    | Android, iOS and desktop     |

### **Acceptance criteria**

The first production release is considered ready when:

- Users can enter and securely save an OpenRouter key.
- API key verification works.
- All available models can be fetched.
- Model search and filters work.
- Endpoint compatibility is checked.
- Users can select a compatible model.
- Chat messages reach OpenRouter successfully.
- Streaming responses render correctly.
- Users can stop generation.
- Conversations persist locally.
- Light and dark themes work.
- No Node.js backend is required.
- All target platform builds pass their respective tests.

# **15. Version 1.0 Scope**

The initial release should focus on reliable AI chat and model discovery.

## **DevZoft AI v1.0**

MVP scope

**Included**

- OpenRouter API key management
- Complete model catalogue
- Model search and filtering
- Free and paid model indicators
- Model compatibility checking
- Multi-model AI chat
- Streaming responses
- Markdown and code blocks
- Local conversation history
- Dark and light themes
- Android, iOS and desktop

**Future releases**

- Image generation
- File and document analysis
- Voice conversations
- Web search integrations
- Advanced AI workflows
- Custom system prompts
- Multiple model comparison
- Local model integrations

# **16. Final Product Definition**

**DevZoft AI** is a Flutter-based, cross-platform, multi-model AI assistant powered by OpenRouter.

It provides users with a single application to discover, compare and interact with AI models from different providers using their own API key.

The product will be built with Dart, Flutter, local storage and direct OpenRouter API integration, with no mandatory account system or custom backend.

# **DevZoft AI**

## One App. Multiple AI Models. Unlimited Possibilities.

Developed by Amal K P DevZoft

Product requirements specification · Version 1.0.0

**Recommended implementation order:** Start with the complete Flutter foundation, then build API key management, OpenRouter model discovery, model compatibility, and finally the streaming chat system. This keeps the most important product functionality testable from the beginning.
