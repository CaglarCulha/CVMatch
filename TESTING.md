# Testing Handbook

## Required Local Checks

Run before handing off code changes:

```sh
dart format lib test
flutter analyze
flutter test
```

Run a local app smoke test when UI, navigation, PDF extraction, or backend configuration changes:

```sh
flutter run -d chrome
flutter run -d chrome --dart-define=CVMATCH_ANALYSIS_API_URL=https://api.example.com/v1/career-analysis
```

Run backend checks when Node.js is available:

```sh
cd backend
npm install
npm run typecheck
npm test
npm run build
```

## Current Test Suite

### `test/widget_test.dart`

Covers the main MVP user flow:

- Login to dashboard navigation.
- Upload CV screen navigation.
- Required PDF validation.
- PDF selection through mocked file picker channel.
- Clean file metadata display.
- Local file path non-disclosure.
- Job description length validation.
- Analysis loading state.
- Result screen content.
- Paywall navigation.
- Invalid CV-like filename blocking.

### `test/pdf_extraction_service_test.dart`

Covers PDF extraction behavior:

- Readable text extraction from a generated text-based PDF.
- Friendly error for empty bytes.
- Friendly error for image-only or textless PDF.

### `test/analysis_service_test.dart`

Covers mock analysis scoring:

- Low confidence when CV validation fails.
- Strong score remains below mock-mode cap.
- Weak score for low keyword overlap.

### `test/api_career_analysis_service_test.dart`

Covers backend API client behavior:

- Request body includes CV text, file name, job description, locale, and target role.
- Valid JSON parses into `CvAnalysisResult`.
- Invalid JSON throws `CareerAnalysisException`.
- Missing fields throw `CareerAnalysisException`.
- Non-2xx backend errors surface friendly messages.
- `200 OK` error payloads without result fields are treated as errors.

## Test Strategy

### Unit Tests

Use for:

- Domain model parsing.
- Service behavior.
- Validation logic.
- Error mapping.
- Mock scoring ranges.

Keep unit tests deterministic and isolated from network, filesystem, and platform channels.

### Widget Tests

Use for:

- Navigation.
- Form validation.
- Loading and error states.
- Sensitive-data non-disclosure.
- Result layout smoke coverage.

Mock platform channels such as file picker. Do not rely on local machine files.

### Integration Tests

Not currently present. Add integration tests when backend, authentication, payments, or persistent storage becomes real.

Recommended first integration paths:

- PDF upload to extraction to analysis result.
- Backend configured success flow.
- Backend configured timeout/error flow.
- Authenticated analysis history flow after persistence exists.

## Testing Sensitive Data Rules

Tests should assert that UI does not show:

- Full local file paths.
- Raw PDF bytes.
- Data URIs.
- Base64 content.
- Full extracted CV text in non-debug surfaces.

When adding debug-only UI, test normal user-facing behavior separately from debug tooling.

## Backend API Testing

Use mocked `http.Client` instances for Flutter tests. Do not call real backend services in unit or widget tests.

Backend contract tests should verify:

- Request schema.
- Response schema.
- Timeout behavior.
- Invalid provider output handling.
- Recruiter-grade scoring behavior.
- Prompt-injection resistant prompt construction.
- No hallucinated skills in evidence-backed strengths or summaries.
- Backward compatibility with the Flutter `CvAnalysisResult` fields.
- Rate-limit and auth error payloads.
- Redaction in backend logs.

The repository backend includes `backend/test/analyze.test.ts` for the local `POST /analyze` contract and validation behavior.
It also includes `backend/test/providerArchitecture.test.ts` for provider selection, OpenAI and Gemini stub behavior, response parsing, result validation, strict mock scoring, prompt-injection boundaries, no-hallucination checks, and Flutter response compatibility.

## CI Expectations

A production CI pipeline should block merges unless these pass:

```sh
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Recommended optional checks:

```sh
flutter build web
flutter pub outdated
```

## Adding New Tests

When adding a feature:

1. Add unit tests for business logic and service boundaries.
2. Add widget tests for user-visible behavior.
3. Add regression tests for bugs.
4. Keep mocks explicit and local to the test file unless reused broadly.
5. Avoid sleeps in tests; prefer pumping known durations only when testing intentionally delayed mock services.

## Related Documents

- Architecture: `ARCHITECTURE.md`
- API contract: `API_SPEC.md`
- Security-sensitive assertions: `SECURITY.md`
- Contributor workflow: `CONTRIBUTING.md`
