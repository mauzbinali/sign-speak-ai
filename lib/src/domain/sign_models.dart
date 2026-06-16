import 'hand_landmarks.dart';

enum ConfidenceLevel { low, medium, high }

class SignDetection {
  const SignDetection({
    required this.letter,
    required this.word,
    required this.confidence,
    required this.landmarks,
    required this.detectedAt,
    this.hands = const <List<HandLandmark>>[],
  });

  factory SignDetection.empty() {
    return SignDetection(
      letter: '-',
      word: 'Waiting',
      confidence: 0,
      landmarks: const [],
      detectedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String letter;
  final String word;
  final double confidence;
  final List<HandLandmark> landmarks;
  final List<List<HandLandmark>> hands;
  final DateTime detectedAt;

  List<List<HandLandmark>> get visibleHands {
    if (hands.isNotEmpty) {
      return hands.where((hand) => hand.length == 21).toList(growable: false);
    }
    return landmarks.length == 21
        ? <List<HandLandmark>>[landmarks]
        : const <List<HandLandmark>>[];
  }

  int get handCount => visibleHands.length;

  bool get hasHand => handCount > 0;

  bool get hasTwoHands => handCount >= 2;

  ConfidenceLevel get level {
    if (confidence >= 0.78) {
      return ConfidenceLevel.high;
    }
    if (confidence >= 0.52) {
      return ConfidenceLevel.medium;
    }
    return ConfidenceLevel.low;
  }

  bool get isConfident => level == ConfidenceLevel.high;
}

class TranslationHistoryEntry {
  const TranslationHistoryEntry({
    required this.sentence,
    required this.createdAt,
    required this.confidence,
  });

  factory TranslationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TranslationHistoryEntry(
      sentence: json['sentence'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] as int? ?? 0,
      ),
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
    );
  }

  final String sentence;
  final DateTime createdAt;
  final double confidence;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sentence': sentence,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'confidence': confidence,
    };
  }
}

class SignCorrectionEntry {
  const SignCorrectionEntry({
    required this.predictedSign,
    required this.correctedSign,
    required this.confidence,
    required this.poseFeatures,
    required this.createdAt,
  });

  factory SignCorrectionEntry.fromJson(Map<String, dynamic> json) {
    return SignCorrectionEntry(
      predictedSign: json['predictedSign'] as String? ?? '',
      correctedSign: json['correctedSign'] as String? ?? '',
      confidence: (json['confidence'] as num? ?? 0).toDouble(),
      poseFeatures: (json['poseFeatures'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toDouble())
          .toList(growable: false),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] as int? ?? 0,
      ),
    );
  }

  final String predictedSign;
  final String correctedSign;
  final double confidence;
  final List<double> poseFeatures;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'predictedSign': predictedSign,
      'correctedSign': correctedSign,
      'confidence': confidence,
      'poseFeatures': poseFeatures,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

enum LessonCategory { alphabet, common, phrase }

class LessonSign {
  const LessonSign({
    required this.sign,
    required this.title,
    required this.description,
    required this.steps,
    required this.meaning,
    required this.usage,
    this.category = LessonCategory.common,
    this.cameraPractice = true,
  });

  final String sign;
  final String title;
  final String description;
  final String meaning;
  final String usage;
  final List<String> steps;
  final LessonCategory category;
  final bool cameraPractice;
}

class EmergencyPhrase {
  const EmergencyPhrase({
    required this.phrase,
    required this.meaning,
    required this.signs,
    required this.steps,
    required this.icon,
  });

  final String phrase;
  final String meaning;
  final List<String> signs;
  final List<String> steps;
  final String icon;
}

class SignSpeakState {
  const SignSpeakState({
    required this.detection,
    required this.sentenceWords,
    required this.history,
    required this.corrections,
    required this.isModelLoading,
    required this.isDarkMode,
    required this.offlineMode,
    required this.assistantMessage,
    required this.successPulse,
    required this.scanSequence,
    required this.practiceTarget,
    required this.practiceScore,
  });

  factory SignSpeakState.initial() {
    return SignSpeakState(
      detection: SignDetection.empty(),
      sentenceWords: const [],
      history: const [],
      corrections: const [],
      isModelLoading: true,
      isDarkMode: true,
      offlineMode: true,
      assistantMessage: 'Place your hand inside the frame',
      successPulse: 0,
      scanSequence: 0,
      practiceTarget: 'GOOD JOB',
      practiceScore: 0,
    );
  }

  final SignDetection detection;
  final List<String> sentenceWords;
  final List<TranslationHistoryEntry> history;
  final List<SignCorrectionEntry> corrections;
  final bool isModelLoading;
  final bool isDarkMode;
  final bool offlineMode;
  final String assistantMessage;
  final int successPulse;
  final int scanSequence;
  final String practiceTarget;
  final double practiceScore;

  String get sentence => sentenceWords.join(' ');

  String get typedSentence {
    if (sentence.isEmpty) {
      return '...';
    }
    return sentence;
  }

  SignSpeakState copyWith({
    SignDetection? detection,
    List<String>? sentenceWords,
    List<TranslationHistoryEntry>? history,
    List<SignCorrectionEntry>? corrections,
    bool? isModelLoading,
    bool? isDarkMode,
    bool? offlineMode,
    String? assistantMessage,
    int? successPulse,
    int? scanSequence,
    String? practiceTarget,
    double? practiceScore,
  }) {
    return SignSpeakState(
      detection: detection ?? this.detection,
      sentenceWords: sentenceWords ?? this.sentenceWords,
      history: history ?? this.history,
      corrections: corrections ?? this.corrections,
      isModelLoading: isModelLoading ?? this.isModelLoading,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      offlineMode: offlineMode ?? this.offlineMode,
      assistantMessage: assistantMessage ?? this.assistantMessage,
      successPulse: successPulse ?? this.successPulse,
      scanSequence: scanSequence ?? this.scanSequence,
      practiceTarget: practiceTarget ?? this.practiceTarget,
      practiceScore: practiceScore ?? this.practiceScore,
    );
  }
}

const alphabetLessons = <LessonSign>[
  LessonSign(
    sign: 'A',
    title: 'Letter A',
    meaning: 'The alphabet letter A.',
    usage: 'Use for spelling names, places, and words letter by letter.',
    description: 'Closed fist with thumb resting along the side.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Curl all four fingers into the palm.',
      'Keep the thumb straight against the side.',
      'Hold the wrist steady at chest height.',
    ],
  ),
  LessonSign(
    sign: 'B',
    title: 'Letter B',
    meaning: 'The alphabet letter B.',
    usage: 'Use for fingerspelling words that include B.',
    description:
        'Flat upright hand with fingers together and thumb across palm.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Extend the four fingers straight up together.',
      'Fold the thumb across the palm.',
      'Face the palm outward.',
    ],
  ),
  LessonSign(
    sign: 'C',
    title: 'Letter C',
    meaning: 'The alphabet letter C.',
    usage: 'Use for fingerspelling words that include C.',
    description: 'Curved hand shaped like the letter C.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Curve all fingers and thumb.',
      'Leave open space between fingertips and thumb.',
      'Turn the C shape toward the viewer.',
    ],
  ),
  LessonSign(
    sign: 'D',
    title: 'Letter D',
    meaning: 'The alphabet letter D.',
    usage: 'Use for fingerspelling words that include D.',
    description:
        'Index finger up with the other fingertips touching the thumb.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Point the index finger upward.',
      'Touch the middle, ring, and pinky fingertips to the thumb.',
      'Keep the index finger straight.',
    ],
  ),
  LessonSign(
    sign: 'E',
    title: 'Letter E',
    meaning: 'The alphabet letter E.',
    usage: 'Use for fingerspelling words that include E.',
    description: 'Bent fingers over the thumb.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Bend all four fingers down.',
      'Tuck the thumb close to the palm.',
      'Keep the hand compact and facing outward.',
    ],
  ),
  LessonSign(
    sign: 'F',
    title: 'Letter F',
    meaning: 'The alphabet letter F.',
    usage: 'Use for fingerspelling words that include F.',
    description: 'Thumb and index touch while three fingers stay up.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Touch thumb and index finger together.',
      'Raise middle, ring, and pinky fingers.',
      'Face the palm outward.',
    ],
  ),
  LessonSign(
    sign: 'G',
    title: 'Letter G',
    meaning: 'The alphabet letter G.',
    usage: 'Use for fingerspelling words that include G.',
    description: 'Index finger and thumb point sideways with a small gap.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Point the index finger sideways.',
      'Place the thumb parallel under it.',
      'Fold the other fingers into the palm.',
    ],
  ),
  LessonSign(
    sign: 'H',
    title: 'Letter H',
    meaning: 'The alphabet letter H.',
    usage: 'Use for fingerspelling words that include H.',
    description: 'Index and middle fingers point sideways together.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Extend index and middle fingers sideways.',
      'Keep the two fingers together.',
      'Fold the ring and pinky fingers.',
    ],
  ),
  LessonSign(
    sign: 'I',
    title: 'Letter I',
    meaning: 'The alphabet letter I.',
    usage: 'Use for fingerspelling words that include I.',
    description: 'Pinky finger up, all other fingers folded.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Raise only the pinky finger.',
      'Fold index, middle, and ring fingers.',
      'Keep the thumb tucked across the fingers.',
    ],
  ),
  LessonSign(
    sign: 'J',
    title: 'Letter J',
    meaning: 'The alphabet letter J.',
    usage: 'Use for fingerspelling words that include J.',
    description: 'Pinky draws the shape of J in the air.',
    category: LessonCategory.alphabet,
    cameraPractice: false,
    steps: <String>[
      'Start with the letter I handshape.',
      'Move the pinky in a small J motion.',
      'Keep the movement smooth and visible.',
    ],
  ),
  LessonSign(
    sign: 'K',
    title: 'Letter K',
    meaning: 'The alphabet letter K.',
    usage: 'Use for fingerspelling words that include K.',
    description: 'Index and middle up with thumb between them.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Raise index and middle fingers.',
      'Place the thumb between them.',
      'Fold ring and pinky fingers.',
    ],
  ),
  LessonSign(
    sign: 'L',
    title: 'Letter L',
    meaning: 'The alphabet letter L.',
    usage: 'Use for fingerspelling words that include L.',
    description: 'Index finger and thumb form an L shape.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Point the index finger upward.',
      'Extend the thumb out to the side.',
      'Fold the other fingers.',
    ],
  ),
  LessonSign(
    sign: 'M',
    title: 'Letter M',
    meaning: 'The alphabet letter M.',
    usage: 'Use for fingerspelling words that include M.',
    description: 'Thumb tucked under three fingers.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Fold the fingers over the thumb.',
      'Place the thumb under index, middle, and ring fingers.',
      'Keep the hand facing outward.',
    ],
  ),
  LessonSign(
    sign: 'N',
    title: 'Letter N',
    meaning: 'The alphabet letter N.',
    usage: 'Use for fingerspelling words that include N.',
    description: 'Thumb tucked under two fingers.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Fold the fingers over the thumb.',
      'Place the thumb under index and middle fingers.',
      'Keep ring and pinky folded naturally.',
    ],
  ),
  LessonSign(
    sign: 'O',
    title: 'Letter O',
    meaning: 'The alphabet letter O.',
    usage: 'Use for fingerspelling words that include O.',
    description: 'Fingertips and thumb make a round O shape.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Curve all fingers toward the thumb.',
      'Touch fingertips close to the thumb.',
      'Leave the hand rounded like O.',
    ],
  ),
  LessonSign(
    sign: 'P',
    title: 'Letter P',
    meaning: 'The alphabet letter P.',
    usage: 'Use for fingerspelling words that include P.',
    description: 'K handshape angled downward.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Start with the K handshape.',
      'Angle the hand downward.',
      'Keep index and middle separated clearly.',
    ],
  ),
  LessonSign(
    sign: 'Q',
    title: 'Letter Q',
    meaning: 'The alphabet letter Q.',
    usage: 'Use for fingerspelling words that include Q.',
    description: 'G handshape angled downward.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Start with the G handshape.',
      'Angle the hand downward.',
      'Keep the thumb and index visible.',
    ],
  ),
  LessonSign(
    sign: 'R',
    title: 'Letter R',
    meaning: 'The alphabet letter R.',
    usage: 'Use for fingerspelling words that include R.',
    description: 'Index and middle fingers crossed.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Raise index and middle fingers.',
      'Cross the middle finger over the index finger.',
      'Fold the ring and pinky fingers.',
    ],
  ),
  LessonSign(
    sign: 'S',
    title: 'Letter S',
    meaning: 'The alphabet letter S.',
    usage: 'Use for fingerspelling words that include S.',
    description: 'Closed fist with thumb across the front.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Curl all fingers into a fist.',
      'Place the thumb across the front of the fingers.',
      'Face the fist outward.',
    ],
  ),
  LessonSign(
    sign: 'T',
    title: 'Letter T',
    meaning: 'The alphabet letter T.',
    usage: 'Use for fingerspelling words that include T.',
    description: 'Thumb tucked between index and middle fingers.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Fold the fingers into a fist.',
      'Place the thumb between index and middle fingers.',
      'Keep the hand compact.',
    ],
  ),
  LessonSign(
    sign: 'U',
    title: 'Letter U',
    meaning: 'The alphabet letter U.',
    usage: 'Use for fingerspelling words that include U.',
    description: 'Index and middle fingers up together.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Raise index and middle fingers.',
      'Keep them straight and together.',
      'Fold the other fingers.',
    ],
  ),
  LessonSign(
    sign: 'V',
    title: 'Letter V',
    meaning: 'The alphabet letter V.',
    usage: 'Use for fingerspelling words that include V.',
    description: 'Index and middle fingers up apart.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Raise index and middle fingers.',
      'Separate them into a V shape.',
      'Fold the other fingers.',
    ],
  ),
  LessonSign(
    sign: 'W',
    title: 'Letter W',
    meaning: 'The alphabet letter W.',
    usage: 'Use for fingerspelling words that include W.',
    description: 'Index, middle, and ring fingers up.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Raise index, middle, and ring fingers.',
      'Keep the pinky folded.',
      'Hold the three fingers apart enough to see.',
    ],
  ),
  LessonSign(
    sign: 'X',
    title: 'Letter X',
    meaning: 'The alphabet letter X.',
    usage: 'Use for fingerspelling words that include X.',
    description: 'Bent index finger like a hook.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Raise the index finger.',
      'Bend the index finger into a hook.',
      'Fold the other fingers.',
    ],
  ),
  LessonSign(
    sign: 'Y',
    title: 'Letter Y',
    meaning: 'The alphabet letter Y.',
    usage: 'Use for fingerspelling words that include Y.',
    description: 'Thumb and pinky extended.',
    category: LessonCategory.alphabet,
    steps: <String>[
      'Extend thumb and pinky.',
      'Fold the three middle fingers.',
      'Face the palm outward or slightly sideways.',
    ],
  ),
  LessonSign(
    sign: 'Z',
    title: 'Letter Z',
    meaning: 'The alphabet letter Z.',
    usage: 'Use for fingerspelling words that include Z.',
    description: 'Index finger draws a Z in the air.',
    category: LessonCategory.alphabet,
    cameraPractice: false,
    steps: <String>[
      'Point with the index finger.',
      'Draw a Z shape in the air.',
      'Make the motion clear and controlled.',
    ],
  ),
];

const commonSignLessons = <LessonSign>[
  LessonSign(
    sign: 'HELLO',
    title: 'Hello',
    meaning: 'A greeting.',
    usage: 'Use when meeting someone or starting a conversation.',
    description: 'Open hand moves outward from the forehead.',
    steps: <String>[
      'Open the hand with fingers together.',
      'Start near the forehead.',
      'Move the palm outward in a clean arc.',
    ],
  ),
  LessonSign(
    sign: 'THANK YOU',
    title: 'Thank You',
    meaning: 'A polite way to show gratitude.',
    usage: 'Use after someone helps you or gives you something.',
    description: 'Flat hand moves forward from the chin.',
    steps: <String>[
      'Touch fingertips near the chin.',
      'Keep the palm facing upward.',
      'Move the hand forward smoothly.',
    ],
  ),
  LessonSign(
    sign: 'YES',
    title: 'Yes',
    meaning: 'Agreement or confirmation.',
    usage: 'Use to answer yes or show something is correct.',
    description: 'A closed hand nodding motion used for yes.',
    steps: <String>[
      'Close the hand into a fist.',
      'Keep the wrist relaxed.',
      'For real ASL, move the fist like a small nod.',
    ],
  ),
  LessonSign(
    sign: 'NO',
    title: 'No',
    meaning: 'Disagreement or refusal.',
    usage: 'Use to answer no or show something is not correct.',
    description: 'Index and middle fingers close toward the thumb.',
    steps: <String>[
      'Raise index and middle fingers.',
      'Keep the other fingers folded.',
      'For real ASL, close the two fingers toward the thumb.',
    ],
  ),
  LessonSign(
    sign: 'PLEASE',
    title: 'Please',
    meaning: 'A polite request.',
    usage: 'Use when asking for help, food, water, or time.',
    description: 'Open hand near the chest moving in a circle.',
    steps: <String>[
      'Open the dominant hand.',
      'Keep the palm flat.',
      'For real ASL, circle the hand on the chest.',
    ],
  ),
  LessonSign(
    sign: 'HELP',
    title: 'Help',
    meaning: 'Requesting assistance.',
    usage: 'Use when you need someone to help you.',
    description: 'One hand supports a raised thumb hand.',
    steps: <String>[
      'Make a thumbs-up shape.',
      'Place it above the opposite palm.',
      'Lift both hands together.',
    ],
  ),
  LessonSign(
    sign: 'STOP',
    title: 'Stop',
    meaning: 'Stop or wait.',
    usage: 'Use to tell someone to stop an action.',
    description: 'One flat hand meets the other palm.',
    steps: <String>[
      'Hold one palm flat.',
      'Bring the other flat hand down to it.',
      'Make the motion clear and controlled.',
    ],
  ),
  LessonSign(
    sign: 'ME',
    title: 'Me',
    meaning: 'Refers to yourself.',
    usage: 'Use in sentences like me, I need, or I am.',
    description: 'Point toward yourself.',
    steps: <String>[
      'Extend the index finger.',
      'Fold the other fingers.',
      'Point gently toward your chest.',
    ],
  ),
  LessonSign(
    sign: 'YOU',
    title: 'You',
    meaning: 'Refers to the person you are addressing.',
    usage: 'Use when pointing to another person in conversation.',
    description: 'Point toward the person you are addressing.',
    steps: <String>[
      'Extend the index finger.',
      'Fold the other fingers.',
      'Point outward toward the person.',
    ],
  ),
  LessonSign(
    sign: 'GOOD JOB',
    title: 'Good Job',
    meaning: 'Praise or approval.',
    usage: 'Use to encourage someone.',
    description: 'Thumbs-up gesture for approval or praise.',
    steps: <String>[
      'Close the four fingers into the palm.',
      'Extend the thumb upward.',
      'Hold the thumb steady in the camera frame.',
    ],
  ),
  LessonSign(
    sign: 'NOT GOOD',
    title: 'Not Good',
    meaning: 'Disapproval or something is bad.',
    usage: 'Use when something is not good or you want to reject it.',
    description: 'Thumbs-down gesture.',
    steps: <String>[
      'Close the four fingers into the palm.',
      'Extend the thumb downward.',
      'Hold the thumb-down shape clearly in the camera frame.',
    ],
  ),
  LessonSign(
    sign: 'FUCK YOU',
    title: 'Fuck You',
    meaning: 'An offensive insult.',
    usage: 'Use only if you intentionally want to show strong anger.',
    description: 'Middle finger raised with the other fingers folded.',
    steps: <String>[
      'Fold the thumb, index, ring, and pinky fingers.',
      'Raise only the middle finger.',
      'Face the back of the hand toward the person.',
    ],
  ),
  LessonSign(
    sign: 'ROCK ON',
    title: 'Rock On',
    meaning: 'Excitement, music, or a playful gesture.',
    usage: 'Use as a casual expressive gesture.',
    description: 'Index and pinky raised with middle and ring folded.',
    steps: <String>[
      'Raise the index finger.',
      'Raise the pinky finger.',
      'Fold the middle and ring fingers.',
    ],
  ),
  LessonSign(
    sign: 'POINT',
    title: 'Point',
    meaning: 'Pointing at something or someone.',
    usage: 'Use for me, you, this, that, where, or choosing an object.',
    description: 'Index finger extended with other fingers folded.',
    steps: <String>[
      'Raise only the index finger.',
      'Fold the thumb and other fingers.',
      'Point toward the person or object.',
    ],
  ),
  LessonSign(
    sign: 'MILK',
    title: 'Milk',
    meaning: 'Milk.',
    usage: 'Use when asking for or talking about milk.',
    description: 'Closed hand shape inspired by the milk-squeezing sign.',
    steps: <String>[
      'Close all fingers into a fist.',
      'Keep the wrist steady.',
      'For real ASL, squeeze the fist gently as a motion.',
    ],
  ),
  LessonSign(
    sign: 'WATER',
    title: 'Water',
    meaning: 'Water.',
    usage: 'Use when asking for water or talking about drinking water.',
    description: 'W hand shape using index, middle, and ring fingers.',
    steps: <String>[
      'Raise index, middle, and ring fingers.',
      'Keep pinky folded.',
      'Hold the W shape clearly toward the camera.',
    ],
  ),
  LessonSign(
    sign: 'MORE',
    title: 'More',
    meaning: 'More.',
    usage: 'Use when you want more of something.',
    description: 'Fingertips gathered together.',
    steps: <String>[
      'Bring thumb and fingertips close together.',
      'Keep the hand relaxed.',
      'For real ASL, tap both hands together.',
    ],
  ),
  LessonSign(
    sign: 'EAT',
    title: 'Eat',
    meaning: 'Eat or food.',
    usage: 'Use when talking about eating or hunger.',
    description: 'Pinched fingertips shape used near the mouth in ASL.',
    steps: <String>[
      'Touch thumb to the fingertips.',
      'Keep the fingers pinched together.',
      'For real ASL, move the hand toward the mouth.',
    ],
  ),
  LessonSign(
    sign: 'I LOVE YOU',
    title: 'I Love You',
    meaning: 'I love you.',
    usage: 'Use with family, friends, or people you care about.',
    description: 'Thumb, index, and pinky extended.',
    steps: <String>[
      'Raise thumb, index, and pinky.',
      'Fold middle and ring fingers.',
      'Face the palm toward the camera.',
    ],
  ),
  LessonSign(
    sign: 'CALL ME',
    title: 'Call Me',
    meaning: 'Call me.',
    usage: 'Use when asking someone to phone you.',
    description: 'Thumb and pinky extended.',
    steps: <String>[
      'Raise the thumb and pinky.',
      'Fold the three middle fingers.',
      'Hold the hand like a phone.',
    ],
  ),
  LessonSign(
    sign: 'PEACE',
    title: 'Peace',
    meaning: 'Peace or V gesture.',
    usage: 'Use as a friendly gesture or to practice the V handshape.',
    description: 'Index and middle fingers extended.',
    steps: <String>[
      'Raise index and middle fingers.',
      'Fold the ring and pinky fingers.',
      'Keep the V shape visible.',
    ],
  ),
  LessonSign(
    sign: 'OKAY',
    title: 'Okay',
    meaning: 'Okay.',
    usage: 'Use to show that something is okay or understood.',
    description: 'Thumb and index touch, other fingers extended.',
    steps: <String>[
      'Touch thumb and index finger.',
      'Extend the other fingers.',
      'Hold the circle shape steady.',
    ],
  ),
  LessonSign(
    sign: 'SORRY',
    title: 'Sorry',
    meaning: 'Apology.',
    usage: 'Use when apologizing.',
    description: 'A fist moves in a small circle over the chest.',
    steps: <String>[
      'Make a closed fist.',
      'Place it near the chest.',
      'Move it in a small circle.',
    ],
  ),
  LessonSign(
    sign: 'BATHROOM',
    title: 'Bathroom',
    meaning: 'Bathroom or restroom.',
    usage: 'Use when asking where the bathroom is.',
    description: 'T handshape shakes gently side to side.',
    steps: <String>[
      'Make the letter T handshape.',
      'Hold it near shoulder height.',
      'Shake the hand gently side to side.',
    ],
  ),
  LessonSign(
    sign: 'NAME',
    title: 'Name',
    meaning: 'Name.',
    usage: 'Use when asking or telling a name.',
    description: 'Two H handshapes tap together.',
    steps: <String>[
      'Make H handshapes with both hands.',
      'Place one above the other.',
      'Tap them together twice.',
    ],
  ),
  LessonSign(
    sign: 'WHERE',
    title: 'Where',
    meaning: 'Where?',
    usage: 'Use when asking for a place or location.',
    description: 'Index finger waves slightly side to side.',
    steps: <String>[
      'Point the index finger upward.',
      'Keep the other fingers folded.',
      'Move the index finger side to side.',
    ],
  ),
  LessonSign(
    sign: 'WHO',
    title: 'Who',
    meaning: 'Who?',
    usage: 'Use when asking about a person.',
    description: 'Index finger moves near the chin.',
    steps: <String>[
      'Make an index-finger handshape.',
      'Place it near the chin.',
      'Move the finger slightly as you ask.',
    ],
  ),
  LessonSign(
    sign: 'NEED',
    title: 'Need',
    meaning: 'Need.',
    usage: 'Use in phrases like I need help or I need water.',
    description: 'Bent index finger moves downward.',
    steps: <String>[
      'Bend the index finger like a hook.',
      'Hold the hand in front of the body.',
      'Move the hand downward slightly.',
    ],
  ),
  LessonSign(
    sign: 'FRIEND',
    title: 'Friend',
    meaning: 'Friend.',
    usage: 'Use when talking about a friend.',
    description: 'Index fingers hook together and switch.',
    steps: <String>[
      'Hook index fingers together.',
      'Switch the hands and hook again.',
      'Keep the movement small and clear.',
    ],
  ),
  LessonSign(
    sign: 'FAMILY',
    title: 'Family',
    meaning: 'Family.',
    usage: 'Use when talking about relatives or people at home.',
    description: 'Two F handshapes circle outward together.',
    steps: <String>[
      'Make F handshapes with both hands.',
      'Touch the hands near the thumbs.',
      'Circle both hands outward and back together.',
    ],
  ),
  LessonSign(
    sign: 'MOTHER',
    title: 'Mother',
    meaning: 'Mother or mom.',
    usage: 'Use when talking about your mother.',
    description: 'Open hand with thumb near the chin.',
    steps: <String>[
      'Open the hand with fingers spread.',
      'Touch the thumb near the chin.',
      'Hold the handshape clearly.',
    ],
  ),
  LessonSign(
    sign: 'FATHER',
    title: 'Father',
    meaning: 'Father or dad.',
    usage: 'Use when talking about your father.',
    description: 'Open hand with thumb near the forehead.',
    steps: <String>[
      'Open the hand with fingers spread.',
      'Touch the thumb near the forehead.',
      'Hold the handshape clearly.',
    ],
  ),
  LessonSign(
    sign: 'WORK',
    title: 'Work',
    meaning: 'Work or job.',
    usage: 'Use when talking about school, work, or a job.',
    description: 'Two fists tap together.',
    steps: <String>[
      'Make fists with both hands.',
      'Place one fist above the other.',
      'Tap the fists together twice.',
    ],
  ),
  LessonSign(
    sign: 'SCHOOL',
    title: 'School',
    meaning: 'School.',
    usage: 'Use when talking about class, school, or learning.',
    description: 'Flat hands clap together twice.',
    steps: <String>[
      'Hold both hands flat.',
      'Bring the palms together.',
      'Tap the hands twice.',
    ],
  ),
  LessonSign(
    sign: 'MONEY',
    title: 'Money',
    meaning: 'Money.',
    usage: 'Use when asking about money, price, or payment.',
    description: 'Flat hand with pinched fingers tapping the palm.',
    steps: <String>[
      'Hold one palm flat.',
      'Pinch the fingertips of the other hand.',
      'Tap the pinched hand into the palm.',
    ],
  ),
  LessonSign(
    sign: 'DRINK',
    title: 'Drink',
    meaning: 'Drink.',
    usage: 'Use when asking for a drink.',
    description: 'C hand moves toward the mouth like holding a cup.',
    steps: <String>[
      'Make a C handshape.',
      'Hold it like a cup.',
      'Move it toward the mouth.',
    ],
  ),
  LessonSign(
    sign: 'SICK',
    title: 'Sick',
    meaning: 'Sick or unwell.',
    usage: 'Use when telling someone you feel sick.',
    description: 'Middle fingers touch the head and stomach area.',
    steps: <String>[
      'Extend the middle fingers.',
      'Place one near the forehead.',
      'Place the other near the stomach.',
    ],
  ),
  LessonSign(
    sign: 'HURT',
    title: 'Hurt',
    meaning: 'Pain or hurt.',
    usage: 'Use when telling someone something hurts.',
    description: 'Index fingers point toward each other and twist.',
    steps: <String>[
      'Point both index fingers toward each other.',
      'Keep them near the painful area if needed.',
      'Twist the fingers slightly.',
    ],
  ),
  LessonSign(
    sign: 'HAPPY',
    title: 'Happy',
    meaning: 'Happy.',
    usage: 'Use when saying you feel happy.',
    description: 'Open hands brush upward on the chest.',
    steps: <String>[
      'Open both hands.',
      'Place them near the chest.',
      'Move them upward gently.',
    ],
  ),
  LessonSign(
    sign: 'SAD',
    title: 'Sad',
    meaning: 'Sad.',
    usage: 'Use when saying you feel sad.',
    description: 'Open hands move downward in front of the face.',
    steps: <String>[
      'Open both hands near the face.',
      'Let the fingers point upward.',
      'Move the hands downward slowly.',
    ],
  ),
  LessonSign(
    sign: 'FINISH',
    title: 'Finish',
    meaning: 'Finished or done.',
    usage: 'Use when something is done.',
    description: 'Open hands turn outward.',
    steps: <String>[
      'Hold both open hands near the body.',
      'Start with palms facing in.',
      'Turn both hands outward.',
    ],
  ),
  LessonSign(
    sign: 'WAIT',
    title: 'Wait',
    meaning: 'Wait.',
    usage: 'Use to ask someone to wait.',
    description: 'Open hands wiggle fingers slightly.',
    steps: <String>[
      'Hold both hands open.',
      'Face palms slightly upward.',
      'Wiggle the fingers gently.',
    ],
  ),
  LessonSign(
    sign: 'GO',
    title: 'Go',
    meaning: 'Go.',
    usage: 'Use to tell someone to go or move.',
    description: 'Index fingers move forward together.',
    steps: <String>[
      'Point both index fingers forward.',
      'Start near the body.',
      'Move both hands forward.',
    ],
  ),
  LessonSign(
    sign: 'COME',
    title: 'Come',
    meaning: 'Come here.',
    usage: 'Use to ask someone to come.',
    description: 'Index fingers move toward the body.',
    steps: <String>[
      'Point both index fingers outward.',
      'Curve the movement toward yourself.',
      'Bring the hands toward your body.',
    ],
  ),
  LessonSign(
    sign: 'LOVE',
    title: 'Love',
    meaning: 'Love.',
    usage: 'Use for love, affection, or care.',
    description: 'Arms crossed over the chest.',
    steps: <String>[
      'Cross both arms over the chest.',
      'Hold the hands closed or relaxed.',
      'Keep the motion gentle.',
    ],
  ),
  LessonSign(
    sign: 'EXCUSE ME',
    title: 'Excuse Me',
    meaning: 'Excuse me.',
    usage: 'Use politely to get attention.',
    description: 'One hand brushes across the other palm.',
    cameraPractice: false,
    steps: <String>[
      'Hold one palm flat.',
      'Place the other hand above it.',
      'Brush across the palm.',
    ],
  ),
  LessonSign(
    sign: 'AGAIN',
    title: 'Again',
    meaning: 'Again or repeat.',
    usage: 'Use when asking someone to repeat.',
    description: 'Curved hand taps into the opposite palm.',
    steps: <String>[
      'Hold one palm open.',
      'Curve the fingers of the other hand.',
      'Tap the curved hand into the palm.',
    ],
  ),
  LessonSign(
    sign: 'GOOD',
    title: 'Good',
    meaning: 'Good or positive.',
    usage: 'Use when something is good or correct.',
    description: 'Flat hand moves away from the mouth toward the palm.',
    steps: <String>[
      'Hold the dominant hand flat near the mouth.',
      'Keep the other palm open in front.',
      'Move the flat hand forward toward the open palm.',
    ],
  ),
  LessonSign(
    sign: 'BAD',
    title: 'Bad',
    meaning: 'Bad or not good.',
    usage: 'Use when something is bad, wrong, or unpleasant.',
    description: 'Flat hand turns downward after moving from the mouth.',
    steps: <String>[
      'Hold the dominant hand flat near the mouth.',
      'Move the hand forward.',
      'Turn the palm downward to finish the sign.',
    ],
  ),
  LessonSign(
    sign: 'PAIN',
    title: 'Pain',
    meaning: 'Pain.',
    usage: 'Use when describing pain or where something hurts.',
    description: 'Index fingers point toward each other and twist.',
    steps: <String>[
      'Point both index fingers toward each other.',
      'Hold them near the pain area if needed.',
      'Twist both hands slightly.',
    ],
  ),
  LessonSign(
    sign: 'HOSPITAL',
    title: 'Hospital',
    meaning: 'Hospital.',
    usage: 'Use when talking about medical help or a hospital.',
    description: 'H handshape draws a cross on the upper arm.',
    steps: <String>[
      'Make an H handshape.',
      'Place it near the upper arm.',
      'Draw a small cross shape.',
    ],
  ),
  LessonSign(
    sign: 'DOCTOR',
    title: 'Doctor',
    meaning: 'Doctor.',
    usage: 'Use when asking for or talking about a doctor.',
    description: 'Fingertips tap the opposite wrist.',
    steps: <String>[
      'Hold one wrist forward.',
      'Bring the other fingertips to the wrist.',
      'Tap the wrist gently.',
    ],
  ),
  LessonSign(
    sign: 'MEDICINE',
    title: 'Medicine',
    meaning: 'Medicine.',
    usage: 'Use when asking for medicine or talking about treatment.',
    description: 'Middle finger circles on the opposite palm.',
    steps: <String>[
      'Hold one palm open.',
      'Touch the middle finger of the other hand to the palm.',
      'Move the fingertip in a small circle.',
    ],
  ),
  LessonSign(
    sign: 'DANGER',
    title: 'Danger',
    meaning: 'Danger or warning.',
    usage: 'Use to warn someone about danger.',
    description: 'Arms cross and move apart sharply.',
    steps: <String>[
      'Cross both hands or forearms in front.',
      'Keep the movement controlled.',
      'Move the hands apart to show warning.',
    ],
  ),
  LessonSign(
    sign: 'LOST',
    title: 'Lost',
    meaning: 'Lost.',
    usage: 'Use when you are lost or something is missing.',
    description: 'Open hands close downward as if something disappears.',
    steps: <String>[
      'Hold both open hands in front.',
      'Move the hands downward.',
      'Close the fingers as the hands move.',
    ],
  ),
  LessonSign(
    sign: 'FIRE',
    title: 'Fire',
    meaning: 'Fire.',
    usage: 'Use for fire, danger, or emergency communication.',
    description: 'Open fingers flick upward like flames.',
    steps: <String>[
      'Open both hands near the body.',
      'Point fingers upward.',
      'Wiggle the fingers upward like flames.',
    ],
  ),
  LessonSign(
    sign: 'CALL',
    title: 'Call',
    meaning: 'Call or phone someone.',
    usage: 'Use when asking someone to call.',
    description: 'Phone-like handshape moves near the face.',
    steps: <String>[
      'Extend thumb and pinky.',
      'Fold the middle fingers.',
      'Move the hand near the ear or cheek.',
    ],
  ),
  LessonSign(
    sign: 'PHONE',
    title: 'Phone',
    meaning: 'Phone.',
    usage: 'Use when talking about a phone or making a call.',
    description: 'Phone-like handshape held near the ear.',
    steps: <String>[
      'Extend thumb and pinky.',
      'Fold the middle fingers.',
      'Hold the hand near the ear.',
    ],
  ),
];

const supportedCameraSignWords = <String>[
  'GOOD JOB',
  'NOT GOOD',
  'FUCK YOU',
  'ROCK ON',
  'POINT',
  'MILK',
  'WATER',
  'I LOVE YOU',
  'CALL ME',
  'PEACE',
  'OKAY',
  'STOP',
  'NO',
];

final signLessons = supportedCameraSignWords
    .map(
      (sign) => commonSignLessons.firstWhere((lesson) => lesson.sign == sign),
    )
    .toList(growable: false);

const emergencyPhrases = <EmergencyPhrase>[
  EmergencyPhrase(
    phrase: 'Stop',
    meaning: 'Ask someone to stop immediately.',
    icon: 'STOP',
    signs: <String>['STOP'],
    steps: <String>[
      'Open the hand with all fingers extended.',
      'Hold the palm clearly toward the camera.',
      'Keep the hand steady so the app reads STOP.',
    ],
  ),
  EmergencyPhrase(
    phrase: 'Call me',
    meaning: 'Ask someone to phone you.',
    icon: 'CALL ME',
    signs: <String>['CALL ME'],
    steps: <String>[
      'Extend the thumb and pinky.',
      'Fold the three middle fingers.',
      'Hold the call shape near your face or toward the camera.',
    ],
  ),
  EmergencyPhrase(
    phrase: 'I need water',
    meaning: 'Ask for water.',
    icon: 'WATER',
    signs: <String>['WATER'],
    steps: <String>[
      'Raise index, middle, and ring fingers.',
      'Fold the pinky and thumb.',
      'Hold the W shape clearly toward the camera.',
    ],
  ),
  EmergencyPhrase(
    phrase: 'I need milk',
    meaning: 'Ask for milk.',
    icon: 'MILK',
    signs: <String>['MILK'],
    steps: <String>[
      'Close all fingers into a fist.',
      'Keep the wrist steady in the frame.',
      'Squeeze gently if you want to show the real motion.',
    ],
  ),
  EmergencyPhrase(
    phrase: 'I am okay',
    meaning: 'Tell someone you are okay.',
    icon: 'OKAY',
    signs: <String>['OKAY'],
    steps: <String>[
      'Touch thumb and index finger.',
      'Extend the other fingers.',
      'Hold the circle shape steady.',
    ],
  ),
  EmergencyPhrase(
    phrase: 'No',
    meaning: 'Refuse or answer no clearly.',
    icon: 'NO',
    signs: <String>['NO'],
    steps: <String>[
      'Raise the index and middle fingers.',
      'Keep the thumb close to the fingers.',
      'Close the fingers toward the thumb for the real motion.',
    ],
  ),
  EmergencyPhrase(
    phrase: 'Not good',
    meaning: 'Show that something is wrong or not okay.',
    icon: 'NOT GOOD',
    signs: <String>['NOT GOOD'],
    steps: <String>[
      'Close the four fingers into the palm.',
      'Extend the thumb downward.',
      'Hold the thumb-down shape clearly.',
    ],
  ),
  EmergencyPhrase(
    phrase: 'Point there',
    meaning: 'Point to a person, place, object, or problem.',
    icon: 'POINT',
    signs: <String>['POINT'],
    steps: <String>[
      'Raise only the index finger.',
      'Fold the thumb and other fingers.',
      'Point toward the thing you mean.',
    ],
  ),
  EmergencyPhrase(
    phrase: 'I love you',
    meaning: 'Tell someone you love them.',
    icon: 'I LOVE YOU',
    signs: <String>['I LOVE YOU'],
    steps: <String>[
      'Raise thumb, index, and pinky.',
      'Fold middle and ring fingers.',
      'Face the palm toward the person.',
    ],
  ),
  EmergencyPhrase(
    phrase: 'Peace',
    meaning: 'Show a calm or friendly peace sign.',
    icon: 'PEACE',
    signs: <String>['PEACE'],
    steps: <String>[
      'Raise index and middle fingers.',
      'Fold ring and pinky fingers.',
      'Keep the V shape visible.',
    ],
  ),
  EmergencyPhrase(
    phrase: 'Good job',
    meaning: 'Show approval or that something is good.',
    icon: 'GOOD JOB',
    signs: <String>['GOOD JOB'],
    steps: <String>[
      'Close the four fingers into the palm.',
      'Extend the thumb upward.',
      'Hold the thumb steady in the camera frame.',
    ],
  ),
];
