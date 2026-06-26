# Roadmap

## Roadmap Principles

- Protect candidate privacy before adding growth features.
- Keep AI-provider secrets on the backend only.
- Ship measurable product increments with tests and documentation.
- Prefer clear, explainable career guidance over opaque score generation.
- Avoid adding persistent storage until data retention rules are explicit.

## Current Baseline

The current MVP includes:

- Flutter Material 3 app shell.
- Dashboard, upload, job description, analysis result, and paywall screens.
- Local PDF selection and readable-text extraction.
- In-memory `CvDocument` state.
- Mock analysis based on keyword overlap.
- Configurable backend analysis service through `CVMATCH_ANALYSIS_API_URL`.
- Friendly loading, validation, and retry UI.
- Unit and widget tests for extraction, service parsing, mock scoring, and the core user flow.
- Node.js + Express + TypeScript backend foundation with `POST /analyze`.
- Backend request and response validation matching `CvAnalysisResult`.
- Extensible backend AI provider architecture with `MockProvider` as default and `OpenAIProvider` as a non-calling stub.

## Phase 1: Backend Analysis Service

Goal: Replace mock scoring for configured environments with a secure backend analysis service.

Deliverables:

- Production backend endpoint matching `API_SPEC.md`.
- Server-side AI provider integration.
- Prompt and response validation on the backend.
- Request authentication between client and backend.
- CORS policy for Flutter Web.
- Backend rate limiting.
- Backend logs with CV text redaction.
- Integration tests covering valid result, invalid JSON, provider timeout, and provider error.

Acceptance criteria:

- Flutter runs with `CVMATCH_ANALYSIS_API_URL`.
- OpenAI or other provider keys exist only on the backend.
- Backend returns a complete `CvAnalysisResult`.
- Client shows friendly retry UI for timeout, network error, invalid JSON, and backend error payloads.

Completed foundation:

- Local backend folder and Express server.
- `POST /analyze` contract endpoint.
- Server-side environment loading for `OPENAI_API_KEY`.
- Provider orchestration, prompt building, response parsing, result validation, safe errors, and no persistence.

## Phase 2: Account And Session Model

Goal: Add user identity without weakening privacy controls.

Deliverables:

- Authentication provider decision record.
- Login, logout, and session restore flows.
- Data classification for user profile, CV metadata, extracted text, and analysis results.
- Updated `DATABASE.md` with concrete persistence schema.
- Updated `SECURITY.md` with auth threats and mitigations.

Acceptance criteria:

- Users can authenticate reliably on web and mobile.
- No CV text is persisted until retention and deletion behavior is implemented.
- Tests cover authenticated and unauthenticated routing.

## Phase 3: Analysis History

Goal: Let users revisit previous analyses safely.

Deliverables:

- Persisted analysis metadata.
- Optional encrypted storage for analysis details.
- User-facing delete action.
- Retention policy surfaced in product copy.
- Previous analyses dashboard connected to real data.

Acceptance criteria:

- Users can view, open, and delete previous analyses.
- Deleting an analysis removes backend records according to the documented retention policy.
- Raw CV text storage is either disabled or encrypted with clear retention limits.

## Phase 4: Premium Monetization

Goal: Turn the paywall into a real subscription experience.

Deliverables:

- Premium feature matrix.
- Subscription provider integration plan.
- Entitlement model.
- Restore purchases flow.
- Graceful handling for cancelled, expired, and billing-retry states.
- Tests for premium and non-premium UI paths.

Acceptance criteria:

- Paywall reflects real entitlements.
- Premium-only actions are enforced by backend authorization, not only by Flutter UI.
- Revenue events avoid sensitive CV content.

## Phase 5: Career Intelligence Features

Goal: Expand beyond one-off match scoring.

Deliverables:

- CV rewrite suggestions by section.
- Job-specific cover-letter export.
- Interview prep mode.
- Keyword coverage map.
- Role-targeting suggestions.
- Multi-language analysis using locale-aware prompts.

Acceptance criteria:

- Each generated recommendation is tied to evidence from the CV or job description.
- The user can distinguish extracted facts from AI-generated suggestions.
- Outputs are reviewable before export or sharing.

## Phase 6: Production Hardening

Goal: Prepare CVMatch for broader release.

Deliverables:

- CI pipeline for format, analyze, tests, and build.
- Dependency vulnerability checks.
- Crash reporting with sensitive-data redaction.
- Accessibility audit.
- Performance budget for PDF extraction and API latency.
- Privacy policy and terms alignment.

Acceptance criteria:

- CI blocks merges that fail required checks.
- App handles large PDFs, scanned PDFs, corrupt PDFs, and backend outages predictably.
- Security review has no unresolved high-risk findings.

## Related Documents

- Product strategy: `PRODUCT.md`
- Architecture constraints: `ARCHITECTURE.md`
- API contract: `API_SPEC.md`
- Security requirements: `SECURITY.md`
- Persistence plan: `DATABASE.md`
