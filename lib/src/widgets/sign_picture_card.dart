import 'package:flutter/material.dart';

import '../domain/sign_models.dart';

const _signImageAssets = <String, String>{
  'CALL ME': 'assets/sign_images/call_me.png',
  'FUCK YOU': 'assets/sign_images/fuck_you.png',
  'GOOD JOB': 'assets/sign_images/good_job.png',
  'I LOVE YOU': 'assets/sign_images/i_love_you.png',
  'MILK': 'assets/sign_images/milk.png',
  'NO': 'assets/sign_images/no.png',
  'NOT GOOD': 'assets/sign_images/not_good.png',
  'OKAY': 'assets/sign_images/okay.png',
  'PEACE': 'assets/sign_images/peace.png',
  'POINT': 'assets/sign_images/point.png',
  'ROCK ON': 'assets/sign_images/rock_on.png',
  'STOP': 'assets/sign_images/stop.png',
  'WATER': 'assets/sign_images/water.png',
};

const _quizImageAssets = <String, String>{
  'FUCK YOU': 'assets/sign_quiz_images/fuck_you.png',
  'GOOD JOB': 'assets/sign_quiz_images/good_job.png',
  'I LOVE YOU': 'assets/sign_quiz_images/i_love_you.png',
  'MILK': 'assets/sign_quiz_images/milk.png',
  'NO': 'assets/sign_quiz_images/no.png',
  'NOT GOOD': 'assets/sign_quiz_images/not_good.png',
  'OKAY': 'assets/sign_quiz_images/okay.png',
  'PEACE': 'assets/sign_quiz_images/peace.png',
  'POINT': 'assets/sign_quiz_images/point.png',
  'ROCK ON': 'assets/sign_quiz_images/rock_on.png',
  'STOP': 'assets/sign_quiz_images/stop.png',
  'WATER': 'assets/sign_quiz_images/water.png',
};

String _normalizedSign(String sign) => sign.trim().toUpperCase();

String? signPictureAssetFor(String sign) {
  return _signImageAssets[_normalizedSign(sign)];
}

String? quizPictureAssetFor(String sign) {
  return _quizImageAssets[_normalizedSign(sign)];
}

bool hasQuizPictureFor(String sign) {
  return quizPictureAssetFor(sign) != null;
}

class SignPictureCard extends StatelessWidget {
  const SignPictureCard({
    super.key,
    required this.sign,
    this.height = 280,
    this.compact = false,
    this.showLabel = true,
    this.quizImage = false,
  });

  final String sign;
  final double height;
  final bool compact;
  final bool showLabel;
  final bool quizImage;

  @override
  Widget build(BuildContext context) {
    final asset =
        quizImage ? quizPictureAssetFor(sign) : signPictureAssetFor(sign);
    final theme = Theme.of(context);

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              blurRadius: compact ? 16 : 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (asset == null)
                _FallbackSignPicture(
                  sign: sign,
                  compact: compact,
                  showLabel: showLabel,
                )
              else
                Padding(
                  padding: EdgeInsets.all(compact ? 4 : 8),
                  child: Image.asset(
                    asset,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return _FallbackSignPicture(
                        sign: sign,
                        compact: compact,
                        showLabel: showLabel,
                      );
                    },
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (asset == null && showLabel)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: _SignLabel(sign: sign),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showSignPictureDialog({
  required BuildContext context,
  required LessonSign lesson,
  VoidCallback? onPractice,
  VoidCallback? onSpeak,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF07100F),
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.56,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SignPictureCard(sign: lesson.sign, height: 360),
              const SizedBox(height: 12),
              _LessonActionBar(
                lesson: lesson,
                onPractice: onPractice == null
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        onPractice();
                      },
                onSpeak: onSpeak,
              ),
              const SizedBox(height: 16),
              Text(
                lesson.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _CoachLine(label: 'Means', value: lesson.meaning),
              const SizedBox(height: 8),
              _CoachLine(label: 'Use', value: lesson.usage),
              const SizedBox(height: 16),
              const _LessonStageRow(),
              const SizedBox(height: 16),
              Text(
                'Copy slowly',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ...lesson.steps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.22,
                          ),
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      );
    },
  );
}

class _FallbackSignPicture extends StatelessWidget {
  const _FallbackSignPicture({
    required this.sign,
    required this.compact,
    required this.showLabel,
  });

  final String sign;
  final bool compact;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.22),
            theme.colorScheme.secondary.withValues(alpha: 0.11),
            Colors.black.withValues(alpha: 0.16),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.back_hand_rounded,
              size: compact ? 34 : 64,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            if (showLabel) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _SignLabel(sign: sign),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignLabel extends StatelessWidget {
  const _SignLabel({required this.sign});

  final String sign;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        sign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
      ),
    );
  }
}

class _CoachLine extends StatelessWidget {
  const _CoachLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyLarge,
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

class _LessonActionBar extends StatelessWidget {
  const _LessonActionBar({
    required this.lesson,
    required this.onPractice,
    required this.onSpeak,
  });

  final LessonSign lesson;
  final VoidCallback? onPractice;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: lesson.cameraPractice ? onPractice : null,
            icon: const Icon(Icons.center_focus_strong_rounded),
            label: const Text('Practice'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSpeak,
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Voice'),
          ),
        ),
      ],
    );
  }
}

class _LessonStageRow extends StatelessWidget {
  const _LessonStageRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const stages = <({IconData icon, String label})>[
      (icon: Icons.visibility_rounded, label: 'Watch'),
      (icon: Icons.back_hand_rounded, label: 'Copy'),
      (icon: Icons.videocam_rounded, label: 'Check'),
    ];

    return Row(
      children: [
        for (var index = 0; index < stages.length; index++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                children: [
                  Icon(stages[index].icon, size: 20),
                  const SizedBox(height: 5),
                  Text(
                    stages[index].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (index < stages.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
