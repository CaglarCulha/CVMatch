import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/mock/mock_data.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/score_badge.dart';
import '../../../shared/widgets/status_chip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppPage(
      title: 'Dashboard',
      maxWidth: 1040,
      actions: [
        IconButton(
          tooltip: 'Premium',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.paywall),
          icon: const Icon(Icons.workspace_premium_outlined),
        ),
      ],
      children: [
        AppCard(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderColor: colorScheme.primary.withValues(alpha: 0.16),
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 660;
              final summary = _DashboardHeroSummary(compact: compact);

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    summary,
                    const SizedBox(height: 24),
                    Center(
                      child: ScoreBadge(
                        score: mockCandidate.matchScore,
                        size: 140,
                        label: 'Job fit',
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: summary),
                  const SizedBox(width: 28),
                  ScoreBadge(
                    score: mockCandidate.matchScore,
                    size: 148,
                    strokeWidth: 10,
                    label: 'Job fit',
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth < 720
                ? constraints.maxWidth
                : (constraints.maxWidth - 24) / 3;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                  width: itemWidth,
                  label: 'ATS score',
                  value: '$mockAtsScore%',
                  icon: Icons.fact_check_outlined,
                  color: colorScheme.primary,
                ),
                _StatCard(
                  width: itemWidth,
                  label: 'Missing keywords',
                  value: '${mockMissingKeywords.length}',
                  icon: Icons.sell_outlined,
                  color: colorScheme.secondary,
                ),
                _StatCard(
                  width: itemWidth,
                  label: 'Analyses saved',
                  value: '${mockPreviousAnalyses.length}',
                  icon: Icons.history_outlined,
                  color: colorScheme.tertiary,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Career readiness dashboard',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth < 720
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DashboardCard(
                  width: cardWidth,
                  title: 'Upload CV',
                  subtitle:
                      'Refresh your candidate profile with the latest CV.',
                  metric: mockCandidate.resumeFileName,
                  icon: Icons.upload_file_outlined,
                  color: colorScheme.primary,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.uploadCV),
                ),
                _DashboardCard(
                  width: cardWidth,
                  title: 'Analyze Job',
                  subtitle: 'Compare your CV to a target role description.',
                  metric: '$mockJobCompany - $mockJobTitle',
                  icon: Icons.manage_search_outlined,
                  color: colorScheme.secondary,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.jobDescription),
                ),
                _PreviousAnalysesCard(width: cardWidth),
                _DashboardCard(
                  width: cardWidth,
                  title: 'Premium',
                  subtitle: 'Unlock deeper rewrites and interview prep.',
                  metric: 'Mock Pro plan',
                  icon: Icons.workspace_premium_outlined,
                  color: const Color(0xFF6366F1),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.paywall),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DashboardHeroSummary extends StatelessWidget {
  const _DashboardHeroSummary({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(
              label: mockCandidate.targetRole,
              icon: Icons.track_changes_outlined,
              color: colorScheme.primary,
            ),
            StatusChip(
              label: mockCandidate.location,
              icon: Icons.location_on_outlined,
              color: colorScheme.secondary,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Welcome back, ${mockCandidate.name.split(' ').first}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your career cockpit is ready',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          mockCandidate.summary,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: compact ? double.infinity : 168,
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.uploadCV),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload CV'),
              ),
            ),
            SizedBox(
              width: compact ? double.infinity : 174,
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.analysisResult),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('View results'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final double width;
  final String title;
  final String subtitle;
  final String metric;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, color: colorScheme.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 22),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              metric,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviousAnalysesCard extends StatelessWidget {
  const _PreviousAnalysesCard({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: AppCard(
        onTap: () => Navigator.pushNamed(context, AppRoutes.analysisResult),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history_outlined,
                    color: colorScheme.tertiary,
                  ),
                ),
                const Spacer(),
                StatusChip(
                  label: '${mockPreviousAnalyses.length} saved',
                  color: colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Previous Analyses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final analysis in mockPreviousAnalyses.take(2)) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      analysis,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 2),
            Text(
              'Open latest analysis',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.tertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
