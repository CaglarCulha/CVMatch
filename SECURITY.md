# Security Handbook

## Security Posture

CVMatch handles CVs and job descriptions, which can contain names, contact details, employment history, education history, compensation signals, immigration status, disability information, and other sensitive personal data. The app must be designed as a privacy-first product even while it is an MVP.

## Core Rules

- Do not store OpenAI or provider API keys in Flutter.
- Do not call OpenAI, Gemini, or other AI providers directly from Flutter.
- Do not display full local file paths, raw PDF bytes, data URIs, base64 content, or full extracted CV text in normal UI.
- Do not persist raw CV text or uploaded PDF bytes in the client.
- Do not log CV text, full job descriptions, file paths, prompts, or provider responses.
- Use backend APIs for AI analysis and keep provider credentials server-side.

## Sensitive Data Inventory

| Data | Risk | Current Handling |
| --- | --- | --- |
| PDF bytes | High | Read for extraction, not displayed. |
| Extracted CV text | High | Stored in memory, sent to backend only when configured. |
| Local file path | Medium | Stored internally, not displayed. |
| Job description | Medium | Stored in memory, sent to backend only when configured. |
| Analysis output | Medium | Displayed to user, stored in memory. |
| API URL | Low | Configured through `--dart-define`; not a secret. |

## Client-Side Threats And Mitigations

### Accidental Sensitive Data Exposure

Mitigations:

- Upload UI displays only file name, file size, and success/error status.
- Raw extracted text is debug-only and truncated.
- Widget tests assert that local file paths are not displayed.
- Future logging must redact sensitive fields by default.

### Malicious Or Broken PDF Files

Mitigations:

- PDF parsing is wrapped in `PdfExtractionService`.
- Empty, scanned, corrupt, and password-protected PDFs receive friendly errors.
- Analysis does not continue when extraction fails.
- Future backend upload flows should scan files and enforce size limits.

### Backend Impersonation Or Misconfiguration

Mitigations:

- Backend URL must be explicit through `CVMATCH_ANALYSIS_API_URL`.
- Production should use HTTPS only.
- Future production backend calls should include app authentication, user authentication, request signing, or equivalent controls.
- Flutter should not embed shared secrets for backend authentication.

### API Response Manipulation

Mitigations:

- `CvAnalysisResult.fromJson` validates required fields and types.
- API service catches invalid JSON and missing fields.
- UI displays friendly retry errors rather than crashing.

## Backend Security Requirements

Any production backend used with CVMatch must:

- Store provider API keys in server-side secret management.
- Authenticate requests.
- Authorize access to user-owned resources.
- Enforce rate limits by user, IP, and tenant where applicable.
- Limit request body size.
- Validate JSON schemas before calling an AI provider.
- Redact CV text, job descriptions, prompts, and provider responses from logs.
- Use TLS.
- Configure CORS for allowed origins only.
- Return structured JSON errors.
- Avoid storing raw CV text unless encryption, retention, and deletion are implemented.

The repository backend foundation in `backend/` currently:

- Reads `OPENAI_API_KEY` from backend environment variables only.
- Does not expose provider keys through API responses, health checks, logs, or Flutter config.
- Does not persist CV text, job descriptions, or analysis results.
- Validates request and response JSON with Zod.
- Avoids echoing sensitive request content in validation errors.
- Uses `MockProvider` when `AI_PROVIDER=mock`.
- Uses `OpenAIProvider` only when `AI_PROVIDER=openai`.
- Uses `GeminiProvider` only when `AI_PROVIDER=gemini`.
- Reads `OPENAI_API_KEY` from backend environment variables only.
- Reads `GEMINI_API_KEY` from backend environment variables only.
- Uses the official OpenAI Node SDK server-side.
- Uses the official Google Gen AI SDK server-side.
- Keeps provider outputs inside the existing parser and validator pipeline.
- Wraps CV text and job descriptions as untrusted prompt sections before provider calls.
- Maps provider failures to safe errors without logging CV text, job descriptions, prompts, provider response bodies, or keys.

## AI Provider Safety

The backend should:

- Treat CV and job descriptions as untrusted input.
- Prevent prompt injection from causing secret disclosure or policy bypass.
- Use system prompts that forbid revealing hidden instructions.
- Delimit user-provided CV and job description content separately from system and developer instructions.
- Instruct providers to ignore any embedded request to change scoring rules, leak prompts, disclose keys, or override the JSON schema.
- Validate model output against `CvAnalysisResult` before responding.
- Bound scores to expected ranges.
- Avoid making employment guarantees.
- Include safety copy for uncertain or low-confidence analysis.

## Dependency Security

Current sensitive dependencies:

- `file_picker`: file selection boundary.
- `syncfusion_flutter_pdf`: PDF parsing boundary.
- `http`: network boundary.

Dependency changes should include:

```sh
flutter pub outdated
flutter analyze
flutter test
```

If a dependency processes PDFs, network data, authentication, payments, or storage, review its maintenance status and platform behavior before adoption.

## Logging Policy

Allowed logs:

- Error category.
- Operation name.
- Timing bucket.
- HTTP status code.
- Boolean success/failure.

Disallowed logs:

- Raw CV text.
- Full job descriptions.
- Full backend response bodies.
- Full local file paths.
- API keys or auth tokens.
- Provider prompts or completions.

## Privacy Requirements For Future Persistence

Before storing user data:

- Update `DATABASE.md` with exact schema.
- Define retention and deletion.
- Define encryption at rest.
- Define backup retention.
- Define user export behavior.
- Define incident response.

## Incident Response

If sensitive data is exposed:

1. Stop the exposure path.
2. Preserve minimal evidence needed for investigation without copying sensitive content unnecessarily.
3. Identify impacted users, fields, environments, and time window.
4. Rotate any exposed secrets.
5. Patch and test the fix.
6. Update documentation and tests to prevent recurrence.

## Related Documents

- Backend contract: `API_SPEC.md`
- Persistence posture: `DATABASE.md`
- Architecture: `ARCHITECTURE.md`
- Testing: `TESTING.md`
