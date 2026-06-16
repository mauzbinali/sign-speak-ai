import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sign_models.dart';
import '../../navigation/app_routes.dart';
import '../../state/sign_speak_controller.dart';
import '../../widgets/animated_ai_background.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/sign_picture_card.dart';
import '../camera/ai_camera_page.dart';

class LearningPage extends ConsumerStatefulWidget {
  const LearningPage({super.key});

  @override
  ConsumerState<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends ConsumerState<LearningPage> {
  final _searchController = TextEditingController();
  var _query = '';
  var _group = _lessonGroups.first.label;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _filteredLessons();

    return Scaffold(
      appBar: AppBar(title: const Text('Learn Sign Language')),
      body: AnimatedAiBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search signs',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final group = _lessonGroups[index];
                    return ChoiceChip(
                      avatar: Icon(group.icon, size: 17),
                      label: Text(group.label),
                      selected: _group == group.label,
                      onSelected: (_) => setState(() => _group = group.label),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemCount: _lessonGroups.length,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: lessons.isEmpty
                    ? const _EmptyLessons()
                    : _LessonList(lessons: lessons),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<LessonSign> _filteredLessons() {
    final group = _lessonGroups.firstWhere(
      (entry) => entry.label == _group,
      orElse: () => _lessonGroups.first,
    );
    final needle = _query.trim().toLowerCase();

    return signLessons.where((lesson) {
      final matchesGroup =
          group.signs.isEmpty || group.signs.contains(lesson.sign);
      if (!matchesGroup) {
        return false;
      }
      if (needle.isEmpty) {
        return true;
      }
      final haystack =
          '${lesson.sign} ${lesson.title} ${lesson.meaning} ${lesson.usage} ${lesson.description}'
              .toLowerCase();
      return haystack.contains(needle);
    }).toList(growable: false);
  }
}

class _LessonList extends ConsumerWidget {
  const _LessonList({required this.lessons});

  final List<LessonSign> lessons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(signSpeakControllerProvider.notifier);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return _LessonCard(
          lesson: lesson,
          onPractice: lesson.cameraPractice
              ? () {
                  controller.setPracticeTarget(lesson.sign);
                  Navigator.of(
                    context,
                  ).push(slideFadeRoute(const AiCameraPage()));
                }
              : null,
          onSpeak: () => controller.speak('${lesson.title}. ${lesson.meaning}'),
          onOpen: () {
            showSignPictureDialog(
              context: context,
              lesson: lesson,
              onPractice: lesson.cameraPractice
                  ? () {
                      controller.setPracticeTarget(lesson.sign);
                      Navigator.of(
                        context,
                      ).push(slideFadeRoute(const AiCameraPage()));
                    }
                  : null,
              onSpeak: () =>
                  controller.speak('${lesson.title}. ${lesson.meaning}'),
            );
          },
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: lessons.length,
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.onPractice,
    required this.onSpeak,
    required this.onOpen,
  });

  final LessonSign lesson;
  final VoidCallback? onPractice;
  final VoidCallback onSpeak;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewSteps = lesson.steps.take(2).toList(growable: false);

    return GlassPanel(
      onTap: onOpen,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 108,
                height: 132,
                child: SignPictureCard(
                  sign: lesson.sign,
                  height: 132,
                  compact: true,
                  showLabel: false,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.16,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lesson.sign.length == 1 ? lesson.sign : 'ASL',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lesson.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _InfoLine(label: 'Means', value: lesson.meaning),
                    const SizedBox(height: 6),
                    _InfoLine(label: 'Use', value: lesson.usage),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: onOpen,
                          icon: const Icon(Icons.slideshow_rounded),
                          label: const Text('Lesson'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onPractice,
                          icon: const Icon(Icons.center_focus_strong_rounded),
                          label: const Text('Practice'),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Voice',
                          onPressed: onSpeak,
                          icon: const Icon(Icons.volume_up_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lesson.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...previewSteps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(step)),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.play_circle_rounded),
            label: const Text('Open slow lesson'),
          ),
        ],
      ),
    );
  }
}

class _EmptyLessons extends StatelessWidget {
  const _EmptyLessons();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 46,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No signs found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try another word or lesson group.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: theme.textTheme.bodyMedium,
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

class _LessonGroupDefinition {
  const _LessonGroupDefinition({
    required this.label,
    required this.icon,
    required this.signs,
  });

  final String label;
  final IconData icon;
  final Set<String> signs;
}

const _lessonGroups = <_LessonGroupDefinition>[
  _LessonGroupDefinition(
    label: 'All',
    icon: Icons.grid_view_rounded,
    signs: <String>{},
  ),
  _LessonGroupDefinition(
    label: 'Basics',
    icon: Icons.waving_hand_rounded,
    signs: <String>{'NO', 'STOP', 'OKAY', 'POINT'},
  ),
  _LessonGroupDefinition(
    label: 'Food',
    icon: Icons.local_drink_rounded,
    signs: <String>{'WATER', 'MILK'},
  ),
  _LessonGroupDefinition(
    label: 'Emergency',
    icon: Icons.emergency_rounded,
    signs: <String>{
      'STOP',
      'CALL ME',
      'WATER',
      'MILK',
      'OKAY',
      'NO',
      'NOT GOOD',
      'POINT',
    },
  ),
  _LessonGroupDefinition(
    label: 'Gestures',
    icon: Icons.back_hand_rounded,
    signs: <String>{
      'GOOD JOB',
      'NOT GOOD',
      'FUCK YOU',
      'ROCK ON',
      'POINT',
      'CALL ME',
      'PEACE',
      'OKAY',
    },
  ),
];
