import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/sakura_decoration.dart';
import '../../../core/widgets/sakura_fall_widget.dart';
import '../../../core/widgets/seigaiha_wave.dart';

/// The soft blush backdrop behind both Bab screens (level picker and
/// chapter list) — a gentle gradient, a faint torii/pagoda skyline, a
/// sakura branch in the corner, drifting petals, and a wave wash at the
/// very bottom. Purely decorative: every piece is `IgnorePointer`-ed or
/// painted behind the real content, so it never competes for a tap.
///
/// Built from pieces this app already has rather than inventing new visual
/// language — [SakuraDecoration] and [SakuraFallWidget] are the same ones
/// `HomeScreen` uses; only the mountain skyline below is new, since
/// nothing existing drew one.
class BabDecorativeBackground extends StatelessWidget {
  final Widget child;

  const BabDecorativeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.hiraganaCardBg, palette.background],
                stops: const [0.0, 0.55],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IgnorePointer(
            child: SizedBox(
              width: 260,
              height: 150,
              child: CustomPaint(
                painter: _SkylinePainter(
                  color: palette.textNavy.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          // Deliberately mostly off-screen — only its bottom-left corner
          // (where the smallest petals are) should ever graze the first
          // card. A larger/lower placement drapes across that card's
          // progress bar and percentage pill, which shipped once and was
          // caught on a physical device: legible text sitting under an
          // 85%-opaque petal is not a flourish, it's a bug.
          top: -36,
          right: -36,
          child: IgnorePointer(
            child: SakuraDecoration(size: 64),
          ),
        ),
        const Positioned.fill(child: SakuraFallWidget(particleCount: 6)),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 90,
          child: SeigaihaWave(
            color: palette.primaryCoral.withValues(alpha: 0.08),
          ),
        ),
        child,
      ],
    );
  }
}

/// A quiet torii + pagoda silhouette sitting on a couple of overlapping
/// mountain humps — one flat low-alpha colour, no internal detail, the
/// same "just a skyline, not an illustration" restraint as the rest of
/// this decoration set.
class _SkylinePainter extends CustomPainter {
  final Color color;

  const _SkylinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final w = size.width;
    final h = size.height;

    // Two overlapping mountain humps along the bottom of the strip.
    final mountains = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.55)
      ..quadraticBezierTo(w * 0.22, h * 0.25, w * 0.42, h * 0.5)
      ..quadraticBezierTo(w * 0.62, h * 0.7, w * 0.8, h * 0.35)
      ..quadraticBezierTo(w * 0.92, h * 0.18, w, h * 0.4)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(mountains, fill);

    // Torii gate on the left third of the skyline.
    final toriiX = w * 0.22;
    final toriiBaseY = h * 0.5;
    final toriiTopY = h * 0.28;
    canvas.drawLine(
      Offset(toriiX - 14, toriiBaseY),
      Offset(toriiX - 14, toriiTopY),
      stroke,
    );
    canvas.drawLine(
      Offset(toriiX + 14, toriiBaseY),
      Offset(toriiX + 14, toriiTopY),
      stroke,
    );
    canvas.drawLine(
      Offset(toriiX - 20, toriiTopY),
      Offset(toriiX + 20, toriiTopY),
      stroke,
    );
    canvas.drawLine(
      Offset(toriiX - 24, toriiTopY - 8),
      Offset(toriiX + 24, toriiTopY - 8),
      stroke,
    );

    // Pagoda on the right, three stacked roof tiers.
    final pagodaX = w * 0.78;
    final pagodaBaseY = h * 0.32;
    for (var tier = 0; tier < 3; tier++) {
      final tierWidth = 30.0 - tier * 7;
      final tierY = pagodaBaseY - tier * 16;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(pagodaX, tierY),
          width: tierWidth,
          height: 4,
        ),
        fill,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(pagodaX, tierY + 8),
          width: tierWidth * 0.5,
          height: 12,
        ),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkylinePainter oldDelegate) =>
      oldDelegate.color != color;
}
