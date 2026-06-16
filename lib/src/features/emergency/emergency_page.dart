import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sign_models.dart';
import '../../state/sign_speak_controller.dart';
import '../../widgets/animated_ai_background.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/sign_picture_card.dart';

class EmergencyPage extends ConsumerWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(signSpeakControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency')),
      body: AnimatedAiBackground(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemBuilder: (context, index) {
            final guide = emergencyPhrases[index];
            return GlassPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 104,
                        height: 124,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.22),
                            child: _AnimatedEmergencyPose(signs: guide.signs),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guide.phrase,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              guide.meaning,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: guide.signs.map((sign) {
                                return Chip(
                                  avatar: const Icon(
                                    Icons.back_hand_rounded,
                                    size: 16,
                                  ),
                                  label: Text(sign),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...guide.steps.map(
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => controller.addPhrase(guide.phrase),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => controller.speak(guide.phrase),
                        icon: const Icon(Icons.volume_up_rounded),
                        label: const Text('Speak'),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Copy',
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: guide.phrase),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied')),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemCount: emergencyPhrases.length,
        ),
      ),
    );
  }
}

class _AnimatedEmergencyPose extends ConsumerStatefulWidget {
  const _AnimatedEmergencyPose({required this.signs});

  final List<String> signs;

  @override
  ConsumerState<_AnimatedEmergencyPose> createState() =>
      _AnimatedEmergencyPoseState();
}

class _AnimatedEmergencyPoseState
    extends ConsumerState<_AnimatedEmergencyPose> {
  Timer? _timer;
  var _tick = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 850), (_) {
      if (mounted) {
        setState(() => _tick++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signs = widget.signs.isEmpty ? const <String>['STOP'] : widget.signs;
    final sign = signs[_tick % signs.length];

    return Stack(
      fit: StackFit.expand,
      children: [
        SignPictureCard(
          sign: sign,
          height: 124,
          compact: true,
          showLabel: false,
        ),
        Positioned(
          left: 6,
          right: 6,
          bottom: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              sign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}
