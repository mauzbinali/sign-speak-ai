import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedAiBackground extends StatefulWidget {
  const AnimatedAiBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedAiBackground> createState() => _AnimatedAiBackgroundState();
}

class _AnimatedAiBackgroundState extends State<AnimatedAiBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _AiBackgroundPainter(
            progress: _controller.value,
            isDark: isDark,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _AiBackgroundPainter extends CustomPainter {
  const _AiBackgroundPainter({required this.progress, required this.isDark});

  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final baseGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const <Color>[
              Color(0xFF0B1016),
              Color(0xFF10211F),
              Color(0xFF261724),
              Color(0xFF0B1016),
            ]
          : const <Color>[
              Color(0xFFEAF9F5),
              Color(0xFFF8F1DD),
              Color(0xFFFFEEF0),
              Color(0xFFEAF3FA),
            ],
    );

    canvas.drawRect(rect, Paint()..shader = baseGradient.createShader(rect));

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF28E0B5).withValues(alpha: isDark ? 0.45 : 0.28);

    final particles = _particles(size);
    for (var i = 0; i < particles.length; i++) {
      final start = particles[i];
      final end = particles[(i + 5) % particles.length];
      if ((start - end).distance < size.shortestSide * 0.34) {
        canvas.drawLine(start, end, linePaint);
      }
      canvas.drawCircle(
        start,
        2.2 + math.sin(progress * math.pi * 2 + i) * 0.9,
        dotPaint,
      );
    }
  }

  List<Offset> _particles(Size size) {
    return List<Offset>.generate(30, (index) {
      final seed = index * 1.618;
      final x =
          (math.sin(seed + progress * math.pi * 2) * 0.5 + 0.5) * size.width;
      final y = ((index * 53) % 100) / 100 * size.height +
          math.cos(seed * 0.7 + progress * math.pi * 2) * 18;
      return Offset(x, y % size.height);
    });
  }

  @override
  bool shouldRepaint(covariant _AiBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
