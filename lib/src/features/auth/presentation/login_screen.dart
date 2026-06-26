import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../shared/widgets/status_chip.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: colorScheme.onPrimary,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'CVMatch',
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'A modern AI career assistant for sharper CVs, better job targeting, and faster interview readiness.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.secondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const Key('login_continue_button'),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.home);
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue with mock account'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.paywall);
                    },
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text('View premium plan'),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: 'Mock data',
                        icon: Icons.dataset_outlined,
                        color: colorScheme.primary,
                      ),
                      StatusChip(
                        label: 'No Firebase',
                        icon: Icons.cloud_off_outlined,
                        color: colorScheme.tertiary,
                      ),
                      StatusChip(
                        label: 'Material 3',
                        icon: Icons.palette_outlined,
                        color: colorScheme.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
