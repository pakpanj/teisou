import 'package:flutter/material.dart';

/// A small cluster of sakura petals, used as a corner decoration (Home
/// header) or scattered accent (flashcard background).
class SakuraDecoration extends StatelessWidget {
  final double size;
  final Color color;

  const SakuraDecoration({super.key, this.size = 48, this.color = const Color(0xFFF4A6B7)});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SakuraPainter(color: color)),
    );
  }
}

class _SakuraPainter extends CustomPainter {
  final Color color;
  _SakuraPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final petalPaint = Paint()..color = color.withValues(alpha: 0.85);
    final branchPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = size.width * 0.03
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.9),
      Offset(size.width * 0.8, size.height * 0.15),
      branchPaint,
    );

    void petal(Offset center, double r) {
      canvas.drawCircle(center, r, petalPaint);
    }

    petal(Offset(size.width * 0.75, size.height * 0.15), size.width * 0.16);
    petal(Offset(size.width * 0.55, size.height * 0.35), size.width * 0.12);
    petal(Offset(size.width * 0.35, size.height * 0.55), size.width * 0.10);
    petal(Offset(size.width * 0.85, size.height * 0.4), size.width * 0.09);
    petal(Offset(size.width * 0.15, size.height * 0.75), size.width * 0.08);
  }

  @override
  bool shouldRepaint(covariant _SakuraPainter oldDelegate) =>
      oldDelegate.color != color;
}
