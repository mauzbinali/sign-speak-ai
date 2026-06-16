import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/achievements/achievements_page.dart';
import '../../features/camera/ai_camera_page.dart';
import '../../features/emergency/emergency_page.dart';
import '../../features/history/history_page.dart';
import '../../features/learning/learning_page.dart';
import '../../features/practice/practice_page.dart';
import '../../features/quiz/quiz_page.dart';
import '../../navigation/app_routes.dart';
import '../../settings/settings_page.dart';
import '../../state/sign_speak_controller.dart';
import '../../widgets/ai_assistant_bubble.dart';
import '../../widgets/animated_ai_background.dart';
import '../../widgets/confidence_meter.dart';
import '../../widgets/glass_panel.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signSpeakControllerProvider);
    final controller = ref.read(signSpeakControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedAiBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFF28E0B5),
                              Color(0xFFFFC857),
                              Color(0xFFFF6B6B),
                            ],
                          ),
                        ),
                        child: const Text(
                          'SS',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign Speak AI',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            Text(
                              'Offline learning and translation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Theme',
                        onPressed: controller.toggleDarkMode,
                        icon: Icon(
                          state.isDarkMode
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Settings',
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).push(slideFadeRoute(const SettingsPage()));
                        },
                        icon: const Icon(Icons.settings_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: GlassPanel(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AiAssistantBubble(message: state.assistantMessage),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _LiveMetric(
                                label: 'Detected Sign',
                                value: state.detection.word,
                                icon: Icons.back_hand_rounded,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _LiveMetric(
                                label: 'Confidence',
                                value:
                                    '${(state.detection.confidence * 100).round()}%',
                                icon: Icons.analytics_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ConfidenceMeter(
                          confidence: state.detection.confidence,
                          height: 12,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).push(slideFadeRoute(const AiCameraPage()));
                          },
                          icon: const Icon(Icons.videocam_rounded),
                          label: const Text('Start Real-Time Translation'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                sliver: SliverGrid.count(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width > 720 ? 3 : 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio:
                      MediaQuery.sizeOf(context).width > 420 ? 1.22 : 1.0,
                  children: [
                    _FeatureCard(
                      title: 'Learn Sign Language',
                      icon: Icons.school_rounded,
                      color: const Color(0xFF28E0B5),
                      onTap: () => Navigator.of(
                        context,
                      ).push(slideFadeRoute(const LearningPage())),
                    ),
                    _FeatureCard(
                      title: 'Practice With AI',
                      icon: Icons.center_focus_strong_rounded,
                      color: const Color(0xFFFFC857),
                      onTap: () => Navigator.of(
                        context,
                      ).push(slideFadeRoute(const PracticePage())),
                    ),
                    _FeatureCard(
                      title: 'Quiz Mode',
                      icon: Icons.quiz_rounded,
                      color: const Color(0xFFA78BFA),
                      onTap: () => Navigator.of(
                        context,
                      ).push(slideFadeRoute(const QuizPage())),
                    ),
                    _FeatureCard(
                      title: 'Translation History',
                      icon: Icons.history_rounded,
                      color: const Color(0xFFFF6B6B),
                      onTap: () => Navigator.of(
                        context,
                      ).push(slideFadeRoute(const HistoryPage())),
                    ),
                    _FeatureCard(
                      title: 'Emergency Communication',
                      icon: Icons.emergency_share_rounded,
                      color: const Color(0xFF7DD3FC),
                      onTap: () => Navigator.of(
                        context,
                      ).push(slideFadeRoute(const EmergencyPage())),
                    ),
                    _FeatureCard(
                      title: 'Achievements',
                      icon: Icons.emoji_events_rounded,
                      color: const Color(0xFFFB7185),
                      onTap: () => Navigator.of(
                        context,
                      ).push(slideFadeRoute(const AchievementsPage())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveMetric extends StatelessWidget {
  const _LiveMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 86),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: theme.colorScheme.secondary),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium,
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
        ],
      ),
    );
  }
}
