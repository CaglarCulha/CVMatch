import 'package:flutter/material.dart';

class ScoreBadge extends StatelessWidget {
  const ScoreBadge({
    required this.score,
    this.label = 'Match',
    this.size = 118,
    this.strokeWidth = 9,
    this.color,
    super.key,
  });

  final int score;
  final String label;
  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final scoreColor = color ?? colorScheme.primary;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: size - 14,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: scoreColor.withValues(alpha: 0.14),
              color: scoreColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: colorScheme.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
