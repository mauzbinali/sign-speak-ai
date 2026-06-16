import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/sign_speak_controller.dart';
import '../widgets/animated_ai_background.dart';
import '../widgets/glass_panel.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signSpeakControllerProvider);
    final controller = ref.read(signSpeakControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedAiBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _PreferencesPanel(
              isDarkMode: state.isDarkMode,
              isModelLoading: state.isModelLoading,
              onThemeChanged: controller.toggleDarkMode,
            ),
            const SizedBox(height: 12),
            _PrivacyPanel(
              savedCount: state.history.length,
              correctionCount: state.corrections.length,
              onClearHistory: () async {
                await controller.clearHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Local history cleared')),
                  );
                }
              },
              onClearCorrections: () async {
                await controller.clearCorrections();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Local corrections cleared')),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            const _ModelPanel(),
          ],
        ),
      ),
    );
  }
}

class _PreferencesPanel extends StatelessWidget {
  const _PreferencesPanel({
    required this.isDarkMode,
    required this.isModelLoading,
    required this.onThemeChanged,
  });

  final bool isDarkMode;
  final bool isModelLoading;
  final VoidCallback onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SwitchListTile(
            value: isDarkMode,
            onChanged: (_) => onThemeChanged(),
            secondary: const Icon(Icons.contrast_rounded),
            title: const Text('Dark Mode'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              isModelLoading
                  ? Icons.hourglass_top_rounded
                  : Icons.memory_rounded,
            ),
            title: const Text('AI Model'),
            subtitle: const Text('Runs on this device'),
            trailing: Text(isModelLoading ? 'Loading' : 'Ready'),
          ),
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.cloud_off_rounded),
            title: Text('Offline Mode'),
            subtitle: Text('No account or server required'),
            trailing: Text('On'),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPanel extends StatelessWidget {
  const _PrivacyPanel({
    required this.savedCount,
    required this.correctionCount,
    required this.onClearHistory,
    required this.onClearCorrections,
  });

  final int savedCount;
  final int correctionCount;
  final Future<void> Function() onClearHistory;
  final Future<void> Function() onClearCorrections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const _PrivacyRow(
            icon: Icons.videocam_rounded,
            title: 'Camera frames',
            detail: 'Processed live on your phone',
          ),
          const _PrivacyRow(
            icon: Icons.wifi_off_rounded,
            title: 'Permissions',
            detail: 'Release build only requests Camera access',
          ),
          const _PrivacyRow(
            icon: Icons.history_rounded,
            title: 'Saved translations',
            detail: 'Stored locally until you clear them',
          ),
          const _PrivacyRow(
            icon: Icons.tune_rounded,
            title: 'Local corrections',
            detail: 'Used only on this phone to reduce repeat mistakes',
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: savedCount == 0 ? null : onClearHistory,
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text('Clear Local History ($savedCount)'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: correctionCount == 0 ? null : onClearCorrections,
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text('Clear Corrections ($correctionCount)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelPanel extends StatelessWidget {
  const _ModelPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <String>[
      'Camera',
      'Hand Landmarks',
      'Local Gesture AI',
      'Riverpod',
      'Text To Speech',
      'Local History',
    ];

    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Stack',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Chip(
                avatar: const Icon(Icons.check_rounded, size: 18),
                label: Text(item),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
