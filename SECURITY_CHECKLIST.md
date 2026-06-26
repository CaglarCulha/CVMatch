# CVMatch Security Checklist

This checklist is the mandatory security gate for CVMatch releases. It applies to the Flutter frontend, Node.js/Express backend, AI provider integrations, CI/CD pipeline, and any future persistence layer.

CVMatch processes highly sensitive personal information, including resumes, email addresses, phone numbers, employment history, education, job descriptions, and AI-generated career recommendations. Treat all resume data and job descriptions as confidential personal data.

## Usage Rules

- Every release item starts unchecked.
- Every checklist row must be explicitly marked pass before release approval.
- A checked fail box blocks release until remediation is complete and retested.
- Evidence must be linked from the release ticket, pull request, or security review record.
- Production releases require authentication, authorization, rate limiting, monitoring, and incident response readiness.

Checklist notation:

| Mark | Meaning |
| --- | --- |
| `[ ] Pass` | Control has been verified and evidence exists. |
| `[ ] Fail` | Control is missing, broken, or unverified. |

## Required Security Commands

Why it matters: Release approval must be based on repeatable evidence, not manual confidence.

Risk level: Critical

Recommended tools: Flutter CLI, npm, `git-secrets`, CodeQL, Dependabot, Snyk, Trivy, OWASP ZAP.

Run these commands before release. Store command output or CI links as release evidence.

### Flutter

```sh
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

### Backend

```sh
cd backend
npm audit --audit-level=moderate
npm test
npm run build
```

### Secret Scanning

```sh
git secrets --scan
git secrets --scan-history
```

### CodeQL

```sh
codeql database create codeql-db --language=javascript-typescript --source-root=.
codeql database analyze codeql-db javascript-security-and-quality.qls --format=sarif-latest --output=codeql-results.sarif
```

### Dependabot

```sh
test -f .github/dependabot.yml
```

### Snyk

```sh
snyk test
snyk test --file=backend/package.json
snyk monitor
```

### Trivy

```sh
trivy fs --severity HIGH,CRITICAL --exit-code 1 .
trivy config --severity HIGH,CRITICAL --exit-code 1 .
```

### OWASP ZAP

```sh
zap-baseline.py -t http://localhost:3001 -r zap-baseline.html
zap-full-scan.py -t https://staging-api.example.com -r zap-full-scan.html
```

## Authentication

Why it matters: CVMatch will process resumes and career data that must only be accessible to the data owner and trusted systems.

Risk level: Critical

Recommended tools: OAuth 2.1/OIDC provider, Firebase Auth or enterprise IdP, session management library, CodeQL, OWASP ZAP.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | User authentication is required before accessing CV upload, analysis, history, billing, or account APIs. |
| [ ] Pass | [ ] Fail | Backend verifies access tokens or sessions on every protected request. |
| [ ] Pass | [ ] Fail | Tokens are validated for issuer, audience, expiry, signature, and revocation where supported. |
| [ ] Pass | [ ] Fail | Refresh tokens are stored only in secure platform storage or HTTP-only secure cookies. |
| [ ] Pass | [ ] Fail | Login, logout, token refresh, and session expiry flows are tested. |
| [ ] Pass | [ ] Fail | Multi-factor authentication is supported or documented for enterprise accounts. |

Common mistakes:

- Trusting a Flutter client-side user ID without backend token verification.
- Storing long-lived tokens in local storage or plain preferences.
- Accepting expired or unsigned JWTs.
- Treating anonymous MVP access as production-ready.

## Authorization

Why it matters: Authenticated users must not read, modify, or analyze another user's resumes, job descriptions, or analysis history.

Risk level: Critical

Recommended tools: API integration tests, authorization middleware tests, CodeQL, OWASP ZAP, threat modeling.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Every user-owned resource has an owner, tenant, or access-control boundary. |
| [ ] Pass | [ ] Fail | Backend authorization is enforced server-side for every resource lookup. |
| [ ] Pass | [ ] Fail | Object IDs cannot be used for insecure direct object reference attacks. |
| [ ] Pass | [ ] Fail | Admin endpoints require explicit admin roles and are not inferred from client claims alone. |
| [ ] Pass | [ ] Fail | Authorization failures return `403` without leaking resource existence or personal data. |
| [ ] Pass | [ ] Fail | Cross-tenant access tests exist for resumes, analyses, subscriptions, and profile data. |

Common mistakes:

- Filtering records by ID but not by user or tenant.
- Trusting role values sent by Flutter.
- Returning different errors that reveal whether another user's record exists.

## API Security

Why it matters: API endpoints are the primary boundary between untrusted clients and sensitive CV processing.

Risk level: Critical

Recommended tools: Zod, Express middleware tests, OWASP ZAP, CodeQL, Postman/Newman, Schemathesis.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Every endpoint has request schema validation and rejects unknown or oversized payloads. |
| [ ] Pass | [ ] Fail | Every endpoint returns structured JSON errors with appropriate HTTP status codes. |
| [ ] Pass | [ ] Fail | Request body size limits are enforced before business logic. |
| [ ] Pass | [ ] Fail | API timeouts exist for backend operations and AI provider calls. |
| [ ] Pass | [ ] Fail | API responses never include secrets, stack traces, raw prompts, or raw CV text unless explicitly required by user-facing product behavior. |
| [ ] Pass | [ ] Fail | Security regression tests cover validation, auth, rate limits, and provider failure modes. |

Common mistakes:

- Returning `200 OK` for business errors.
- Echoing invalid request bodies in error responses.
- Missing timeout handling on upstream calls.
- Exposing implementation exceptions to Flutter.

## File Upload Security

Why it matters: Resume upload is a high-risk boundary. Malicious PDFs can trigger parser vulnerabilities, denial of service, or data exfiltration paths.

Risk level: Critical

Recommended tools: Syncfusion PDF parser review, file signature library, ClamAV, Trivy, fuzz tests, corpus tests.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Only PDF uploads are accepted. |
| [ ] Pass | [ ] Fail | File extension, MIME type, and PDF magic bytes are all verified. |
| [ ] Pass | [ ] Fail | EXE, ZIP, JS, HTML, SVG, Office files, and macro-enabled files are rejected. |
| [ ] Pass | [ ] Fail | Upload size limit is enforced before parsing. |
| [ ] Pass | [ ] Fail | PDF page count limit is enforced. |
| [ ] Pass | [ ] Fail | Maximum extracted character limit is enforced before AI analysis. |
| [ ] Pass | [ ] Fail | Password-protected, corrupted, empty, and image-only PDFs fail safely with friendly errors. |
| [ ] Pass | [ ] Fail | Uploaded files and extracted text are not persisted unless documented retention, encryption, and deletion controls exist. |

Common mistakes:

- Trusting filename or extension.
- Parsing before checking size.
- Allowing SVG or HTML because they look like documents.
- Displaying full local paths or raw extracted text.

## PDF Upload Validation

Why it matters: PDF-specific validation reduces parser abuse, zip-bomb style payloads, and scanned-document failure cases.

Risk level: Critical

Recommended tools: PDF corpus tests, parser sandboxing, file-type detection, ClamAV, AFL/libFuzzer for native parsers where applicable.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Magic bytes begin with a valid PDF signature such as `%PDF-`. |
| [ ] Pass | [ ] Fail | MIME type matches `application/pdf` where the platform provides reliable MIME metadata. |
| [ ] Pass | [ ] Fail | Parser confirms a readable PDF structure before text extraction proceeds. |
| [ ] Pass | [ ] Fail | Page count is bounded by product policy. |
| [ ] Pass | [ ] Fail | Extracted text length is bounded by product policy. |
| [ ] Pass | [ ] Fail | Scanned or image-only PDFs receive a non-sensitive user-facing error. |
| [ ] Pass | [ ] Fail | Test fixtures cover valid, empty, corrupted, image-only, oversized, and password-protected PDFs. |

Common mistakes:

- Treating client-side validation as sufficient for future backend uploads.
- Allowing unlimited extracted text into prompts.
- Logging parser errors that include local file paths or document content.

## OpenAI Integration

Why it matters: AI provider calls send sensitive CV and job data to an external service and can be abused for cost exhaustion or prompt injection.

Risk level: Critical

Recommended tools: OpenAI Node SDK, Zod, prompt-injection tests, AI red-team prompts, egress monitoring, rate limiter.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Flutter never calls OpenAI directly. |
| [ ] Pass | [ ] Fail | `OPENAI_API_KEY` is read only from backend environment or secret manager. |
| [ ] Pass | [ ] Fail | AI provider calls have timeout, retry policy, and safe failure mapping. |
| [ ] Pass | [ ] Fail | AI responses are schema constrained and validated before returning to the client. |
| [ ] Pass | [ ] Fail | Prompts instruct the model to ignore CV/job-description instructions that attempt to override system rules. |
| [ ] Pass | [ ] Fail | Raw prompts, CV text, job descriptions, provider responses, and API keys are not logged. |
| [ ] Pass | [ ] Fail | OpenAI usage is rate-limited per user, tenant, and IP. |

Common mistakes:

- Embedding provider keys in Flutter.
- Trusting JSON mode without schema validation.
- Logging provider errors that include request payloads.
- Retrying non-retryable provider errors.

## Secure OpenAI Usage

Why it matters: Secure provider usage protects secrets, user privacy, cost controls, and result integrity.

Risk level: Critical

Recommended tools: OpenAI structured outputs, backend secret manager, Zod, OpenTelemetry redaction, billing alerts.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Provider key is scoped to the least privilege and environment required. |
| [ ] Pass | [ ] Fail | Provider key rotation procedure is documented and tested. |
| [ ] Pass | [ ] Fail | Token and cost budgets are enforced per request and per account. |
| [ ] Pass | [ ] Fail | Structured output schema requires all fields needed by the API contract. |
| [ ] Pass | [ ] Fail | Provider model name is configured server-side and does not expose secrets. |
| [ ] Pass | [ ] Fail | Provider failures never disclose prompts, payloads, stack traces, or provider credentials. |

Common mistakes:

- Using one shared production key across development and staging.
- Sending unnecessary personal data to the provider.
- Allowing user-controlled model names or provider URLs.

## AI Prompt Injection Protection

Why it matters: CVs and job descriptions are untrusted text. Attackers can embed instructions that attempt to reveal prompts, bypass validation, or manipulate output.

Risk level: High

Recommended tools: prompt-injection test suite, red-team prompts, Zod, structured outputs, content filters.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | System prompts explicitly treat CV and job text as untrusted data. |
| [ ] Pass | [ ] Fail | Model is instructed not to reveal hidden instructions, prompts, or system policy. |
| [ ] Pass | [ ] Fail | Output is limited to a strict JSON schema. |
| [ ] Pass | [ ] Fail | Backend validates output types, ranges, and required fields. |
| [ ] Pass | [ ] Fail | Prompt injection fixtures are tested, including attempts to leak API keys or system prompts. |
| [ ] Pass | [ ] Fail | AI output is never used to make authorization, billing, or privileged system decisions. |

Common mistakes:

- Assuming system prompts fully prevent injection.
- Rendering AI output as trusted HTML.
- Allowing the model to choose tools, URLs, or backend actions without policy checks.

## Secrets Management

Why it matters: API keys, tokens, and credentials can grant access to provider accounts, user data, infrastructure, and billing.

Risk level: Critical

Recommended tools: cloud secret manager, `git-secrets`, GitHub secret scanning, Snyk, Trivy.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | No API keys, tokens, passwords, private keys, or credentials exist in source code, docs, tests, assets, screenshots, or commit history. |
| [ ] Pass | [ ] Fail | `.env` files are ignored and never committed. |
| [ ] Pass | [ ] Fail | `.env.example` contains names only, never real values. |
| [ ] Pass | [ ] Fail | Production secrets come from a managed secret store. |
| [ ] Pass | [ ] Fail | Secret rotation and revocation process is documented. |
| [ ] Pass | [ ] Fail | CI blocks commits and pull requests containing secrets. |

Common mistakes:

- Putting secrets in Flutter `--dart-define`.
- Adding sample tokens to README files.
- Printing environment variables during CI debugging.

## Environment Variables

Why it matters: Misconfigured environments can expose APIs, loosen CORS, disable protections, or route production data to development systems.

Risk level: High

Recommended tools: environment schema validation, dotenv for local only, secret manager, CI config checks, Trivy config scanning.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Backend validates environment variables at startup. |
| [ ] Pass | [ ] Fail | Production fails closed when required variables are missing. |
| [ ] Pass | [ ] Fail | Production does not allow wildcard CORS origins. |
| [ ] Pass | [ ] Fail | Provider keys and database credentials are not exposed to Flutter. |
| [ ] Pass | [ ] Fail | Development, staging, and production use separate keys and resources. |
| [ ] Pass | [ ] Fail | Environment values are documented without revealing secrets. |

Common mistakes:

- Defaulting production to permissive development behavior.
- Reusing staging secrets in production.
- Treating backend URLs as secrets while leaking real secrets elsewhere.

## Logging

Why it matters: Logs are often copied into third-party systems and retained longer than application data.

Risk level: Critical

Recommended tools: structured logger with redaction, OpenTelemetry processors, log sampling, DLP scanners.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Logs never include CV text, emails, phone numbers, job descriptions, prompts, provider responses, API keys, authorization headers, JWTs, or local file paths. |
| [ ] Pass | [ ] Fail | Allowed logs are limited to request ID, endpoint, duration, status code, and error category. |
| [ ] Pass | [ ] Fail | Error logs include stack traces only server-side and only without sensitive payloads. |
| [ ] Pass | [ ] Fail | Log retention is documented and aligned with privacy requirements. |
| [ ] Pass | [ ] Fail | Production logging redaction is tested. |
| [ ] Pass | [ ] Fail | CI and test logs do not print secrets or personal data fixtures. |

Common mistakes:

- Logging entire request bodies on validation failure.
- Logging provider exceptions that contain payloads.
- Sending unredacted logs to analytics or crash reporting tools.

## Error Handling

Why it matters: Error messages can disclose stack traces, implementation details, secrets, or personal data.

Risk level: High

Recommended tools: Express error middleware, Flutter error boundaries, Sentry with PII scrubbing, tests.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Backend has a global error handler returning structured JSON. |
| [ ] Pass | [ ] Fail | User-facing errors are friendly, actionable, and do not expose internals. |
| [ ] Pass | [ ] Fail | Provider and parser failures map to appropriate status codes. |
| [ ] Pass | [ ] Fail | Flutter handles network, timeout, invalid JSON, and non-2xx errors safely. |
| [ ] Pass | [ ] Fail | Stack traces are not sent to clients. |
| [ ] Pass | [ ] Fail | Error paths are tested for sensitive-data non-disclosure. |

Common mistakes:

- Returning raw exception messages from backend.
- Displaying backend stack traces in Flutter.
- Crashing on malformed API responses.

## Input Validation

Why it matters: All user and provider inputs are untrusted and can trigger injection, denial of service, or logic abuse.

Risk level: Critical

Recommended tools: Zod, Dart model validation, property-based testing, fuzz tests, CodeQL.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Backend validates all request bodies with strict schemas. |
| [ ] Pass | [ ] Fail | Flutter validates user inputs before sending requests but backend remains authoritative. |
| [ ] Pass | [ ] Fail | String lengths, array sizes, score ranges, file sizes, page counts, and extracted text lengths are bounded. |
| [ ] Pass | [ ] Fail | Unknown fields are rejected or safely ignored according to documented API behavior. |
| [ ] Pass | [ ] Fail | AI provider responses are validated before returning. |
| [ ] Pass | [ ] Fail | Validation errors do not echo sensitive input. |

Common mistakes:

- Relying only on Flutter validation.
- Missing maximum lengths.
- Accepting provider output as trusted.

## Output Encoding

Why it matters: AI-generated content and user-provided job descriptions can contain scripts or markup that must not execute in clients.

Risk level: High

Recommended tools: Flutter widgets with text rendering, HTML sanitizer if HTML is introduced, OWASP ZAP.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | User and AI content is rendered as text, not raw HTML. |
| [ ] Pass | [ ] Fail | No WebView renders untrusted CV, job, or AI content without sanitization and a restrictive content security policy. |
| [ ] Pass | [ ] Fail | Backend returns JSON with correct `Content-Type`. |
| [ ] Pass | [ ] Fail | Generated exports encode or escape user and AI content according to file format. |
| [ ] Pass | [ ] Fail | Markdown, HTML, or rich-text rendering is threat-modeled before introduction. |

Common mistakes:

- Displaying AI output inside raw HTML.
- Trusting text because it came from a model.
- Exporting unescaped spreadsheet formulas.

## CORS

Why it matters: CORS controls browser access to backend responses and must be restrictive in production while supporting Flutter Web development safely.

Risk level: High

Recommended tools: `cors` package, Supertest, OWASP ZAP, browser devtools.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | CORS middleware is registered before all routes. |
| [ ] Pass | [ ] Fail | Production origins are explicit and do not use `*`. |
| [ ] Pass | [ ] Fail | Development allows only expected localhost origins and methods. |
| [ ] Pass | [ ] Fail | Allowed methods are limited to required methods. |
| [ ] Pass | [ ] Fail | Allowed headers are limited to required headers such as `Content-Type` and `Authorization`. |
| [ ] Pass | [ ] Fail | Preflight and POST responses include expected CORS headers. |

Common mistakes:

- Allowing all origins in production.
- Configuring OPTIONS but not POST.
- Reflecting arbitrary origins with credentials enabled.

## Rate Limiting

Why it matters: Analysis endpoints can be abused for denial of service, brute force, credential stuffing, and OpenAI cost exhaustion.

Risk level: Critical

Recommended tools: `express-rate-limit`, Redis-backed rate limiter, API gateway limits, WAF, OpenAI billing alerts.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Authentication endpoints have brute-force protections. |
| [ ] Pass | [ ] Fail | `POST /analyze` is limited by user, tenant, IP, and subscription tier. |
| [ ] Pass | [ ] Fail | AI provider calls have cost and token budgets. |
| [ ] Pass | [ ] Fail | Rate-limit responses return `429` with structured JSON. |
| [ ] Pass | [ ] Fail | Limits are enforced at application and infrastructure layers. |
| [ ] Pass | [ ] Fail | Abuse and throttling metrics are monitored. |

Common mistakes:

- Relying only on frontend button disabling.
- Applying global IP limits that break enterprise NAT users.
- Missing provider cost caps.

## HTTP Security Headers

Why it matters: Security headers reduce browser-based attacks including XSS, clickjacking, MIME sniffing, and downgrade attacks.

Risk level: High

Recommended tools: Helmet, securityheaders.com, OWASP ZAP, Mozilla Observatory.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Backend uses Helmet or equivalent secure headers. |
| [ ] Pass | [ ] Fail | `Content-Security-Policy` is configured for web deployments. |
| [ ] Pass | [ ] Fail | `X-Content-Type-Options: nosniff` is enabled. |
| [ ] Pass | [ ] Fail | `Referrer-Policy` is configured. |
| [ ] Pass | [ ] Fail | `X-Frame-Options` or CSP `frame-ancestors` prevents clickjacking. |
| [ ] Pass | [ ] Fail | HSTS is enabled for production HTTPS domains. |

Common mistakes:

- Assuming Helmet defaults are sufficient for every deployment.
- Missing CSP for Flutter Web hosting.
- Enabling HSTS on local development domains.

## Dependency Security

Why it matters: Third-party packages parse PDFs, make network calls, run build tools, and can introduce supply-chain vulnerabilities.

Risk level: Critical

Recommended tools: `npm audit`, `flutter pub outdated`, Dependabot, Snyk, Trivy, OSV-Scanner.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | `npm audit --audit-level=moderate` passes for backend dependencies. |
| [ ] Pass | [ ] Fail | Flutter dependencies are reviewed with `flutter pub outdated`. |
| [ ] Pass | [ ] Fail | Dependabot is enabled for npm, GitHub Actions, and Dart where supported. |
| [ ] Pass | [ ] Fail | New dependencies have active maintenance, acceptable license, and no known high/critical vulnerabilities. |
| [ ] Pass | [ ] Fail | Lockfiles are committed and reviewed. |
| [ ] Pass | [ ] Fail | CI blocks high and critical dependency vulnerabilities. |

Common mistakes:

- Ignoring dev dependency vulnerabilities that run in CI.
- Adding abandoned packages for security-sensitive parsing.
- Updating dependencies without running tests.

## Mobile Security

Why it matters: Mobile devices can be lost, compromised, inspected, or run on untrusted networks.

Risk level: High

Recommended tools: MobSF, platform secure storage, Android Network Security Config, iOS ATS, certificate pinning assessment.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Production mobile builds use HTTPS-only APIs. |
| [ ] Pass | [ ] Fail | Sensitive tokens use iOS Keychain or Android Keystore-backed storage. |
| [ ] Pass | [ ] Fail | Debug endpoints and verbose logs are disabled in release builds. |
| [ ] Pass | [ ] Fail | App transport security and Android network security settings prevent cleartext production traffic. |
| [ ] Pass | [ ] Fail | Crash reporting scrubs personal data. |
| [ ] Pass | [ ] Fail | Release builds are signed with protected keys. |

Common mistakes:

- Allowing cleartext HTTP in production.
- Keeping debug menus in release builds.
- Storing tokens in plain shared preferences.

## Flutter Security

Why it matters: Flutter handles file selection, local PDF extraction, API calls, state, and presentation of sensitive AI output.

Risk level: High

Recommended tools: `flutter analyze`, `flutter test`, MobSF, Semgrep, platform channel tests.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | `flutter analyze` passes. |
| [ ] Pass | [ ] Fail | `flutter test` passes. |
| [ ] Pass | [ ] Fail | `dart format --set-exit-if-changed lib test` passes. |
| [ ] Pass | [ ] Fail | Flutter does not embed OpenAI keys, backend secrets, or shared API secrets. |
| [ ] Pass | [ ] Fail | UI never displays full file paths, raw PDF bytes, data URIs, base64 content, or full extracted CV text in normal mode. |
| [ ] Pass | [ ] Fail | API responses are parsed defensively and invalid responses fail safely. |
| [ ] Pass | [ ] Fail | Debug-only surfaces are excluded from release behavior. |

Common mistakes:

- Treating `--dart-define` as secret storage.
- Showing debug extraction text in production.
- Trusting backend JSON without type validation.

## Backend Security

Why it matters: The backend is the enforcement point for auth, validation, secrets, AI calls, rate limits, and future persistence.

Risk level: Critical

Recommended tools: Express, Helmet, Zod, CodeQL, Supertest, Snyk, Trivy, OWASP ZAP.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | `npm test` passes. |
| [ ] Pass | [ ] Fail | `npm run build` passes. |
| [ ] Pass | [ ] Fail | All protected endpoints enforce authentication and authorization. |
| [ ] Pass | [ ] Fail | Request body limits and schema validation are active before provider calls. |
| [ ] Pass | [ ] Fail | Global error handling returns JSON and logs only safe metadata. |
| [ ] Pass | [ ] Fail | AI provider calls have timeout, retry bounds, and output validation. |
| [ ] Pass | [ ] Fail | Backend does not persist sensitive data unless database controls are complete. |

Common mistakes:

- Shipping MVP backend without auth or rate limits.
- Catching provider errors but returning raw messages.
- Logging request bodies for debugging.

## Database Security

Why it matters: Future persistence of resumes and analyses creates long-lived privacy, compliance, and breach-impact risk.

Risk level: Critical

Recommended tools: managed database IAM, encryption at rest, migration review, Prisma/Drizzle with parameterized queries, database audit logs.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | No sensitive data is persisted until schema, retention, deletion, and encryption controls are documented. |
| [ ] Pass | [ ] Fail | Database access uses least-privilege credentials and network restrictions. |
| [ ] Pass | [ ] Fail | Queries are parameterized; string concatenation is prohibited. |
| [ ] Pass | [ ] Fail | Encryption at rest and backups are enabled. |
| [ ] Pass | [ ] Fail | User deletion removes or anonymizes CV text, analysis history, and derived AI outputs according to policy. |
| [ ] Pass | [ ] Fail | Backup retention and restore access are reviewed. |

Common mistakes:

- Persisting raw CV text before retention policy exists.
- Using admin database credentials from the app server.
- Forgetting AI-generated recommendations are also personal data.

## CI/CD Security

Why it matters: CI/CD can leak secrets, publish vulnerable builds, or allow unreviewed code into production.

Risk level: Critical

Recommended tools: GitHub Actions environments, CodeQL, Dependabot, Snyk, Trivy, `git-secrets`, branch protection.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | CI runs Flutter, backend, audit, secret scanning, and CodeQL checks. |
| [ ] Pass | [ ] Fail | Production deploys require protected environments and reviewer approval. |
| [ ] Pass | [ ] Fail | CI secrets are scoped to required jobs only. |
| [ ] Pass | [ ] Fail | Pull requests from forks cannot access production secrets. |
| [ ] Pass | [ ] Fail | Build artifacts do not contain `.env` files, source maps with secrets, or debug configuration. |
| [ ] Pass | [ ] Fail | Release provenance and build logs are retained. |

Common mistakes:

- Printing secrets in failed CI steps.
- Running deployment from unprotected branches.
- Allowing dependency update PRs to auto-deploy.

## GitHub Security

Why it matters: Repository controls prevent unauthorized changes, leaked secrets, and unreviewed vulnerable dependencies.

Risk level: High

Recommended tools: GitHub branch protection, code owners, Dependabot, secret scanning, CodeQL, signed commits.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Branch protection requires reviews and passing checks. |
| [ ] Pass | [ ] Fail | Code owners are configured for security-sensitive areas. |
| [ ] Pass | [ ] Fail | GitHub secret scanning and push protection are enabled. |
| [ ] Pass | [ ] Fail | Dependabot alerts and security updates are enabled. |
| [ ] Pass | [ ] Fail | CodeQL analysis runs on pull requests and default branch. |
| [ ] Pass | [ ] Fail | Admin bypass permissions are minimized and reviewed. |

Common mistakes:

- Letting maintainers bypass required checks.
- Missing CODEOWNERS for backend, auth, and security docs.
- Ignoring Dependabot alerts for dev dependencies.

## Monitoring

Why it matters: Security controls must detect abuse, failures, rate-limit events, suspicious provider usage, and privacy incidents.

Risk level: High

Recommended tools: OpenTelemetry, cloud logs with redaction, SIEM, Sentry with PII scrubbing, uptime checks, billing alerts.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | API error rates, latency, rate-limit events, and provider failures are monitored. |
| [ ] Pass | [ ] Fail | OpenAI usage and spend alerts are configured. |
| [ ] Pass | [ ] Fail | Authentication failures and suspicious access patterns are monitored. |
| [ ] Pass | [ ] Fail | Logs and traces use request IDs without sensitive payloads. |
| [ ] Pass | [ ] Fail | Alerts have documented owners and escalation paths. |
| [ ] Pass | [ ] Fail | Monitoring coverage is tested before production launch. |

Common mistakes:

- Monitoring only uptime, not abuse or cost.
- Sending personal data to observability vendors.
- Creating alerts with no owner.

## Incident Response

Why it matters: Resume data exposure can create significant user harm and regulatory obligations.

Risk level: Critical

Recommended tools: incident runbook, pager, secret rotation playbooks, forensic log retention, privacy counsel workflow.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Security incident response runbook exists and is tested. |
| [ ] Pass | [ ] Fail | Data breach triage includes affected users, data categories, time window, and containment steps. |
| [ ] Pass | [ ] Fail | Secret rotation procedure is documented. |
| [ ] Pass | [ ] Fail | Provider key compromise procedure is documented. |
| [ ] Pass | [ ] Fail | Legal, privacy, support, and engineering notification paths are documented. |
| [ ] Pass | [ ] Fail | Post-incident review requires corrective actions and regression tests. |

Common mistakes:

- Copying sensitive data into incident tickets.
- Delaying secret rotation while investigating.
- Missing user notification criteria.

## OWASP Top 10

Why it matters: OWASP Top 10 maps the most common web application risk classes that affect CVMatch backend and Flutter Web deployments.

Risk level: Critical

Recommended tools: OWASP ZAP, CodeQL, Semgrep, Snyk, threat modeling.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Broken access control is mitigated with server-side authorization checks. |
| [ ] Pass | [ ] Fail | Cryptographic failures are mitigated with TLS, secure storage, and no secret exposure. |
| [ ] Pass | [ ] Fail | Injection is mitigated with schema validation, parameterized queries, and no command execution from user input. |
| [ ] Pass | [ ] Fail | Insecure design is mitigated with threat modeling for uploads, AI, auth, and persistence. |
| [ ] Pass | [ ] Fail | Security misconfiguration is mitigated with environment validation, Helmet, strict CORS, and secure defaults. |
| [ ] Pass | [ ] Fail | Vulnerable components are mitigated with dependency scanning and upgrade SLAs. |
| [ ] Pass | [ ] Fail | Identification and authentication failures are mitigated with strong auth and session controls. |
| [ ] Pass | [ ] Fail | Software and data integrity failures are mitigated with lockfiles, CI checks, and protected deployments. |
| [ ] Pass | [ ] Fail | Logging and monitoring failures are mitigated with safe structured logs and alerting. |
| [ ] Pass | [ ] Fail | SSRF is mitigated by avoiding user-controlled outbound URLs and restricting egress. |

Common mistakes:

- Treating OWASP as a one-time audit.
- Ignoring insecure design until implementation is complete.
- Missing SSRF review when adding integrations.

## OWASP API Top 10

Why it matters: CVMatch exposes APIs that will process personal data and trigger paid AI provider calls.

Risk level: Critical

Recommended tools: OWASP ZAP API scan, Schemathesis, Postman/Newman, CodeQL, rate-limit tests.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Broken object level authorization is tested for every user-owned object. |
| [ ] Pass | [ ] Fail | Broken authentication is mitigated with backend token/session verification. |
| [ ] Pass | [ ] Fail | Broken object property level authorization is mitigated by filtering writable and readable fields. |
| [ ] Pass | [ ] Fail | Unrestricted resource consumption is mitigated with rate limits, timeouts, body limits, and token budgets. |
| [ ] Pass | [ ] Fail | Broken function level authorization is mitigated by role checks on privileged endpoints. |
| [ ] Pass | [ ] Fail | Unrestricted access to sensitive business flows is mitigated with abuse controls around AI analysis and billing. |
| [ ] Pass | [ ] Fail | SSRF is mitigated by disallowing user-controlled fetch URLs. |
| [ ] Pass | [ ] Fail | Security misconfiguration is mitigated with production-safe CORS, headers, and environment validation. |
| [ ] Pass | [ ] Fail | Improper inventory management is mitigated with documented endpoints and deprecated route removal. |
| [ ] Pass | [ ] Fail | Unsafe API consumption is mitigated by validating AI and third-party responses. |

Common mistakes:

- Missing field-level authorization.
- Letting users submit unbounded analysis requests.
- Trusting third-party API responses without validation.

## Resume Privacy

Why it matters: Resumes can include special category data, contact details, identity information, and employment history.

Risk level: Critical

Recommended tools: privacy review, data inventory, DLP scanning, retention automation, access review.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Data inventory covers PDF bytes, extracted text, job descriptions, analysis results, logs, and backups. |
| [ ] Pass | [ ] Fail | Product collects only data required for CV analysis. |
| [ ] Pass | [ ] Fail | Raw CV text is not persisted unless retention and deletion controls are complete. |
| [ ] Pass | [ ] Fail | Users can understand what data is sent to backend and AI providers. |
| [ ] Pass | [ ] Fail | Internal access to resume data is restricted and audited. |
| [ ] Pass | [ ] Fail | Debug and support workflows do not require copying raw resumes. |

Common mistakes:

- Treating AI outputs as non-sensitive.
- Keeping uploaded PDFs indefinitely by default.
- Using real resumes in demos, tests, or screenshots.

## GDPR Readiness

Why it matters: CVMatch may process personal data of users in GDPR jurisdictions and must support privacy rights and lawful processing.

Risk level: Critical

Recommended tools: data processing inventory, privacy impact assessment, consent management, deletion/export workflows.

Checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Lawful basis for processing is documented. |
| [ ] Pass | [ ] Fail | Privacy notice explains CV analysis, AI provider processing, retention, and user rights. |
| [ ] Pass | [ ] Fail | Data processing agreements are in place for AI, hosting, monitoring, and analytics vendors. |
| [ ] Pass | [ ] Fail | Users can request access, export, correction, and deletion. |
| [ ] Pass | [ ] Fail | Data retention periods are documented and technically enforced. |
| [ ] Pass | [ ] Fail | Cross-border transfer safeguards are reviewed. |
| [ ] Pass | [ ] Fail | Breach notification workflow meets regulatory timelines. |

Common mistakes:

- Launching persistence without deletion workflows.
- Sending personal data to vendors without DPA review.
- Retaining logs longer than necessary.

## Release Security Gate

A release must never be approved until every item in this section is checked.

Why it matters: CVMatch handles sensitive personal data, so release approval must fail closed when security evidence is missing.

Risk level: Critical

Recommended tools: CI required checks, release checklist, security sign-off, artifact attestation.

Mandatory release checklist:

| Pass | Fail | Item |
| --- | --- | --- |
| [ ] Pass | [ ] Fail | Every applicable checklist item in this document is marked pass. |
| [ ] Pass | [ ] Fail | `dart format --set-exit-if-changed lib test` passes. |
| [ ] Pass | [ ] Fail | `flutter analyze` passes. |
| [ ] Pass | [ ] Fail | `flutter test` passes. |
| [ ] Pass | [ ] Fail | `npm audit --audit-level=moderate` passes. |
| [ ] Pass | [ ] Fail | `npm test` passes. |
| [ ] Pass | [ ] Fail | `npm run build` passes. |
| [ ] Pass | [ ] Fail | `git secrets --scan` and `git secrets --scan-history` pass. |
| [ ] Pass | [ ] Fail | CodeQL has no unresolved high or critical findings. |
| [ ] Pass | [ ] Fail | Dependabot has no unresolved high or critical alerts. |
| [ ] Pass | [ ] Fail | Snyk has no unresolved high or critical findings. |
| [ ] Pass | [ ] Fail | Trivy has no unresolved high or critical findings. |
| [ ] Pass | [ ] Fail | OWASP ZAP scan findings are triaged and high-risk issues are fixed. |
| [ ] Pass | [ ] Fail | Authentication and authorization are enabled for production APIs. |
| [ ] Pass | [ ] Fail | Rate limiting is enabled for auth and analysis endpoints. |
| [ ] Pass | [ ] Fail | Production CORS uses explicit trusted origins only. |
| [ ] Pass | [ ] Fail | OpenAI keys are stored only in backend secret management. |
| [ ] Pass | [ ] Fail | Logs are verified to exclude CV text, job descriptions, prompts, tokens, and personal data. |
| [ ] Pass | [ ] Fail | Incident response owner and rollback plan are documented for the release. |

Release approval rule:

```text
If any item is unchecked or marked Fail, the release is blocked.
Security approval cannot be overridden for convenience, demo deadlines, or partial MVP scope.
```

Common mistakes:

- Approving a release with known authentication, rate-limit, or dependency gaps.
- Treating staging-only scan evidence as production release evidence.
- Allowing manual approvals to bypass failing security checks.
