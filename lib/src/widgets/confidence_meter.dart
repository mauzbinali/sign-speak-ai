import 'package:flutter/material.dart';

import '../domain/sign_models.dart';

class ConfidenceMeter extends StatelessWidget {
  const ConfidenceMeter({
    super.key,
    required this.confidence,
    this.height = 10,
  });

  final double confidence;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = confidenceColor(confidence);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 0,
          end: confidence.clamp(0.0, 1.0).toDouble(),
        ),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return LinearProgressIndicator(
            value: value,
            minHeight: height,
            color: color,
            backgroundColor: color.withValues(alpha: 0.18),
          );
        },
      ),
    );
  }
}

Color confidenceColor(double confidence) {
  if (confidence >= 0.78) {
    return const Color(0xFF28E0B5);
  }
  if (confidence >= 0.52) {
    return const Color(0xFFFFC857);
  }
  return const Color(0xFFFF5A66);
}

Color confidenceLevelColor(ConfidenceLevel level) {
  switch (level) {
    case ConfidenceLevel.high:
      return const Color(0xFF28E0B5);
    case ConfidenceLevel.medium:
      return const Color(0xFFFFC857);
    case ConfidenceLevel.low:
      return const Color(0xFFFF5A66);
  }
}
