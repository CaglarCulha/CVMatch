# CVMatch Backend

Node.js + Express + TypeScript backend foundation for CVMatch career analysis.

The backend exposes `POST /analyze` and returns JSON matching the Flutter `CvAnalysisResult` model. It uses an extensible provider architecture with `MockProvider` for safe local runs and `OpenAIProvider` for real AI analysis when explicitly enabled.

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
```

Current providers:

- `MockProvider`: default deterministic provider for local development and tests.
- `OpenAIProvider`: official OpenAI Node SDK provider, selected only when `AI_PROVIDER=openai`.

OpenAI provider behavior:

- Reads `OPENAI_API_KEY` from backend environment variables only.
- Uses `OPENAI_MODEL`, defaulting to `gpt-4.1-mini`.
- Applies `OPENAI_REQUEST_TIMEOUT_MS`, defaulting to 45 seconds.
- Requests structured JSON output with the `CvAnalysisResult` JSON schema.
- Returns raw provider JSON through `ResponseParser` and `ResultValidator`.
- Maps missing API key, timeout, malformed response, invalid JSON, and OpenAI API errors to safe API errors.

To add Anthropic, Gemini, Ollama, or another provider later:

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

Successful response:

```json
{
  "matchScore": 78,
  "atsScore": 74,
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

- `OPENAI_API_KEY` is read only by the backend environment.
- The API never returns or logs the OpenAI key.
- `OpenAIProvider` calls OpenAI only when `AI_PROVIDER=openai`.
- Request validation errors do not echo `cvText` or `jobDescription`.
- The backend does not persist CV text, job descriptions, or analysis results.
- Keep AI-provider integration server-side only.
