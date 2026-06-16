import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'hand_landmarks.dart';

class SignPoseLibrary {
  const SignPoseLibrary._();

  static List<double> modelFeaturesFor(
    List<HandLandmark> landmarks, {
    bool mirrorX = false,
  }) {
    if (landmarks.length != 21) {
      return const [];
    }

    final wrist = landmarks[0].position;
    final palmScale = _palmScale(landmarks);
    final scale = math.max(palmScale, 0.001);

    return landmarks.expand((landmark) {
      final dx = (landmark.position.dx - wrist.dx) / scale;
      return <double>[
        mirrorX ? -dx : dx,
        (landmark.position.dy - wrist.dy) / scale,
        landmark.z / scale,
      ];
    }).toList(growable: false);
  }

  static double featureDistance(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) {
      return double.infinity;
    }
    var total = 0.0;
    for (var index = 0; index < a.length; index++) {
      final delta = a[index] - b[index];
      total += delta * delta;
    }
    return math.sqrt(total / a.length);
  }

  static List<HandLandmark> poseForSign(String rawSign, double phase) {
    final sign = rawSign.toUpperCase();
    final loop = phase - phase.floorToDouble();
    final wave = math.sin(loop * math.pi * 2);
    final spec = _PoseSpec.forSign(sign, loop);
    final center = Offset(
      0.5 + spec.shift.dx + wave * 0.006,
      0.68 + spec.shift.dy + math.cos(loop * math.pi * 2) * 0.004,
    );

    final points = <Offset>[
      center,
      ..._thumb(
        base: center + const Offset(-0.082, -0.072),
        openness: spec.thumb,
        rotation: spec.thumbRotation,
      ),
      ..._finger(
        base: center + const Offset(-0.074, -0.162),
        angle: -1.88 - spec.spread * 0.36,
        segment: 0.068,
        openness: spec.index,
        hook: spec.indexHook,
      ),
      ..._finger(
        base: center + const Offset(-0.018, -0.19),
        angle: -1.58,
        segment: 0.075,
        openness: spec.middle,
      ),
      ..._finger(
        base: center + const Offset(0.04, -0.173),
        angle: -1.31 + spec.spread * 0.24,
        segment: 0.069,
        openness: spec.ring,
      ),
      ..._finger(
        base: center + const Offset(0.088, -0.132),
        angle: -1.08 + spec.spread * 0.32,
        segment: 0.06,
        openness: spec.pinky,
      ),
    ];

    final highlights = spec.highlightedIndexes;
    return List<HandLandmark>.generate(points.length, (index) {
      return HandLandmark(
        index: index,
        name: handLandmarkNames[index],
        position: points[index],
        isHighlighted: highlights.contains(index),
      );
    }, growable: false);
  }

  static List<List<HandLandmark>> handsForSign(String rawSign, double phase) {
    final sign = rawSign.toUpperCase();
    final loop = phase - phase.floorToDouble();
    final pulse = (math.sin(loop * math.pi * 2) + 1) / 2;
    final eased = Curves.easeInOut.transform(pulse);

    List<HandLandmark> hand(
      String sign, {
      double dx = 0,
      double dy = 0,
      bool mirrorX = false,
    }) {
      return _transformHand(
        poseForSign(sign, phase),
        dx: dx,
        dy: dy,
        mirrorX: mirrorX,
      );
    }

    switch (sign) {
      case 'HELP':
        return <List<HandLandmark>>[
          hand('B', dx: -0.11, dy: 0.06, mirrorX: true),
          hand('GOOD JOB', dx: 0.1, dy: -0.02 - eased * 0.04),
        ];
      case 'MORE':
        return <List<HandLandmark>>[
          hand('MORE', dx: -0.1 + eased * 0.035, mirrorX: true),
          hand('MORE', dx: 0.1 - eased * 0.035),
        ];
      case 'NAME':
        return <List<HandLandmark>>[
          hand('H', dx: -0.08, dy: 0.02, mirrorX: true),
          hand('H', dx: 0.08, dy: -0.02 + eased * 0.025),
        ];
      case 'FAMILY':
        return <List<HandLandmark>>[
          hand('OKAY', dx: -0.14 - eased * 0.035, mirrorX: true),
          hand('OKAY', dx: 0.14 + eased * 0.035),
        ];
      case 'WORK':
        return <List<HandLandmark>>[
          hand('A', dx: -0.09, dy: 0.02, mirrorX: true),
          hand('A', dx: 0.09, dy: -0.02 + eased * 0.035),
        ];
      case 'SCHOOL':
        return <List<HandLandmark>>[
          hand('B', dx: -0.1, dy: 0.03, mirrorX: true),
          hand('B', dx: 0.1, dy: -0.02 + eased * 0.035),
        ];
      case 'MONEY':
      case 'MEDICINE':
      case 'DOCTOR':
        return <List<HandLandmark>>[
          hand('B', dx: -0.11, dy: 0.04, mirrorX: true),
          hand(
            sign == 'MONEY' ? 'MORE' : 'FUCK YOU',
            dx: 0.1,
            dy: -0.03 + eased * 0.04,
          ),
        ];
      case 'HURT':
      case 'PAIN':
        return <List<HandLandmark>>[
          hand('POINT', dx: -0.11 + eased * 0.025, mirrorX: true),
          hand('POINT', dx: 0.11 - eased * 0.025),
        ];
      case 'SICK':
        return <List<HandLandmark>>[
          hand('FUCK YOU', dx: -0.1, dy: -0.08, mirrorX: true),
          hand('FUCK YOU', dx: 0.1, dy: 0.08),
        ];
      case 'HAPPY':
        return <List<HandLandmark>>[
          hand('B', dx: -0.11, dy: 0.06 - eased * 0.07, mirrorX: true),
          hand('B', dx: 0.11, dy: 0.04 - eased * 0.07),
        ];
      case 'SAD':
        return <List<HandLandmark>>[
          hand('B', dx: -0.1, dy: -0.08 + eased * 0.08, mirrorX: true),
          hand('B', dx: 0.1, dy: -0.08 + eased * 0.08),
        ];
      case 'FINISH':
        return <List<HandLandmark>>[
          hand('B', dx: -0.1 - eased * 0.03, mirrorX: true),
          hand('B', dx: 0.1 + eased * 0.03),
        ];
      case 'WAIT':
        return <List<HandLandmark>>[
          hand('B', dx: -0.11, dy: math.sin(loop * math.pi * 6) * 0.018),
          hand(
            'B',
            dx: 0.11,
            dy: math.cos(loop * math.pi * 6) * 0.018,
            mirrorX: true,
          ),
        ];
      case 'GO':
      case 'COME':
        final direction = sign == 'GO' ? -1.0 : 1.0;
        return <List<HandLandmark>>[
          hand('POINT', dx: -0.08, dy: direction * eased * 0.055),
          hand('POINT', dx: 0.08, dy: direction * eased * 0.055, mirrorX: true),
        ];
      case 'LOVE':
        return <List<HandLandmark>>[
          hand('A', dx: -0.08 + eased * 0.03, dy: 0.02, mirrorX: true),
          hand('A', dx: 0.08 - eased * 0.03, dy: 0.02),
        ];
      case 'DANGER':
        return <List<HandLandmark>>[
          hand('B', dx: -0.07 - eased * 0.06, dy: 0.02, mirrorX: true),
          hand('B', dx: 0.07 + eased * 0.06, dy: 0.02),
        ];
      case 'LOST':
        return <List<HandLandmark>>[
          hand('B', dx: -0.08, dy: eased * 0.055, mirrorX: true),
          hand('B', dx: 0.08, dy: eased * 0.055),
        ];
      case 'FIRE':
        return <List<HandLandmark>>[
          hand(
            'B',
            dx: -0.09,
            dy: -math.sin(loop * math.pi * 6) * 0.026,
            mirrorX: true,
          ),
          hand('B', dx: 0.09, dy: -math.cos(loop * math.pi * 6) * 0.026),
        ];
      default:
        return <List<HandLandmark>>[poseForSign(sign, phase)];
    }
  }

  static List<String> cycleLabelsFor(String rawSign) {
    final sign = rawSign.toUpperCase();
    switch (sign) {
      case 'HELLO':
        return const ['open palm', 'start near forehead', 'wave outward'];
      case 'THANK YOU':
        return const ['flat hand', 'touch chin', 'move forward'];
      case 'YES':
        return const ['make fist', 'relax wrist', 'nod twice'];
      case 'NO':
        return const ['two fingers up', 'thumb ready', 'close fingers'];
      case 'PLEASE':
        return const ['flat palm', 'touch chest', 'circle'];
      case 'MILK':
        return const ['open fingers', 'squeeze fist', 'repeat'];
      case 'MORE':
        return const ['pinch fingers', 'bring hands close', 'tap'];
      case 'EAT':
        return const ['pinch fingers', 'move to mouth', 'repeat'];
      case 'DRINK':
        return const ['make cup shape', 'lift hand', 'move to mouth'];
      case 'BATHROOM':
        return const ['make T shape', 'raise hand', 'shake side to side'];
      case 'SORRY':
        return const ['make fist', 'touch chest', 'circle slowly'];
      case 'NAME':
        return const ['make H hands', 'cross fingers', 'tap twice'];
      case 'FRIEND':
        return const ['hook index', 'switch hands', 'hook again'];
      case 'FAMILY':
        return const ['make F hands', 'start together', 'circle outward'];
      case 'MOTHER':
        return const ['open hand', 'thumb to chin', 'hold'];
      case 'FATHER':
        return const ['open hand', 'thumb to forehead', 'hold'];
      case 'WORK':
        return const ['make two fists', 'stack hands', 'tap twice'];
      case 'SCHOOL':
        return const ['open palms', 'bring together', 'clap twice'];
      case 'MONEY':
        return const ['open palm', 'pinch fingers', 'tap palm'];
      case 'SICK':
        return const ['middle fingers', 'touch head', 'touch body'];
      case 'HURT':
      case 'PAIN':
        return const ['point fingers', 'aim together', 'twist'];
      case 'HAPPY':
        return const ['open hands', 'touch chest', 'brush upward'];
      case 'SAD':
        return const ['open hands', 'near face', 'move downward'];
      case 'FINISH':
        return const ['open hands', 'palms in', 'turn outward'];
      case 'WAIT':
        return const ['open hands', 'palms up', 'wiggle fingers'];
      case 'GO':
        return const ['point fingers', 'start near body', 'move forward'];
      case 'COME':
        return const ['point fingers', 'start outward', 'move inward'];
      case 'LOVE':
        return const ['make fists', 'cross arms', 'hold chest'];
      case 'AGAIN':
        return const ['curve hand', 'open palm', 'tap again'];
      case 'GOOD':
        return const ['flat hand', 'start at mouth', 'move to palm'];
      case 'BAD':
        return const ['flat hand', 'start at mouth', 'turn downward'];
      case 'HOSPITAL':
        return const ['make H shape', 'touch arm', 'draw cross'];
      case 'DOCTOR':
        return const ['show wrist', 'touch fingertips', 'tap wrist'];
      case 'MEDICINE':
        return const ['open palm', 'middle finger', 'circle palm'];
      case 'DANGER':
        return const ['cross hands', 'warn clearly', 'move apart'];
      case 'LOST':
        return const ['open hands', 'move downward', 'close fingers'];
      case 'FIRE':
        return const ['open hands', 'fingers up', 'flick like flames'];
      case 'CALL':
      case 'PHONE':
        return const ['thumb and pinky', 'near ear', 'hold phone'];
      case 'J':
        return const ['pinky up', 'move down', 'curve into J'];
      case 'Z':
        return const ['index up', 'draw top line', 'finish Z'];
      case 'WHERE':
        return const ['index up', 'hold steady', 'move side to side'];
      case 'NEED':
        return const ['hook index', 'hold in front', 'move down'];
      case 'GOOD JOB':
      case 'HELP':
        return const ['make fist', 'thumb up', 'hold steady'];
      case 'NOT GOOD':
        return const ['make fist', 'thumb down', 'hold steady'];
      case 'FUCK YOU':
        return const ['fold fingers', 'raise middle', 'face outward'];
      case 'ROCK ON':
        return const ['index up', 'pinky up', 'fold middle'];
      case 'POINT':
        return const ['index up', 'aim finger', 'hold steady'];
      case 'WATER':
      case 'W':
        return const ['three fingers', 'pinky folded', 'hold W'];
      case 'I LOVE YOU':
        return const ['thumb up', 'index up', 'pinky up'];
      case 'CALL ME':
      case 'Y':
        return const ['thumb out', 'pinky out', 'hold phone shape'];
      default:
        return const ['make handshape', 'face camera', 'hold steady'];
    }
  }

  static double _palmScale(List<HandLandmark> landmarks) {
    final wrist = landmarks[0].position;
    return ((landmarks[5].position - wrist).distance +
            (landmarks[9].position - wrist).distance +
            (landmarks[13].position - wrist).distance +
            (landmarks[17].position - wrist).distance) /
        4;
  }

  static List<HandLandmark> _transformHand(
    List<HandLandmark> landmarks, {
    required double dx,
    required double dy,
    required bool mirrorX,
  }) {
    return landmarks.map((landmark) {
      final x = mirrorX ? 1 - landmark.position.dx : landmark.position.dx;
      return HandLandmark(
        index: landmark.index,
        name: landmark.name,
        position: Offset(x + dx, landmark.position.dy + dy),
        z: landmark.z,
        isHighlighted: landmark.isHighlighted,
      );
    }).toList(growable: false);
  }

  static List<Offset> _thumb({
    required Offset base,
    required double openness,
    required double rotation,
  }) {
    final open = openness.clamp(0.0, 1.0);
    final angle = _lerp(-0.22, -2.34 + rotation, open);
    final segment = _lerp(0.032, 0.058, open);
    final curl = _lerp(0.72, 0.08, open);
    return _finger(
      base: base,
      angle: angle,
      segment: segment,
      openness: open,
      curl: curl,
    );
  }

  static List<Offset> _finger({
    required Offset base,
    required double angle,
    required double segment,
    required double openness,
    bool hook = false,
    double? curl,
  }) {
    final open = openness.clamp(0.0, 1.0);
    final points = <Offset>[];
    var current = base;
    var currentAngle = angle;
    final bend = curl ?? (hook ? 0.62 : _lerp(0.88, 0.06, open));
    final segmentScale = _lerp(0.58, 1.0, open);
    for (var i = 0; i < 4; i++) {
      points.add(current);
      currentAngle += bend * (i / 3);
      current += Offset(
        math.cos(currentAngle) * segment * segmentScale * (1 - i * 0.08),
        math.sin(currentAngle) * segment * segmentScale * (1 - i * 0.08),
      );
    }
    return points;
  }

  static double _lerp(double a, double b, double t) {
    return a + (b - a) * t.clamp(0.0, 1.0);
  }
}

class _PoseSpec {
  const _PoseSpec({
    required this.thumb,
    required this.index,
    required this.middle,
    required this.ring,
    required this.pinky,
    this.spread = 0.28,
    this.shift = Offset.zero,
    this.thumbRotation = 0,
    this.indexHook = false,
    this.highlightedIndexes = const <int>{4, 8, 12, 16, 20},
  });

  factory _PoseSpec.forSign(String sign, double phase) {
    final pulse = (math.sin(phase * math.pi * 2) + 1) / 2;
    final eased = Curves.easeInOut.transform(pulse);
    switch (sign) {
      case 'B':
        return const _PoseSpec(
          thumb: 0.18,
          index: 1,
          middle: 1,
          ring: 1,
          pinky: 1,
          spread: 0.08,
        );
      case 'C':
      case 'O':
        return const _PoseSpec(
          thumb: 0.58,
          index: 0.58,
          middle: 0.58,
          ring: 0.58,
          pinky: 0.58,
          spread: 0.18,
        );
      case 'D':
        return const _PoseSpec(
          thumb: 0.45,
          index: 1,
          middle: 0.34,
          ring: 0.28,
          pinky: 0.24,
          highlightedIndexes: <int>{4, 8},
        );
      case 'E':
        return const _PoseSpec(
          thumb: 0.22,
          index: 0.28,
          middle: 0.28,
          ring: 0.28,
          pinky: 0.28,
        );
      case 'F':
      case 'OKAY':
        return const _PoseSpec(
          thumb: 0.62,
          index: 0.48,
          middle: 1,
          ring: 1,
          pinky: 1,
          highlightedIndexes: <int>{4, 8, 12, 16, 20},
        );
      case 'G':
      case 'L':
      case 'POINT':
      case 'ME':
      case 'YOU':
      case 'WHO':
        return const _PoseSpec(
          thumb: 1,
          index: 1,
          middle: 0.12,
          ring: 0.12,
          pinky: 0.12,
          spread: 0.42,
          highlightedIndexes: <int>{4, 8},
        );
      case 'H':
      case 'U':
      case 'V':
      case 'PEACE':
        return const _PoseSpec(
          thumb: 0.18,
          index: 1,
          middle: 1,
          ring: 0.12,
          pinky: 0.12,
          spread: 0.5,
          highlightedIndexes: <int>{8, 12},
        );
      case 'FUCK YOU':
        return const _PoseSpec(
          thumb: 0.18,
          index: 0.12,
          middle: 1,
          ring: 0.12,
          pinky: 0.12,
          highlightedIndexes: <int>{12},
        );
      case 'I':
        return const _PoseSpec(
          thumb: 0.18,
          index: 0.12,
          middle: 0.12,
          ring: 0.12,
          pinky: 1,
          highlightedIndexes: <int>{20},
        );
      case 'J':
        return _PoseSpec(
          thumb: 0.18,
          index: 0.12,
          middle: 0.12,
          ring: 0.12,
          pinky: 1,
          shift: Offset(
            math.sin(phase * math.pi * 1.3) * 0.045,
            phase < 0.58 ? phase * 0.07 : 0.04 - (phase - 0.58) * 0.12,
          ),
          highlightedIndexes: const <int>{20},
        );
      case 'K':
      case 'P':
        return const _PoseSpec(
          thumb: 0.78,
          index: 1,
          middle: 1,
          ring: 0.12,
          pinky: 0.12,
          spread: 0.3,
          highlightedIndexes: <int>{4, 8, 12},
        );
      case 'W':
      case 'WATER':
        return const _PoseSpec(
          thumb: 0.18,
          index: 1,
          middle: 1,
          ring: 1,
          pinky: 0.12,
          spread: 0.56,
          highlightedIndexes: <int>{8, 12, 16},
        );
      case 'X':
      case 'NEED':
        return _PoseSpec(
          thumb: 0.18,
          index: 0.78,
          middle: 0.12,
          ring: 0.12,
          pinky: 0.12,
          indexHook: true,
          shift: sign == 'NEED' ? Offset(0, eased * 0.06) : Offset.zero,
          highlightedIndexes: const <int>{8},
        );
      case 'Y':
      case 'CALL ME':
        return const _PoseSpec(
          thumb: 1,
          index: 0.12,
          middle: 0.12,
          ring: 0.12,
          pinky: 1,
          spread: 0.42,
          highlightedIndexes: <int>{4, 20},
        );
      case 'Z':
        return _PoseSpec(
          thumb: 0.18,
          index: 1,
          middle: 0.12,
          ring: 0.12,
          pinky: 0.12,
          shift: phase < 0.33
              ? Offset((phase - 0.16) * 0.16, -0.035)
              : phase < 0.66
                  ? Offset((0.5 - phase) * 0.18, (phase - 0.33) * 0.13)
                  : Offset((phase - 0.82) * 0.16, 0.035),
          highlightedIndexes: const <int>{8},
        );
      case 'HELLO':
        return _PoseSpec(
          thumb: 0.32,
          index: 1,
          middle: 1,
          ring: 1,
          pinky: 1,
          spread: 0.4,
          shift: Offset(eased * 0.075 - 0.035, -0.035 * (1 - eased)),
        );
      case 'THANK YOU':
        return _PoseSpec(
          thumb: 0.38,
          index: 1,
          middle: 1,
          ring: 1,
          pinky: 1,
          spread: 0.18,
          shift: Offset(eased * 0.055, eased * 0.05 - 0.035),
        );
      case 'YES':
        return _PoseSpec(
          thumb: 0.28,
          index: 0.1,
          middle: 0.1,
          ring: 0.1,
          pinky: 0.1,
          shift: Offset(0, math.sin(phase * math.pi * 4) * 0.032),
          highlightedIndexes: const <int>{0, 4, 8, 12, 16, 20},
        );
      case 'NO':
        return _PoseSpec(
          thumb: 0.55 + eased * 0.22,
          index: 1 - eased * 0.5,
          middle: 1 - eased * 0.5,
          ring: 0.12,
          pinky: 0.12,
          spread: 0.36,
          highlightedIndexes: const <int>{4, 8, 12},
        );
      case 'PLEASE':
        return _PoseSpec(
          thumb: 0.32,
          index: 1,
          middle: 1,
          ring: 1,
          pinky: 1,
          spread: 0.18,
          shift: Offset(
            math.cos(phase * math.pi * 2) * 0.035,
            math.sin(phase * math.pi * 2) * 0.026,
          ),
        );
      case 'MORE':
      case 'EAT':
      case 'AGAIN':
        return _PoseSpec(
          thumb: 0.45 + eased * 0.16,
          index: 0.42 + eased * 0.1,
          middle: 0.42 + eased * 0.1,
          ring: 0.42 + eased * 0.1,
          pinky: 0.38 + eased * 0.08,
          shift: sign == 'EAT'
              ? Offset(0.015, -0.04 + eased * 0.055)
              : sign == 'AGAIN'
                  ? Offset(eased * 0.055, 0.02)
                  : Offset.zero,
          highlightedIndexes: const <int>{4, 8, 12, 16, 20},
        );
      case 'DRINK':
        return _PoseSpec(
          thumb: 0.62,
          index: 0.58,
          middle: 0.58,
          ring: 0.58,
          pinky: 0.58,
          spread: 0.18,
          shift: Offset(0, -eased * 0.055),
        );
      case 'BATHROOM':
        return _PoseSpec(
          thumb: 0.72,
          index: 0.1,
          middle: 0.1,
          ring: 0.1,
          pinky: 0.1,
          shift: Offset(math.sin(phase * math.pi * 4) * 0.042, 0),
          highlightedIndexes: const <int>{4},
        );
      case 'SORRY':
        return _PoseSpec(
          thumb: 0.28,
          index: 0.1,
          middle: 0.1,
          ring: 0.1,
          pinky: 0.1,
          shift: Offset(
            math.cos(phase * math.pi * 2) * 0.028,
            math.sin(phase * math.pi * 2) * 0.028,
          ),
        );
      case 'MILK':
        return _PoseSpec(
          thumb: 0.32,
          index: 0.12 + eased * 0.46,
          middle: 0.12 + eased * 0.46,
          ring: 0.12 + eased * 0.46,
          pinky: 0.12 + eased * 0.46,
          highlightedIndexes: const <int>{4, 8, 12, 16, 20},
        );
      case 'I LOVE YOU':
        return const _PoseSpec(
          thumb: 1,
          index: 1,
          middle: 0.12,
          ring: 0.12,
          pinky: 1,
          spread: 0.48,
          highlightedIndexes: <int>{4, 8, 20},
        );
      case 'CALL':
      case 'PHONE':
        return const _PoseSpec(
          thumb: 1,
          index: 0.12,
          middle: 0.12,
          ring: 0.12,
          pinky: 1,
          spread: 0.42,
          shift: Offset(0.03, -0.06),
          highlightedIndexes: <int>{4, 20},
        );
      case 'MOTHER':
        return const _PoseSpec(
          thumb: 1,
          index: 1,
          middle: 1,
          ring: 1,
          pinky: 1,
          spread: 0.48,
          shift: Offset(0, -0.06),
          highlightedIndexes: <int>{4, 8, 12, 16, 20},
        );
      case 'FATHER':
        return const _PoseSpec(
          thumb: 1,
          index: 1,
          middle: 1,
          ring: 1,
          pinky: 1,
          spread: 0.48,
          shift: Offset(0, -0.12),
          highlightedIndexes: <int>{4, 8, 12, 16, 20},
        );
      case 'GOOD':
        return _PoseSpec(
          thumb: 0.32,
          index: 1,
          middle: 1,
          ring: 1,
          pinky: 1,
          spread: 0.16,
          shift: Offset(eased * 0.07, -0.035 + eased * 0.035),
        );
      case 'BAD':
        return _PoseSpec(
          thumb: 0.32,
          index: 1,
          middle: 1,
          ring: 1,
          pinky: 1,
          spread: 0.16,
          shift: Offset(eased * 0.055, eased * 0.04),
        );
      case 'HOSPITAL':
        return _PoseSpec(
          thumb: 0.18,
          index: 1,
          middle: 1,
          ring: 0.12,
          pinky: 0.12,
          spread: 0.5,
          shift: phase < 0.5
              ? Offset((phase - 0.25) * 0.08, 0)
              : Offset(0, (phase - 0.75) * 0.08),
          highlightedIndexes: const <int>{8, 12},
        );
      case 'FRIEND':
        return _PoseSpec(
          thumb: 0.25,
          index: 1,
          middle: 0.12,
          ring: 0.12,
          pinky: 0.12,
          indexHook: true,
          shift: Offset(eased * 0.05, 0),
          highlightedIndexes: const <int>{8},
        );
      case 'GOOD JOB':
      case 'HELP':
        return const _PoseSpec(
          thumb: 1,
          index: 0.1,
          middle: 0.1,
          ring: 0.1,
          pinky: 0.1,
          thumbRotation: 0.85,
          highlightedIndexes: <int>{1, 2, 3, 4},
        );
      case 'NOT GOOD':
        return const _PoseSpec(
          thumb: 1,
          index: 0.1,
          middle: 0.1,
          ring: 0.1,
          pinky: 0.1,
          thumbRotation: -0.65,
          shift: Offset(0, 0.04),
          highlightedIndexes: <int>{1, 2, 3, 4},
        );
      case 'ROCK ON':
        return const _PoseSpec(
          thumb: 0.2,
          index: 1,
          middle: 0.12,
          ring: 0.12,
          pinky: 1,
          spread: 0.48,
          highlightedIndexes: <int>{8, 20},
        );
      case 'STOP':
        return _PoseSpec(
          thumb: 0.25,
          index: 1,
          middle: 1,
          ring: 1,
          pinky: 1,
          shift: Offset(0, eased * 0.045),
        );
      case 'WHERE':
        return _PoseSpec(
          thumb: 0.25,
          index: 1,
          middle: 0.12,
          ring: 0.12,
          pinky: 0.12,
          shift: Offset(math.sin(phase * math.pi * 4) * 0.045, 0),
          highlightedIndexes: const <int>{8},
        );
      case 'A':
      case 'M':
      case 'N':
      case 'S':
      case 'T':
      default:
        return const _PoseSpec(
          thumb: 0.28,
          index: 0.1,
          middle: 0.1,
          ring: 0.1,
          pinky: 0.1,
          highlightedIndexes: <int>{0, 4, 8, 12, 16, 20},
        );
    }
  }

  final double thumb;
  final double index;
  final double middle;
  final double ring;
  final double pinky;
  final double spread;
  final Offset shift;
  final double thumbRotation;
  final bool indexHook;
  final Set<int> highlightedIndexes;
}
