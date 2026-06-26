# CVMatch

A modern AI career assistant MVP built with Flutter and Material 3.

## AI Analysis Backend

CVMatch is prepared to call a career analysis backend, but it does not call
OpenAI directly from Flutter and does not store API keys in the app.

- If `CVMATCH_ANALYSIS_API_URL` is empty, the app uses `MockAnalysisService`.
- If `CVMATCH_ANALYSIS_API_URL` is set, the app uses `ApiCareerAnalysisService`.
- Configure the backend URL at runtime:

```sh
flutter run --dart-define=CVMATCH_ANALYSIS_API_URL=https://api.example.com/v1/career-analysis
```

For local backend development:

```sh
cd backend
npm install
cp .env.example .env
npm run dev
```

Then connect Flutter to the local backend:

```sh
flutter run -d chrome --dart-define=CVMATCH_ANALYSIS_API_URL=http://localhost:3001/analyze
```

See `backend/README.md` for backend setup, validation, and API examples.

The backend should accept a `POST` JSON body with:

- `cvText`
- `cvFileName`
- `jobDescription`
- `locale`
- `targetRole` when available

The backend response should match `CvAnalysisResult`:

- `matchScore`
- `atsScore`
- `missingKeywords`
- `strongPoints`
- `weakPoints`
- `suggestedImprovements`
- `coverLetter`
- `interviewQuestions`

Keep OpenAI keys and provider logic on the backend only. Flutter should call
your backend API, and the backend should handle authentication, rate limiting,
AI provider calls, and response validation.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
