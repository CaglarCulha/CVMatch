# API Specification

## Purpose

This document defines the contract between the Flutter client and the CVMatch career analysis backend. The backend is responsible for any AI-provider calls. The Flutter client must not call OpenAI or any other model provider directly.

## Client Configuration

The Flutter client selects the analysis implementation with:

```sh
CVMATCH_ANALYSIS_API_URL
```

Run with a backend:

```sh
flutter run --dart-define=CVMATCH_ANALYSIS_API_URL=https://api.example.com/v1/career-analysis
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
  "missingKeywords": [
    "Activation metrics",
    "Experiment design"
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

## Related Documents

- Architecture: `ARCHITECTURE.md`
- Security: `SECURITY.md`
- Product behavior: `PRODUCT.md`
- Testing expectations: `TESTING.md`
