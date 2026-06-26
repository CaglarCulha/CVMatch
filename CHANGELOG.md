# Changelog

This changelog follows the spirit of Keep a Changelog and uses the app version from `pubspec.yaml`.

## 1.0.0+1 - 2026-06-26

### Added

- Node.js + Express + TypeScript backend foundation in `backend/`.
- `POST /analyze` backend endpoint accepting CV text, CV file name, job description, locale, and target role.
- Backend validation with Zod for analysis requests and `CvAnalysisResult` responses.
- Extensible backend AI provider architecture with `AIProvider`, `MockProvider`, `OpenAIProvider`, `ProviderFactory`, `AnalysisOrchestrator`, `PromptBuilder`, `ResponseParser`, and `ResultValidator`.
- Real `OpenAIProvider` implementation using the official OpenAI Node SDK, structured JSON output, timeout handling, safe error mapping, and mocked tests.
- Backend `.env.example` with server-side `OPENAI_API_KEY` configuration.
- Backend README with local setup and Flutter connection instructions.
- Flutter Material 3 MVP for CVMatch.
- Light and dark mode with blue/indigo SaaS visual direction.
- Login, dashboard, upload CV, job description, analysis result, and paywall screens.
- Dashboard cards for Upload CV, Analyze Job, Previous Analyses, and Premium.
- PDF-only selection with `file_picker`.
- Cross-platform file access with `cross_file`.
- Local readable-text PDF extraction with `syncfusion_flutter_pdf`.
- `CvDocument` model with file name, file size, extracted text, page count, and extraction status.
- Friendly PDF extraction errors for empty, scanned/image-only, corrupt, and password-protected PDFs.
- Debug-only extraction diagnostics showing character count, page count, and a truncated text preview.
- In-memory app state through `CVMatchState` and `CVMatchScope`.
- Job description entry with a 100-character minimum.
- `CvAnalysisRequest` and `CvAnalysisResult` models.
- `CareerAnalysisService` abstraction for real analysis integrations.
- `MockAnalysisService` fallback using CV/job keyword overlap and realistic mock score ranges.
- `ApiCareerAnalysisService` for configurable backend analysis requests.
- `CVMATCH_ANALYSIS_API_URL` runtime configuration through `--dart-define`.
- 45-second backend request timeout.
- Friendly network, timeout, invalid JSON, missing-field, and backend-error handling.
- Analysis retry UI and debug-only mock fallback when a backend is configured.
- Professional result layout with circular match score, ATS score, missing keyword chips, strengths, weaknesses, suggested improvements, cover-letter draft, and interview questions.
- Backend/mock analysis mode labeling on result screen.
- Unit tests for PDF extraction, mock scoring, and API service parsing/error behavior.
- Widget tests for the core MVP flow and sensitive file path non-disclosure.
- Engineering handbook documents:
  - `AGENTS.md`
  - `PRODUCT.md`
  - `ARCHITECTURE.md`
  - `ROADMAP.md`
  - `API_SPEC.md`
  - `DESIGN_SYSTEM.md`
  - `DATABASE.md`
  - `SECURITY.md`
  - `TESTING.md`
  - `CONTRIBUTING.md`

### Security

- Kept AI provider calls out of the Flutter client.
- Documented that OpenAI and provider keys must remain backend-only.
- Avoided normal UI display of full file paths, PDF bytes, data URIs, base64 content, and raw extracted CV text.
- Kept CV data in memory only for the MVP.

### Not Included

- Firebase authentication.
- Firestore or another production database.
- RevenueCat or payment processing.
- Direct OpenAI SDK usage in Flutter.
- Production backend implementation.

## Release Process

For each future release:

1. Add a new version section above the previous release.
2. Group changes under Added, Changed, Fixed, Removed, Security, or Deprecated.
3. Include migration notes for API, database, or security changes.
4. Confirm `flutter analyze` and `flutter test` pass before tagging.
