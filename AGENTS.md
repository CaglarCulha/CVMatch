# Agent Engineering Guide

This file applies to the entire repository. It is the operating guide for AI coding agents and human contributors working on CVMatch.

## Project Snapshot

CVMatch is a Flutter Material 3 career-assistant MVP. The app lets a user upload a PDF CV, extracts readable text locally, collects a job description, and analyzes the CV against the job through either:

- `MockAnalysisService` when no backend URL is configured.
- `ApiCareerAnalysisService` when `CVMATCH_ANALYSIS_API_URL` is provided with `--dart-define`.

The Flutter client must never call OpenAI directly, store provider API keys, or persist raw CV text unless an explicit product and security decision is documented first. See `SECURITY.md`, `API_SPEC.md`, and `DATABASE.md`.

## Required Commands

Run these before handing off changes that affect Dart, Flutter, tests, dependencies, or docs with embedded commands:

```sh
dart format lib test
flutter analyze
flutter test
```

For local web verification:

```sh
flutter run -d chrome
flutter run -d chrome --dart-define=CVMATCH_ANALYSIS_API_URL=https://api.example.com/v1/career-analysis
```

## Repository Map

- `lib/main.dart` starts `CVMatchApp`.
- `lib/src/app/` owns routing and in-memory application state.
- `lib/src/core/config/` owns runtime configuration.
- `lib/src/core/theme/` owns Material 3 theme tokens.
- `lib/src/core/mock/` owns demo data.
- `lib/src/features/*/presentation/` contains feature screens.
- `lib/src/features/*/domain/` contains models and service contracts.
- `lib/src/features/*/data/` contains concrete service implementations.
- `lib/src/shared/widgets/` contains reusable UI primitives.
- `test/` contains unit and widget tests.

## Architecture Rules

- Keep feature code under `lib/src/features/<feature>/`.
- Put reusable UI in `lib/src/shared/widgets/`, not inside a feature folder.
- Put cross-cutting runtime config in `lib/src/core/config/`.
- Keep domain models free of Flutter widget dependencies.
- New analysis integrations must implement `CareerAnalysisService`.
- Keep `MockAnalysisService` deterministic enough for tests.
- Keep file paths, data URIs, raw PDF bytes, and raw extracted CV text out of normal UI.
- Use `CVMatchState` for current app-wide in-memory state until a documented state-management migration is accepted.
- Do not introduce Firebase, RevenueCat, OpenAI SDKs, analytics SDKs, or persistent storage without updating `ARCHITECTURE.md`, `SECURITY.md`, and `DATABASE.md`.

## UI Rules

- Use Material 3 and the centralized theme in `lib/src/core/theme/app_theme.dart`.
- Prefer existing primitives: `AppPage`, `AppCard`, `StatusChip`, and `ScoreBadge`.
- Maintain light and dark mode compatibility.
- Keep spacing consistent with existing screen rhythm: 8, 12, 16, 20, 24, and 32 px.
- Avoid displaying private internal values such as full file paths or extracted CV text outside debug-only sections.

## Security Rules

- No API keys in Flutter code, assets, `.env` files, README examples, tests, or screenshots.
- Backend URLs may be configured with `--dart-define`; secrets may not.
- Treat CV content and job descriptions as sensitive personal data.
- Use friendly errors for PDF extraction and API failures. Do not surface raw stack traces to users.
- When adding logging, redact CV text, file paths, and backend response bodies by default.

## Testing Rules

- Add unit tests for service parsing, validation, and error handling.
- Add widget tests for navigation, user-visible validation, and sensitive-data non-disclosure.
- Use mocked clients/channels for external boundaries.
- Do not make tests depend on real network, local machine files, or provider credentials.

## Documentation Rules

Update the handbook when behavior changes:

- Product scope changes: `PRODUCT.md`, `ROADMAP.md`.
- Architecture or dependency changes: `ARCHITECTURE.md`, `SECURITY.md`.
- Backend contract changes: `API_SPEC.md`.
- Data persistence changes: `DATABASE.md`.
- Visual system changes: `DESIGN_SYSTEM.md`.
- Test strategy changes: `TESTING.md`.
- Contributor workflow changes: `CONTRIBUTING.md`.
- User-visible or integration changes: `CHANGELOG.md`.

## Definition of Done

A change is ready when:

- The implementation matches the requested scope without unrelated refactors.
- `dart format lib test`, `flutter analyze`, and `flutter test` pass.
- Sensitive data is not exposed in normal UI or logs.
- Public contracts are documented.
- The final response names the files changed and validation performed.
