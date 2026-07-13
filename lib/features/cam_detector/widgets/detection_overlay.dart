import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/japanese_text_filter.dart';

/// A single Japanese text block detected in the current camera frame,
/// with its bounding box already scaled from camera-image pixel space to
/// the preview widget's coordinate space.
class ScaledDetection {
  final TextBlock block;
  final Rect rect;

  ScaledDetection({required this.block, required this.rect});
}

/// Draws a rounded-rect outline over every detected Japanese text block
/// and hosts an invisible tap target on top of each, matching
/// [ScaledDetection.rect]. The block with the largest area is highlighted
/// as the "most prominent" detection so tapping isn't required to pick
/// something to look up.
class DetectionOverlay extends StatelessWidget {
  final List<ScaledDetection> detections;
  final ScaledDetection? prominent;
  final ValueChanged<TextBlock> onTapBlock;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.prominent,
    required this.onTapBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _BoxPainter(detections: detections, prominent: prominent),
          ),
        ),
        ...detections.map(
          (d) => Positioned.fromRect(
            rect: d.rect,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTapBlock(d.block),
            ),
          ),
        ),
      ],
    );
  }
}

class _BoxPainter extends CustomPainter {
  final List<ScaledDetection> detections;
  final ScaledDetection? prominent;

  _BoxPainter({required this.detections, required this.prominent});

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      final isProminent = detection == prominent;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isProminent ? 3 : 1.5
        ..color = isProminent ? AppColors.primaryCoral : Colors.white.withValues(alpha: 0.8);
      final rrect = RRect.fromRectAndRadius(detection.rect, const Radius.circular(6));
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) =>
      oldDelegate.detections != detections || oldDelegate.prominent != prominent;
}

/// Scales ML Kit's [RecognizedText] bounding boxes (in camera-image pixel
/// space) into the preview widget's coordinate space, filtering out
/// blocks with no Japanese characters.
///
/// [imageSize] must be the same width/height passed to the [InputImage]
/// that was recognized (i.e. the raw camera sensor frame, which for a
/// portrait-locked back camera is typically landscape — width/height
/// swapped relative to the portrait preview). [previewSize] is the size
/// of the widget the preview/overlay are laid out in.
List<ScaledDetection> scaleDetections({
  required RecognizedText recognizedText,
  required Size imageSize,
  required Size previewSize,
}) {
  final scaleX = previewSize.width / imageSize.height;
  final scaleY = previewSize.height / imageSize.width;

  final result = <ScaledDetection>[];
  for (final block in recognizedText.blocks) {
    if (!containsJapanese(block.text)) continue;
    final box = block.boundingBox;
    // Image pixel space is rotated 90° relative to the portrait preview:
    // image-x maps to preview-y, image-y maps to (mirrored) preview-x.
    final rect = Rect.fromLTRB(
      previewSize.width - box.bottom * scaleX,
      box.left * scaleY,
      previewSize.width - box.top * scaleX,
      box.right * scaleY,
    );
    result.add(ScaledDetection(block: block, rect: rect));
  }
  return result;
}
