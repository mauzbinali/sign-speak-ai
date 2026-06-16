import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/hand_landmarks.dart';
import '../domain/sign_models.dart';
import '../services/correction_repository.dart';
import '../services/history_repository.dart';
import '../services/sign_ai_service.dart';
import '../services/speech_service.dart';

final signAiServiceProvider = Provider<SignAiService>((ref) {
  final service = SignAiService();
  ref.onDispose(service.dispose);
  return service;
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

final correctionRepositoryProvider = Provider<CorrectionRepository>((ref) {
  return CorrectionRepository();
});

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService();
  ref.onDispose(() {
    unawaited(service.stop());
  });
  return service;
});

final signSpeakControllerProvider =
    StateNotifierProvider<SignSpeakController, SignSpeakState>((ref) {
  return SignSpeakController(
    aiService: ref.watch(signAiServiceProvider),
    historyRepository: ref.watch(historyRepositoryProvider),
    correctionRepository: ref.watch(correctionRepositoryProvider),
    speechService: ref.watch(speechServiceProvider),
  );
});

class SignSpeakController extends StateNotifier<SignSpeakState> {
  SignSpeakController({
    required SignAiService aiService,
    required HistoryRepository historyRepository,
    required CorrectionRepository correctionRepository,
    required SpeechService speechService,
  })  : _aiService = aiService,
        _historyRepository = historyRepository,
        _correctionRepository = correctionRepository,
        _speechService = speechService,
        super(SignSpeakState.initial()) {
    unawaited(_boot());
  }

  final SignAiService _aiService;
  final HistoryRepository _historyRepository;
  final CorrectionRepository _correctionRepository;
  final SpeechService _speechService;
  final List<SignDetection> _recentDetections = <SignDetection>[];
  var _tick = 0;

  Future<void> _boot() async {
    state = state.copyWith(
      isModelLoading: true,
      assistantMessage: 'Loading AI model',
    );
    await _aiService.loadModel();
    final history = await _historyRepository.load();
    final corrections = await _correctionRepository.load();
    _aiService.setCorrections(corrections);
    state = state.copyWith(
      isModelLoading: false,
      history: history,
      corrections: corrections,
      assistantMessage: 'Place your hand inside the frame',
    );
  }

  void scanNextFrame() {
    if (state.isModelLoading) {
      return;
    }

    _tick++;
    final detection = _aiService.detectFrame(_tick);
    _applyDetection(detection);
  }

  void applyTrackedHand(List<HandLandmark> landmarks) {
    applyTrackedHands(<List<HandLandmark>>[landmarks]);
  }

  void applyTrackedHands(List<List<HandLandmark>> hands) {
    if (state.isModelLoading) {
      return;
    }

    final detection = _aiService.detectTrackedHands(hands);
    _applyDetection(detection);
  }

  void markNoTrackedHand() {
    if (state.isModelLoading) {
      return;
    }

    _recentDetections.clear();
    state = state.copyWith(
      detection: SignDetection.empty(),
      practiceScore: 0,
      scanSequence: state.scanSequence + 1,
      assistantMessage: 'Place your hand inside the frame',
    );
  }

  void _applyDetection(SignDetection detection) {
    final stableDetection = _stabilizeDetection(detection);
    final score = _aiService.scorePractice(
      target: state.practiceTarget,
      detection: stableDetection,
    );
    final wasConfident = state.detection.isConfident;
    final isConfident = stableDetection.isConfident;
    final pulse = isConfident && !wasConfident
        ? state.successPulse + 1
        : state.successPulse;

    state = state.copyWith(
      detection: stableDetection,
      practiceScore: score,
      scanSequence: state.scanSequence + 1,
      successPulse: pulse,
      assistantMessage: _assistantMessageFor(stableDetection),
    );
  }

  SignDetection _stabilizeDetection(SignDetection detection) {
    if (!detection.hasHand) {
      _recentDetections.clear();
      return detection;
    }

    _recentDetections.add(detection);
    if (_recentDetections.length > 5) {
      _recentDetections.removeAt(0);
    }

    final usable = _recentDetections
        .where((item) => item.word != 'UNCLEAR' && item.word != 'Waiting')
        .toList(growable: false);
    if (usable.isEmpty) {
      return detection;
    }

    final recentUnclearCount = _recentDetections
        .where((item) => item.word == 'UNCLEAR' || item.word == 'Waiting')
        .length;
    if (recentUnclearCount >= 3 && detection.word == 'UNCLEAR') {
      return detection;
    }

    final counts = <String, int>{};
    final confidenceTotals = <String, double>{};
    for (final item in usable) {
      counts[item.word] = (counts[item.word] ?? 0) + 1;
      confidenceTotals[item.word] =
          (confidenceTotals[item.word] ?? 0) + item.confidence;
    }

    final bestWord = counts.entries.reduce((best, next) {
      if (next.value != best.value) {
        return next.value > best.value ? next : best;
      }
      final nextConfidence = confidenceTotals[next.key] ?? 0;
      final bestConfidence = confidenceTotals[best.key] ?? 0;
      return nextConfidence > bestConfidence ? next : best;
    }).key;
    final voteCount = counts[bestWord] ?? 0;
    final requiredVotes = _isQuickGesture(bestWord) ? 2 : 3;
    final averageConfidence =
        (confidenceTotals[bestWord] ?? detection.confidence) / voteCount;
    final currentWord = state.detection.word;
    if (detection.word == 'UNCLEAR' &&
        currentWord != 'Waiting' &&
        currentWord != 'UNCLEAR' &&
        state.detection.confidence >= 0.68) {
      return SignDetection(
        letter: '-',
        word: currentWord,
        confidence:
            (state.detection.confidence * 0.68).clamp(0.0, 1.0).toDouble(),
        landmarks: detection.landmarks,
        hands: detection.visibleHands,
        detectedAt: detection.detectedAt,
      );
    }
    final shouldUpdate = voteCount >= requiredVotes ||
        (detection.word == bestWord && detection.confidence >= 0.92);
    final stableWord = shouldUpdate || !state.detection.hasHand
        ? bestWord
        : currentWord == 'Waiting'
            ? detection.word
            : currentWord;
    final stableConfidence = shouldUpdate
        ? averageConfidence
        : stableWord == currentWord
            ? state.detection.confidence * 0.65 + detection.confidence * 0.35
            : detection.confidence * 0.7;

    return SignDetection(
      letter: '-',
      word: stableWord,
      confidence: stableConfidence.clamp(0.0, 1.0).toDouble(),
      landmarks: detection.landmarks,
      hands: detection.visibleHands,
      detectedAt: detection.detectedAt,
    );
  }

  bool _isQuickGesture(String word) {
    return supportedCameraSignWords.contains(word);
  }

  void addCurrentSign() {
    final word = state.detection.word;
    if (word == 'UNCLEAR' ||
        word == 'Waiting' ||
        state.detection.confidence < 0.52) {
      state = state.copyWith(assistantMessage: 'Try again');
      return;
    }

    state = state.copyWith(
      sentenceWords: <String>[...state.sentenceWords, word],
      assistantMessage: 'Sign detected successfully',
      successPulse: state.successPulse + 1,
    );
  }

  void addPhrase(String phrase) {
    final words = phrase.toUpperCase().split(' ');
    state = state.copyWith(
      sentenceWords: <String>[...state.sentenceWords, ...words],
      assistantMessage: 'Emergency phrase added',
    );
  }

  void clearSentence() {
    state = state.copyWith(
      sentenceWords: const [],
      assistantMessage: 'Sentence cleared',
    );
  }

  Future<void> saveSentence() async {
    if (state.sentence.trim().isEmpty) {
      state = state.copyWith(assistantMessage: 'Add a sign first');
      return;
    }

    final entry = TranslationHistoryEntry(
      sentence: state.sentence,
      createdAt: DateTime.now(),
      confidence: state.detection.confidence,
    );
    final history = <TranslationHistoryEntry>[
      entry,
      ...state.history,
    ].take(20).toList();
    state = state.copyWith(
      history: history,
      assistantMessage: 'Translation saved',
    );
    await _historyRepository.save(history);
  }

  Future<void> clearHistory() async {
    state = state.copyWith(
      history: const [],
      assistantMessage: 'Local history cleared',
    );
    await _historyRepository.clear();
  }

  Future<void> correctCurrentSign(String correctedSign) async {
    final normalizedCorrection = correctedSign.trim().toUpperCase();
    final detection = state.detection;
    if (normalizedCorrection.isEmpty || !detection.hasHand) {
      state = state.copyWith(
        assistantMessage: 'Place your hand inside the frame',
      );
      return;
    }

    final entry = SignCorrectionEntry(
      predictedSign: detection.word,
      correctedSign: normalizedCorrection,
      confidence: detection.confidence,
      poseFeatures: SignAiService.correctionFeaturesFor(detection.landmarks),
      createdAt: DateTime.now(),
    );
    final corrections = <SignCorrectionEntry>[
      entry,
      ...state.corrections,
    ].take(60).toList();
    _aiService.setCorrections(corrections);

    final correctedDetection = SignDetection(
      letter: normalizedCorrection.length == 1
          ? normalizedCorrection
          : normalizedCorrection.substring(0, 1),
      word: normalizedCorrection,
      confidence: detection.confidence < 0.78 ? 0.78 : detection.confidence,
      landmarks: detection.landmarks,
      hands: detection.visibleHands,
      detectedAt: DateTime.now(),
    );

    state = state.copyWith(
      corrections: corrections,
      detection: correctedDetection,
      assistantMessage: 'Correction saved on this phone',
      successPulse: state.successPulse + 1,
    );
    await _correctionRepository.save(corrections);
  }

  Future<void> clearCorrections() async {
    _aiService.setCorrections(const []);
    state = state.copyWith(
      corrections: const [],
      assistantMessage: 'Local corrections cleared',
    );
    await _correctionRepository.clear();
  }

  Future<void> speak(String text) async {
    final message = text.trim().isEmpty ? state.sentence : text;
    if (message.trim().isEmpty) {
      state = state.copyWith(assistantMessage: 'Add a sign first');
      return;
    }
    await _speechService.speak(message);
    state = state.copyWith(assistantMessage: 'Speaking translation');
  }

  void setPracticeTarget(String target) {
    state = state.copyWith(
      practiceTarget: target,
      practiceScore: 0,
      assistantMessage: 'Copy the target sign',
    );
  }

  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  String _assistantMessageFor(SignDetection detection) {
    final framingMessage = _framingMessageFor(detection.visibleHands);
    if (framingMessage != null) {
      return framingMessage;
    }

    switch (detection.level) {
      case ConfidenceLevel.high:
        return detection.word == 'UNCLEAR' ? 'Try again' : 'Great job';
      case ConfidenceLevel.medium:
        return 'Keep your hand steady';
      case ConfidenceLevel.low:
        return 'Place your hand inside the frame';
    }
  }

  String? _framingMessageFor(List<List<HandLandmark>> hands) {
    if (hands.isEmpty) {
      return null;
    }

    var minX = 1.0;
    var maxX = 0.0;
    var minY = 1.0;
    var maxY = 0.0;
    for (final hand in hands) {
      for (final landmark in hand) {
        minX = landmark.position.dx < minX ? landmark.position.dx : minX;
        maxX = landmark.position.dx > maxX ? landmark.position.dx : maxX;
        minY = landmark.position.dy < minY ? landmark.position.dy : minY;
        maxY = landmark.position.dy > maxY ? landmark.position.dy : maxY;
      }
    }

    final width = maxX - minX;
    final height = maxY - minY;
    if (width < 0.16 || height < 0.18) {
      return 'Move your hand closer';
    }
    if (minX < 0.04 || maxX > 0.96 || minY < 0.04 || maxY > 0.96) {
      return 'Center your hand in the frame';
    }
    return null;
  }
}
