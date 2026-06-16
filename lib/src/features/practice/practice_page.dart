import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sign_models.dart';
import '../../navigation/app_routes.dart';
import '../../state/sign_speak_controller.dart';
import '../../widgets/animated_ai_background.dart';
import '../../widgets/confidence_meter.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/sign_picture_card.dart';
import '../camera/ai_camera_page.dart';

class PracticePage extends ConsumerStatefulWidget {
  const PracticePage({super.key});

  @override
  ConsumerState<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends ConsumerState<PracticePage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signSpeakControllerProvider);
    final controller = ref.read(signSpeakControllerProvider.notifier);
    final practiceLessons = signLessons
        .where((lesson) => lesson.cameraPractice)
        .toList(growable: false);
    final targetLesson = practiceLessons.firstWhere(
      (lesson) => lesson.sign == state.practiceTarget,
      orElse: () => practiceLessons.first,
    );
    final result = _resultText(state.practiceScore);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: AnimatedAiBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            GlassPanel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Sign',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final lesson = practiceLessons[index];
                        final selected = lesson.sign == targetLesson.sign;
                        return ChoiceChip(
                          label: Text(lesson.sign),
                          selected: selected,
                          onSelected: (_) =>
                              controller.setPracticeTarget(lesson.sign),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemCount: practiceLessons.length,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SignPictureCard(sign: targetLesson.sign, height: 260),
                  const SizedBox(height: 14),
                  Text(
                    targetLesson.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _PracticeInfo(label: 'Means', value: targetLesson.meaning),
                  const SizedBox(height: 6),
                  _PracticeInfo(label: 'Use', value: targetLesson.usage),
                  const SizedBox(height: 12),
                  ...targetLesson.steps.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(step)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassPanel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          result,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        '${(state.practiceScore * 100).round()}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: confidenceColor(state.practiceScore),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ConfidenceMeter(confidence: state.practiceScore, height: 12),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            controller.setPracticeTarget(targetLesson.sign);
                            Navigator.of(
                              context,
                            ).push(slideFadeRoute(const AiCameraPage()));
                          },
                          icon: const Icon(Icons.videocam_rounded),
                          label: const Text('Open Camera To Copy'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        tooltip: 'Voice',
                        onPressed: () => controller.speak(targetLesson.title),
                        icon: const Icon(Icons.volume_up_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resultText(double score) {
    if (score >= 0.86) {
      return 'Correct';
    }
    if (score >= 0.62) {
      return 'Almost correct';
    }
    return 'Try again';
  }
}

class _PracticeInfo extends StatelessWidget {
  const _PracticeInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
