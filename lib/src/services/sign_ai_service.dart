import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/hand_landmarks.dart';
import '../domain/sign_models.dart';
import '../domain/sign_pose_library.dart';

class SignAiService {
  static const _labels = supportedCameraSignWords;

  Future<void> loadModel() async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
  }

  List<List<HandLandmark>> _smoothedHands = const <List<HandLandmark>>[];

  void setCorrections(List<SignCorrectionEntry> corrections) {}

  SignDetection detectFrame(int tick) {
    final phase = tick / 8;
    final labelIndex = (tick ~/ 5) % _labels.length;
    final word = _labels[labelIndex];
    final confidence = _confidenceFor(phase);

    final landmarks = SignPoseLibrary.poseForSign(word, phase);
    return SignDetection(
      letter: word.length == 1 ? word : word.substring(0, 1),
      word: confidence < 0.48 ? 'UNCLEAR' : word,
      confidence: confidence,
      landmarks: landmarks,
      hands: <List<HandLandmark>>[landmarks],
      detectedAt: DateTime.now(),
    );
  }

  SignDetection detectTrackedHand(List<HandLandmark> landmarks) {
    return detectTrackedHands(<List<HandLandmark>>[landmarks]);
  }

  SignDetection detectTrackedHands(List<List<HandLandmark>> hands) {
    final validHands = hands
        .where((hand) => hand.length == 21)
        .map((hand) => hand.toList(growable: false))
        .toList(growable: false);

    if (validHands.isEmpty) {
      _smoothedHands = const <List<HandLandmark>>[];
      return SignDetection.empty();
    }

    final trackedHands = _smoothHands(<List<HandLandmark>>[
      _selectPrimaryHand(validHands),
    ]);
    final tracked = trackedHands
        .asMap()
        .entries
        .map(
          (entry) => _TrackedHand(
            index: entry.key,
            landmarks: entry.value,
            states: _fingerStates(entry.value),
            center: _handCenter(entry.value),
          ),
        )
        .toList(growable: false);
    const primaryIndex = 0;
    final primary = tracked[primaryIndex];

    final singleHandGesture = _bestSingleHandGestureFor(tracked);
    final gesture = singleHandGesture;

    var word = 'UNCLEAR';
    var confidence = gesture?.confidence ??
        math.min(
          _confidenceForTrackedHand(primary.landmarks, primary.states),
          tracked.length >= 2 ? 0.58 : 0.56,
        );
    var highlightedByHand = <int, Set<int>>{
      for (final hand in tracked)
        hand.index: _highlightedIndexesForTrackedHand(hand.states),
    };

    if (gesture != null) {
      word = gesture.word;
      confidence = gesture.confidence;
      highlightedByHand = gesture.highlightedIndexesByHand(tracked.length);
    }

    final highlightedHands = tracked.map((hand) {
      final highlightedIndexes = highlightedByHand[hand.index] ?? const <int>{};
      return _highlightLandmarks(hand.landmarks, highlightedIndexes);
    }).toList(growable: false);
    final primaryLandmarks = highlightedHands[primaryIndex];

    return SignDetection(
      letter: '-',
      word: gesture == null || confidence < 0.5 ? 'UNCLEAR' : word,
      confidence: confidence,
      landmarks: primaryLandmarks,
      hands: highlightedHands,
      detectedAt: DateTime.now(),
    );
  }

  void dispose() {
    _smoothedHands = const <List<HandLandmark>>[];
  }

  static List<double> correctionFeaturesFor(List<HandLandmark> landmarks) {
    if (landmarks.length != 21) {
      return const [];
    }

    return SignPoseLibrary.modelFeaturesFor(landmarks);
  }

  List<HandLandmark> poseForSign(String sign, double phase) {
    return SignPoseLibrary.poseForSign(sign, phase);
  }

  double scorePractice({
    required String target,
    required SignDetection detection,
  }) {
    final normalizedTarget = target.toUpperCase();
    final normalizedWord = detection.word.toUpperCase();
    final matchBoost = normalizedWord == normalizedTarget ? 0.18 : 0;
    final base = detection.confidence + matchBoost;
    return base.clamp(0.0, 1.0).toDouble();
  }

  double _confidenceFor(double phase) {
    final wave = (math.sin(phase * 1.6) + 1) / 2;
    final microMotion = (math.cos(phase * 3.4) + 1) / 2;
    return (0.42 + wave * 0.42 + microMotion * 0.13)
        .clamp(0.0, 0.99)
        .toDouble();
  }

  _FingerStates _fingerStates(List<HandLandmark> landmarks) {
    final wrist = landmarks[0].position;

    double openness({required int tip, required int pip, required int mcp}) {
      final tipPoint = landmarks[tip].position;
      final pipPoint = landmarks[pip].position;
      final mcpPoint = landmarks[mcp].position;
      final tipDistance = (tipPoint - wrist).distance;
      final pipDistance = math.max((pipPoint - wrist).distance, 0.001);
      final mcpToTip = (tipPoint - mcpPoint).distance;
      final mcpToPip = math.max((pipPoint - mcpPoint).distance, 0.001);
      final distanceScore = ((tipDistance / pipDistance) - 0.88) / 0.34;
      final lengthScore = ((mcpToTip / mcpToPip) - 0.96) / 0.58;
      return ((distanceScore + lengthScore) / 2).clamp(0.0, 1.0).toDouble();
    }

    final thumbTip = landmarks[4].position;
    final thumbIp = landmarks[3].position;
    final thumbMcp = landmarks[2].position;
    final thumbDistanceScore = (((thumbTip - wrist).distance /
                math.max((thumbIp - wrist).distance, 0.001)) -
            0.86) /
        0.34;
    final thumbLengthScore = (((thumbTip - thumbMcp).distance /
                math.max((thumbIp - thumbMcp).distance, 0.001)) -
            0.92) /
        0.52;
    final thumbOpen = ((thumbDistanceScore + thumbLengthScore) / 2)
        .clamp(0.0, 1.0)
        .toDouble();

    final indexOpen = openness(tip: 8, pip: 6, mcp: 5);
    final middleOpen = openness(tip: 12, pip: 10, mcp: 9);
    final ringOpen = openness(tip: 16, pip: 14, mcp: 13);
    final pinkyOpen = openness(tip: 20, pip: 18, mcp: 17);

    return _FingerStates(
      thumb: thumbOpen >= 0.5,
      index: indexOpen >= 0.52,
      middle: middleOpen >= 0.52,
      ring: ringOpen >= 0.52,
      pinky: pinkyOpen >= 0.52,
      openness: <double>[thumbOpen, indexOpen, middleOpen, ringOpen, pinkyOpen],
    );
  }

  List<List<HandLandmark>> _smoothHands(List<List<HandLandmark>> hands) {
    final previousHands = _smoothedHands;
    final usedPreviousIndexes = <int>{};
    final smoothed = <List<HandLandmark>>[];

    for (final hand in hands) {
      final handCenter = _handCenter(hand);
      var bestPreviousIndex = -1;
      var bestDistance = double.infinity;

      for (var index = 0; index < previousHands.length; index++) {
        if (usedPreviousIndexes.contains(index) ||
            previousHands[index].length != hand.length) {
          continue;
        }
        final distance =
            (_handCenter(previousHands[index]) - handCenter).distance;
        if (distance < bestDistance) {
          bestDistance = distance;
          bestPreviousIndex = index;
        }
      }

      if (bestPreviousIndex == -1 || bestDistance > 0.32) {
        smoothed.add(hand);
        continue;
      }

      usedPreviousIndexes.add(bestPreviousIndex);
      smoothed.add(
        _smoothLandmarksWith(previousHands[bestPreviousIndex], hand),
      );
    }

    _smoothedHands = smoothed;
    return smoothed;
  }

  List<HandLandmark> _smoothLandmarksWith(
    List<HandLandmark> previous,
    List<HandLandmark> currentLandmarks,
  ) {
    final movement =
        (_handCenter(currentLandmarks) - _handCenter(previous)).distance;
    final baseCurrentWeight = movement > 0.12
        ? 0.86
        : movement > 0.06
            ? 0.68
            : movement > 0.025
                ? 0.48
                : 0.32;

    return List<HandLandmark>.generate(currentLandmarks.length, (index) {
      final current = currentLandmarks[index];
      final old = previous[index];
      final pointMovement = (current.position - old.position).distance;
      final currentWeight = pointMovement > 0.16
          ? 0.9
          : pointMovement > 0.075
              ? math.max(baseCurrentWeight, 0.72)
              : baseCurrentWeight;
      final tunedCurrentWeight = index >= 1 && index <= 4
          ? math.max(currentWeight, pointMovement > 0.035 ? 0.78 : 0.58)
          : currentWeight;
      final oldWeight = 1 - tunedCurrentWeight;
      final position = Offset(
        old.position.dx * oldWeight + current.position.dx * tunedCurrentWeight,
        old.position.dy * oldWeight + current.position.dy * tunedCurrentWeight,
      );
      return HandLandmark(
        index: current.index,
        name: current.name,
        position: position,
        z: old.z * oldWeight + current.z * tunedCurrentWeight,
      );
    }, growable: false);
  }

  _GesturePrediction? _distinctGestureFor(
    List<HandLandmark> landmarks,
    _FingerStates states,
  ) {
    final thumbOpen = states.openness[0];
    final indexOpen = states.openness[1];
    final middleOpen = states.openness[2];
    final ringOpen = states.openness[3];
    final pinkyOpen = states.openness[4];
    final thumbTip = landmarks[4].position;
    final thumbMcp = landmarks[2].position;
    final indexTip = landmarks[8].position;
    final wrist = landmarks[0].position;
    final palmScale = _palmScale(landmarks);
    final touchScale = palmScale.clamp(0.09, 0.26);
    bool open(double value, [double threshold = 0.52]) => value >= threshold;
    bool closed(double value, [double threshold = 0.48]) => value <= threshold;
    bool near(Offset a, Offset b, double factor) {
      return (a - b).distance < (touchScale * factor).clamp(0.035, 0.12);
    }

    final fourFingersClosed = closed(indexOpen, 0.62) &&
        closed(middleOpen, 0.62) &&
        closed(ringOpen, 0.62) &&
        closed(pinkyOpen, 0.62);
    final thumbVerticalDelta = (thumbTip.dy - thumbMcp.dy) / palmScale;
    final thumbTipFromWristY = (thumbTip.dy - wrist.dy) / palmScale;
    final thumbSideReach = (thumbTip.dx - thumbMcp.dx).abs() / palmScale;
    final thumbExtension = (thumbTip - thumbMcp).distance / palmScale;
    final thumbClearlyUp =
        thumbVerticalDelta < -0.72 || thumbTipFromWristY < -0.62;
    final thumbClearlyDown =
        thumbVerticalDelta > 0.52 || thumbTipFromWristY > 0.34;
    final thumbStrong =
        thumbExtension > 0.72 && (thumbSideReach > 0.34 || thumbOpen > 0.52);
    final thumbUpStrong = thumbStrong && thumbClearlyUp;
    final thumbDownStrong = thumbStrong && thumbClearlyDown;
    final thumbExtendedForGesture =
        thumbExtension > 0.64 && (thumbSideReach > 0.32 || thumbOpen > 0.58);
    final thumbIndexTouching = near(thumbTip, indexTip, 0.34);

    if (fourFingersClosed && thumbUpStrong) {
      return const _GesturePrediction(
        word: 'GOOD JOB',
        confidence: 0.96,
        highlightedIndexes: <int>{0, 1, 2, 3, 4},
      );
    }

    if (fourFingersClosed && thumbDownStrong) {
      return const _GesturePrediction(
        word: 'NOT GOOD',
        confidence: 0.9,
        highlightedIndexes: <int>{0, 1, 2, 3, 4},
      );
    }

    if (fourFingersClosed) {
      return const _GesturePrediction(
        word: 'MILK',
        confidence: 0.84,
        highlightedIndexes: <int>{0, 4, 8, 12, 16, 20},
      );
    }

    if (open(indexOpen) &&
        open(middleOpen) &&
        open(ringOpen) &&
        open(pinkyOpen) &&
        !thumbIndexTouching) {
      return const _GesturePrediction(
        word: 'STOP',
        confidence: 0.86,
        highlightedIndexes: <int>{0, 4, 8, 12, 16, 20},
      );
    }

    if (open(indexOpen, 0.54) &&
        open(middleOpen, 0.54) &&
        open(ringOpen, 0.54) &&
        closed(pinkyOpen, 0.58)) {
      return const _GesturePrediction(
        word: 'WATER',
        confidence: 0.95,
        highlightedIndexes: <int>{0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16},
      );
    }

    if (open(indexOpen, 0.55) &&
        open(middleOpen, 0.55) &&
        closed(ringOpen, 0.55) &&
        closed(pinkyOpen, 0.55) &&
        !thumbIndexTouching) {
      return const _GesturePrediction(
        word: 'PEACE',
        confidence: 0.9,
        highlightedIndexes: <int>{0, 5, 6, 7, 8, 9, 10, 11, 12},
      );
    }

    if (thumbExtendedForGesture &&
        open(indexOpen, 0.54) &&
        closed(middleOpen, 0.55) &&
        closed(ringOpen, 0.55) &&
        open(pinkyOpen, 0.54)) {
      return const _GesturePrediction(
        word: 'I LOVE YOU',
        confidence: 0.94,
        highlightedIndexes: <int>{0, 1, 2, 3, 4, 5, 6, 7, 8, 17, 18, 19, 20},
      );
    }

    if (closed(thumbOpen, 0.55) &&
        open(indexOpen, 0.52) &&
        open(middleOpen, 0.52) &&
        closed(ringOpen, 0.55) &&
        closed(pinkyOpen, 0.55) &&
        thumbIndexTouching) {
      return const _GesturePrediction(
        word: 'NO',
        confidence: 0.86,
        highlightedIndexes: <int>{0, 4, 8, 12},
      );
    }

    if (closed(indexOpen, 0.5) &&
        open(middleOpen, 0.56) &&
        closed(ringOpen, 0.52) &&
        closed(pinkyOpen, 0.52)) {
      return const _GesturePrediction(
        word: 'FUCK YOU',
        confidence: 0.94,
        highlightedIndexes: <int>{0, 9, 10, 11, 12},
      );
    }

    if (!thumbExtendedForGesture &&
        open(indexOpen, 0.54) &&
        closed(middleOpen, 0.54) &&
        closed(ringOpen, 0.54) &&
        open(pinkyOpen, 0.54)) {
      return const _GesturePrediction(
        word: 'ROCK ON',
        confidence: 0.88,
        highlightedIndexes: <int>{0, 5, 6, 7, 8, 17, 18, 19, 20},
      );
    }

    if (open(thumbOpen, 0.54) &&
        closed(indexOpen, 0.54) &&
        closed(middleOpen, 0.54) &&
        closed(ringOpen, 0.54) &&
        open(pinkyOpen, 0.54)) {
      return const _GesturePrediction(
        word: 'CALL ME',
        confidence: 0.88,
        highlightedIndexes: <int>{0, 1, 2, 3, 4, 17, 18, 19, 20},
      );
    }

    if (open(indexOpen, 0.54) &&
        closed(middleOpen, 0.54) &&
        closed(ringOpen, 0.54) &&
        closed(pinkyOpen, 0.54)) {
      return const _GesturePrediction(
        word: 'POINT',
        confidence: 0.86,
        highlightedIndexes: <int>{0, 5, 6, 7, 8},
      );
    }

    if (thumbIndexTouching &&
        open(middleOpen, 0.54) &&
        open(ringOpen, 0.54) &&
        open(pinkyOpen, 0.54)) {
      return const _GesturePrediction(
        word: 'OKAY',
        confidence: 0.88,
        highlightedIndexes: <int>{0, 1, 2, 3, 4, 5, 6, 7, 8},
      );
    }

    return null;
  }

  _GesturePrediction? _bestSingleHandGestureFor(List<_TrackedHand> hands) {
    _GesturePrediction? bestGesture;
    var bestHandIndex = 0;

    for (final hand in hands) {
      final gesture = _distinctGestureFor(hand.landmarks, hand.states);
      if (gesture == null) {
        continue;
      }
      if (bestGesture == null || gesture.confidence > bestGesture.confidence) {
        bestGesture = gesture;
        bestHandIndex = hand.index;
      }
    }

    final gesture = bestGesture;
    if (gesture == null) {
      return null;
    }
    return gesture.forHand(bestHandIndex);
  }

  List<HandLandmark> _selectPrimaryHand(List<List<HandLandmark>> hands) {
    final previous = _smoothedHands.isNotEmpty ? _smoothedHands.first : null;
    if (previous == null || previous.length != 21) {
      return _largestHand(hands);
    }

    final previousCenter = _handCenter(previous);
    List<HandLandmark>? nearest;
    var nearestDistance = double.infinity;
    for (final hand in hands) {
      final distance = (_handCenter(hand) - previousCenter).distance;
      if (distance < nearestDistance) {
        nearest = hand;
        nearestDistance = distance;
      }
    }

    if (nearest != null && nearestDistance < 0.34) {
      return nearest;
    }
    return _largestHand(hands);
  }

  List<HandLandmark> _largestHand(List<List<HandLandmark>> hands) {
    var largest = hands.first;
    var largestArea = 0.0;
    for (final hand in hands) {
      final bounds = _handBounds(hand);
      final area = bounds.width * bounds.height;
      if (area > largestArea) {
        largest = hand;
        largestArea = area;
      }
    }
    return largest;
  }

  Rect _handBounds(List<HandLandmark> landmarks) {
    var minX = 1.0;
    var maxX = 0.0;
    var minY = 1.0;
    var maxY = 0.0;
    for (final landmark in landmarks) {
      minX = math.min(minX, landmark.position.dx);
      maxX = math.max(maxX, landmark.position.dx);
      minY = math.min(minY, landmark.position.dy);
      maxY = math.max(maxY, landmark.position.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  List<HandLandmark> _highlightLandmarks(
    List<HandLandmark> landmarks,
    Set<int> highlightedIndexes,
  ) {
    return landmarks.map((landmark) {
      return HandLandmark(
        index: landmark.index,
        name: landmark.name,
        position: landmark.position,
        z: landmark.z,
        isHighlighted: highlightedIndexes.contains(landmark.index),
      );
    }).toList(growable: false);
  }

  Offset _handCenter(List<HandLandmark> landmarks) {
    var total = Offset.zero;
    for (final landmark in landmarks) {
      total += landmark.position;
    }
    return total / landmarks.length.toDouble();
  }

  double _palmScale(List<HandLandmark> landmarks) {
    final wrist = landmarks[0].position;
    return math.max(
      ((landmarks[5].position - wrist).distance +
              (landmarks[9].position - wrist).distance +
              (landmarks[13].position - wrist).distance +
              (landmarks[17].position - wrist).distance) /
          4,
      0.001,
    );
  }

  double _confidenceForTrackedHand(
    List<HandLandmark> landmarks,
    _FingerStates states,
  ) {
    final palmSize = _palmScale(landmarks);
    final tipSpread =
        ((landmarks[4].position - landmarks[8].position).distance +
                (landmarks[8].position - landmarks[12].position).distance +
                (landmarks[12].position - landmarks[16].position).distance +
                (landmarks[16].position - landmarks[20].position).distance) /
            4;
    final scaleScore = (palmSize * 4).clamp(0.0, 0.22).toDouble();
    final spreadScore = (tipSpread * 2).clamp(0.0, 0.18).toDouble();
    final patternScore =
        states.openFingerCount == 0 || states.openFingerCount >= 2
            ? 0.12
            : 0.07;
    return (0.48 + scaleScore + spreadScore + patternScore)
        .clamp(0.0, 0.96)
        .toDouble();
  }

  Set<int> _highlightedIndexesForTrackedHand(_FingerStates states) {
    final highlights = <int>{0, 5, 9, 13, 17};
    if (states.thumb) {
      highlights.addAll(<int>{1, 2, 3, 4});
    }
    if (states.index) {
      highlights.addAll(<int>{5, 6, 7, 8});
    }
    if (states.middle) {
      highlights.addAll(<int>{9, 10, 11, 12});
    }
    if (states.ring) {
      highlights.addAll(<int>{13, 14, 15, 16});
    }
    if (states.pinky) {
      highlights.addAll(<int>{17, 18, 19, 20});
    }
    return highlights;
  }
}

class _FingerStates {
  const _FingerStates({
    required this.thumb,
    required this.index,
    required this.middle,
    required this.ring,
    required this.pinky,
    required this.openness,
  });

  final bool thumb;
  final bool index;
  final bool middle;
  final bool ring;
  final bool pinky;
  final List<double> openness;

  int get openFingerCount {
    return <bool>[index, middle, ring, pinky].where((open) => open).length;
  }

  bool get allOpen {
    return thumb && index && middle && ring && pinky;
  }

  bool get fourFingersOpen {
    return index && middle && ring && pinky;
  }

  bool get onlyThumbOpen {
    return thumb && !index && !middle && !ring && !pinky;
  }

  bool get onlyMiddleOpen {
    return !index && middle && !ring && !pinky;
  }

  bool get indexOnly {
    return index && !middle && !ring && !pinky;
  }

  bool get noneOpen {
    return !thumb && !index && !middle && !ring && !pinky;
  }
}

class _TrackedHand {
  const _TrackedHand({
    required this.index,
    required this.landmarks,
    required this.states,
    required this.center,
  });

  final int index;
  final List<HandLandmark> landmarks;
  final _FingerStates states;
  final Offset center;
}

class _GesturePrediction {
  const _GesturePrediction({
    required this.word,
    required this.confidence,
    required this.highlightedIndexes,
    this.highlightedByHand,
  });

  final String word;
  final double confidence;
  final Set<int> highlightedIndexes;
  final Map<int, Set<int>>? highlightedByHand;

  _GesturePrediction forHand(int handIndex) {
    return _GesturePrediction(
      word: word,
      confidence: confidence,
      highlightedIndexes: highlightedIndexes,
      highlightedByHand: <int, Set<int>>{handIndex: highlightedIndexes},
    );
  }

  Map<int, Set<int>> highlightedIndexesByHand(int handCount) {
    final custom = highlightedByHand;
    if (custom != null) {
      return custom;
    }
    return <int, Set<int>>{
      for (var index = 0; index < handCount; index++) index: highlightedIndexes,
    };
  }
}
