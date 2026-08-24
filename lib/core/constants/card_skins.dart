import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/models/app_language.dart';

/// The pattern drawn on a card back. Each is painted from shapes rather
/// than an image asset, so a new skin costs nothing to add and nothing
/// to download — the same reason the rest of this mode is drawn rather
/// than illustrated.
enum CardSkinPattern { seigaiha, asanoha, sakura, stripes, stars, plain }

/// Where a skin comes from. The three never substitute for each other —
/// see `NOTES_CARD_GAME_MODE.md`, "tiga keluarga yang tidak boleh saling
/// menggantikan".
enum CardSkinSource {
  /// Everyone has these from the first launch.
  free,

  /// Unlocked only when **both** conditions hold: the star total *and* a
  /// live Premium subscription — added 2026-08-24, replacing the earlier
  /// stars-alone rule. Either one dropping re-locks the skin: the stars
  /// falling below the threshold (a season's 70% carry can do that), or
  /// the subscription lapsing. No amount of stars buys it without
  /// Premium, and no amount of Premium buys it without the stars — see
  /// [isCardSkinUnlocked]'s own doc comment for exactly how the two
  /// combine.
  achievement,

  /// Bought with real money. Stars must never open one either, or the
  /// paid family becomes the poor relation of the earned one.
  paid,

  /// Handed out during an event, and only then. Neither money nor stars
  /// opens one — which is the whole point: it dates you. Someone playing
  /// with a Tanabata skin was here that July, and no amount of either
  /// currency can buy that later.
  ///
  /// **Nothing grants these yet.** There is no event system, so every
  /// one shows as locked, and the picker says why rather than dangling a
  /// price that does not exist.
  event,
}

/// A skin a player wears on the cards they play.
///
/// **The one cosmetic an opponent actually sees.** Avatars and covers
/// sit on your own profile, where nobody is looking; this is on every
/// card you play, in front of the person you are playing, for as long as
/// they are answering it.
class CardSkinPreset {
  const CardSkinPreset({
    required this.id,
    required this.label,
    required this.labelEn,
    required this.pattern,
    required this.start,
    required this.end,
    this.source = CardSkinSource.free,
    this.starsRequired = 0,
    this.darkFace = false,
    this.illustrated = false,
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

  final CardSkinSource source;

  /// Star **total** (0-90+) needed, for [CardSkinSource.achievement].
  /// Deliberately the tier boundaries themselves, so the sentence a
  /// child hears is "a gold card means you reached Gold".
  final int starsRequired;

  /// Whether the middle of the card is dark, so the character drawn on
  /// top of it has to be light. Three of the six illustrated skins are
  /// dark; without this the glyph would be black on black on those.
  final bool darkFace;

  /// Whether this skin has real illustrated art in `assets/card_skins/`.
  ///
  /// **The three free skins deliberately do not.** They are painted from
  /// [pattern] instead, and that is the difference a player is meant to
  /// see: what you start with the app draws, what you earn or buy an
  /// illustrator drew. Keeping both paths also means a new skin can be
  /// prototyped from a pattern before any art exists — which is how all
  /// six of the illustrated ones started.
  final bool illustrated;

  /// Where that art lives, derived from [id] so there is no second
  /// filename table to fall out of step — the same call
  /// `AvatarPreset.assetPath` already makes.
  String get assetPath => 'assets/card_skins/$id.png';

  String labelFor(AppLanguage language) =>
      language == AppLanguage.english ? labelEn : label;
}

/// Every skin in the game.
///
/// Every skin `CardSkinSource.paid` here (`shop_tab.dart`'s Toko tab) is
/// individually purchasable via `in_app_purchase` — id
/// `skin_<CardSkinPreset.id>` — once its own product exists in Play
/// Console; see `IapProducts.productIdForSkin`. The same three paid
/// skins are also bundled free into the Premium subscription (see
/// [isCardSkinUnlocked]'s `premium` parameter), so a subscriber never
/// has to buy them separately on top of the monthly fee.
class CardSkinPresets {
  static const classic = CardSkinPreset(
    id: 'classic',
    label: 'Ombak Klasik',
    labelEn: 'Classic Wave',
    pattern: CardSkinPattern.seigaiha,
    start: Color(0xFF5B9BF5),
    end: Color(0xFFF56B7B),
  );

  /// Star totals for the three achievement skins — the tier boundaries
  /// themselves, so each one reads as "you reached that tier".
  static const goldThreshold = 35;
  static const diamondThreshold = 60;
  static const emeraldThreshold = 90;

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
    // --- Pencapaian: butuh bintang DAN akun Premium, tidak dijual langsung ---
    CardSkinPreset(
      id: 'emas_kencana',
      label: 'Emas Kencana',
      labelEn: 'Kencana Gold',
      pattern: CardSkinPattern.asanoha,
      start: Color(0xFFF5C451),
      end: Color(0xFFC1761B),
      source: CardSkinSource.achievement,
      starsRequired: goldThreshold,
      illustrated: true,
    ),
    CardSkinPreset(
      id: 'night_purple',
      label: 'Ungu Malam',
      labelEn: 'Night Purple',
      pattern: CardSkinPattern.stars,
      start: Color(0xFF3B2E6E),
      end: Color(0xFF16204A),
      source: CardSkinSource.achievement,
      starsRequired: diamondThreshold,
      darkFace: true,
      illustrated: true,
    ),
    CardSkinPreset(
      id: 'dragon_black',
      label: 'Naga Hitam',
      labelEn: 'Black Dragon',
      pattern: CardSkinPattern.plain,
      start: Color(0xFF3A3A3A),
      end: Color(0xFF101010),
      source: CardSkinSource.achievement,
      starsRequired: emeraldThreshold,
      darkFace: true,
      illustrated: true,
    ),

    // --- Berbayar: dijual di Toko, tidak bisa didapat dengan bintang ---
    CardSkinPreset(
      id: 'cloud_white',
      label: 'Awan Putih',
      labelEn: 'Cloud White',
      pattern: CardSkinPattern.seigaiha,
      start: Color(0xFFF2F4F8),
      end: Color(0xFFCFD6E4),
      source: CardSkinSource.paid,
      illustrated: true,
    ),
    CardSkinPreset(
      id: 'neon_city',
      label: 'Kota Neon',
      labelEn: 'Neon City',
      pattern: CardSkinPattern.stripes,
      start: Color(0xFF12103A),
      end: Color(0xFF2B1B5A),
      source: CardSkinSource.paid,
      darkFace: true,
      illustrated: true,
    ),
    // --- Event: dibagikan saat acara, tidak dijual, bukan dari bintang ---
    // The 7 illustrated event skins that used to live here (Sakura
    // Rembulan, Ombak Besar, Kitsune, Mimpi Kupu-kupu, Tanabata, Hina
    // Matsuri, Oni Merah) were removed 2026-08-24 — the art didn't match
    // the card's real aspect ratio and read as low-quality on an actual
    // card back. No event system has ever existed to grant them anyway
    // (see [CardSkinSource.event]'s own doc comment), so removing them
    // cost nothing functionally. `CardSkinSource.event` stays defined for
    // whenever a real event system and real art exist; `ofSource(event)`
    // is simply empty until then, and the picker's own "no unlocked
    // event skins" branch already handles an empty list correctly.
    CardSkinPreset(
      id: 'sakura_gold',
      label: 'Sakura Emas',
      labelEn: 'Sakura Gold',
      pattern: CardSkinPattern.sakura,
      start: Color(0xFFFFD9E2),
      end: Color(0xFFE8B04B),
      source: CardSkinSource.paid,
      illustrated: true,
    ),
  ];

  static Iterable<CardSkinPreset> ofSource(CardSkinSource source) =>
      all.where((s) => s.source == source);

  /// Flat price for every [CardSkinSource.paid] skin, added 2026-08-24 —
  /// each one of the three (not a bundle) costs this many coins. Mirrored
  /// in `functions/spend_coins.js`'s `SKIN_COIN_PRICE`, same discipline
  /// as `AvatarPresets.coinPrice`/`FramePresets.coinPrice`/
  /// `CoverPresets.coinPrice` already keep with their own JS mirror.
  /// Deliberately its own constant, not reusing those three's 150 — a
  /// skin an opponent actually sees (see [CardSkinPreset]'s own doc
  /// comment) is priced higher on purpose.
  static const coinPrice = 300;

  /// Whether [id] can be bought with coins right now — true for exactly
  /// the [CardSkinSource.paid] family. Real money still works too once
  /// its own Play Console product exists (see `IapProducts`); coins are
  /// an additional path, not a replacement.
  static bool isCoinUnlockable(String id) =>
      ofSource(CardSkinSource.paid).any((s) => s.id == id);

  /// Falls back to [classic] for an unknown or absent id, so a skin
  /// removed in a later version never leaves a player with no card back.
  static CardSkinPreset byId(String? id) {
    for (final skin in all) {
      if (skin.id == id) return skin;
    }
    return classic;
  }
}

/// Whether every skin is selectable regardless of how it is normally
/// earned.
///
/// **Deliberately `kDebugMode`, not a hand-set bool.** While the art is
/// being judged, every skin has to be pickable so each one can be seen
/// on a real card in a real match. That is exactly the kind of temporary
/// state that ships by accident — and if it shipped, the whole
/// three-family design would vanish silently: every skin free, the
/// achievement ones proving nothing, the paid ones unsellable. This
/// project has already had one gate constant sit switched off through an
/// entire content rollout (`kBabGateQuizRequired`), so the lesson is
/// paid for. Hanging it off the build mode, the way `AdService` picks
/// its ad units, makes a release build structurally incapable of it.
bool get kCardSkinsAllUnlocked => kDebugMode;

/// Whether [skin] can be worn right now.
///
/// - Free: always.
/// - Achievement: **both** the star **total** must *currently* reach its
///   threshold **and** [premium] must be true — added 2026-08-24, per
///   explicit product decision, replacing the earlier stars-only rule.
///   Note "currently" for the stars half — a season's 70% carry can drop
///   a player below it again, and the skin is meant to lock back, same
///   as before. The [premium] half re-locks the moment a subscription
///   lapses too, for the same reason it already does for [paid] below —
///   this is a live check, never a stored one.
/// - Paid: owned outright (bought individually via `skin_<id>`), **or**
///   [premium] — the Premium subscription's "Skin Battle Card
///   eksklusif" benefit bundles the entire paid family (Awan Putih,
///   Kota Neon, Sakura Emas) in for free, per an explicit product
///   decision rather than making a subscriber buy them separately too.
///   [premium] is meant to be passed live from `subscriptionProvider`,
///   never stored — same as [moduleAccessProvider] gating a whole
///   module, letting Premium in re-locks the skins the moment a
///   subscription lapses rather than leaving them owned forever, which
///   [owned] alone (a real purchase) correctly does not.
/// - Event: same test as a bought skin, for now with nothing that can
///   set it — no event has ever been run, so this is always false and
///   the picker explains rather than dangles.
///
/// [starTotal] comes from the server-written `leaderboard/{uid}` row,
/// never from a local sum — the ladder's arithmetic lives in
/// `functions/battle_stars.js` and is deliberately not duplicated in
/// Dart. That also means an opponent's device can check the same thing
/// about them, which is what makes a re-locked skin actually disappear
/// from other people's screens rather than only from its owner's.
bool isCardSkinUnlocked(
  CardSkinPreset skin, {
  required int starTotal,
  bool owned = false,
  bool premium = false,
  bool allUnlocked = false,
}) {
  if (allUnlocked) return true;
  return switch (skin.source) {
    CardSkinSource.free => true,
    CardSkinSource.achievement =>
      starTotal >= skin.starsRequired && premium,
    CardSkinSource.paid => owned || premium,
    CardSkinSource.event => owned,
  };
}

/// The skin to actually draw for a player, given what they picked and
/// where they stand.
///
/// Falls back to [CardSkinPresets.classic] when the chosen skin is no
/// longer unlocked — which happens for real every season. The choice
/// itself is left stored untouched, so the moment the stars come back so
/// does the skin, with nothing to re-pick. Silently swapping to some
/// other skin, or leaving a locked one on display, would both be worse:
/// one is confusing, the other makes the lock meaningless.
CardSkinPreset effectiveCardSkin(
  String? chosenId, {
  required int starTotal,
  bool owned = false,
  bool premium = false,
  bool allUnlocked = false,
}) {
  final skin = CardSkinPresets.byId(chosenId);
  return isCardSkinUnlocked(
    skin,
    starTotal: starTotal,
    owned: owned,
    premium: premium,
    allUnlocked: allUnlocked,
  )
      ? skin
      : CardSkinPresets.classic;
}

/// Paints a skin. Sized by its parent — used both on the real card in a
/// match and on the small tiles in the picker.
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
        child: skin.illustrated
            ? Image.asset(
                skin.assetPath,
                fit: BoxFit.cover,
                // The gradient underneath is the fallback, so a missing
                // or broken file leaves a plausible card back rather
                // than Flutter's broken-image glyph — the same contract
                // `KotobaImage` and `AvatarPresetArt` already keep.
                errorBuilder: (context, _, _) => CustomPaint(
                  painter: _SkinPainter(skin: skin, showCrest: showCrest),
                  child: const SizedBox.expand(),
                ),
              )
            : CustomPaint(
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
