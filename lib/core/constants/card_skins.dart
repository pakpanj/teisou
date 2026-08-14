import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/app_language.dart';

/// The pattern drawn on a card back. Each is painted from shapes rather
/// than an image asset, so a new skin costs nothing to add and nothing
/// to download — the same reason the rest of this mode is drawn rather
/// than illustrated.
enum CardSkinPattern { seigaiha, asanoha, sakura, stripes, stars, plain }

/// A card back a player can wear.
///
/// **This is deliberately the one cosmetic your opponent sees.** Avatars
/// and covers are shown on your own profile, where nobody is looking; a
/// card back is on every card you play, in front of the person you are
/// playing. That is what makes it worth wanting, and worth selling.
class CardSkinPreset {
  const CardSkinPreset({
    required this.id,
    required this.label,
    required this.labelEn,
    required this.pattern,
    required this.start,
    required this.end,
    this.premium = false,
  });

  final String id;
  final String label;

  /// English name, kept beside the art rather than as decorative getters
  /// in `AppStrings` — the same call [CoverPreset] already makes.
  final String labelEn;

  final CardSkinPattern pattern;

  /// The back's gradient, top-left to bottom-right.
  final Color start;
  final Color end;

  /// Locked skins. Unlocking follows exactly the path premium avatars
  /// already use — an active subscription, or a rewarded ad — because
  /// that is the only purchase machinery this app actually has today.
  /// Real money needs the billing work that is still an open release
  /// blocker; see `CardSkinPresets` for the note.
  final bool premium;

  String labelFor(AppLanguage language) =>
      language == AppLanguage.english ? labelEn : label;
}

/// Every skin in the game.
///
/// **Sellable, not yet sold.** The gate here is premium-or-rewarded-ad,
/// which is what exists; charging for an individual skin needs
/// `in_app_purchase` wired up, which this project has never had (see
/// CLAUDE.md's release-readiness section). When that lands, a price
/// belongs on [CardSkinPreset] and the lock branches on ownership
/// instead of on [CardSkinPreset.premium] — nothing else has to move.
class CardSkinPresets {
  static const classic = CardSkinPreset(
    id: 'classic',
    label: 'Ombak Klasik',
    labelEn: 'Classic Wave',
    pattern: CardSkinPattern.seigaiha,
    start: Color(0xFF5B9BF5),
    end: Color(0xFFF56B7B),
  );

  /// Everyone starts here, and it stays free forever: a player whose
  /// cards look broken until they pay is not a player for long.
  static const all = <CardSkinPreset>[
    classic,
    CardSkinPreset(
      id: 'sakura',
      label: 'Sakura Pagi',
      labelEn: 'Morning Sakura',
      pattern: CardSkinPattern.sakura,
      start: Color(0xFFFFC1CF),
      end: Color(0xFFF9748F),
    ),
    CardSkinPreset(
      id: 'indigo',
      label: 'Nila Malam',
      labelEn: 'Midnight Indigo',
      pattern: CardSkinPattern.asanoha,
      start: Color(0xFF2E3A87),
      end: Color(0xFF6C4BB6),
    ),
    CardSkinPreset(
      id: 'matcha',
      label: 'Matcha',
      labelEn: 'Matcha',
      pattern: CardSkinPattern.stripes,
      start: Color(0xFF8BC178),
      end: Color(0xFF3E7A4E),
      premium: true,
    ),
    CardSkinPreset(
      id: 'kinzan',
      label: 'Emas Kinzan',
      labelEn: 'Kinzan Gold',
      pattern: CardSkinPattern.asanoha,
      start: Color(0xFFF5C451),
      end: Color(0xFFC1761B),
      premium: true,
    ),
    CardSkinPreset(
      id: 'yozora',
      label: 'Langit Malam',
      labelEn: 'Night Sky',
      pattern: CardSkinPattern.stars,
      start: Color(0xFF16204A),
      end: Color(0xFF3B2E6E),
      premium: true,
    ),
    CardSkinPreset(
      id: 'sumi',
      label: 'Tinta Sumi',
      labelEn: 'Sumi Ink',
      pattern: CardSkinPattern.plain,
      start: Color(0xFF3A3A3A),
      end: Color(0xFF101010),
      premium: true,
    ),
  ];

  /// Falls back to [classic] for an unknown or absent id, so a skin
  /// removed in a later version never leaves a player with no card back.
  static CardSkinPreset byId(String? id) {
    for (final skin in all) {
      if (skin.id == id) return skin;
    }
    return classic;
  }
}

/// Paints a skin's back. Sized by its parent — used both on the real
/// card in a match and on the small tiles in the picker.
class CardSkinBack extends StatelessWidget {
  const CardSkinBack({
    super.key,
    required this.skin,
    this.borderRadius = 20,
    this.showCrest = true,
  });

  final CardSkinPreset skin;
  final double borderRadius;

  /// The あ medallion in the middle. Dropped on the small picker tiles,
  /// where it would be bigger than the pattern it sits on.
  final bool showCrest;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [skin.start, skin.end],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          painter: _SkinPainter(skin: skin, showCrest: showCrest),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _SkinPainter extends CustomPainter {
  _SkinPainter({required this.skin, required this.showCrest});

  final CardSkinPreset skin;
  final bool showCrest;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width < 90 ? 0.9 : 1.6
      ..color = Colors.white.withValues(alpha: 0.45);
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.22);
    final step = size.width < 90 ? 11.0 : 26.0;

    switch (skin.pattern) {
      case CardSkinPattern.seigaiha:
        for (var y = step; y < size.height + step; y += step) {
          for (var x = 0.0; x < size.width + step; x += step) {
            canvas.drawArc(
              Rect.fromCircle(center: Offset(x, y), radius: step * 0.62),
              math.pi,
              math.pi,
              false,
              ink,
            );
          }
        }
      case CardSkinPattern.asanoha:
        // The hemp-leaf star, drawn as spokes on a grid — six lines from
        // each node is enough to read as asanoha at this size.
        for (var y = 0.0; y < size.height + step; y += step) {
          for (var x = 0.0; x < size.width + step; x += step) {
            for (var i = 0; i < 6; i++) {
              final a = math.pi / 3 * i;
              canvas.drawLine(
                Offset(x, y),
                Offset(x + math.cos(a) * step * 0.5,
                    y + math.sin(a) * step * 0.5),
                ink,
              );
            }
          }
        }
      case CardSkinPattern.sakura:
        for (var y = step * 0.6; y < size.height + step; y += step) {
          var row = 0;
          for (var x = 0.0; x < size.width + step; x += step) {
            final offset = Offset(x + (row.isEven ? 0 : step / 2), y);
            for (var i = 0; i < 5; i++) {
              final a = math.pi * 2 / 5 * i;
              canvas.drawCircle(
                offset + Offset(math.cos(a), math.sin(a)) * step * 0.22,
                step * 0.13,
                fill,
              );
            }
            row++;
          }
        }
      case CardSkinPattern.stripes:
        for (var x = -size.height; x < size.width; x += step * 0.8) {
          canvas.drawLine(
            Offset(x, 0),
            Offset(x + size.height, size.height),
            ink,
          );
        }
      case CardSkinPattern.stars:
        final rng = math.Random(11);
        for (var i = 0; i < 46; i++) {
          canvas.drawCircle(
            Offset(rng.nextDouble() * size.width,
                rng.nextDouble() * size.height),
            rng.nextDouble() * (size.width < 90 ? 1.2 : 2.4) + 0.6,
            fill,
          );
        }
      case CardSkinPattern.plain:
        // Nothing but the gradient — a deliberate option, not a gap.
        break;
    }

    if (!showCrest) return;
    final crest = size.width * 0.21;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      crest,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'あ',
        style: TextStyle(
          fontSize: crest,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
  }

  @override
  bool shouldRepaint(_SkinPainter oldDelegate) =>
      oldDelegate.skin.id != skin.id || oldDelegate.showCrest != showCrest;
}
