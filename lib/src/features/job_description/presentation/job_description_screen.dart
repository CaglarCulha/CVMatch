import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../app/cvmatch_state.dart';
import '../../../core/config/app_config.dart';
import '../../../core/mock/mock_data.dart';
import '../../analysis/data/services/career_analysis_service_factory.dart';
import '../../analysis/data/services/mock_analysis_service.dart';
import '../../analysis/domain/models/cv_analysis_result.dart';
import '../../analysis/domain/services/career_analysis_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/status_chip.dart';

class JobDescriptionScreen extends StatefulWidget {
  const JobDescriptionScreen({super.key});

  @override
  State<JobDescriptionScreen> createState() => _JobDescriptionScreenState();
}

class _JobDescriptionScreenState extends State<JobDescriptionScreen> {
  late final CareerAnalysisService _analysisService =
      CareerAnalysisServiceFactory.create(AppConfig.fromEnvironment);
  final _controller = TextEditingController();
  String? _errorText;
  String? _analysisErrorText;
  bool _isInitialized = false;
  bool _isAnalyzing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _controller.text = CVMatchScope.of(context, listen: false).jobDescription;
    _isInitialized = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyzeMatch() async {
    final description = _controller.text.trim();
    final appState = CVMatchScope.of(context, listen: false);

    if (!appState.hasSelectedPdf ||
        appState.selectedCvFileName == null ||
        appState.selectedCvFilePath == null ||
        appState.cvDocument == null) {
      setState(() {
        _errorText = 'Select a PDF CV before running analysis.';
        _analysisErrorText = null;
      });
      return;
    }

    if (!appState.hasValidCv) {
      setState(() {
        _errorText =
            appState.cvValidationWarning ??
            'This file does not appear to be a CV or resume. Please upload a valid CV PDF.';
        _analysisErrorText = null;
      });
      return;
    }

    if (description.length < 100) {
      setState(() {
        _errorText =
            'Add at least 100 characters to analyze this job description.';
        _analysisErrorText = null;
      });
      return;
    }

    setState(() {
      _errorText = null;
      _analysisErrorText = null;
      _isAnalyzing = true;
    });

    try {
      final result = await _analysisService.analyze(
        cvDocument: appState.cvDocument!,
        jobDescription: description,
        locale: Localizations.localeOf(context).toLanguageTag(),
        targetRole: mockJobTitle,
      );

      if (!mounted) return;

      _completeAnalysis(appState, description, result);
    } on CareerAnalysisException catch (error) {
      if (!mounted) return;

      setState(() {
        _analysisErrorText = error.message;
        _isAnalyzing = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _analysisErrorText =
            'Something went wrong while analyzing your CV. Please try again.';
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _runDebugMockAnalysis() async {
    final description = _controller.text.trim();
    final appState = CVMatchScope.of(context, listen: false);
    final cvDocument = appState.cvDocument;

    if (cvDocument == null) {
      return;
    }

    setState(() {
      _errorText = null;
      _analysisErrorText = null;
      _isAnalyzing = true;
    });

    final result = await const MockAnalysisService().analyze(
      cvDocument: cvDocument,
      jobDescription: description,
      locale: Localizations.localeOf(context).toLanguageTag(),
      targetRole: mockJobTitle,
    );

    if (!mounted) return;

    _completeAnalysis(appState, description, result);
  }

  void _completeAnalysis(
    CVMatchState appState,
    String description,
    CvAnalysisResult result,
  ) {
    appState
      ..setJobDescription(description)
      ..setAnalysisResult(result);

    setState(() {
      _isAnalyzing = false;
    });

    Navigator.pushNamed(context, AppRoutes.analysisResult, arguments: result);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final characterCount = _controller.text.trim().length;

    return AppPage(
      title: 'Job Description',
      subtitle:
          'Paste or edit the role description. At least 100 characters are required before analysis.',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.business_center_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$mockJobTitle at $mockJobCompany',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                enabled: !_isAnalyzing,
                maxLines: 14,
                minLines: 10,
                onChanged: (_) {
                  if (_errorText != null || _analysisErrorText != null) {
                    setState(() {
                      _errorText = null;
                      _analysisErrorText = null;
                    });
                    return;
                  }
                  setState(() {});
                },
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Job description',
                ),
              ),
              if (_isAnalyzing) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Analyzing your CV...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (_analysisErrorText != null) ...[
                const SizedBox(height: 14),
                _AnalysisErrorCard(
                  message: _analysisErrorText!,
                  onRetry: _isAnalyzing ? null : _analyzeMatch,
                  onUseMock:
                      kDebugMode && AppConfig.fromEnvironment.hasAnalysisApi
                      ? (_isAnalyzing ? null : _runDebugMockAnalysis)
                      : null,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$characterCount / 100 characters minimum',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: characterCount >= 100
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_errorText != null)
                    Flexible(
                      child: Text(
                        _errorText!,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Matching focus',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(
              label: 'AI workflows',
              icon: Icons.auto_awesome_outlined,
              color: colorScheme.primary,
            ),
            StatusChip(
              label: 'Roadmap ownership',
              icon: Icons.map_outlined,
              color: colorScheme.secondary,
            ),
            StatusChip(
              label: 'Model quality',
              icon: Icons.fact_check_outlined,
              color: colorScheme.tertiary,
            ),
            StatusChip(
              label: 'Launch storytelling',
              icon: Icons.campaign_outlined,
              color: const Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('analyze_match_button'),
          onPressed: _isAnalyzing ? null : _analyzeMatch,
          icon: _isAnalyzing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.analytics_outlined),
          label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze match'),
        ),
      ],
    );
  }
}

class _AnalysisErrorCard extends StatelessWidget {
  const _AnalysisErrorCard({
    required this.message,
    required this.onRetry,
    required this.onUseMock,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onUseMock;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_off_outlined, color: colorScheme.error),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Try again'),
              ),
              if (onUseMock != null)
                OutlinedButton.icon(
                  onPressed: onUseMock,
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Use mock analysis'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
