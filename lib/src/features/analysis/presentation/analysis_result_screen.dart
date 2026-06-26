import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../app/cvmatch_state.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/score_badge.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/services/mock_analysis_service.dart';
import '../domain/models/cv_analysis_request.dart';
import '../domain/models/cv_analysis_result.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = CVMatchScope.of(context);
    final result = _resolveResult(context, appState);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedCvName =
        appState.selectedCvFileName ?? mockCandidate.resumeFileName;
    final jobPreview = _shortPreview(appState.jobDescription);
    final hasBackendAnalysis = AppConfig.fromEnvironment.hasAnalysisApi;

    return AppPage(
      title: 'Analysis Result',
      maxWidth: 1040,
      actions: [
        IconButton(
          tooltip: 'Premium insights',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.paywall),
          icon: const Icon(Icons.lock_open_outlined),
        ),
      ],
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = constraints.maxWidth;
            final compact = fullWidth < 760;
            final scoreWidth = compact ? fullWidth : fullWidth * 0.58 - 6;
            final atsWidth = compact ? fullWidth : fullWidth * 0.42 - 6;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: scoreWidth,
                  child: AppCard(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderColor: colorScheme.primary.withValues(alpha: 0.16),
                    padding: const EdgeInsets.all(24),
                    child: _MatchSummary(
                      result: result,
                      compact: compact,
                      hasBackendAnalysis: hasBackendAnalysis,
                    ),
                  ),
                ),
                SizedBox(
                  width: atsWidth,
                  child: _AtsScoreCard(result: result),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _AnalysisInputsCard(
          selectedCvName: selectedCvName,
          jobPreview: jobPreview,
        ),
        const SizedBox(height: 12),
        StatusChip(
          label: hasBackendAnalysis
              ? 'Backend analysis - OpenAI keys stay on the server.'
              : 'Mock analysis - configure a backend API for real AI scoring.',
          icon: Icons.science_outlined,
          color: colorScheme.tertiary,
        ),
        const SizedBox(height: 24),
        Text('Score breakdown', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth < 760
                ? constraints.maxWidth
                : (constraints.maxWidth - 24) / 3;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _ScoreCard(
                    title: 'Match score',
                    score: result.matchScore,
                    detail: 'Overall fit between your CV and this job.',
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _ScoreCard(
                    title: 'ATS score',
                    score: result.atsScore,
                    detail: 'Estimated parsing and keyword compatibility.',
                    color: colorScheme.secondary,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _ScoreCard(
                    title: 'Keyword coverage',
                    score: (100 - result.missingKeywords.length * 9).clamp(
                      42,
                      92,
                    ),
                    detail:
                        '${result.missingKeywords.length} priority gaps found.',
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _MissingKeywordsCard(keywords: result.missingKeywords),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final listWidth = constraints.maxWidth < 760
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: listWidth,
                  child: _InsightListCard(
                    title: 'Strong points',
                    icon: Icons.verified_outlined,
                    color: colorScheme.primary,
                    items: result.strongPoints,
                  ),
                ),
                SizedBox(
                  width: listWidth,
                  child: _InsightListCard(
                    title: 'Weak points',
                    icon: Icons.report_problem_outlined,
                    color: colorScheme.tertiary,
                    items: result.weakPoints,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _SuggestedImprovementsCard(items: result.suggestedImprovements),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final sectionWidth = constraints.maxWidth < 760
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: sectionWidth,
                  child: _CoverLetterCard(coverLetter: result.coverLetter),
                ),
                SizedBox(
                  width: sectionWidth,
                  child: _InterviewQuestionsCard(
                    questions: result.interviewQuestions,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.paywall),
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('Unlock full rewrite'),
        ),
      ],
    );
  }

  CvAnalysisResult _resolveResult(BuildContext context, CVMatchState appState) {
    final argument = ModalRoute.of(context)?.settings.arguments;
    if (argument is CvAnalysisResult) {
      return argument;
    }
    if (appState.latestAnalysisResult != null) {
      return appState.latestAnalysisResult!;
    }

    return const MockAnalysisService().buildMockResult(
      CvAnalysisRequest(
        cvFileName: appState.selectedCvFileName ?? mockCandidate.resumeFileName,
        cvFilePath: appState.selectedCvFilePath ?? mockCandidate.resumeFileName,
        jobDescription: appState.jobDescription,
        cvText: appState.cvText,
        isCvValid: appState.hasValidCv,
      ),
    );
  }

  String _shortPreview(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 180) {
      return normalized;
    }
    return '${normalized.substring(0, 180)}...';
  }
}

class _AnalysisInputsCard extends StatelessWidget {
  const _AnalysisInputsCard({
    required this.selectedCvName,
    required this.jobPreview,
  });

  final String selectedCvName;
  final String jobPreview;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.input_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'Analysis inputs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InputSummaryRow(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Selected CV',
            value: selectedCvName,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 14),
          _InputSummaryRow(
            icon: Icons.description_outlined,
            label: 'Job description preview',
            value: jobPreview,
            color: colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}

class _InputSummaryRow extends StatelessWidget {
  const _InputSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchSummary extends StatelessWidget {
  const _MatchSummary({
    required this.result,
    required this.compact,
    required this.hasBackendAnalysis,
  });

  final CvAnalysisResult result;
  final bool compact;
  final bool hasBackendAnalysis;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusChip(
          label: hasBackendAnalysis
              ? 'Backend analysis result'
              : 'Mock analysis result',
          icon: Icons.trending_up_outlined,
          color: colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Text(
          '$mockJobTitle at $mockJobCompany',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          'CVMatch found a ${result.matchScore}% fit with ${result.missingKeywords.length} keyword gaps and ${result.suggestedImprovements.length} practical improvements.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(
              label: 'ATS ${result.atsScore}%',
              icon: Icons.fact_check_outlined,
              color: colorScheme.secondary,
            ),
            StatusChip(
              label: 'Ready for tailoring',
              icon: Icons.edit_note_outlined,
              color: colorScheme.tertiary,
            ),
          ],
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ScoreBadge(
              score: result.matchScore,
              size: 156,
              strokeWidth: 11,
              label: 'Match',
            ),
          ),
          const SizedBox(height: 24),
          summary,
        ],
      );
    }

    return Row(
      children: [
        ScoreBadge(
          score: result.matchScore,
          size: 164,
          strokeWidth: 12,
          label: 'Match',
        ),
        const SizedBox(width: 28),
        Expanded(child: summary),
      ],
    );
  }
}

class _AtsScoreCard extends StatelessWidget {
  const _AtsScoreCard({required this.result});

  final CvAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  color: colorScheme.secondary,
                ),
              ),
              const Spacer(),
              Text(
                '${result.atsScore}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('ATS score card', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Estimated parser readability and keyword alignment for this job description.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: result.atsScore / 100,
              color: colorScheme.secondary,
              backgroundColor: colorScheme.secondary.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.title,
    required this.score,
    required this.detail,
    required this.color,
  });

  final String title;
  final int score;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '$score%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: score / 100,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            detail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingKeywordsCard extends StatelessWidget {
  const _MissingKeywordsCard({required this.keywords});

  final List<String> keywords;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sell_outlined, color: colorScheme.secondary),
              const SizedBox(width: 10),
              Text(
                'Missing keywords',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add these naturally where they match real experience.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final keyword in keywords)
                StatusChip(
                  label: keyword,
                  icon: Icons.add,
                  color: colorScheme.secondary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightListCard extends StatelessWidget {
  const _InsightListCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _SuggestedImprovementsCard extends StatelessWidget {
  const _SuggestedImprovementsCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      color: colorScheme.secondary.withValues(alpha: 0.08),
      borderColor: colorScheme.secondary.withValues(alpha: 0.18),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: 'Suggested improvements',
            icon: Icons.auto_fix_high_outlined,
            color: colorScheme.secondary,
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < items.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items[index],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (index != items.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _CoverLetterCard extends StatelessWidget {
  const _CoverLetterCard({required this.coverLetter});

  final String coverLetter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cover letter draft',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            coverLetter,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.42,
            ),
          ),
        ],
      ),
    );
  }
}

class _InterviewQuestionsCard extends StatelessWidget {
  const _InterviewQuestionsCard({required this.questions});

  final List<String> questions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.record_voice_over_outlined,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Interview questions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < questions.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}.',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    questions[index],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            if (index != questions.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
