import 'package:flutter/material.dart';

/// A rounded speech bubble with a tail pointing at whoever is speaking.
///
/// The tail is the whole reason this exists. A plain rounded card beside a
/// character reads as a caption *about* it; a tail makes the same words read
/// as coming *from* it — which is the difference between a label and a
/// character talking to you, and the effect the Clash of Clans advisor gets
/// for free by pointing her bubble at herself.
///
/// Drawn as one path rather than a box plus a rotated triangle, so the tail
/// joins the body seamlessly: an overlapping triangle shows a seam wherever
/// the bubble is translucent or shadowed, and this bubble is both.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = 16,
    this.tailSize = 10,
    this.tailTopOffset = 22,
    this.padding = const EdgeInsets.all(14),
    this.shadow,
  });

  final Widget child;
  final Color color;
  final double borderRadius;

  /// How far the tail sticks out to the left, and half its height.
  final double tailSize;

  /// Distance from the bubble's top to the tail's tip. Fixed rather than
  /// centred so the tail keeps pointing at the character's head as the
  /// message grows taller — a centred tail drifts down past a talking head
  /// on a three-line message and starts pointing at its feet.
  final double tailTopOffset;

  final EdgeInsets padding;
  final BoxShadow? shadow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpeechBubblePainter(
        color: color,
        borderRadius: borderRadius,
        tailSize: tailSize,
        tailTopOffset: tailTopOffset,
        shadow: shadow,
      ),
      child: Padding(
        // Leave room for the tail so the text never runs under it.
        padding: padding.copyWith(left: padding.left + tailSize),
        child: child,
      ),
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  _SpeechBubblePainter({
    required this.color,
    required this.borderRadius,
    required this.tailSize,
    required this.tailTopOffset,
    required this.shadow,
  });

  final Color color;
  final double borderRadius;
  final double tailSize;
  final double tailTopOffset;
  final BoxShadow? shadow;

  Path _buildPath(Size size) {
    final body = RRect.fromLTRBR(
      tailSize,
      0,
      size.width,
      size.height,
      Radius.circular(borderRadius),
    );

    // Keep the tail clear of the rounded corners, so it meets a straight
    // edge rather than sprouting from a curve.
    final lowest = borderRadius + tailSize;
    final highest = size.height - borderRadius - tailSize;

    // A one-line bubble is shorter than both margins combined, which
    // leaves no straight edge at all — and asking clamp for a range whose
    // maximum is below its minimum throws. That is not theoretical: it
    // took out the entire guide bubble on every screen, silently, because
    // a painter that throws simply paints nothing. Centre the tail
    // instead; on a bubble that small it is the only place it fits.
    final tip = highest <= lowest
        ? size.height / 2
        : tailTopOffset.clamp(lowest, highest);

    return Path()
      ..addRRect(body)
      ..moveTo(tailSize, tip - tailSize)
      ..lineTo(0, tip)
      ..lineTo(tailSize, tip + tailSize)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    final boxShadow = shadow;
    if (boxShadow != null) {
      canvas.drawPath(
        path.shift(boxShadow.offset),
        Paint()
          ..color = boxShadow.color
          // BoxShadow.blurSigma, not blurRadius: it is the same conversion
          // BoxDecoration applies internally, so this bubble and every
          // Container card in the app read identically for one value.
          // Passing the radius straight through gives a far heavier shadow.
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            boxShadow.blurSigma,
          ),
      );
    }

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SpeechBubblePainter old) {
    return old.color != color ||
        old.borderRadius != borderRadius ||
        old.tailSize != tailSize ||
        old.tailTopOffset != tailTopOffset ||
        old.shadow != shadow;
  }
}
