# Architecture Handbook

## Overview

CVMatch is a Flutter application organized by feature with clear presentation, domain, and data boundaries. The client currently stores state in memory, extracts PDF text locally, and sends analysis requests to either a mock implementation or a configurable backend API.

## Runtime Stack

- Flutter with Material 3.
- Dart SDK constraint: `^3.11.5`.
- `file_picker` for PDF selection.
- `cross_file` for platform-neutral file access.
- `syncfusion_flutter_pdf` for PDF text extraction.
- `http` for backend analysis requests.
- `flutter_lints` for static linting.
- `flutter_test` for unit and widget tests.

## Application Entry

- `lib/main.dart` runs `CVMatchApp`.
- `lib/src/app/cvmatch_app.dart` configures:
  - `MaterialApp`
  - Light and dark themes
  - System theme mode
  - Initial route
  - `CVMatchScope`

## Routing

Routes are centralized in `lib/src/app/app_routes.dart`:

- `/` -> `LoginScreen`
- `/home` -> `HomeScreen`
- `/upload-cv` -> `UploadCVScreen`
- `/job-description` -> `JobDescriptionScreen`
- `/analysis-result` -> `AnalysisResultScreen`
- `/paywall` -> `PaywallScreen`

Unknown routes fall back to `LoginScreen`.

## Folder Structure

```text
lib/
  main.dart
  src/
    app/
      app_routes.dart
      cvmatch_app.dart
      cvmatch_state.dart
    core/
      config/
        app_config.dart
      mock/
        mock_data.dart
      theme/
        app_theme.dart
    features/
      analysis/
        data/services/
        domain/models/
        domain/services/
        presentation/
      auth/
        presentation/
      cv_upload/
        domain/models/
        domain/services/
        presentation/
      home/
        presentation/
      job_description/
        presentation/
      paywall/
        presentation/
    shared/
      widgets/
```

## State Management

`CVMatchState` is a `ChangeNotifier` exposed through `CVMatchScope`.

Current state includes:

- Selected CV file name.
- Internal selected CV file path.
- Selected CV size.
- CV validation warning.
- `CvDocument` with extracted text and page count.
- Current job description.
- Latest `CvAnalysisResult`.

The app intentionally keeps this data in memory only. Closing or refreshing the app clears the state.

## CV Upload And Extraction Flow

1. User selects a PDF in `UploadCVScreen`.
2. File picker returns file metadata and bytes.
3. `PdfExtractionService` reads PDF bytes.
4. The service normalizes extracted text and returns `CvDocument`.
5. `CVMatchState.setSelectedCv` stores the document and internal file path.
6. The UI displays only safe metadata:
   - File name
   - File size
   - Success or friendly error status
7. Debug builds may show extraction count, page count, and the first 300 extracted characters for developer verification.

Normal UI must never show full file paths, data URIs, base64 content, raw PDF bytes, or full extracted CV text.

## Analysis Flow

1. `JobDescriptionScreen` validates:
   - A PDF CV is selected.
   - CV validation passed.
   - Extracted text exists.
   - Job description has at least 100 characters.
2. The screen creates an analysis request through `CareerAnalysisService`.
3. `CareerAnalysisServiceFactory` selects implementation:
   - Empty `CVMATCH_ANALYSIS_API_URL`: `MockAnalysisService`
   - Non-empty `CVMATCH_ANALYSIS_API_URL`: `ApiCareerAnalysisService`
4. The screen shows “Analyzing your CV...” during the request.
5. Success stores `CvAnalysisResult` in state and navigates to `AnalysisResultScreen`.
6. Failure displays a friendly error and “Try again”.
7. Debug builds can use mock fallback when backend analysis fails.

## Service Contracts

### `CareerAnalysisService`

The main analysis contract:

```dart
Future<CvAnalysisResult> analyze({
  required CvDocument cvDocument,
  required String jobDescription,
  String locale = 'en',
  String? targetRole,
});
```

All future AI, backend, or hybrid analysis services should implement this interface.

### `MockAnalysisService`

Provides deterministic local analysis based on keyword overlap. It is used for MVP demos, local development, and fallback when no backend URL exists.

### `ApiCareerAnalysisService`

Sends extracted CV text and job description to the configured backend API. It handles:

- JSON request creation.
- 45-second timeout.
- Non-2xx API responses.
- Network errors.
- Invalid JSON.
- Missing response fields.
- API error payloads.

See `API_SPEC.md` for the backend contract.

## Configuration

Configuration is centralized in `lib/src/core/config/app_config.dart`.

Current runtime key:

```sh
CVMATCH_ANALYSIS_API_URL
```

Example:

```sh
flutter run --dart-define=CVMATCH_ANALYSIS_API_URL=https://api.example.com/v1/career-analysis
```

No API keys or provider secrets may be configured in the Flutter client.

## Dependency Direction

Preferred dependency direction:

```text
presentation -> domain -> data implementations
core/shared -> used by features
features -> may reference sibling feature domain models only when part of an explicit flow
```

Avoid importing presentation code into domain or data layers.

## Error Handling

- PDF extraction errors are represented as `PdfExtractionException`.
- Analysis errors are represented as `CareerAnalysisException`.
- UI should display short, friendly, actionable messages.
- Raw exception strings should not be shown when they may contain internal implementation details.

## Platform Notes

- PDF extraction is implemented with platform-neutral bytes through `cross_file` and Syncfusion PDF APIs.
- Web builds require backend CORS configuration for API calls.
- Mobile builds require HTTPS endpoints for production.
- Local development can run with mock analysis and no backend URL.

## Known Architecture Constraints

- `CVMatchState` is intentionally simple; it is acceptable for the MVP but should be revisited before adding authentication, persistence, or multi-session history.
- The legacy `AnalysisService` contract remains in the tree. New work should use `CareerAnalysisService`.
- Result confidence is limited in mock mode; production analysis should be performed by a backend.

## Related Documents

- Product scope: `PRODUCT.md`
- Backend contract: `API_SPEC.md`
- Security posture: `SECURITY.md`
- Database posture: `DATABASE.md`
- Testing strategy: `TESTING.md`
