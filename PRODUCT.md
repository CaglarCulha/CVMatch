# Product Handbook

## Product Name

CVMatch

## Product Promise

CVMatch helps candidates understand how well a CV matches a job description, what keywords or proof points are missing, and how to improve the application package before submitting.

## Current Product Stage

CVMatch is an MVP Flutter app with local PDF text extraction, mock analysis fallback, and a configurable backend analysis integration. It is not yet a production SaaS with authentication, billing, cloud storage, analytics, or direct AI-provider integration.

## Target Users

- Job seekers tailoring a CV to a specific role.
- Career coaches reviewing candidate materials quickly.
- Early SaaS evaluators validating AI-assisted career workflows.

## Core Jobs To Be Done

1. Upload a text-based PDF CV safely.
2. Paste a job description with enough detail for analysis.
3. Receive a clear match score, ATS score, missing keywords, strengths, weaknesses, improvement suggestions, cover-letter draft, and interview questions.
4. Understand when the result is mock analysis versus backend-powered analysis.
5. Avoid accidental exposure of private CV content in the UI.

## MVP Screens

- `LoginScreen`: Lightweight entry into the MVP experience.
- `HomeScreen`: Dashboard with cards for upload, job analysis, previous analyses, and premium.
- `UploadCVScreen`: PDF-only selection, extraction, validation, clean selected-file summary, and debug-only extraction preview.
- `JobDescriptionScreen`: Multiline job description entry, 100-character validation, loading state, retry UI, and analysis submission.
- `AnalysisResultScreen`: Visual score summary, ATS card, missing keywords, strong points, weak points, suggested improvements, cover letter, and interview questions.
- `PaywallScreen`: Premium-oriented upgrade screen for future monetization.

## Current Capabilities

- Material 3 UI with light and dark mode.
- Local PDF selection through `file_picker`.
- PDF text extraction through `syncfusion_flutter_pdf`.
- In-memory CV document state through `CVMatchState`.
- Basic CV filename validation for terms such as CV, resume, résumé, curriculum, vitae, or profile.
- Job description validation requiring at least 100 characters.
- Mock scoring based on keyword overlap between extracted CV text and job description.
- Configurable backend analysis service through `CVMATCH_ANALYSIS_API_URL`.
- Friendly error messages for unreadable PDFs, API failures, invalid API JSON, and timeouts.

## Explicit Non-Goals For The Current Client

- Firebase authentication or Firestore.
- RevenueCat subscriptions.
- Direct OpenAI calls from Flutter.
- Local database persistence.
- Cloud CV storage.
- Background uploads.
- Real payment processing.
- Production account management.

These may be added later only after the architecture, security, database, and API documentation are updated.

## User Journey

1. User opens CVMatch and continues from the login screen.
2. User lands on the dashboard and chooses Upload CV.
3. User selects a PDF.
4. The app extracts text locally and validates that readable text exists.
5. The app shows only file name, file size, and a clean success or error status.
6. User continues to job description entry.
7. User pastes a role description with at least 100 characters.
8. The app displays “Analyzing your CV...” while calling the configured service.
9. If no backend URL is configured, mock analysis runs.
10. If a backend URL is configured, the app POSTs extracted CV text and job details to the backend.
11. User reviews the analysis result and can navigate to premium upsell.

## Product Principles

- Privacy first: CV content is sensitive and must be treated as private by default.
- Clear confidence: Always distinguish mock analysis from backend analysis.
- Actionable output: Every result should help the user improve the CV, not just produce a score.
- Honest limitations: Scanned PDFs, password-protected files, invalid backend responses, and missing text should produce clear explanations.
- Fast recovery: Validation errors and API failures should include a visible next action.

## Success Metrics

When analytics are introduced, measure these events without storing raw CV text:

- PDF selection started.
- PDF extraction succeeded or failed by reason category.
- Job description validation failed or passed.
- Analysis request started.
- Analysis request succeeded, timed out, or failed by error category.
- Analysis result viewed.
- Paywall viewed.
- Premium CTA clicked.

Do not log full file paths, raw extracted CV text, full job descriptions, API response bodies, or provider prompts.

## Related Documents

- Engineering architecture: `ARCHITECTURE.md`
- Backend contract: `API_SPEC.md`
- Security and privacy: `SECURITY.md`
- Data persistence posture: `DATABASE.md`
- Design guidelines: `DESIGN_SYSTEM.md`
- Roadmap: `ROADMAP.md`
