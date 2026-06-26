import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/status_chip.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _billingPeriod = 'yearly';

  @override
  Widget build(BuildContext context) {
    final price = _billingPeriod == 'yearly' ? r'$79' : r'$9';
    final cadence = _billingPeriod == 'yearly' ? 'per year' : 'per month';

    return AppPage(
      title: 'CVMatch Pro',
      maxWidth: 960,
      children: [
        const _PremiumHero(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'yearly',
                label: Text('Yearly'),
                icon: Icon(Icons.savings_outlined),
              ),
              ButtonSegment(
                value: 'monthly',
                label: Text('Monthly'),
                icon: Icon(Icons.calendar_month_outlined),
              ),
            ],
            selected: {_billingPeriod},
            onSelectionChanged: (selection) {
              setState(() {
                _billingPeriod = selection.first;
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final planWidth = compact
                ? constraints.maxWidth
                : constraints.maxWidth * 0.58 - 6;
            final detailWidth = compact
                ? constraints.maxWidth
                : constraints.maxWidth * 0.42 - 6;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: planWidth,
                  child: _PlanCard(price: price, cadence: cadence),
                ),
                SizedBox(width: detailWidth, child: const _PremiumStack()),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
            colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Premium career intelligence',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Turn every application into a sharper pitch',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Unlock deeper CV rewrites, role-specific interview prep, and priority insights for active job searches.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.price, required this.cadence});

  final String price;
  final String cadence;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      borderColor: colorScheme.primary.withValues(alpha: 0.28),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pro plan',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Built for candidates applying weekly.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: 'Mock',
                icon: Icons.science_outlined,
                color: colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  cadence,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _FeatureRow(text: 'Unlimited CV and job analyses'),
          const _FeatureRow(text: 'Keyword and ATS optimization insights'),
          const _FeatureRow(text: 'Tailored CV bullet rewrites'),
          const _FeatureRow(text: 'Cover letter and interview prep drafts'),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Mock checkout only. Payments are not connected.',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Start mock trial'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            },
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to dashboard'),
          ),
        ],
      ),
    );
  }
}

class _PremiumStack extends StatelessWidget {
  const _PremiumStack();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _ValueCard(
          icon: Icons.speed_outlined,
          title: 'Faster tailoring',
          text: 'Move from generic CV to role-specific pitch in minutes.',
          color: colorScheme.primary,
        ),
        const SizedBox(height: 12),
        _ValueCard(
          icon: Icons.psychology_alt_outlined,
          title: 'Deeper insights',
          text: 'See what recruiters and ATS filters are likely to miss.',
          color: colorScheme.secondary,
        ),
        const SizedBox(height: 12),
        _ValueCard(
          icon: Icons.shield_outlined,
          title: 'Ready for real services',
          text:
              'No Firebase, OpenAI, or RevenueCat integrations are active yet.',
          color: colorScheme.tertiary,
        ),
      ],
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
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
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
