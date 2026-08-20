import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/mascot_widget.dart';
import '../../../core/widgets/sakura_fall_widget.dart';

/// The banner at the top of Home: Mt. Fuji, sakura trees and the waving
/// maneki-neko. **Light theme only.** `assets/banners/home_hero.png` is a
/// real illustration (cropped from a reference mockup, with the mockup's
/// own title text/status-bar/icon chrome removed via inpainting rather
/// than left in — a flat illustration can't be "relit" for dark mode by a
/// runtime colour filter, the same reasoning [ClanLeaderboardBanner] and
/// [ModuleSkylineBanner] document, so dark mode falls back to
/// [_FujiSakuraPainter] — the same low-alpha, code-drawn scene this screen
/// used before the real asset was cropped, kept only as the dark-mode path
/// now rather than deleted.
class HomeHeroScene extends StatelessWidget {
  const HomeHeroScene({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // A night version of the same scene, exactly as
    // `ClanLeaderboardBanner` and the Card Game backdrop already do it —
    // rather than dark mode dropping to the code-drawn scene, which loses
    // the mascot entirely and reads as a bug (reported from a screenshot).
    // Until `home_hero_dark.png` exists the errorBuilder still catches it,
    // so this costs nothing today and needs no code change when it lands.
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Image.asset(
        isDark
            ? 'assets/banners/home_hero_dark.png'
            : 'assets/banners/home_hero.png',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) => const _CodeDrawnHero(),
      ),
    );
  }
}

class _CodeDrawnHero extends StatelessWidget {
  const _CodeDrawnHero();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.katakanaCardBg, palette.hiraganaCardBg],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _FujiSakuraPainter(
                  // Softer than they were. At alpha 0.5/0.55 these shapes
                  // read as the subject rather than the backdrop they are
                  // — a flat triangle and two circles carrying a screen on
                  // their own, which is what made this look broken next to
                  // the real illustration.
                  fujiColor: palette.secondaryBlue.withValues(alpha: 0.28),
                  snowColor: Colors.white.withValues(alpha: 0.55),
                  canopyColor: palette.primaryCoral.withValues(alpha: 0.3),
                  trunkColor: palette.textNavy.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          const Positioned.fill(child: SakuraFallWidget(particleCount: 5)),
          // **The scene was drawn to sit behind a mascot that was never
          // placed here** — see [_FujiSakuraPainter]'s own doc comment,
          // which says "centered behind the mascot". So dark mode showed
          // the backdrop alone, subject missing, and the app's own
          // character absent from its home screen. The art is a
          // transparent PNG, so it needs no light/dark variant of its own.
          Positioned(
            right: 24,
            bottom: 0,
            child: MascotWidget(
              mood: MascotMood.waving,
              size: 132,
              showBackdrop: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mt. Fuji centered behind the mascot, with a low sakura tree canopy on
/// each side — one flat silhouette and a handful of circles, the same
/// restraint [SakuraDecoration]/[_SkylinePainter] already use elsewhere in
/// this app rather than reaching for photographic detail.
class _FujiSakuraPainter extends CustomPainter {
  final Color fujiColor;
  final Color snowColor;
  final Color canopyColor;
  final Color trunkColor;

  const _FujiSakuraPainter({
    required this.fujiColor,
    required this.snowColor,
    required this.canopyColor,
    required this.trunkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fujiPaint = Paint()..color = fujiColor;
    final snowPaint = Paint()..color = snowColor;

    // Mt. Fuji: a single wide triangle, peak toward the left third so the
    // mascot (centered, slightly toward the right half) stands clear of
    // the summit rather than directly in front of it.
    final peak = Offset(w * 0.4, h * 0.14);
    final fuji = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(w * 0.02, h * 0.6)
      ..lineTo(w * 0.86, h * 0.6)
      ..close();
    canvas.drawPath(fuji, fujiPaint);

    // Snow cap: a smaller, notched triangle at the summit.
    final snow = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(peak.dx - w * 0.09, peak.dy + h * 0.14)
      ..lineTo(peak.dx - w * 0.03, peak.dy + h * 0.1)
      ..lineTo(peak.dx, peak.dy + h * 0.18)
      ..lineTo(peak.dx + w * 0.04, peak.dy + h * 0.09)
      ..lineTo(peak.dx + w * 0.09, peak.dy + h * 0.13)
      ..close();
    canvas.drawPath(snow, snowPaint);

    void sakuraTree(double trunkX, double baseY, double scale) {
      final trunkPaint = Paint()
        ..color = trunkColor
        ..strokeWidth = 4 * scale
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(trunkX, baseY),
        Offset(trunkX, baseY - h * 0.3 * scale),
        trunkPaint,
      );
      final canopyPaint = Paint()..color = canopyColor;
      final canopyCenter = Offset(trunkX, baseY - h * 0.38 * scale);
      // A denser cluster than a handful of sparse circles — overlapping
      // enough that the canopy reads as one rounded mass, matching the
      // reference mockup's full tree rather than a thin scatter of dots.
      for (final offset in const [
        Offset(0, 0),
        Offset(-0.55, 0.2),
        Offset(0.55, 0.2),
        Offset(-0.75, -0.15),
        Offset(0.75, -0.15),
        Offset(-0.25, -0.45),
        Offset(0.3, -0.42),
        Offset(0, -0.62),
        Offset(-0.4, -0.68),
        Offset(0.45, -0.6),
      ]) {
        canvas.drawCircle(
          canopyCenter +
              Offset(offset.dx * w * 0.1, offset.dy * h * 0.22) * scale,
          w * 0.085 * scale,
          canopyPaint,
        );
      }
    }

    sakuraTree(w * 0.1, h * 1.0, 1.05);
    sakuraTree(w * 0.9, h * 1.0, 0.9);
  }

  @override
  bool shouldRepaint(covariant _FujiSakuraPainter oldDelegate) =>
      oldDelegate.fujiColor != fujiColor ||
      oldDelegate.snowColor != snowColor ||
      oldDelegate.canopyColor != canopyColor ||
      oldDelegate.trunkColor != trunkColor;
}
