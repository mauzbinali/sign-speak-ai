import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/sign_speak_controller.dart';
import '../../widgets/animated_ai_background.dart';
import '../../widgets/confidence_meter.dart';
import '../../widgets/glass_panel.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signSpeakControllerProvider);
    final controller = ref.read(signSpeakControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (state.history.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              onPressed: () async {
                await controller.clearHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History cleared')),
                  );
                }
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: AnimatedAiBackground(
        child: state.history.isEmpty
            ? Center(
                child: GlassPanel(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 42,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No saved translations yet',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Build a sentence in the camera screen, then tap Save to keep it here on this phone.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemBuilder: (context, index) {
                  final entry = state.history[index];
                  return GlassPanel(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.sentence,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 10),
                        ConfidenceMeter(
                          confidence: entry.confidence,
                          height: 8,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatDate(entry.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Speak',
                              onPressed: () => controller.speak(entry.sentence),
                              icon: const Icon(Icons.volume_up_rounded),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: 'Copy',
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: entry.sentence),
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
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemCount: state.history.length,
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.month}/${date.day}/${date.year}  $hour:$minute';
  }
}
