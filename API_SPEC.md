# API Specification

## Purpose

This document defines the contract between the Flutter client and the CVMatch career analysis backend. The backend is responsible for any AI-provider calls, including CV analysis and CV rewrite workflows. The Flutter client must not call OpenAI, Gemini, or any other model provider directly.

## Client Configuration

The Flutter client selects the analysis implementation with:

```sh
CVMATCH_ANALYSIS_API_URL
```

Run with a backend:

```sh
flutter run --dart-define=CVMATCH_ANALYSIS_API_URL=https://api.example.com/v1/career-analysis
```

Run with the local repository backend:

```sh
flutter run -d chrome --dart-define=CVMATCH_ANALYSIS_API_URL=http://localhost:3001/analyze
```

Run without a backend:

```sh
flutter run
```

When the URL is empty, the client uses `MockAnalysisService`.

## Endpoint

The configured URL is the full endpoint URL. The current client sends:

```http
POST {CVMATCH_ANALYSIS_API_URL}
Accept: application/json
Content-Type: application/json
```

The client timeout is 45 seconds.

The repository backend exposes this route locally:

```http
POST http://localhost:3001/analyze
Accept: application/json
Content-Type: application/json
```

The repository backend also exposes the CV rewrite route locally:

```http
POST http://localhost:3001/rewrite-cv
Accept: application/json
Content-Type: application/json
```

## Request Body

```json
{
  "cvText": "Readable extracted CV text...",
  "cvFileName": "Derya_Kaya_CV.pdf",
  "jobDescription": "Full job description text...",
  "locale": "en-US",
  "targetRole": "AI Product Manager"
}
```

### Request Fields

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `cvText` | string | yes | Normalized readable text extracted from the uploaded PDF. |
| `cvFileName` | string | yes | Original selected file name. Do not depend on this for identity or authorization. |
| `jobDescription` | string | yes | User-provided job description. Client requires at least 100 characters. |
| `locale` | string | yes | Locale tag from Flutter localizations, such as `en-US` or `tr-TR`. |
| `targetRole` | string | no | Role label when the client can infer or provide one. |

## Successful Response

Return `200 OK` with JSON matching `CvAnalysisResult`:

```json
{
  "matchScore": 78,
  "atsScore": 74,
  "keywordCoverage": 68,
  "missingKeywords": [
    "Activation metrics",
    "Experiment design"
  ],
  "strengths": [
    "Roadmap ownership is supported by the CV and matters because the role requires product prioritization."
  ],
  "weaknesses": [
    "The CV does not quantify activation or retention outcomes."
  ],
  "improvements": [
    "Add one Product Experience bullet with the metric, product area, and business outcome. Example: Improved activation by [insert verified metric] through onboarding experiments."
  ],
  "rewrittenSummary": "AI product manager with evidence of roadmap ownership, stakeholder leadership, and prompt-testing workflows. Add verified activation or conversion metrics to strengthen fit for this role.",
  "mainReasonsForScore": [
    "Core product ownership is evidenced, but required activation metrics are underdeveloped."
  ],
  "confidenceLevel": "medium",
  "recruiterVerdict": "Worth a recruiter screen if the candidate can add quantified product outcomes before applying.",
  "rejectionRisks": [
    "The CV does not prove activation impact.",
    "Experiment design evidence is thin.",
    "The strongest AI workflow evidence may be too buried."
  ],
  "fastestFixes": [
    "Move AI workflow evidence into the summary.",
    "Add one quantified activation or conversion bullet.",
    "Mirror the job's experiment-design language where truthful."
  ],
  "strongPoints": [
    "The CV demonstrates roadmap ownership and stakeholder leadership."
  ],
  "weakPoints": [
    "The CV does not quantify activation or retention outcomes."
  ],
  "suggestedImprovements": [
    "Add a bullet showing measurable impact on activation or conversion."
  ],
  "coverLetter": "Dear hiring team, ...",
  "interviewQuestions": [
    "Tell me about a product decision you made using activation data."
  ]
}
```

### Response Fields

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `matchScore` | integer | yes | Overall CV-to-job fit, expected 0-100. |
| `atsScore` | integer | yes | Estimated applicant tracking system compatibility, expected 0-100. |
| `missingKeywords` | string[] | yes | Important role keywords not sufficiently represented in the CV. |
| `strongPoints` | string[] | yes | Evidence-backed strengths. |
| `weakPoints` | string[] | yes | Evidence-backed gaps or risks. |
| `suggestedImprovements` | string[] | yes | Actionable CV changes. |
| `coverLetter` | string | yes | Draft cover letter text. |
| `interviewQuestions` | string[] | yes | Suggested preparation questions. |

The Flutter parser accepts numeric strings for scores but backend responses should send JSON numbers.

### Recruiter Reasoning Fields

The backend may return additional backward-compatible fields for richer recruiter-level analysis. Current Flutter builds ignore unknown fields until the UI is extended.

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `keywordCoverage` | integer | no | Estimated coverage of important role-specific keywords and evidence, expected 0-100. |
| `strengths` | string[] | no | Modern alias for evidence-backed strengths; content should match or expand `strongPoints`. |
| `weaknesses` | string[] | no | Modern alias for evidence-backed risks; content should match or expand `weakPoints`. |
| `improvements` | string[] | no | Modern alias for actionable recommendations; content should match or expand `suggestedImprovements`. |
| `rewrittenSummary` | string | no | Tailored professional summary using only evidence from the CV. |
| `mainReasonsForScore` | string[] | no | Main evidence-based reasons for the match score. |
| `confidenceLevel` | string | no | Analysis confidence: `low`, `medium`, or `high`. |
| `recruiterVerdict` | string | no | Concise recruiter-style hiring-readiness verdict. |
| `rejectionRisks` | string[] | no | Top three reasons the application may be rejected. |
| `fastestFixes` | string[] | no | Top three fastest truthful changes to improve fit. |

## CV Rewrite Endpoint

`POST /rewrite-cv` rewrites selected CV content for a specific job description. This endpoint is backend-only for now; no Flutter UI calls it yet.

### CV Rewrite Request

```json
{
  "cvText": "Readable extracted CV text...",
  "jobDescription": "Full job description text...",
  "targetRole": "AI Product Manager",
  "locale": "en-US"
}
```

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `cvText` | string | yes | Normalized readable text extracted from the uploaded PDF. |
| `jobDescription` | string | yes | User-provided job description. Backend requires at least 100 characters. |
| `targetRole` | string | no | Role label used to tailor rewrite language. |
| `locale` | string | no | Locale tag such as `en-US` or `tr-TR`; defaults to `en` when omitted. |

Unknown fields are rejected. Validation errors must not echo `cvText` or `jobDescription`.

### CV Rewrite Response

Return `200 OK` with strict JSON:

```json
{
  "rewrittenSummary": "AI product manager with CV-supported roadmap ownership, stakeholder leadership, and prompt-testing experience. Add [insert measurable result] where the candidate can verify impact.",
  "rewrittenExperienceBullets": [
    "Owned roadmap prioritization for AI workflow improvements; add [insert measurable result] to quantify customer or activation impact.",
    "Collaborated with stakeholders on prompt-testing and launch planning; add [insert measurable result] where accurate."
  ],
  "rewrittenSkills": [
    "Roadmap ownership",
    "Stakeholder leadership",
    "Prompt testing",
    "Launch planning"
  ],
  "improvementNotes": [
    "Add verified activation or conversion metrics to the most relevant experience bullet.",
    "Only add missing tools from the job description if the candidate has actually used them."
  ],
  "warnings": [
    "Metric placeholders must be replaced with truthful values before applying.",
    "Do not add unsupported job requirements as skills."
  ]
}
```

### CV Rewrite Response Fields

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `rewrittenSummary` | string | yes | Truthful, job-tailored professional summary based only on CV evidence. |
| `rewrittenExperienceBullets` | string[] | yes | Rewritten CV bullets using scope, action, tools/processes, and truthful results or placeholders. |
| `rewrittenSkills` | string[] | yes | Skills supported by the CV and relevant to the job description. |
| `improvementNotes` | string[] | yes | Actionable guidance on what to add, where to add it, and why it improves fit. |
| `warnings` | string[] | yes | Truthfulness, missing evidence, unsupported requirement, and placeholder warnings. |

Rewrite providers must never invent experience, fabricate metrics, or add unsupported tools. When measurable impact is missing, providers must use placeholders such as `[insert measurable result]`.

## Error Responses

Return a non-2xx status with a JSON error payload:

```json
{
  "error": "Analysis service is temporarily unavailable."
}
```

or:

```json
{
  "message": "Job description is too short."
}
```

The client reads `error` first and then `message`. If neither exists, it displays a generic friendly API error.

### Recommended Status Codes

| Status | Meaning | Client Behavior |
| --- | --- | --- |
| `400` | Invalid request body | Shows backend message and Try again. |
| `401` | Missing or invalid client authentication | Shows backend message and Try again. |
| `413` | Request too large | Shows backend message and Try again. |
| `422` | Unable to analyze content | Shows backend message and Try again. |
| `429` | Rate limit exceeded | Shows backend message and Try again. |
| `500` | Internal server error | Shows backend message or generic API error. |
| `503` | Provider or service unavailable | Shows backend message or generic API error. |
| `504` | Backend/provider timeout | Shows backend message or generic timeout-style error. |

## API Error Payload With `200 OK`

The client also treats a `200 OK` body containing `error` or `message` without `matchScore` as an API error. Backends should still prefer appropriate non-2xx status codes.

## Backend Responsibilities

The backend must:

- Keep OpenAI or other provider API keys server-side only.
- Authenticate client requests before processing sensitive content.
- Enforce rate limits.
- Validate request size and schema before calling an AI provider.
- Redact CV text and job descriptions from logs.
- Validate and normalize AI-provider output before returning it to Flutter.
- Return JSON only.
- Configure CORS for trusted Flutter Web origins.
- Use TLS in production.

The current repository backend validates requests and returns contract-compatible JSON through `AnalysisOrchestrator` and `CvRewriteOrchestrator`. `MockProvider` is used when `AI_PROVIDER=mock`. `OpenAIProvider` is used only when `AI_PROVIDER=openai`, and `GeminiProvider` is used only when `AI_PROVIDER=gemini`. Gemini and mock modes support `POST /rewrite-cv`; OpenAI rewrite support is intentionally not enabled yet. Provider keys are read from backend environment variables, and output validation stays inside parser and validator layers.

## Client Responsibilities

The Flutter client must:

- Validate PDF extraction success before analysis.
- Send only the configured request fields.
- Use the 45-second timeout.
- Parse response JSON defensively.
- Show friendly errors and retry controls.
- Avoid displaying raw extracted CV text in normal UI.
- Avoid storing backend secrets.

## Example cURL

```sh
curl -X POST "https://api.example.com/v1/career-analysis" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "cvText": "Product discovery roadmap ownership prompt testing...",
    "cvFileName": "Derya_Kaya_CV.pdf",
    "jobDescription": "We are hiring an AI product manager...",
    "locale": "en-US",
    "targetRole": "AI Product Manager"
  }'
```

CV rewrite example:

```sh
curl -X POST "http://localhost:3001/rewrite-cv" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "cvText": "Product discovery roadmap ownership prompt testing...",
    "jobDescription": "We are hiring an AI product manager...",
    "locale": "en-US",
    "targetRole": "AI Product Manager"
  }'
```

## Related Documents

- Architecture: `ARCHITECTURE.md`
- Security: `SECURITY.md`
- Product behavior: `PRODUCT.md`
- Testing expectations: `TESTING.md`
