# Contributing Guide

## Welcome

CVMatch is a Flutter MVP for AI-assisted career analysis. Contributions should keep the app privacy-conscious, testable, and easy to evolve into a backend-powered SaaS product.

## Prerequisites

- Flutter SDK compatible with the repository Dart constraint.
- Chrome or a supported mobile simulator/device for manual verification.
- Git.

Install dependencies:

```sh
flutter pub get
```

Run the app:

```sh
flutter run -d chrome
```

Run with backend analysis:

```sh
flutter run -d chrome --dart-define=CVMATCH_ANALYSIS_API_URL=https://api.example.com/v1/career-analysis
```

## Development Workflow

1. Read the relevant handbook docs before changing behavior.
2. Keep changes focused on one product or engineering concern.
3. Update tests with the change.
4. Update documentation when contracts, security posture, data handling, or UX behavior changes.
5. Run required checks.
6. Summarize user-visible changes and validation results.

## Required Checks

```sh
dart format lib test
flutter analyze
flutter test
```

## Code Style

- Follow `flutter_lints`.
- Prefer small widgets and small services.
- Keep domain models simple and serializable when they cross service boundaries.
- Use descriptive names.
- Avoid unrelated refactors.
- Avoid one-letter variables except in conventional short callbacks where clarity is not harmed.
- Do not add comments that restate code; document intent when the reason is not obvious.

## Architecture Contributions

When adding features:

- Place feature screens in `lib/src/features/<feature>/presentation/`.
- Place feature models in `lib/src/features/<feature>/domain/models/`.
- Place service contracts in `lib/src/features/<feature>/domain/services/`.
- Place concrete implementations in `lib/src/features/<feature>/data/services/`.
- Place reusable widgets in `lib/src/shared/widgets/`.
- Place cross-cutting config in `lib/src/core/config/`.

Use `CareerAnalysisService` for analysis integrations. Do not bypass it from presentation code.

## Security Contributions

Never commit:

- API keys.
- Provider tokens.
- Private backend URLs with credentials.
- Real CV files.
- Raw extracted CV text from real users.
- Screenshots containing private user information.

Do not add direct OpenAI calls to Flutter. AI provider calls belong on the backend.

## UI Contributions

- Use Material 3.
- Use `AppTheme`.
- Preserve light and dark mode.
- Prefer `AppPage`, `AppCard`, `StatusChip`, and `ScoreBadge`.
- Keep sensitive internal values out of user-facing UI.
- Keep errors friendly and actionable.

## Dependency Contributions

Before adding a dependency:

1. Confirm it is necessary.
2. Check platform support for web and mobile.
3. Check maintenance and license suitability.
4. Consider security impact.
5. Update `ARCHITECTURE.md` and `SECURITY.md` if the dependency touches files, network, auth, payments, storage, or AI.

After adding:

```sh
flutter pub get
flutter analyze
flutter test
```

## Documentation Contributions

Update:

- `PRODUCT.md` for product scope, UX behavior, or non-goals.
- `ARCHITECTURE.md` for structure, dependencies, state, or service changes.
- `API_SPEC.md` for backend request/response changes.
- `DESIGN_SYSTEM.md` for theme, component, or copy changes.
- `DATABASE.md` for persistence or retention changes.
- `SECURITY.md` for data handling or threat model changes.
- `TESTING.md` for test strategy changes.
- `ROADMAP.md` for sequencing changes.
- `CHANGELOG.md` for user-visible or integration changes.

## Pull Request Checklist

- Scope is focused and documented.
- UI works in light and dark mode when applicable.
- Sensitive data is not displayed or logged.
- Backend contracts remain compatible or are documented.
- Tests cover new behavior.
- Required checks pass.
- Changelog is updated for user-visible behavior.

## Related Documents

- Agent rules: `AGENTS.md`
- Architecture: `ARCHITECTURE.md`
- Security: `SECURITY.md`
- Testing: `TESTING.md`
