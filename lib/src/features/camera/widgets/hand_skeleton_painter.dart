import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../domain/hand_landmarks.dart';
import '../../../widgets/confidence_meter.dart';

class HandSkeletonPainter extends CustomPainter {
  const HandSkeletonPainter({
    required this.landmarks,
    required this.confidence,
    required this.animation,
    this.hands = const <List<HandLandmark>>[],
    this.previewSize,
    this.lensDirection = CameraLensDirection.back,
    this.sensorOrientation = 0,
    this.showDetectionBox = true,
  });

  final List<HandLandmark> landmarks;
  final List<List<HandLandmark>> hands;
  final double confidence;
  final double animation;
  final Size? previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;
  final bool showDetectionBox;

  @override
  void paint(Canvas canvas, Size size) {
    final confidencePaintColor = confidenceColor(confidence);
    final boxRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.46),
      width: size.width * 0.7,
      height: size.height * 0.54,
    );

    if (showDetectionBox) {
      _drawDetectionBox(canvas, boxRect, confidencePaintColor);
    }

    final handSets = _visibleHands;
    if (handSets.isEmpty) {
      return;
    }

    for (final hand in handSets) {
      final points = hand.map((landmark) {
        return _projectLandmark(landmark, size);
      }).toList(growable: false);

      _drawConnections(canvas, points, confidencePaintColor);
      _drawDots(canvas, points, hand, confidencePaintColor);
    }
  }

  List<List<HandLandmark>> get _visibleHands {
    if (hands.isNotEmpty) {
      return hands.where((hand) => hand.length == 21).toList(growable: false);
    }
    return landmarks.length == 21
        ? <List<HandLandmark>>[landmarks]
        : const <List<HandLandmark>>[];
  }

  Rect _previewTransform(Size canvasSize) {
    final sourceSize = previewSize;
    if (sourceSize == null || sourceSize.isEmpty) {
      return Offset.zero & canvasSize;
    }

    final displaySourceSize = Size(sourceSize.height, sourceSize.width);
    final scale = math.max(
      canvasSize.width / displaySourceSize.width,
      canvasSize.height / displaySourceSize.height,
    );
    final fittedWidth = displaySourceSize.width * scale;
    final fittedHeight = displaySourceSize.height * scale;
    return Rect.fromLTWH(
      (canvasSize.width - fittedWidth) / 2,
      (canvasSize.height - fittedHeight) / 2,
      fittedWidth,
      fittedHeight,
    );
  }

  Offset _projectLandmark(HandLandmark landmark, Size canvasSize) {
    return _projectNormalizedPoint(landmark.position, canvasSize);
  }

  Offset _projectNormalizedPoint(Offset point, Size canvasSize) {
    final sourceSize = previewSize;
    if (sourceSize == null || sourceSize.isEmpty) {
      return Offset(point.dx * canvasSize.width, point.dy * canvasSize.height);
    }

    final previewRect = _previewTransform(canvasSize);
    final scale = previewRect.width / sourceSize.height;
    final logicalPoint = Offset(
      (point.dx - 0.5) * sourceSize.width,
      (point.dy - 0.5) * sourceSize.height,
    );

    var transformed = logicalPoint;
    if (lensDirection == CameraLensDirection.front) {
      transformed = Offset(transformed.dx, -transformed.dy);
    }

    final radians = sensorOrientation * math.pi / 180;
    transformed = Offset(
      transformed.dx * math.cos(radians) - transformed.dy * math.sin(radians),
      transformed.dx * math.sin(radians) + transformed.dy * math.cos(radians),
    );

    return previewRect.center + transformed * scale;
  }

  void _drawDetectionBox(Canvas canvas, Rect rect, Color color) {
    final pulse = (math.sin(animation * math.pi * 2) + 1) / 2;
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 + pulse * 4
      ..color = color.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.82);
    final radius = Radius.circular(8 + pulse * 2);

    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), glowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), borderPaint);

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    const cornerLength = 34.0;
    final corners = <Offset>[
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];

    for (final corner in corners) {
      final horizontalDirection = corner.dx < rect.center.dx ? 1.0 : -1.0;
      final verticalDirection = corner.dy < rect.center.dy ? 1.0 : -1.0;
      canvas.drawLine(
        corner,
        corner + Offset(cornerLength * horizontalDirection, 0),
        cornerPaint,
      );
      canvas.drawLine(
        corner,
        corner + Offset(0, cornerLength * verticalDirection),
        cornerPaint,
      );
    }
  }

  void _drawConnections(Canvas canvas, List<Offset> points, Color color) {
    final pulse = (math.sin(animation * math.pi * 2) + 1) / 2;
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + pulse * 0.8
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: <Color>[color, const Color(0xFFFFFFFF).withValues(alpha: 0.85)],
      ).createShader(const Rect.fromLTWH(0, 0, 320, 320));

    for (final connection in handSkeletonConnections) {
      canvas.drawLine(
        points[connection.start],
        points[connection.end],
        glowPaint,
      );
      canvas.drawLine(
        points[connection.start],
        points[connection.end],
        linePaint,
      );
    }
  }

  void _drawDots(
    Canvas canvas,
    List<Offset> points,
    List<HandLandmark> hand,
    Color color,
  ) {
    final pulse = (math.sin(animation * math.pi * 2) + 1) / 2;
    for (var i = 0; i < points.length; i++) {
      final highlighted = hand[i].isHighlighted;
      final radius = highlighted ? 6.2 + pulse * 2.2 : 4.3 + pulse * 1.2;
      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: highlighted ? 0.35 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = highlighted ? const Color(0xFFFFFFFF) : color;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: 0.8);

      canvas.drawCircle(points[i], radius + 8, glowPaint);
      canvas.drawCircle(points[i], radius, dotPaint);
      canvas.drawCircle(points[i], radius + 3, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HandSkeletonPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks ||
        oldDelegate.hands != hands ||
        oldDelegate.confidence != confidence ||
        oldDelegate.animation != animation ||
        oldDelegate.previewSize != previewSize ||
        oldDelegate.lensDirection != lensDirection ||
        oldDelegate.sensorOrientation != sensorOrientation ||
        oldDelegate.showDetectionBox != showDetectionBox;
  }
}

class StaticHandPose extends StatefulWidget {
  const StaticHandPose({
    super.key,
    required this.landmarks,
    this.confidence = 0.92,
  });

  final List<HandLandmark> landmarks;
  final double confidence;

  @override
  State<StaticHandPose> createState() => _StaticHandPoseState();
}

class _StaticHandPoseState extends State<StaticHandPose>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: HandSkeletonPainter(
            landmarks: widget.landmarks,
            confidence: widget.confidence,
            animation: _controller.value,
            showDetectionBox: false,
          ),
          child: child,
        );
      },
      child: const SizedBox.expand(),
    );
  }
}
