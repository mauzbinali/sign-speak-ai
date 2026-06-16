import 'package:flutter_test/flutter_test.dart';
import 'package:sign_speak_ai/src/domain/hand_landmarks.dart';
import 'package:sign_speak_ai/src/domain/sign_models.dart';
import 'package:sign_speak_ai/src/services/sign_ai_service.dart';

void main() {
  test('word gestures win over alphabet fallback', () {
    expect(
      _detect(_pose(index: true, middle: true, ring: true, pinky: true)),
      'STOP',
    );
    expect(_detect(_pose(index: true, middle: true, ring: true)), 'WATER');
    expect(_detect(_pose()), 'MILK');
    expect(_detect(_pose(thumb: true)), 'GOOD JOB');
    expect(_detect(_pose(thumbDown: true)), 'NOT GOOD');
    expect(_detect(_pose(index: true, middle: true)), 'PEACE');
    expect(_detect(_pose(thumb: true, index: true)), 'POINT');
    expect(_detect(_pose(middle: true)), 'FUCK YOU');
    expect(_detect(_pose(thumb: true, index: true, pinky: true)), 'I LOVE YOU');
    expect(_detect(_pose(thumb: true, pinky: true)), 'CALL ME');
  });

  test('thumb noise does not block fist, stop, or okay signs', () {
    expect(_detect(_pose(thumbSide: true)), 'MILK');
    expect(_detect(_pose(thumbWeakDown: true)), 'MILK');
    expect(
      _detect(
        _pose(
          thumbSide: true,
          index: true,
          middle: true,
          ring: true,
          pinky: true,
        ),
      ),
      'STOP',
    );
    expect(_detect(_okayPose()), 'OKAY');
  });

  test('rock on and i love you are separated by strong thumb extension', () {
    expect(_detect(_pose(index: true, pinky: true)), 'ROCK ON');
    expect(
      _detect(_pose(thumbSide: true, index: true, pinky: true)),
      'ROCK ON',
    );
    expect(_detect(_pose(thumb: true, index: true, pinky: true)), 'I LOVE YOU');
  });

  test('normal hand movement does not become motion-only words', () {
    final service = SignAiService();
    final frames = <List<HandLandmark>>[
      _pose(index: true, middle: true, ring: true, pinky: true, offsetX: -0.06),
      _pose(index: true, middle: true, ring: true, pinky: true, offsetX: -0.03),
      _pose(index: true, middle: true, ring: true, pinky: true),
      _pose(index: true, middle: true, ring: true, pinky: true, offsetX: 0.03),
      _pose(index: true, middle: true, ring: true, pinky: true, offsetX: 0.06),
    ];

    final words = frames
        .map((landmarks) => service.detectTrackedHand(landmarks).word)
        .toSet();

    expect(words, isNot(contains('HELLO')));
    expect(words, isNot(contains('PLEASE')));
    expect(words, contains('STOP'));
    service.dispose();
  });

  test('shared lesson flows use supported camera signs', () {
    final alphabetSigns = alphabetLessons.map((lesson) => lesson.sign).toSet();
    final visibleSigns = signLessons.map((lesson) => lesson.sign).toSet();
    final supportedSigns = supportedCameraSignWords.toSet();

    expect(visibleSigns.intersection(alphabetSigns), isEmpty);
    expect(visibleSigns, supportedSigns);
    expect(visibleSigns, containsAll(<String>{'MILK', 'WATER', 'FUCK YOU'}));
    expect(visibleSigns, isNot(contains('A')));
  });

  test('emergency phrases only use supported camera signs', () {
    final supportedSigns = supportedCameraSignWords.toSet();
    for (final phrase in emergencyPhrases) {
      expect(phrase.signs, isNotEmpty);
      expect(phrase.signs.every(supportedSigns.contains), isTrue);
    }
  });

  test('multi-hand input uses the primary camera detector', () {
    final service = SignAiService();
    final detection = service.detectTrackedHands(<List<HandLandmark>>[
      _pose(thumb: true, offsetX: -0.16),
      _pose(index: true, middle: true, ring: true, pinky: true, offsetX: 0.16),
    ]);

    expect(detection.word, isNot('HELP'));
    expect(detection.handCount, 1);
    expect(detection.hasTwoHands, isFalse);
    expect(detection.visibleHands.every((hand) => hand.length == 21), isTrue);
    service.dispose();
  });
}

String _detect(List<HandLandmark> landmarks) {
  final service = SignAiService();
  final word = service.detectTrackedHand(landmarks).word;
  service.dispose();
  return word;
}

List<HandLandmark> _pose({
  bool thumb = false,
  bool index = false,
  bool middle = false,
  bool ring = false,
  bool pinky = false,
  bool thumbDown = false,
  bool thumbSide = false,
  bool thumbWeakDown = false,
  double offsetX = 0,
}) {
  final points = <Offset>[
    const Offset(0.50, 0.82),
    ..._thumb(
      open: thumb,
      down: thumbDown,
      side: thumbSide,
      weakDown: thumbWeakDown,
    ),
    ..._finger(x: 0.43, open: index),
    ..._finger(x: 0.50, open: middle),
    ..._finger(x: 0.57, open: ring),
    ..._finger(x: 0.64, open: pinky),
  ];

  final shiftedPoints = points.map((point) {
    return Offset(point.dx + offsetX, point.dy);
  }).toList(growable: false);

  return List<HandLandmark>.generate(shiftedPoints.length, (index) {
    return HandLandmark(
      index: index,
      name: handLandmarkNames[index],
      position: shiftedPoints[index],
    );
  }, growable: false);
}

List<HandLandmark> _okayPose() {
  const points = <Offset>[
    Offset(0.50, 0.82),
    Offset(0.45, 0.72),
    Offset(0.40, 0.66),
    Offset(0.37, 0.58),
    Offset(0.43, 0.47),
    Offset(0.43, 0.64),
    Offset(0.43, 0.56),
    Offset(0.44, 0.50),
    Offset(0.43, 0.47),
    Offset(0.50, 0.64),
    Offset(0.50, 0.52),
    Offset(0.50, 0.42),
    Offset(0.50, 0.32),
    Offset(0.57, 0.64),
    Offset(0.57, 0.52),
    Offset(0.57, 0.42),
    Offset(0.57, 0.32),
    Offset(0.64, 0.64),
    Offset(0.64, 0.52),
    Offset(0.64, 0.42),
    Offset(0.64, 0.32),
  ];
  return List<HandLandmark>.generate(points.length, (index) {
    return HandLandmark(
      index: index,
      name: handLandmarkNames[index],
      position: points[index],
    );
  }, growable: false);
}

List<Offset> _thumb({
  required bool open,
  required bool down,
  required bool side,
  required bool weakDown,
}) {
  if (down) {
    return const [
      Offset(0.45, 0.72),
      Offset(0.40, 0.76),
      Offset(0.35, 0.82),
      Offset(0.30, 0.88),
    ];
  }
  if (weakDown) {
    return const [
      Offset(0.45, 0.72),
      Offset(0.45, 0.74),
      Offset(0.47, 0.76),
      Offset(0.48, 0.78),
    ];
  }
  if (side) {
    return const [
      Offset(0.45, 0.72),
      Offset(0.41, 0.71),
      Offset(0.36, 0.72),
      Offset(0.31, 0.73),
    ];
  }
  if (open) {
    return const [
      Offset(0.45, 0.72),
      Offset(0.40, 0.65),
      Offset(0.35, 0.58),
      Offset(0.30, 0.51),
    ];
  }
  return const [
    Offset(0.45, 0.72),
    Offset(0.46, 0.73),
    Offset(0.50, 0.74),
    Offset(0.46, 0.73),
  ];
}

List<Offset> _finger({required double x, required bool open}) {
  if (open) {
    return [Offset(x, 0.64), Offset(x, 0.52), Offset(x, 0.42), Offset(x, 0.32)];
  }
  return [Offset(x, 0.64), Offset(x, 0.56), Offset(x, 0.60), Offset(x, 0.64)];
}
