import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// The wide sakura illustration sitting between the Skor Global/Clan tab
/// bar and the clan picker — purely decorative, no text or controls drawn
/// on top of it, so this is just an [Image.asset] at a fixed height, not a
/// background layer other widgets need to sit inside of.
///
/// Two separate PNGs (day for light theme, night for dark theme), swapped
/// by [Theme.of(context).brightness] rather than one image with a runtime
/// colour filter — a flat illustration can't be relit convincingly by a
/// filter, and both were generated with their scene already fading into
/// the exact matching app background colour at the top/bottom edges
/// (`#FFFFFF` / `#121620`), so each only ever needs to sit on its own
/// matching background to look seamless.
class ClanLeaderboardBanner extends StatelessWidget {
  const ClanLeaderboardBanner({super.key});

  static const _height = 132.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = isDark
        ? 'assets/leaderboard/clan_banner_dark.png'
        : 'assets/leaderboard/clan_banner_light.png';

    return SizedBox(
      width: double.infinity,
      height: _height,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        // No error/placeholder art needed the way avatar/clan-icon presets
        // need one — this is bundled at build time, not user-generated, so
        // a missing file is a packaging bug to fix, not a runtime state to
        // degrade gracefully from. Still won't crash the screen: a failed
        // Image.asset just leaves this strip blank.
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}

/// [ClanLeaderboardBanner] with a green gradient wash over its own bottom
/// edge, so the banner dissolves into the tab picker's green pills instead
/// of cutting hard into the plain white/dark content below it — the seam
/// was clearly visible once the tab picker above it turned green, since
/// the banner's own bottom edge only fades toward the *page* background
/// colour, not toward that new green. Use this instead of the bare banner
/// everywhere the leaderboard tabs render one.
class LeaderboardBannerHeader extends StatelessWidget {
  const LeaderboardBannerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ClanLeaderboardBanner(),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 46,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    context.palette.successGreen.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
