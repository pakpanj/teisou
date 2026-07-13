import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import 'widgets/detection_overlay.dart';
import 'widgets/detection_result_sheet.dart';

enum _CamState {
  initializing,
  permissionDenied,
  permissionPermanentlyDenied,
  noCamera,
  error,
  ready,
}

/// Live camera preview that scans for Japanese text (hiragana/katakana/
/// kanji) using on-device ML Kit OCR, throttled to roughly one frame a
/// second. Tapping a detected block (or the auto-highlighted "most
/// prominent" one) opens [DetectionResultSheet] with a dictionary lookup.
class CamDetectorScreen extends StatefulWidget {
  const CamDetectorScreen({super.key});

  @override
  State<CamDetectorScreen> createState() => _CamDetectorScreenState();
}

class _CamDetectorScreenState extends State<CamDetectorScreen>
    with WidgetsBindingObserver {
  static const _throttle = Duration(milliseconds: 700);

  final _recognizer = TextRecognizer(script: TextRecognitionScript.japanese);

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  _CamState _state = _CamState.initializing;
  String? _errorMessage;

  bool _isPaused = false;
  bool _isProcessingFrame = false;
  DateTime? _lastProcessedAt;
  RecognizedText? _lastRecognizedText;
  Size? _lastImageSize;
  int _recognitionFailureStreak = 0;
  bool _showRecognitionWarning = false;

  FlashMode _flashMode = FlashMode.off;

  /// Bumped every time a controller is started or disposed, so an in-flight
  /// [_startController] call that gets superseded by a newer dispose/start
  /// (e.g. rapid background/foreground toggling) can tell it's stale and
  /// avoid resurrecting a disposed controller or clobbering a newer one.
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _requestPermissionAndInit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _disposeController();
    _recognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_controller == null) return;
      _disposeController();
      // The widget tree may still hold a CameraPreview built with the
      // controller we just disposed — rebuild now so it's dropped before
      // Flutter tries to reattach/repaint that stale surface on resume.
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      // Only reconnect if we actually own a camera session that got
      // released while backgrounded — not during initial permission/
      // camera setup, and not if the user is looking at an error state.
      if (_controller == null && _state == _CamState.ready && _cameras.isNotEmpty) {
        _startController(_cameras[_cameraIndex]);
      }
    }
  }

  Future<void> _requestPermissionAndInit() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      await _initCameras();
    } else if (status.isPermanentlyDenied) {
      setState(() => _state = _CamState.permissionPermanentlyDenied);
    } else {
      setState(() => _state = _CamState.permissionDenied);
    }
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _CamState.noCamera);
      return;
    }
    if (_cameras.isEmpty) {
      setState(() => _state = _CamState.noCamera);
      return;
    }

    final backIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
    _cameraIndex = backIndex == -1 ? 0 : backIndex;
    await _startController(_cameras[_cameraIndex]);
  }

  Future<void> _startController(CameraDescription description) async {
    final generation = ++_requestGeneration;
    final controller = CameraController(
      description,
      // .medium (720x480) was noticeably too low-res for OCR to read small
      // text accurately; .high trades a bit of throughput for much better
      // recognition quality, still comfortably inside the 700ms throttle.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await controller.initialize();
    } catch (_) {
      if (!mounted || generation != _requestGeneration) {
        controller.dispose();
        return;
      }
      setState(() {
        _state = _CamState.error;
        _errorMessage = 'Gagal membuka kamera. Coba lagi.';
      });
      return;
    }

    // Superseded by a newer start/dispose (e.g. rapid background/foreground
    // toggling) while initialize() was in flight — discard this one instead
    // of resurrecting it into `_controller`.
    if (!mounted || generation != _requestGeneration) {
      controller.dispose();
      return;
    }

    _controller = controller;
    _flashMode = FlashMode.off;
    _recognitionFailureStreak = 0;
    setState(() {
      _state = _CamState.ready;
      _showRecognitionWarning = false;
    });
    await controller.startImageStream(_processCameraImage);
  }

  Future<void> _disposeController() async {
    _requestGeneration++;
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {
      // Already stopped/disposed — nothing to clean up.
    }
    await controller.dispose();
  }

  void _processCameraImage(CameraImage image) {
    if (_isPaused || _isProcessingFrame) return;
    final now = DateTime.now();
    if (_lastProcessedAt != null && now.difference(_lastProcessedAt!) < _throttle) return;

    final controller = _controller;
    if (controller == null || image.planes.isEmpty) return;

    final inputImage = _toInputImage(image, controller.description);
    if (inputImage == null) return;

    _isProcessingFrame = true;
    _lastProcessedAt = now;

    _recognizer.processImage(inputImage).then((recognizedText) {
      _isProcessingFrame = false;
      if (!mounted) return;
      setState(() {
        _lastRecognizedText = recognizedText;
        _lastImageSize = Size(image.width.toDouble(), image.height.toDouble());
        _recognitionFailureStreak = 0;
        _showRecognitionWarning = false;
      });
    }).catchError((_) {
      _isProcessingFrame = false;
      if (!mounted) return;
      _recognitionFailureStreak++;
      // A handful of consecutive failures usually means the on-device
      // Japanese OCR model hasn't finished its (one-time, Play Services)
      // background download yet — surface a hint instead of silently
      // never showing any detections.
      if (_recognitionFailureStreak >= 5 && !_showRecognitionWarning) {
        setState(() => _showRecognitionWarning = true);
      }
    });
  }

  /// Converts a raw [CameraImage] frame into ML Kit's [InputImage]. Assumes
  /// the screen is locked to portrait (see [initState]), which lets the
  /// rotation compensation collapse to the camera's sensor orientation
  /// directly instead of also tracking live device rotation.
  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    final rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.rotation0deg;
    final format = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _lastRecognizedText = null;
        _lastImageSize = null;
      }
    });
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = _flashMode == FlashMode.torch ? FlashMode.off : FlashMode.torch;
    try {
      await controller.setFlashMode(next);
      if (!mounted) return;
      setState(() => _flashMode = next);
    } catch (_) {
      // Some devices/lenses don't support torch — ignore silently.
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    await _disposeController();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    setState(() {
      _lastRecognizedText = null;
      _lastImageSize = null;
      _recognitionFailureStreak = 0;
      _showRecognitionWarning = false;
    });
    await _startController(_cameras[_cameraIndex]);
  }

  void _showResult(String text) {
    setState(() {
      _isPaused = true;
      _lastRecognizedText = null;
      _lastImageSize = null;
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetectionResultSheet(text: text),
    ).whenComplete(() {
      if (!mounted) return;
      setState(() => _isPaused = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Cam Detector'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _CamState.initializing:
        return const _CenteredMessage(
          icon: null,
          message: 'Menyiapkan kamera...',
          showSpinner: true,
        );
      case _CamState.permissionDenied:
        return _CenteredMessage(
          icon: Icons.camera_alt_outlined,
          message:
              'Izin kamera dibutuhkan untuk memindai karakter Jepang. '
              'Aplikasi tidak akan mengirim gambar kamu kemana pun.',
          actionLabel: 'Izinkan Kamera',
          onAction: _requestPermissionAndInit,
        );
      case _CamState.permissionPermanentlyDenied:
        return _CenteredMessage(
          icon: Icons.camera_alt_outlined,
          message:
              'Izin kamera ditolak permanen. Buka Pengaturan untuk '
              'mengaktifkannya secara manual.',
          actionLabel: 'Buka Pengaturan',
          onAction: openAppSettings,
        );
      case _CamState.noCamera:
        return const _CenteredMessage(
          icon: Icons.videocam_off_outlined,
          message: 'Tidak ada kamera yang tersedia di perangkat ini.',
        );
      case _CamState.error:
        return _CenteredMessage(
          icon: Icons.error_outline,
          message: _errorMessage ?? 'Terjadi kesalahan.',
          actionLabel: 'Coba Lagi',
          onAction: _initCameras,
        );
      case _CamState.ready:
        return _buildCameraView();
    }
  }

  Widget _buildCameraView() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const _CenteredMessage(
        icon: null,
        message: 'Menyiapkan kamera...',
        showSpinner: true,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = Size(constraints.maxWidth, constraints.maxHeight);
        final recognizedText = _lastRecognizedText;
        final imageSize = _lastImageSize;
        final detections = (recognizedText != null && imageSize != null && !_isPaused)
            ? scaleDetections(
                recognizedText: recognizedText,
                imageSize: imageSize,
                previewSize: previewSize,
              )
            : const <ScaledDetection>[];
        final prominent = detections.isEmpty
            ? null
            : detections.reduce(
                (a, b) => (a.rect.width * a.rect.height) > (b.rect.width * b.rect.height) ? a : b,
              );

        return Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            DetectionOverlay(
              detections: detections,
              prominent: prominent,
              onTapBlock: (block) => _showResult(block.text),
            ),
            const _ScanFrameGuide(),
            if (_showRecognitionWarning)
              Positioned(
                top: 12,
                left: 12,
                right: 72,
                child: _RecognitionWarningBanner(
                  onDismiss: () => setState(() => _showRecognitionWarning = false),
                ),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                children: [
                  _RoundIconButton(
                    icon: _flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off,
                    onTap: _toggleFlash,
                    tooltip: 'Nyala/Matikan Flash',
                  ),
                  const SizedBox(height: 8),
                  if (_cameras.length > 1)
                    _RoundIconButton(
                      icon: Icons.cameraswitch,
                      onTap: _switchCamera,
                      tooltip: 'Ganti Kamera',
                    ),
                ],
              ),
            ),
            if (prominent != null && !_isPaused)
              Positioned(
                left: 16,
                right: 16,
                bottom: 96,
                child: _ProminentResultChip(
                  text: prominent.block.text,
                  onTap: () => _showResult(prominent.block.text),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Center(
                child: _RoundIconButton(
                  icon: _isPaused ? Icons.play_arrow : Icons.pause,
                  onTap: _togglePause,
                  tooltip: _isPaused ? 'Lanjutkan Deteksi' : 'Jeda Deteksi',
                  large: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecognitionWarningBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const _RecognitionWarningBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Model pengenalan teks belum siap. Pastikan koneksi '
                'internet aktif untuk pemakaian pertama, lalu coba lagi.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            InkWell(
              onTap: onDismiss,
              child: const Icon(Icons.close, color: Colors.white70, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFrameGuide extends StatelessWidget {
  const _ScanFrameGuide();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.85,
          heightFactor: 0.4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool large;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: large ? 32 : 22),
        padding: EdgeInsets.all(large ? 16 : 10),
      ),
    );
  }
}

class _ProminentResultChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ProminentResultChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryCoral,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData? icon;
  final String message;
  final bool showSpinner;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CenteredMessage({
    required this.icon,
    required this.message,
    this.showSpinner = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              const CircularProgressIndicator(color: Colors.white)
            else if (icon != null)
              Icon(icon, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
