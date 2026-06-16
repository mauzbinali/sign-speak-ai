import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hand_landmarker/hand_landmarker.dart' as media_pipe;

import '../../domain/hand_landmarks.dart';
import '../../domain/sign_models.dart';
import '../../navigation/app_routes.dart';
import '../../settings/settings_page.dart';
import '../../state/sign_speak_controller.dart';
import '../../widgets/ai_assistant_bubble.dart';
import '../../widgets/confidence_meter.dart';
import '../../widgets/glass_panel.dart';
import 'widgets/hand_skeleton_painter.dart';

class AiCameraPage extends ConsumerStatefulWidget {
  const AiCameraPage({super.key});

  @override
  ConsumerState<AiCameraPage> createState() => _AiCameraPageState();
}

class _AiCameraPageState extends ConsumerState<AiCameraPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _frameInterval = Duration(milliseconds: 55);

  CameraController? _cameraController;
  media_pipe.HandLandmarkerPlugin? _handLandmarker;
  List<CameraDescription> _cameras = const [];
  late final AnimationController _skeletonAnimation;
  DateTime _lastFrameProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);
  var _cameraIndex = 0;
  var _flashOn = false;
  var _isCameraReady = false;
  var _isTrackerReady = false;
  var _isDetecting = false;
  var _isStartingCamera = false;
  var _emptyFrameCount = 0;
  var _trackerErrorCount = 0;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _skeletonAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('no_camera', 'No cameras available');
      }

      final frontIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      _cameraIndex = frontIndex >= 0 ? frontIndex : 0;
      await _startCamera(_cameraIndex);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cameraError = '$error';
        _isCameraReady = false;
      });
    }
  }

  Future<void> _startCamera(int index) async {
    if (_isStartingCamera) {
      return;
    }
    _isStartingCamera = true;
    final previousController = _cameraController;
    try {
      if (previousController?.value.isStreamingImages ?? false) {
        await previousController?.stopImageStream();
      }
      _cameraController = CameraController(
        _cameras[index],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await previousController?.dispose();
      await _initializeHandTracker();
      await _cameraController!.initialize();
      await _startImageStreamIfReady();

      if (!mounted) {
        return;
      }
      setState(() {
        _cameraIndex = index;
        _isCameraReady = true;
        _cameraError = null;
        _flashOn = false;
      });
    } finally {
      _isStartingCamera = false;
    }
  }

  Future<void> _initializeHandTracker() async {
    if (_handLandmarker != null) {
      _isTrackerReady = true;
      return;
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      _isTrackerReady = false;
      _cameraError = 'Real hand tracking is available on Android devices.';
      return;
    }

    try {
      _handLandmarker = media_pipe.HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: 0.5,
        delegate: media_pipe.HandLandmarkerDelegate.gpu,
      );
      _isTrackerReady = true;
    } catch (_) {
      _handLandmarker = media_pipe.HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: 0.5,
        delegate: media_pipe.HandLandmarkerDelegate.cpu,
      );
      _isTrackerReady = true;
    }
  }

  void _processCameraImage(CameraImage image) {
    final landmarker = _handLandmarker;
    final controller = _cameraController;
    final now = DateTime.now();
    if (!_isTrackerReady ||
        _isDetecting ||
        landmarker == null ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }
    if (now.difference(_lastFrameProcessedAt) < _frameInterval) {
      return;
    }
    _lastFrameProcessedAt = now;

    _isDetecting = true;
    try {
      final hands = landmarker.detect(
        image,
        controller.description.sensorOrientation,
      );
      if (!mounted) {
        return;
      }

      final appHands = hands
          .where((hand) => hand.landmarks.length == 21)
          .map((hand) => _toAppLandmarks(hand.landmarks))
          .toList(growable: false);

      if (appHands.isEmpty) {
        _emptyFrameCount++;
        if (_emptyFrameCount >= 14) {
          ref.read(signSpeakControllerProvider.notifier).markNoTrackedHand();
          _emptyFrameCount = 0;
        }
        return;
      }

      _emptyFrameCount = 0;
      _trackerErrorCount = 0;
      ref
          .read(signSpeakControllerProvider.notifier)
          .applyTrackedHands(appHands);
    } catch (error) {
      _trackerErrorCount++;
      if (mounted) {
        final shouldShowError =
            _trackerErrorCount <= 2 || _trackerErrorCount % 30 == 0;
        if (shouldShowError) {
          setState(() {
            _cameraError = 'Hand tracker error: $error';
          });
        }
      }
    } finally {
      _isDetecting = false;
    }
  }

  List<HandLandmark> _toAppLandmarks(List<media_pipe.Landmark> landmarks) {
    return List<HandLandmark>.generate(landmarks.length, (index) {
      final landmark = landmarks[index];
      return HandLandmark(
        index: index,
        name: handLandmarkNames[index],
        position: Offset(
          landmark.x.clamp(0.0, 1.0).toDouble(),
          landmark.y.clamp(0.0, 1.0).toDouble(),
        ),
        z: landmark.z,
      );
    }, growable: false);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) {
      return;
    }
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera(nextIndex);
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    final nextValue = !_flashOn;
    try {
      await controller.setFlashMode(
        nextValue ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) {
        setState(() => _flashOn = nextValue);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _flashOn = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _skeletonAnimation.dispose();
    if (_cameraController?.value.isStreamingImages ?? false) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    _handLandmarker?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _pauseImageStream();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _startImageStreamIfReady();
    }
  }

  Future<void> _pauseImageStream() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
    }
  }

  Future<void> _startImageStreamIfReady() async {
    final controller = _cameraController;
    if (!_isTrackerReady ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isStreamingImages) {
      return;
    }
    try {
      await controller.startImageStream(_processCameraImage);
    } catch (error) {
      if (mounted) {
        setState(() {
          _cameraError = 'Camera stream error: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signSpeakControllerProvider);
    final previewSize = _overlayPreviewSize();
    final activeCamera =
        _isCameraReady && _cameras.isNotEmpty ? _cameras[_cameraIndex] : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _CameraSurface(controller: _cameraController),
            ),
            if (!_isCameraReady)
              Positioned.fill(child: _CameraFallback(error: _cameraError)),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _skeletonAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: HandSkeletonPainter(
                      landmarks: state.detection.landmarks,
                      hands: state.detection.visibleHands,
                      confidence: state.detection.confidence,
                      animation: _skeletonAnimation.value,
                      previewSize: previewSize,
                      lensDirection: activeCamera?.lensDirection ??
                          CameraLensDirection.back,
                      sensorOrientation: activeCamera?.sensorOrientation ?? 0,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              top: 12,
              child: _CameraTopBar(
                flashOn: _flashOn,
                canSwitchCamera: _cameras.length > 1,
                onBack: () => Navigator.pop(context),
                onFlash: _toggleFlash,
                onSwitchCamera: _switchCamera,
                onSettings: () {
                  Navigator.of(
                    context,
                  ).push(slideFadeRoute(const SettingsPage()));
                },
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 88,
              child: AiAssistantBubble(
                message: state.assistantMessage,
                compact: true,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _SuccessPulse(successPulse: state.successPulse),
              ),
            ),
            if (state.isModelLoading)
              const Positioned.fill(child: _AiLoadingOverlay()),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _PredictionSheet(
                onAdd: ref
                    .read(signSpeakControllerProvider.notifier)
                    .addCurrentSign,
                onClear: ref
                    .read(signSpeakControllerProvider.notifier)
                    .clearSentence,
                onSave:
                    ref.read(signSpeakControllerProvider.notifier).saveSentence,
                onSpeak: () {
                  ref
                      .read(signSpeakControllerProvider.notifier)
                      .speak(state.sentence);
                },
                onCopy: () async {
                  await Clipboard.setData(ClipboardData(text: state.sentence));
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Copied')));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Size? _overlayPreviewSize() {
    final previewSize = _cameraController?.value.previewSize;
    if (previewSize == null) {
      return null;
    }
    return previewSize;
  }
}

class _CameraSurface extends StatelessWidget {
  const _CameraSurface({required this.controller});

  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    final activeController = controller;
    if (activeController == null || !activeController.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: activeController.value.previewSize?.height ?? 720,
            height: activeController.value.previewSize?.width ?? 1280,
            child: CameraPreview(activeController),
          ),
        ),
      ),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  const _CameraFallback({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF07100F),
            Color(0xFF12241F),
            Color(0xFF2A1721),
          ],
        ),
      ),
      child: Center(
        child: GlassPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_rounded,
                color: theme.colorScheme.secondary,
                size: 38,
              ),
              const SizedBox(height: 10),
              Text(
                'Camera preview unavailable',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Text(
                    error!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraTopBar extends StatelessWidget {
  const _CameraTopBar({
    required this.flashOn,
    required this.canSwitchCamera,
    required this.onBack,
    required this.onFlash,
    required this.onSwitchCamera,
    required this.onSettings,
  });

  final bool flashOn;
  final bool canSwitchCamera;
  final VoidCallback onBack;
  final VoidCallback onFlash;
  final VoidCallback onSwitchCamera;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(icon: Icons.arrow_back_rounded, onPressed: onBack),
        const SizedBox(width: 10),
        Expanded(
          child: GlassPanel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF28E0B5), Color(0xFFFFC857)],
                    ),
                  ),
                  child: const Text(
                    'SS',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Sign Speak AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundIconButton(
          icon: flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          onPressed: onFlash,
        ),
        const SizedBox(width: 8),
        _RoundIconButton(
          icon: Icons.cameraswitch_rounded,
          onPressed: canSwitchCamera ? onSwitchCamera : null,
        ),
        const SizedBox(width: 8),
        _RoundIconButton(icon: Icons.settings_rounded, onPressed: onSettings),
      ],
    );
  }
}

class _PredictionSheet extends ConsumerWidget {
  const _PredictionSheet({
    required this.onAdd,
    required this.onClear,
    required this.onSave,
    required this.onSpeak,
    required this.onCopy,
  });

  final VoidCallback onAdd;
  final VoidCallback onClear;
  final VoidCallback onSave;
  final VoidCallback onSpeak;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signSpeakControllerProvider);
    final detection = state.detection;
    final percent = (detection.confidence * 100).round();
    final isUnclear = detection.level == ConfidenceLevel.low;

    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(state.scanSequence ~/ 2),
      tween: Tween<double>(begin: isUnclear ? -8 : 0, end: 0),
      duration: const Duration(milliseconds: 360),
      curve: Curves.elasticOut,
      builder: (context, offset, child) {
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SignStat(
                    label: 'Detected Word',
                    value: detection.word,
                    color: confidenceColor(detection.confidence),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ConfidenceMeter(confidence: detection.confidence),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    '$percent%',
                    key: ValueKey<int>(percent),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: confidenceColor(detection.confidence),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SignalChip(
                  icon: Icons.back_hand_rounded,
                  label: detection.hasHand ? 'Tracking live' : 'Place hand',
                  active: detection.handCount > 0,
                ),
                const _SignalChip(
                  icon: Icons.center_focus_strong_rounded,
                  label: 'Live AI',
                  active: true,
                ),
                const _SignalChip(
                  icon: Icons.translate_rounded,
                  label: 'Translation',
                  active: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _TypingSentence(sentence: state.typedSentence),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_rounded),
                  label: const Text('Clear'),
                ),
                OutlinedButton.icon(
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Speak'),
                ),
                IconButton.filledTonal(
                  tooltip: 'Save',
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_add_rounded),
                ),
                IconButton.filledTonal(
                  tooltip: 'Copy',
                  onPressed: state.sentence.isEmpty ? null : onCopy,
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignStat extends StatelessWidget {
  const _SignStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(minHeight: 86),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: Text(
              value,
              key: ValueKey<String>(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active ? theme.colorScheme.secondary : Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingSentence extends StatelessWidget {
  const _TypingSentence({required this.sentence});

  final String sentence;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey<String>(sentence),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          sentence,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.34),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(tooltip: '', onPressed: onPressed, icon: Icon(icon)),
    );
  }
}

class _SuccessPulse extends StatelessWidget {
  const _SuccessPulse({required this.successPulse});

  final int successPulse;

  @override
  Widget build(BuildContext context) {
    if (successPulse == 0) {
      return const SizedBox.shrink();
    }
    return Center(
      child: TweenAnimationBuilder<double>(
        key: ValueKey<int>(successPulse),
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: (1 - value).clamp(0.0, 1.0).toDouble(),
            child: Transform.scale(
              scale: 0.8 + value * 1.2,
              child: Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF28E0B5).withValues(alpha: 0.9),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF28E0B5).withValues(alpha: 0.4),
                      blurRadius: 32,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF28E0B5),
                  size: 72,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AiLoadingOverlay extends StatelessWidget {
  const _AiLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: GlassPanel(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Loading AI model',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
