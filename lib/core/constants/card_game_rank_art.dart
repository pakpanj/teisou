import 'package:flutter/material.dart';

import '../../data/models/card_game_rank.dart';

/// The colours each tier wears, and the crest that carries them.
///
/// The illustrated badges now live in `assets/ranks/`; the painted
/// shield below stays on as the fallback, and is what these colours
/// still draw. They are also used on their own — behind the division
/// pips, in the progress bar, in the rank card's tint — so they follow
/// the art rather than the tier's name: **Diamond's badge is amethyst
/// purple, not the blue the word suggests**, and a token disagreeing
/// with the picture next to it would read as a bug.
extension CardGameTierArt on CardGameTier {
  Color get crestStart => switch (this) {
    CardGameTier.bronze => const Color(0xFFC98B5E),
    CardGameTier.silver => const Color(0xFFD3DAE3),
    CardGameTier.gold => const Color(0xFFF7CE63),
    CardGameTier.diamond => const Color(0xFFC79BF0),
    CardGameTier.emerald => const Color(0xFF6FD79B),
  };

  Color get crestEnd => switch (this) {
    CardGameTier.bronze => const Color(0xFF8A5433),
    CardGameTier.silver => const Color(0xFF8E99AC),
    CardGameTier.gold => const Color(0xFFC98A15),
    CardGameTier.diamond => const Color(0xFF6A34A8),
    CardGameTier.emerald => const Color(0xFF1F8B57),
  };

  /// Derived from the enum's own name, so there is no second filename
  /// table to fall out of step — the same call `CardSkinPreset` makes.
  String get crestAsset => 'assets/ranks/rank_$name.png';
}

/// A tier's shield.
class RankCrest extends StatelessWidget {
  const RankCrest({super.key, required this.tier, this.size = 56});

  final CardGameTier tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        tier.crestAsset,
        fit: BoxFit.contain,
        // The painted shield is kept rather than deleted, as the
        // fallback: a standing is the thing this whole mode is about,
        // and a missing file must never leave that space empty.
        errorBuilder: (context, _, _) =>
            CustomPaint(painter: _CrestPainter(tier)),
      ),
    );
  }
}

class _CrestPainter extends CustomPainter {
  _CrestPainter(this.tier);

  final CardGameTier tier;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // A shield: square shoulders, sides tapering to a point. Plain
    // enough to stay readable at the 20px it shrinks to in the corner of
    // a skin tile, which is the size that decides the shape.
    final shield = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.92, h * 0.2)
      ..lineTo(w * 0.92, h * 0.52)
      ..quadraticBezierTo(w * 0.92, h * 0.86, w * 0.5, h * 0.97)
      ..quadraticBezierTo(w * 0.08, h * 0.86, w * 0.08, h * 0.52)
      ..lineTo(w * 0.08, h * 0.2)
      ..close();

    canvas.drawPath(
      shield,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tier.crestStart, tier.crestEnd],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      shield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.05
        ..color = Colors.white.withValues(alpha: 0.75),
    );
    // A highlight down one side, so it reads as metal rather than as a
    // flat sticker.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.1)
        ..lineTo(w * 0.5, h * 0.9)
        ..lineTo(w * 0.2, h * 0.62)
        ..lineTo(w * 0.2, h * 0.24)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(_CrestPainter oldDelegate) => oldDelegate.tier != tier;
}
