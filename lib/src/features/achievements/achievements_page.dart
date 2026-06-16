import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/sign_speak_controller.dart';
import '../../widgets/animated_ai_background.dart';
import '../../widgets/glass_panel.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signSpeakControllerProvider);
    final achievements = <_Achievement>[
      _Achievement(
        title: 'First Detection',
        icon: Icons.back_hand_rounded,
        unlocked: state.scanSequence > 0,
      ),
      _Achievement(
        title: 'Confident Signal',
        icon: Icons.bolt_rounded,
        unlocked: state.detection.confidence >= 0.78,
      ),
      _Achievement(
        title: 'Sentence Builder',
        icon: Icons.text_fields_rounded,
        unlocked: state.sentenceWords.length >= 3,
      ),
      _Achievement(
        title: 'Practice Streak',
        icon: Icons.local_fire_department_rounded,
        unlocked: state.practiceScore >= 0.86,
      ),
      _Achievement(
        title: 'Saved Translation',
        icon: Icons.bookmark_added_rounded,
        unlocked: state.history.isNotEmpty,
      ),
      _Achievement(
        title: 'Offline Ready',
        icon: Icons.cloud_off_rounded,
        unlocked: state.offlineMode,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: AnimatedAiBackground(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.sizeOf(context).width > 620 ? 3 : 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            final color = achievement.unlocked
                ? const Color(0xFFFFC857)
                : Colors.white.withValues(alpha: 0.32);
            return GlassPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(achievement.icon, color: color, size: 34),
                  const Spacer(),
                  Text(
                    achievement.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    achievement.unlocked ? 'Unlocked' : 'Locked',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Achievement {
  const _Achievement({
    required this.title,
    required this.icon,
    required this.unlocked,
  });

  final String title;
  final IconData icon;
  final bool unlocked;
}
