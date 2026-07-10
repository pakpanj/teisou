import 'package:flutter/material.dart';

/// Stylized Mt. Fuji + torii gate scenery used along the bottom of the
/// Home, Flashcard, and exam-adjacent screens.
class MountainScenery extends StatelessWidget {
  final double height;
  final Color skyColor;
  final Color mountainColor;

  const MountainScenery({
    super.key,
    this.height = 160,
    this.skyColor = const Color(0xFF7C93B8),
    this.mountainColor = const Color(0xFF4A5F82),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _MountainPainter(
          skyColor: skyColor,
          mountainColor: mountainColor,
        ),
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  final Color skyColor;
  final Color mountainColor;

  _MountainPainter({required this.skyColor, required this.mountainColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skyColor.withValues(alpha: 0.35), skyColor.withValues(alpha: 0.75)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final farMountain = Paint()..color = mountainColor.withValues(alpha: 0.45);
    final farPath = Path()
      ..moveTo(0, size.height * 0.65)
      ..lineTo(size.width * 0.25, size.height * 0.35)
      ..lineTo(size.width * 0.5, size.height * 0.65)
      ..close();
    canvas.drawPath(farPath, farMountain);

    final fujiPaint = Paint()..color = mountainColor;
    final fujiPath = Path()
      ..moveTo(size.width * 0.32, size.height * 0.75)
      ..lineTo(size.width * 0.55, size.height * 0.18)
      ..lineTo(size.width * 0.78, size.height * 0.75)
      ..close();
    canvas.drawPath(fujiPath, fujiPaint);

    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final snowPath = Path()
      ..moveTo(size.width * 0.55, size.height * 0.18)
      ..lineTo(size.width * 0.62, size.height * 0.32)
      ..lineTo(size.width * 0.55, size.height * 0.30)
      ..lineTo(size.width * 0.48, size.height * 0.32)
      ..close();
    canvas.drawPath(snowPath, snowPaint);

    final groundPaint = Paint()..color = mountainColor.withValues(alpha: 0.85);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.75, size.width, size.height * 0.25),
      groundPaint,
    );

    _drawTorii(canvas, size);
  }

  void _drawTorii(Canvas canvas, Size size) {
    final toriiPaint = Paint()
      ..color = const Color(0xFFD1495B)
      ..strokeWidth = size.height * 0.035
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.85;
    final baseY = size.height * 0.75;
    final topY = size.height * 0.5;
    final legOffset = size.width * 0.045;

    canvas.drawLine(Offset(cx - legOffset, baseY), Offset(cx - legOffset, topY), toriiPaint);
    canvas.drawLine(Offset(cx + legOffset, baseY), Offset(cx + legOffset, topY), toriiPaint);
    canvas.drawLine(
      Offset(cx - legOffset * 2.2, topY),
      Offset(cx + legOffset * 2.2, topY),
      toriiPaint,
    );
    canvas.drawLine(
      Offset(cx - legOffset * 1.6, topY - size.height * 0.06),
      Offset(cx + legOffset * 1.6, topY - size.height * 0.06),
      toriiPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MountainPainter oldDelegate) =>
      oldDelegate.skyColor != skyColor || oldDelegate.mountainColor != mountainColor;
}
