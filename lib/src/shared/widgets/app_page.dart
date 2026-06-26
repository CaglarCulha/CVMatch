import 'package:flutter/material.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    required this.title,
    required this.children,
    this.subtitle,
    this.actions,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 28),
    this.maxWidth = 880,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: padding,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
