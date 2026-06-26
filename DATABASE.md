# Database Handbook

## Current Persistence Posture

CVMatch currently uses no application database.

All sensitive runtime data is stored in memory through `CVMatchState`:

- Selected CV file name.
- Internal selected file path.
- File size.
- Extracted CV text.
- PDF page count.
- Job description.
- Latest analysis result.

This data is cleared when the app process, browser tab, or Flutter session is reset.

## Why No Database Yet

CV and job description data can contain highly sensitive personal information. The MVP intentionally avoids persistence until authentication, retention, deletion, and encryption requirements are implemented and reviewed.

## Client-Side Storage Rules

The Flutter client must not persist the following without an approved design update:

- Raw CV text.
- Uploaded PDF bytes.
- Full local file paths.
- Full job descriptions.
- AI prompts.
- Full backend responses containing user-provided content.

Acceptable in-memory data is already represented by `CVMatchState`.

## Data Classification

| Data | Classification | Current Storage | Notes |
| --- | --- | --- | --- |
| CV file name | Personal data | Memory | Displayed to user. |
| CV file size | Low sensitivity metadata | Memory | Displayed to user. |
| Local file path | Sensitive local metadata | Memory | Never displayed in normal UI. |
| Extracted CV text | Sensitive personal data | Memory | Sent to backend only when configured. |
| Job description | User content / potentially sensitive | Memory | Sent to backend only when configured. |
| Analysis result | Derived personal data | Memory | Displayed to user. |
| Auth identity | Not implemented | None | Future feature. |
| Billing status | Not implemented | None | Future feature. |

## Future Persistence Principles

Before adding a database:

1. Define authentication and authorization.
2. Define retention periods.
3. Define user deletion behavior.
4. Define whether raw CV text is stored or processed ephemerally.
5. Define encryption requirements.
6. Define audit logging with redaction.
7. Update `SECURITY.md`, `API_SPEC.md`, and this file.

## Recommended Future Backend Data Model

If analysis history is implemented, prefer storing metadata and derived results separately from raw content.

### `users`

| Column | Type | Requirement |
| --- | --- | --- |
| `id` | UUID | Primary key. |
| `email` | text | Unique when email auth is used. |
| `created_at` | timestamp | Required. |
| `updated_at` | timestamp | Required. |
| `deleted_at` | timestamp nullable | Supports soft delete and recovery workflows. |

### `cv_documents`

| Column | Type | Requirement |
| --- | --- | --- |
| `id` | UUID | Primary key. |
| `user_id` | UUID | Foreign key to `users.id`. |
| `file_name` | text | Required. |
| `file_size_bytes` | integer nullable | From upload metadata. |
| `page_count` | integer nullable | From extraction. |
| `extraction_succeeded` | boolean | Required. |
| `extracted_text_hash` | text nullable | Enables deduplication without storing raw text. |
| `created_at` | timestamp | Required. |

Raw extracted text should be omitted by default. If product requirements demand storage, store it encrypted and document retention.

### `job_descriptions`

| Column | Type | Requirement |
| --- | --- | --- |
| `id` | UUID | Primary key. |
| `user_id` | UUID | Foreign key to `users.id`. |
| `title` | text nullable | User-provided or inferred. |
| `company` | text nullable | User-provided or inferred. |
| `content_hash` | text | Hash of normalized content. |
| `created_at` | timestamp | Required. |

Raw job description content should be omitted unless history requires it. If stored, encrypt it.

### `analysis_results`

| Column | Type | Requirement |
| --- | --- | --- |
| `id` | UUID | Primary key. |
| `user_id` | UUID | Foreign key to `users.id`. |
| `cv_document_id` | UUID | Foreign key to `cv_documents.id`. |
| `job_description_id` | UUID | Foreign key to `job_descriptions.id`. |
| `match_score` | integer | 0-100. |
| `ats_score` | integer | 0-100. |
| `result_json` | JSON | Stores `CvAnalysisResult` fields. |
| `analysis_mode` | text | `mock`, `backend`, or provider-specific backend mode. |
| `created_at` | timestamp | Required. |
| `deleted_at` | timestamp nullable | User deletion support. |

### `subscriptions`

| Column | Type | Requirement |
| --- | --- | --- |
| `id` | UUID | Primary key. |
| `user_id` | UUID | Foreign key to `users.id`. |
| `provider` | text | Billing provider. |
| `provider_customer_id` | text | External customer reference. |
| `status` | text | Active, trialing, expired, cancelled, billing_retry. |
| `current_period_end` | timestamp nullable | Entitlement boundary. |
| `updated_at` | timestamp | Required. |

Entitlements must be enforced server-side, not only in Flutter UI.

## Deletion Requirements For Future Persistence

When user deletion exists:

- Delete or anonymize analysis metadata.
- Delete encrypted raw content if stored.
- Delete provider customer references when legally and operationally possible.
- Keep only minimal compliance records when required.
- Expose deletion status to the user.

## Related Documents

- Security: `SECURITY.md`
- Product roadmap: `ROADMAP.md`
- Backend contract: `API_SPEC.md`
- Architecture: `ARCHITECTURE.md`
