import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Simplified maneki-neko (beckoning cat) illustration shown on the exam
/// result screen: white cat, one paw raised, holding a gold coin.
class ManekiNekoMascot extends StatelessWidget {
  final double size;

  const ManekiNekoMascot({super.key, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.hiraganaCardBg,
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: CustomPaint(painter: _ManekiNekoPainter()),
    );
  }
}

class _ManekiNekoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyPaint = Paint()..color = Colors.white;
    final outlinePaint = Paint()
      ..color = AppColors.textNavy.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02;
    final pinkPaint = Paint()..color = const Color(0xFFF4A6B7);
    final goldPaint = Paint()..color = const Color(0xFFE8B84B);

    // Body.
    final bodyRect = Rect.fromLTWH(w * 0.18, h * 0.38, w * 0.64, h * 0.55);
    final bodyRRect = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(w * 0.28),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);
    canvas.drawRRect(bodyRRect, outlinePaint);

    // Head.
    final headCenter = Offset(w * 0.5, h * 0.32);
    final headRadius = w * 0.28;
    canvas.drawCircle(headCenter, headRadius, bodyPaint);
    canvas.drawCircle(headCenter, headRadius, outlinePaint);

    // Ears.
    final leftEar = Path()
      ..moveTo(w * 0.28, h * 0.16)
      ..lineTo(w * 0.36, h * 0.02)
      ..lineTo(w * 0.44, h * 0.16)
      ..close();
    final rightEar = Path()
      ..moveTo(w * 0.56, h * 0.16)
      ..lineTo(w * 0.64, h * 0.02)
      ..lineTo(w * 0.72, h * 0.16)
      ..close();
    canvas.drawPath(leftEar, bodyPaint);
    canvas.drawPath(rightEar, bodyPaint);
    canvas.drawPath(leftEar, outlinePaint);
    canvas.drawPath(rightEar, outlinePaint);

    // Inner ears.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.32, h * 0.13)
        ..lineTo(w * 0.36, h * 0.05)
        ..lineTo(w * 0.40, h * 0.13)
        ..close(),
      pinkPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.60, h * 0.13)
        ..lineTo(w * 0.64, h * 0.05)
        ..lineTo(w * 0.68, h * 0.13)
        ..close(),
      pinkPaint,
    );

    // Eyes.
    final eyePaint = Paint()..color = AppColors.textNavy;
    canvas.drawCircle(Offset(w * 0.42, h * 0.32), w * 0.025, eyePaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.32), w * 0.025, eyePaint);

    // Nose.
    canvas.drawCircle(Offset(w * 0.5, h * 0.37), w * 0.02, pinkPaint);

    // Whiskers.
    final whiskerPaint = Paint()
      ..color = AppColors.textNavy.withValues(alpha: 0.4)
      ..strokeWidth = w * 0.008;
    for (final dy in [-0.02, 0.0, 0.02]) {
      canvas.drawLine(
        Offset(w * 0.30, h * (0.38 + dy)),
        Offset(w * 0.40, h * (0.37 + dy)),
        whiskerPaint,
      );
      canvas.drawLine(
        Offset(w * 0.60, h * (0.37 + dy)),
        Offset(w * 0.70, h * (0.38 + dy)),
        whiskerPaint,
      );
    }

    // Raised paw (right side, beckoning).
    final pawRect = Rect.fromLTWH(w * 0.62, h * 0.28, w * 0.16, h * 0.28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(pawRect, Radius.circular(w * 0.08)),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pawRect, Radius.circular(w * 0.08)),
      outlinePaint,
    );

    // Gold coin (koban).
    final coinCenter = Offset(w * 0.82, h * 0.5);
    canvas.drawOval(
      Rect.fromCenter(center: coinCenter, width: w * 0.22, height: h * 0.14),
      goldPaint,
    );
    final coinLinePaint = Paint()
      ..color = AppColors.textNavy.withValues(alpha: 0.5)
      ..strokeWidth = w * 0.01
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(coinCenter.dx - w * 0.05, coinCenter.dy),
      Offset(coinCenter.dx + w * 0.05, coinCenter.dy),
      coinLinePaint,
    );

    // Collar & bell.
    final collarPaint = Paint()..color = const Color(0xFFF4667A);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.36, h * 0.46, w * 0.28, h * 0.05),
      collarPaint,
    );
    canvas.drawCircle(Offset(w * 0.5, h * 0.53), w * 0.03, goldPaint);
  }

  @override
  bool shouldRepaint(covariant _ManekiNekoPainter oldDelegate) => false;
}
