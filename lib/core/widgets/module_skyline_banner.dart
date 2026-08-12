import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// The Fuji/torii/pagoda skyline strip sitting behind a module's header —
/// shared across Bunpou/Partikel/Kaiwa/Dokkai/Choukai's home screens, the
/// same "one shared decorative asset reused across every screen that wants
/// it" precedent as [ClanLeaderboardBanner] and [SeigaihaWave].
///
/// **Light theme only.** `assets/module_frames/bg_module_header.png` is a
/// real illustration (generated directly from a written spec, not cropped
/// from a mockup — see `scripts/module_frame_asset_prompts.md`), and a flat
/// illustration like this can't be convincingly "relit" for dark mode by a
/// runtime colour filter — the same reasoning [ClanLeaderboardBanner]
/// documents for why it ships two separate PNGs rather than one plus a
/// filter. Unlike that banner, there's no matching night illustration here
/// to pair it with, so dark mode falls back to [_SkylinePainter] — the
/// same low-alpha, code-drawn silhouette [BabDecorativeBackground] already
/// uses, which was built theme-aware from the start.
class ModuleSkylineBanner extends StatelessWidget {
  final double height;

  const ModuleSkylineBanner({super.key, this.height = 150});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!isDark) {
      return SizedBox(
        width: double.infinity,
        height: height,
        // The source art is a fully opaque photo-style illustration with a
        // hard bottom edge — laid directly over the plain scaffold
        // background below it, that edge read as a visible seam/cut
        // (flagged directly against a screenshot). A bottom-fading
        // ShaderMask dissolves the image itself into transparency over its
        // last quarter, so the scaffold's own background colour takes
        // over gradually instead of the banner just stopping — same fix
        // shape as ClanLeaderboardBanner's own gradient-fade tail.
        child: ShaderMask(
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0.0, 0.7, 1.0],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: Image.asset(
            'assets/module_frames/bg_module_header.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            // Bundled at build time, not user-generated — a missing file is
            // a packaging bug, not a runtime state to degrade gracefully
            // from. Still won't crash the screen: a failed load just leaves
            // the strip blank, same contract as ClanLeaderboardBanner.
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      );
    }
    final palette = context.palette;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _SkylinePainter(color: palette.textNavy.withValues(alpha: 0.08)),
      ),
    );
  }
}

/// A quiet torii + pagoda silhouette on a couple of overlapping mountain
/// humps — the dark-mode fallback for [ModuleSkylineBanner], mirroring
/// [BabDecorativeBackground]'s own private skyline painter closely enough
/// to read as the same visual language, without duplicating that file's
/// private class.
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

    final mountain = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.3, h * 0.5)
      ..lineTo(w * 0.5, h * 0.7)
      ..lineTo(w * 0.68, h * 0.35)
      ..lineTo(w * 0.85, h * 0.6)
      ..lineTo(w, h * 0.45)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(mountain, fill);

    final toriiX = w * 0.72;
    final toriiBaseY = h * 0.68;
    final toriiTopY = h * 0.4;
    canvas.drawLine(
      Offset(toriiX - 16, toriiBaseY),
      Offset(toriiX - 16, toriiTopY),
      stroke,
    );
    canvas.drawLine(
      Offset(toriiX + 16, toriiBaseY),
      Offset(toriiX + 16, toriiTopY),
      stroke,
    );
    canvas.drawLine(
      Offset(toriiX - 22, toriiTopY),
      Offset(toriiX + 22, toriiTopY),
      stroke,
    );
    canvas.drawLine(
      Offset(toriiX - 26, toriiTopY - 8),
      Offset(toriiX + 26, toriiTopY - 8),
      stroke,
    );

    final pagodaX = w * 0.9;
    final pagodaBaseY = h * 0.42;
    for (var tier = 0; tier < 3; tier++) {
      final tierWidth = 26.0 - tier * 6;
      final tierY = pagodaBaseY - tier * 15;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(pagodaX, tierY), width: tierWidth, height: 4),
        fill,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(pagodaX, tierY - 7),
          width: tierWidth * 0.45,
          height: 10,
        ),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkylinePainter oldDelegate) =>
      oldDelegate.color != color;
}
