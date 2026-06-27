# CVMatch Backend

Node.js + Express + TypeScript backend foundation for CVMatch career analysis and CV rewriting.

The backend exposes `POST /analyze` and `POST /rewrite-cv`. Analysis returns JSON matching the Flutter `CvAnalysisResult` model. CV rewrite returns structured JSON for a truthful job-tailored summary, bullets, skills, notes, and warnings. It uses an extensible provider architecture with `MockProvider` for safe local runs, `OpenAIProvider` for OpenAI analysis, and `GeminiProvider` for Gemini analysis and rewrite when explicitly enabled.

## Requirements

- Node.js 20.11 or newer.
- npm.

## Setup

```sh
cd backend
npm install
cp .env.example .env
```

Set server-side environment values in `.env`:

```sh
PORT=3001
CORS_ORIGIN=http://localhost:54321,http://127.0.0.1:54321
AI_PROVIDER=openai
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4.1-mini
OPENAI_REQUEST_TIMEOUT_MS=45000
GEMINI_API_KEY=
GEMINI_MODEL=gemini-2.5-flash
GEMINI_REQUEST_TIMEOUT_MS=45000
```

Do not commit `.env` or any real API key.

For local development without OpenAI calls, use:

```sh
AI_PROVIDER=mock
```

For real OpenAI analysis, use:

```sh
AI_PROVIDER=openai
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4.1-mini
```

Fill `OPENAI_API_KEY` only in your local `.env` or deployment secret manager.

For real Gemini analysis, use:

```sh
AI_PROVIDER=gemini
GEMINI_API_KEY=
GEMINI_MODEL=gemini-2.5-flash
```

Fill `GEMINI_API_KEY` only in your local `.env` or deployment secret manager.

## Run Locally

```sh
npm run dev
```

The backend starts at:

```text
http://localhost:3001
```

Health check:

```sh
curl http://localhost:3001/health
```

Analyze request:

```sh
curl -X POST "http://localhost:3001/analyze" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "cvText": "Professional summary experience skills education projects. Product discovery roadmap ownership AI workflows prompt testing activation metrics.",
    "cvFileName": "Derya_Kaya_CV.pdf",
    "jobDescription": "We are hiring an AI product manager to own product discovery, roadmap strategy, prompt testing, activation metrics, stakeholder leadership, and launch planning for trusted assistant workflows.",
    "locale": "en-US",
    "targetRole": "AI Product Manager"
  }'
```

CV rewrite request:

```sh
curl -X POST "http://localhost:3001/rewrite-cv" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "cvText": "Professional summary experience skills education projects. Product discovery roadmap ownership AI workflows prompt testing launch planning.",
    "jobDescription": "We are hiring an AI product manager to own roadmap strategy, customer discovery, prompt testing, stakeholder leadership, launch planning, activation metrics, and experimentation for AI assistant workflows.",
    "locale": "en-US",
    "targetRole": "AI Product Manager"
  }'
```

## Validate

```sh
npm run typecheck
npm test
npm run build
```

## Provider Architecture

The analysis path is:

```text
POST /analyze
  -> AnalysisOrchestrator
  -> PromptBuilder
  -> AIProvider
  -> ResponseParser
  -> ResultValidator
  -> CvAnalysisResult JSON

POST /rewrite-cv
  -> CvRewriteOrchestrator
  -> PromptBuilder
  -> AIProvider
  -> ResponseParser
  -> CvRewriteValidator
  -> CvRewriteResult JSON
```

Current providers:

- `MockProvider`: default deterministic provider for local development and tests.
- `OpenAIProvider`: official OpenAI Node SDK provider, selected only when `AI_PROVIDER=openai`.
- `GeminiProvider`: official Google Gen AI SDK provider, selected only when `AI_PROVIDER=gemini`.

All analysis providers are expected to behave like strict recruiter-level analysis engines, not generic keyword checkers. Provider prompts require evidence-based scoring, separate match and ATS evaluation, role-specific missing keywords, actionable recommendations, and prompt-injection resistance. Mock mode mirrors the same product posture with deterministic keyword-overlap heuristics for safe local development.

CV rewrite providers are expected to preserve truthful candidate background, avoid invented experience, avoid fabricated metrics, and use placeholders such as `[insert measurable result]` when measurable impact is missing. Unsupported job requirements are returned as warnings or improvement notes instead of being added as skills.

OpenAI provider behavior:

- Reads `OPENAI_API_KEY` from backend environment variables only.
- Uses `OPENAI_MODEL`, defaulting to `gpt-4.1-mini`.
- Applies `OPENAI_REQUEST_TIMEOUT_MS`, defaulting to 45 seconds.
- Requests structured JSON output with the `CvAnalysisResult` JSON schema.
- Returns raw provider JSON through `ResponseParser` and `ResultValidator`.
- Maps missing API key, timeout, malformed response, invalid JSON, and OpenAI API errors to safe API errors.
- Does not support `POST /rewrite-cv` yet; rewrite support is implemented first for Gemini and mock mode.

Gemini provider behavior:

- Reads `GEMINI_API_KEY` from backend environment variables only.
- Uses `GEMINI_MODEL`, defaulting to `gemini-2.5-flash`.
- Applies `GEMINI_REQUEST_TIMEOUT_MS`, defaulting to 45 seconds.
- Requests structured JSON output with the same `CvAnalysisResult` JSON schema.
- Requests structured JSON output with the `CvRewriteResult` JSON schema for `POST /rewrite-cv`.
- Returns raw provider JSON through `ResponseParser` and the appropriate result validator.
- Maps missing API key, timeout, malformed response, invalid JSON, and Gemini API errors to safe API errors.

To add Anthropic, Ollama, or another provider later:

1. Implement `AIProvider`.
2. Return strict JSON matching `CvAnalysisResult`.
3. Add the provider to `ProviderFactory`.
4. Keep API keys in backend environment variables only.
5. Add provider-specific tests without changing route or orchestration business logic.

## Connect Flutter Locally

Run Flutter with the backend endpoint configured:

```sh
flutter run -d chrome --dart-define=CVMATCH_ANALYSIS_API_URL=http://localhost:3001/analyze
```

The Flutter app will continue using `MockAnalysisService` when `CVMATCH_ANALYSIS_API_URL` is not set.

## API Contract

### `POST /analyze`

Request body:

```json
{
  "cvText": "Readable extracted CV text...",
  "cvFileName": "Derya_Kaya_CV.pdf",
  "jobDescription": "Full job description text...",
  "locale": "en-US",
  "targetRole": "AI Product Manager"
}
```

### `POST /rewrite-cv`

Request body:

```json
{
  "cvText": "Readable extracted CV text...",
  "jobDescription": "Full job description text...",
  "locale": "en-US",
  "targetRole": "AI Product Manager"
}
```

Successful response:

```json
{
  "rewrittenSummary": "AI product manager with CV-supported roadmap ownership and prompt-testing experience. Add [insert measurable result] where verified.",
  "rewrittenExperienceBullets": [
    "Owned roadmap prioritization for AI workflow improvements; add [insert measurable result] to quantify impact."
  ],
  "rewrittenSkills": ["Roadmap ownership", "Prompt testing", "Launch planning"],
  "improvementNotes": [
    "Add verified activation or conversion metrics to the most relevant experience bullet."
  ],
  "warnings": [
    "Metric placeholders must be replaced with truthful values before applying."
  ]
}
```

Successful response:

```json
{
  "matchScore": 78,
  "atsScore": 74,
  "keywordCoverage": 68,
  "strengths": ["Roadmap ownership appears in the CV and matters because the role requires product prioritization."],
  "weaknesses": ["Missing quantified activation or retention outcomes."],
  "improvements": ["Add one Product Experience bullet with the metric, product area, and business outcome."],
  "rewrittenSummary": "AI product manager with evidence of roadmap ownership and prompt-testing workflows. Add verified activation or conversion metrics to strengthen fit.",
  "mainReasonsForScore": ["Core product ownership is evidenced, but activation metrics are underdeveloped."],
  "confidenceLevel": "medium",
  "recruiterVerdict": "Worth a recruiter screen if the candidate adds quantified product outcomes before applying.",
  "rejectionRisks": ["Missing quantified impact.", "Experiment design evidence is thin.", "AI workflow evidence may be buried."],
  "fastestFixes": ["Move AI workflow evidence into the summary.", "Add one quantified activation bullet.", "Mirror experiment-design language where truthful."],
  "missingKeywords": ["Activation metrics"],
  "strongPoints": ["Roadmap ownership appears in both the CV and job description."],
  "weakPoints": ["Missing or underrepresented role signals: Activation metrics."],
  "suggestedImprovements": ["Add truthful evidence for priority keywords such as Activation metrics."],
  "coverLetter": "Dear hiring team,...",
  "interviewQuestions": ["Which project best demonstrates your readiness for this AI Product Manager?"]
}
```

Validation errors return:

```json
{
  "error": "Invalid analysis request.",
  "details": [
    {
      "field": "jobDescription",
      "message": "jobDescription must be at least 100 characters."
    }
  ]
}
```

## Security Notes

- `OPENAI_API_KEY` and `GEMINI_API_KEY` are read only by the backend environment.
- The API never returns or logs provider keys.
- `OpenAIProvider` calls OpenAI only when `AI_PROVIDER=openai`.
- `GeminiProvider` calls Gemini only when `AI_PROVIDER=gemini`.
- Request validation errors do not echo `cvText` or `jobDescription`.
- The backend does not persist CV text, job descriptions, or analysis results.
- The backend does not persist CV rewrite outputs.
- Keep AI-provider integration server-side only.
- Provider prompts delimit CV text and job descriptions as untrusted data and instruct models to ignore embedded instructions that attempt to override system rules, leak prompts, force inflated scores, or fabricate rewrite content.
