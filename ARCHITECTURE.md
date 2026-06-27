# Architecture Handbook

## Overview

CVMatch is a Flutter application organized by feature with clear presentation, domain, and data boundaries. The client currently stores state in memory, extracts PDF text locally, and sends analysis requests to either a mock implementation or a configurable backend API.

## Runtime Stack

### Flutter Client

- Flutter with Material 3.
- Dart SDK constraint: `^3.11.5`.
- `file_picker` for PDF selection.
- `cross_file` for platform-neutral file access.
- `syncfusion_flutter_pdf` for PDF text extraction.
- `http` for backend analysis requests.
- `flutter_lints` for static linting.
- `flutter_test` for unit and widget tests.

### Backend API

- Node.js 20.11 or newer.
- Express for HTTP routing.
- TypeScript for strict backend implementation.
- Zod for request and response validation.
- Helmet for default HTTP security headers.
- CORS configured by environment for Flutter Web origins.
- dotenv for local environment loading.
- Official OpenAI Node SDK and Google Gen AI SDK for backend-only provider integrations.

## Application Entry

- `lib/main.dart` runs `CVMatchApp`.
- `lib/src/app/cvmatch_app.dart` configures:
  - `MaterialApp`
  - Light and dark themes
  - System theme mode
  - Initial route
  - `CVMatchScope`

## Routing

Routes are centralized in `lib/src/app/app_routes.dart`:

- `/` -> `LoginScreen`
- `/home` -> `HomeScreen`
- `/upload-cv` -> `UploadCVScreen`
- `/job-description` -> `JobDescriptionScreen`
- `/analysis-result` -> `AnalysisResultScreen`
- `/paywall` -> `PaywallScreen`

Unknown routes fall back to `LoginScreen`.

## Folder Structure

```text
lib/
  main.dart
  src/
    app/
      app_routes.dart
      cvmatch_app.dart
      cvmatch_state.dart
    core/
      config/
        app_config.dart
      mock/
        mock_data.dart
      theme/
        app_theme.dart
    features/
      analysis/
        data/services/
        domain/models/
        domain/services/
        presentation/
      auth/
        presentation/
      cv_upload/
        domain/models/
        domain/services/
        presentation/
      home/
        presentation/
      job_description/
        presentation/
      paywall/
        presentation/
    shared/
      widgets/
backend/
  .env.example
  package.json
  tsconfig.json
  src/
    app.ts
    server.ts
    config/
    errors/
    middleware/
    providers/
      templates/
    routes/
    schemas/
    types/
    utils/
  test/
```

## State Management

`CVMatchState` is a `ChangeNotifier` exposed through `CVMatchScope`.

Current state includes:

- Selected CV file name.
- Internal selected CV file path.
- Selected CV size.
- CV validation warning.
- `CvDocument` with extracted text and page count.
- Current job description.
- Latest `CvAnalysisResult`.

The app intentionally keeps this data in memory only. Closing or refreshing the app clears the state.

## CV Upload And Extraction Flow

1. User selects a PDF in `UploadCVScreen`.
2. File picker returns file metadata and bytes.
3. `PdfExtractionService` reads PDF bytes.
4. The service normalizes extracted text and returns `CvDocument`.
5. `CVMatchState.setSelectedCv` stores the document and internal file path.
6. The UI displays only safe metadata:
   - File name
   - File size
   - Success or friendly error status
7. Debug builds may show extraction count, page count, and the first 300 extracted characters for developer verification.

Normal UI must never show full file paths, data URIs, base64 content, raw PDF bytes, or full extracted CV text.

## Analysis Flow

1. `JobDescriptionScreen` validates:
   - A PDF CV is selected.
   - CV validation passed.
   - Extracted text exists.
   - Job description has at least 100 characters.
2. The screen creates an analysis request through `CareerAnalysisService`.
3. `CareerAnalysisServiceFactory` selects implementation:
   - Empty `CVMATCH_ANALYSIS_API_URL`: `MockAnalysisService`
   - Non-empty `CVMATCH_ANALYSIS_API_URL`: `ApiCareerAnalysisService`
4. The screen shows “Analyzing your CV...” during the request.
5. Success stores `CvAnalysisResult` in state and navigates to `AnalysisResultScreen`.
6. Failure displays a friendly error and “Try again”.
7. Debug builds can use mock fallback when backend analysis fails.

## Service Contracts

### `CareerAnalysisService`

The main analysis contract:

```dart
Future<CvAnalysisResult> analyze({
  required CvDocument cvDocument,
  required String jobDescription,
  String locale = 'en',
  String? targetRole,
});
```

All future AI, backend, or hybrid analysis services should implement this interface.

### `MockAnalysisService`

Provides deterministic local analysis based on keyword overlap. It is used for MVP demos, local development, and fallback when no backend URL exists.

### `ApiCareerAnalysisService`

Sends extracted CV text and job description to the configured backend API. It handles:

- JSON request creation.
- 45-second timeout.
- Non-2xx API responses.
- Network errors.
- Invalid JSON.
- Missing response fields.
- API error payloads.

See `API_SPEC.md` for the backend contract.

## Backend API Architecture

The backend foundation lives in `backend/` and exposes:

- `GET /health`
- `POST /analyze`
- `POST /rewrite-cv`

Backend request flow:

1. `server.ts` starts the Express app.
2. `app.ts` applies Helmet, CORS, JSON body limits, routes, not-found handling, and error handling.
3. `routes/analyze.ts` validates the request body with `analyzeRequestSchema`.
4. The route calls `AnalysisOrchestrator`.
5. `PromptBuilder` creates provider prompts from templates.
6. `ProviderFactory` selects an `AIProvider`; `MockProvider` is the default.
7. The provider returns raw JSON text.
8. `ResponseParser` parses provider text into JSON.
9. `ResultValidator` validates the JSON against `cvAnalysisResultSchema`.
10. The backend returns JSON matching Flutter `CvAnalysisResult`.

CV rewrite request flow:

1. `routes/rewriteCv.ts` validates the request body with `rewriteCvRequestSchema`.
2. The route calls `CvRewriteOrchestrator`.
3. `PromptBuilder.buildCvRewrite` creates guarded rewrite prompts from templates.
4. `ProviderFactory` selects the configured `AIProvider`; `MockProvider` is the safe default and `GeminiProvider` is the first real rewrite provider.
5. The provider returns raw JSON text matching `CvRewriteResult`.
6. `ResponseParser` parses provider text into JSON.
7. `CvRewriteValidator` validates the JSON against `cvRewriteResultSchema`.
8. The backend returns structured CV rewrite JSON without persisting CV text or rewrite output.

## AI Provider Architecture

The backend provider layer lives in `backend/src/providers/`.

Key components:

- `AIProvider`: provider interface for OpenAI, Anthropic, Gemini, Ollama, or local providers.
- `MockProvider`: deterministic default provider for local development and tests.
- `OpenAIProvider`: official OpenAI Node SDK provider selected only when `AI_PROVIDER=openai`.
- `GeminiProvider`: official Google Gen AI SDK provider selected only when `AI_PROVIDER=gemini`.
- `ProviderFactory`: selects the provider from backend configuration.
- `AnalysisOrchestrator`: business-flow coordinator used by the route.
- `CvRewriteOrchestrator`: business-flow coordinator for CV rewrite requests.
- `PromptBuilder`: builds prompts using templates from `providers/templates/`.
- `ResponseParser`: parses strict JSON from provider responses, including fenced JSON.
- `ResultValidator`: validates parsed provider JSON against `CvAnalysisResult`.
- `CvRewriteValidator`: validates parsed provider JSON against `CvRewriteResult`.

Adding a provider should not require route or orchestration changes. Implement `AIProvider`, add the provider to `ProviderFactory`, keep credentials server-side, and add provider-specific tests.

`OpenAIProvider` reads `OPENAI_API_KEY` and `OPENAI_MODEL` from backend environment variables, uses structured JSON output, applies a backend request timeout, and sends provider output through the existing `ResponseParser` and `ResultValidator` pipeline. The default model is `gpt-4.1-mini`.

`GeminiProvider` reads `GEMINI_API_KEY` and `GEMINI_MODEL` from backend environment variables, uses structured JSON output with the same `CvAnalysisResult` JSON schema, applies a backend request timeout, and sends provider output through the existing `ResponseParser` and `ResultValidator` pipeline. The default model is `gemini-2.5-flash`.

Provider prompts and schemas enforce recruiter-grade analysis quality across OpenAI, Gemini, and future providers:

- Match scores must be strict, evidence-based, and penalize missing required experience, tools, quotas, KPIs, leadership, and industry context.
- ATS scores are evaluated separately from match scores and reflect parsing quality, section clarity, keyword alignment, and recruiter readability.
- Missing keywords should be role-specific rather than generic; examples include CRM, Salesforce, SAP, quota ownership, pipeline management, technical sales, and stakeholder management.
- Strengths must be supported by CV evidence, weaknesses must explain missing proof, and improvements must state what to change, where to add it, why it matters, and example wording when possible.
- Optional recruiter reasoning fields such as `mainReasonsForScore`, `confidenceLevel`, `recruiterVerdict`, `rejectionRisks`, and `fastestFixes` are backward-compatible additions to the backend response contract.
- User-provided CV text and job descriptions are wrapped as untrusted content so provider prompts can explicitly ignore embedded prompt-injection attempts.

CV rewrite prompts and schemas enforce truth-preserving rewrite behavior:

- Rewrites must preserve the candidate's real background and use only evidence from the CV and job description.
- Metrics, tools, platforms, employers, degrees, certifications, seniority, and ownership claims must not be invented.
- Missing metrics use placeholders such as `[insert measurable result]` until the candidate supplies accurate values.
- Unsupported job requirements are returned as warnings or improvement notes instead of being added as skills.
- Gemini and mock providers currently support `POST /rewrite-cv`; OpenAI rewrite support remains intentionally disabled until separately implemented and tested.

## Configuration

Configuration is centralized in `lib/src/core/config/app_config.dart`.

Current runtime key:

```sh
CVMATCH_ANALYSIS_API_URL
```

Example:

```sh
flutter run --dart-define=CVMATCH_ANALYSIS_API_URL=https://api.example.com/v1/career-analysis
```

Local backend example:

```sh
flutter run -d chrome --dart-define=CVMATCH_ANALYSIS_API_URL=http://localhost:3001/analyze
```

No API keys or provider secrets may be configured in the Flutter client.

## Dependency Direction

Preferred dependency direction:

```text
presentation -> domain -> data implementations
core/shared -> used by features
features -> may reference sibling feature domain models only when part of an explicit flow
```

Avoid importing presentation code into domain or data layers.

## Error Handling

- PDF extraction errors are represented as `PdfExtractionException`.
- Analysis errors are represented as `CareerAnalysisException`.
- UI should display short, friendly, actionable messages.
- Raw exception strings should not be shown when they may contain internal implementation details.

## Platform Notes

- PDF extraction is implemented with platform-neutral bytes through `cross_file` and Syncfusion PDF APIs.
- Web builds require backend CORS configuration for API calls.
- Mobile builds require HTTPS endpoints for production.
- Local development can run with mock analysis and no backend URL.

## Known Architecture Constraints

- `CVMatchState` is intentionally simple; it is acceptable for the MVP but should be revisited before adding authentication, persistence, or multi-session history.
- The legacy `AnalysisService` contract remains in the tree. New work should use `CareerAnalysisService`.
- Result confidence is limited in mock mode; production analysis should be performed by a backend.

## Related Documents

- Product scope: `PRODUCT.md`
- Backend contract: `API_SPEC.md`
- Security posture: `SECURITY.md`
- Database posture: `DATABASE.md`
- Testing strategy: `TESTING.md`
