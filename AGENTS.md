# AGENTS.md

## Project state
- Spec-only repo: `PRD.md` is authoritative; `README.md` is a placeholder; no Flutter project, manifests, or tests yet.
- Scaffold per `PRD.md` §8 (feature-first Clean Architecture) when starting.

## Stack and constraints
- Flutter/Dart cross-platform app; no backend and no Node.js—direct Dart-to-OpenRouter HTTPS only.
- State: Riverpod; routing: go_router; DB: Drift/SQLite; prefs: SharedPreferences; secrets: flutter_secure_storage.
- API key never logged or stored in plain prefs; deletion supported; HTTPS only.
- Local-first chat history; no mandatory accounts/registration.

## OpenRouter integration
- Base URL `https://openrouter.ai/api/v1`; endpoints: `/models`, `/responses`, `/chat/completions`, `/key`, `/credits`, `/models/{author}/{slug}/endpoints`.
- Validate key via `GET /models` with `Authorization: Bearer <key>`.
- Implement separate request/response adapters for Responses vs Chat Completions APIs.
- Stream via SSE with cancellation, interruption, and completion handling.
- A model is usable for an operation only after endpoint discovery confirms support—do not assume `/models` implies `/responses`.
- Derive model categories from metadata/capabilities, not model names.
- Retry only idempotent operations; never blindly retry payment/non-idempotent calls.

## Data and codegen
- Schema: `conversations(id,title,model_id,created_at,updated_at,is_pinned)`; `messages(id,conversation_id,role,content,created_at,status)`.
- After schema/DAO changes: `flutter pub get` then `dart run build_runner build`.

## Commands (once project exists)
- `flutter pub get`
- `dart run build_runner build`
- `flutter analyze`
- `dart format .`
- `flutter test` (single: `flutter test <file>` or `flutter test --name "<test>"`)
- Integration/API tests require a valid OpenRouter API key; do not run in keyless CI.

## Architecture
- Entry points: `lib/main.dart`, `lib/app.dart`; feature-first under `lib/features/`; services under `lib/services/`.
- Key services: `openrouter_service`, `secure_key_service`, `storage_service`, `streaming_service`.

## Model catalogue caching (PRD §7.3)
- Fetch after key config, cache locally, show cached immediately, refresh on request/periodically, keep stale catalogue offline.

## UI conventions
- Material 3; Inter body (semibold headings), JetBrains Mono code; dark `#090B0A`, light `#F7F8F7`, accent `#10B981`, surface `#202722`.
- Responsive: bottom nav (mobile), adaptive sidebar (tablet), persistent sidebar (desktop).
- Mobile nav: Chat, Discover, History, Settings.
- No comments unless requested.

## Key packages (PRD §9)
- Runtime: flutter_riverpod, go_router, http, flutter_secure_storage, drift, sqlite3_flutter_libs, path_provider, flutter_markdown, google_fonts, uuid, shared_preferences.
- Dev: flutter_lints, drift_dev, build_runner.

## Implementation order
- PRD §16: foundation → API key management → model discovery/compatibility → streaming chat → local data → advanced → production.