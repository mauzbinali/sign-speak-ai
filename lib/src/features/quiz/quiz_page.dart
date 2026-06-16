import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sign_models.dart';
import '../../state/sign_speak_controller.dart';
import '../../widgets/animated_ai_background.dart';
import '../../widgets/confidence_meter.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/sign_picture_card.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  static final _quizLessons = signLessons
      .where(
        (lesson) => lesson.cameraPractice && hasQuizPictureFor(lesson.sign),
      )
      .toList(growable: false);

  var _questionIndex = 0;
  var _score = 0;
  String? _selectedSign;

  LessonSign get _currentLesson =>
      _quizLessons[_questionIndex % _quizLessons.length];

  bool get _answered => _selectedSign != null;

  @override
  Widget build(BuildContext context) {
    final lesson = _currentLesson;
    final progress =
        (_questionIndex + (_answered ? 1 : 0)) / _quizLessons.length;
    final options = _optionsForQuestion();

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: AnimatedAiBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            GlassPanel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Question ${_questionIndex + 1}/${_quizLessons.length}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Text(
                        'Score $_score',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ConfidenceMeter(
                    confidence: progress.clamp(0, 1).toDouble(),
                    height: 10,
                  ),
                  const SizedBox(height: 16),
                  SignPictureCard(
                    sign: lesson.sign,
                    height: 280,
                    compact: true,
                    showLabel: false,
                    quizImage: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Which sign is this?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AnswerButton(
                        label: option.title,
                        isSelected: _selectedSign == option.sign,
                        isCorrect: _answered && option.sign == lesson.sign,
                        isWrong: _answered &&
                            _selectedSign == option.sign &&
                            option.sign != lesson.sign,
                        onPressed:
                            _answered ? null : () => _choose(option.sign),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_answered) ...[
              const SizedBox(height: 12),
              GlassPanel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedSign == lesson.sign ? 'Correct' : 'Try again',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(lesson.description),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _nextQuestion,
                            icon: Icon(
                              _questionIndex + 1 >= _quizLessons.length
                                  ? Icons.refresh_rounded
                                  : Icons.arrow_forward_rounded,
                            ),
                            label: Text(
                              _questionIndex + 1 >= _quizLessons.length
                                  ? 'Restart'
                                  : 'Next',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          tooltip: 'Voice',
                          onPressed: () {
                            ref
                                .read(signSpeakControllerProvider.notifier)
                                .speak(lesson.title);
                          },
                          icon: const Icon(Icons.volume_up_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<LessonSign> _optionsForQuestion() {
    final lesson = _currentLesson;
    final options = <LessonSign>[lesson];
    var offset = 1;
    while (options.length < 4) {
      final candidate =
          _quizLessons[(_questionIndex + offset * 3) % _quizLessons.length];
      if (!options.any((item) => item.sign == candidate.sign)) {
        options.add(candidate);
      }
      offset++;
    }
    options.sort((a, b) => a.title.compareTo(b.title));
    return options;
  }

  void _choose(String sign) {
    setState(() {
      _selectedSign = sign;
      if (sign == _currentLesson.sign) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_questionIndex + 1 >= _quizLessons.length) {
        _questionIndex = 0;
        _score = 0;
      } else {
        _questionIndex++;
      }
      _selectedSign = null;
    });
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect
        ? const Color(0xFF28E0B5)
        : isWrong
            ? const Color(0xFFFF5A66)
            : Theme.of(context).colorScheme.outline;

    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(
          color: color.withValues(alpha: isSelected ? 0.9 : 0.45),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(
        isCorrect
            ? Icons.check_circle_rounded
            : isWrong
                ? Icons.cancel_rounded
                : Icons.pan_tool_alt_rounded,
      ),
      label: Text(label),
    );
  }
}
