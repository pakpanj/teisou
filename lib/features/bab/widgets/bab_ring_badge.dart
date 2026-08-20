import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/module_card_frame.dart';

/// A circular badge (level key, chapter number, a checkmark, a lock) with
/// a sakura wreath ring around its rim — the "wreath" motif the reference
/// design uses for both the level cards and the chapter cards. Purely
/// decorative beyond the badge itself; the wreath is skipped when
/// [showPetals] is false so a muted/locked card doesn't wear the same
/// festive ring as an active one.
///
/// The ring is `assets/module_frames/frame_level_badge.png` (see
/// `scripts/module_frame_asset_prompts.md`, prompt #5) — a real generated
/// illustration, not the code-drawn dot ring this widget used before. The
/// wreath's own pink stays fixed regardless of [color]; per-level/per-
/// module colour coding still reads through the inner circle's border and
/// fill, which was always the more prominent signal of the two.
class BabRingBadge extends StatelessWidget {
  final double size;
  final Color color;
  final Widget child;
  final bool showPetals;

  const BabRingBadge({
    super.key,
    required this.size,
    required this.color,
    required this.child,
    this.showPetals = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showPetals)
            Image.asset(
              frameAsset(context, 'frame_level_badge'),
              width: size,
              height: size,
              errorBuilder: (context, error, stackTrace) => CustomPaint(
                size: Size(size, size),
                painter: _PetalRingPainter(color: color),
              ),
            ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Fallback for [BabRingBadge] if the bundled wreath art is ever missing —
/// the original code-drawn dot ring this widget used before real art
/// existed for it.
class _PetalRingPainter extends CustomPainter {
  final Color color;

  const _PetalRingPainter({required this.color});

  static const _petalCount = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final ringRadius = size.width * 0.42;
    final paint = Paint()..color = color.withValues(alpha: 0.55);

    for (var i = 0; i < _petalCount; i++) {
      final angle = (2 * math.pi / _petalCount) * i;
      final x = cx + ringRadius * math.cos(angle);
      final y = cy + ringRadius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), size.width * 0.045, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PetalRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The pill-shaped percentage readout beside a progress bar ("0%").
class BabPercentPill extends StatelessWidget {
  final int percent;
  final Color color;

  const BabPercentPill({super.key, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// The small dashed connector drawn above a locked card's lock icon,
/// suggesting a path continuing down from the chapter above it.
class BabPathConnector extends StatelessWidget {
  final Color color;

  const BabPathConnector({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
      height: 16,
      child: CustomPaint(painter: _DashPainter(color: color)),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;

  const _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashHeight = 3.0;
    const gap = 3.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, math.min(y + dashHeight, size.height)),
        paint,
      );
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A circular chevron button — the white "go" affordance on the right of
/// an active/available card.
class BabChevronButton extends StatelessWidget {
  final Color color;
  final double size;

  const BabChevronButton({super.key, required this.color, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.chevron_right, color: color, size: size * 0.6),
    );
  }
}
