import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A faint seigaiha (repeating Japanese wave) wash — purely decorative,
/// low-opacity, meant to sit behind the bottom of a screen. Shared by the
/// Clan leaderboard and the Bab curriculum screens rather than copied,
/// since the shape is genuinely identical between them; only the tint
/// colour differs per caller.
class SeigaihaWave extends StatelessWidget {
  final Color color;

  const SeigaihaWave({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _SeigaihaPainter(color: color),
      ),
    );
  }
}

class _SeigaihaPainter extends CustomPainter {
  final Color color;

  const _SeigaihaPainter({required this.color});

  static const _radius = 20.0;
  static const _rings = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final rowSpacing = _radius * 0.55;
    final rows = (size.height / rowSpacing).ceil() + 1;
    final cols = (size.width / (_radius * 2)).ceil() + 2;

    for (var row = 0; row < rows; row++) {
      final cy = size.height - row * rowSpacing;
      final xOffset = row.isOdd ? _radius : 0.0;
      for (var col = -1; col < cols; col++) {
        final cx = col * _radius * 2 + xOffset;
        for (var ring = 1; ring <= _rings; ring++) {
          final r = _radius * ring / _rings;
          canvas.drawArc(
            Rect.fromCircle(center: Offset(cx, cy), radius: r),
            math.pi,
            math.pi,
            false,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SeigaihaPainter oldDelegate) =>
      oldDelegate.color != color;
}
