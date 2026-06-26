# Design System

## Design Direction

CVMatch should feel like a polished modern SaaS/mobile app: trustworthy, calm, structured, and action-oriented. The current visual system uses Material 3 with a professional blue/indigo palette and full dark-mode support.

## Theme Source

The canonical theme lives in:

```text
lib/src/core/theme/app_theme.dart
```

Do not hardcode new global colors or typography in screens when the theme can express the same intent.

## Color Palette

### Light Theme

| Token | Value | Usage |
| --- | --- | --- |
| Primary | `#2563EB` | Main actions, score accents, primary chips. |
| Secondary | `#4F46E5` | Secondary accents, ATS indicators. |
| Tertiary | `#0EA5E9` | Supporting highlights and informational chips. |
| Scaffold | `#F6F8FC` | App background. |
| Surface | `#FFFFFF` | Cards and form fields. |
| Surface Container | `#EFF4FF` | Soft panels and elevated sections. |
| Outline | `#D7DEEA` | Borders in light mode. |
| Outline Variant | `#E4EAF4` | Subtle borders and field outlines. |

### Dark Theme

| Token | Value | Usage |
| --- | --- | --- |
| Primary | `#93C5FD` | Main actions and highlights. |
| Secondary | `#A5B4FC` | Secondary accents. |
| Tertiary | `#67E8F9` | Informational highlights. |
| Scaffold | `#080C17` | App background. |
| Surface | `#111827` | Cards and input fields. |
| Surface Container | `#172033` | Soft panels. |
| Outline | `#334155` | Borders in dark mode. |
| Outline Variant | `#1F2937` | Subtle borders and field outlines. |

## Typography

Use the Material text theme through `Theme.of(context).textTheme`.

Current emphasis rules:

- `displaySmall`: weight 800.
- `headlineMedium`: weight 800.
- `headlineSmall`: weight 800.
- `titleLarge`: weight 800.
- `titleMedium`: weight 700.
- Body text uses theme default weight and color unless emphasis is required.

Avoid custom fonts until the performance and licensing implications are reviewed.

## Spacing

Preferred spacing scale:

- `4`: compact inline separation.
- `8`: chip and small component gaps.
- `10`/`12`: icon-label gaps and card internals.
- `16`: default content padding.
- `20`: section separation.
- `24`: large card padding and major vertical separation.
- `32`: hero and page-level spacing.

Keep screens visually breathable. Prefer fewer dense clusters over many cramped controls.

## Shape

The theme currently uses 8 px radius for many Material components. Some custom containers use larger radii for premium/error panels. Keep shape usage intentional:

- Inputs, buttons, chips, snack bars: 8 px.
- Soft custom panels: 16-24 px when a more premium surface is needed.
- Avoid mixing many radius sizes in one screen.

## Core Components

### `AppPage`

Use for page scaffolding, width constraints, title, subtitle, and optional actions.

### `AppCard`

Use for content groups, dashboard modules, result cards, and form panels.

### `StatusChip`

Use for compact metadata, analysis mode labels, focus areas, and status indicators.

### `ScoreBadge`

Use for circular match-score visuals. Scores should be paired with explanatory text and not used as the only result signal.

## Screen Guidelines

### Login

- Communicate the product promise quickly.
- Keep the primary action obvious.
- Do not imply real authentication until auth exists.

### Home Dashboard

- Treat dashboard cards as task shortcuts.
- Keep Upload CV and Analyze Job visually primary.
- Previous Analyses should be honest about current persistence limitations.
- Premium should feel aspirational but not misleading.

### Upload CV

- Show file name and file size only.
- Show “PDF selected successfully” when extraction succeeds.
- Show friendly extraction errors.
- Keep raw extracted text debug-only.

### Job Description

- Use a large multiline text field.
- Show character minimum feedback.
- Show “Analyzing your CV...” during requests.
- Show retry actions in the same context as the error.

### Analysis Result

- Lead with a circular match score and plain-language summary.
- Include ATS score, missing keyword chips, strengths, weaknesses, improvements, cover letter, and interview questions.
- Clearly label mock versus backend analysis.

### Paywall

- Use premium visual hierarchy without dark patterns.
- Communicate future premium value honestly.
- Do not represent billing as active until subscription infrastructure exists.

## Accessibility

- Maintain contrast in light and dark mode.
- Do not encode status by color alone; pair icons and labels.
- Keep tappable controls at least 48 px high.
- Use descriptive button labels.
- Keep long result text selectable or easily readable where practical.
- Avoid animations that block task completion.

## Content Voice

CVMatch copy should be:

- Professional.
- Encouraging.
- Specific.
- Honest about mock/backend mode.
- Free of exaggerated guarantees.

Avoid promising that CVMatch can guarantee interviews, ATS acceptance, or hiring outcomes.

## Related Documents

- Product behavior: `PRODUCT.md`
- Architecture and component locations: `ARCHITECTURE.md`
- Security-sensitive display rules: `SECURITY.md`
