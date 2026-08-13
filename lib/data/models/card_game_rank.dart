/// The five Card Game Mode tiers, locked in `NOTES_CARD_GAME_MODE.md`'s
/// "Tangga bintang" section — order matters, it's also the promotion
/// order.
enum CardGameTier { bronze, silver, gold, diamond, emerald }

extension CardGameTierX on CardGameTier {
  String get key => switch (this) {
    CardGameTier.bronze => 'bronze',
    CardGameTier.silver => 'silver',
    CardGameTier.gold => 'gold',
    CardGameTier.diamond => 'diamond',
    CardGameTier.emerald => 'emerald',
  };

  static CardGameTier fromKey(String? key) => switch (key) {
    'silver' => CardGameTier.silver,
    'gold' => CardGameTier.gold,
    'diamond' => CardGameTier.diamond,
    'emerald' => CardGameTier.emerald,
    _ => CardGameTier.bronze,
  };

  /// Stars needed to fill one division at this tier before promoting to
  /// the next division (or the next tier, from division I). Meaningless
  /// for [CardGameTier.emerald] — see [hasDivisions].
  int get starsPerDivision => switch (this) {
    CardGameTier.bronze => 3,
    CardGameTier.silver => 4,
    CardGameTier.gold => 5,
    CardGameTier.diamond => 6,
    CardGameTier.emerald => 0,
  };

  /// Every tier but Emerald has 5 divisions (V down to I). Emerald's
  /// stars "terus terkumpul" — they just accumulate, uncapped, with no
  /// division ladder inside the tier.
  bool get hasDivisions => this != CardGameTier.emerald;

  /// The tier promoted into after clearing this one's division I (or,
  /// for Emerald, `null` — there is nothing above it).
  CardGameTier? get next => switch (this) {
    CardGameTier.bronze => CardGameTier.silver,
    CardGameTier.silver => CardGameTier.gold,
    CardGameTier.gold => CardGameTier.diamond,
    CardGameTier.diamond => CardGameTier.emerald,
    CardGameTier.emerald => null,
  };

  /// Shown as-is in both languages — see `battleRankStandingLabel`'s
  /// comment in `AppStrings` for why these aren't translated.
  String get displayName => switch (this) {
    CardGameTier.bronze => 'Bronze',
    CardGameTier.silver => 'Silver',
    CardGameTier.gold => 'Gold',
    CardGameTier.diamond => 'Diamond',
    CardGameTier.emerald => 'Emerald',
  };

  /// Bronze and Silver never lose stars on a loss — the ladder that
  /// actually bites only starts at Gold. See "Bronze dan Silver diberi
  /// perlindungan" in `NOTES_CARD_GAME_MODE.md`.
  bool get lossProtected =>
      this == CardGameTier.bronze || this == CardGameTier.silver;

  /// Which learning content a public/bot match's cards are drawn from at
  /// this tier — see "Isi kartu ditentukan oleh rank". Friend/clan
  /// matches ignore this entirely; content there is freely chosen.
  CardTierContent get cardContent => switch (this) {
    CardGameTier.bronze => CardTierContent.hiragana,
    CardGameTier.silver => CardTierContent.katakanaAndKanaCombo,
    CardGameTier.gold => CardTierContent.kanjiN5,
    CardGameTier.diamond => CardTierContent.kanjiN4N3,
    CardGameTier.emerald => CardTierContent.kanjiN2N1,
  };

  /// Bronze/Silver cards are answered in romaji (the phone's own
  /// keyboard is enough); Gold and up are answered in hiragana, which
  /// needs `KanaKeyboard`. See "Ini sekaligus menyelesaikan masalah dua
  /// keyboard".
  bool get answersWithKanaKeyboard =>
      this != CardGameTier.bronze && this != CardGameTier.silver;
}

/// What a tier's public/bot-match cards are drawn from — a mapping, not
/// a choice; see [CardGameTierX.cardContent].
enum CardTierContent { hiragana, katakanaAndKanaCombo, kanjiN5, kanjiN4N3, kanjiN2N1 }

extension CardTierContentX on CardTierContent {
  /// Stored on `BattleMatch.cardTierContent` at creation — lets the bot
  /// AI (`functions/battle_bot.js`) read a match's difficulty tier
  /// directly instead of re-deriving it from `turnOrder`'s card ids.
  String get key => switch (this) {
    CardTierContent.hiragana => 'hiragana',
    CardTierContent.katakanaAndKanaCombo => 'katakanaAndKanaCombo',
    CardTierContent.kanjiN5 => 'kanjiN5',
    CardTierContent.kanjiN4N3 => 'kanjiN4N3',
    CardTierContent.kanjiN2N1 => 'kanjiN2N1',
  };

  static CardTierContent fromKey(String? key) => switch (key) {
    'katakanaAndKanaCombo' => CardTierContent.katakanaAndKanaCombo,
    'kanjiN5' => CardTierContent.kanjiN5,
    'kanjiN4N3' => CardTierContent.kanjiN4N3,
    'kanjiN2N1' => CardTierContent.kanjiN2N1,
    _ => CardTierContent.hiragana,
  };
}

/// A player's current Card Game Mode standing: tier, division within
/// that tier, stars within the current division, and the season this
/// standing belongs to.
///
/// **Read-only from this app's point of view.** Promotion, demotion,
/// loss protection, the streak bonus and the season's 70% carry all live
/// in `functions/battle_stars.js`, which is the only writer of this
/// field anywhere — `firestore.rules` rejects any client write that
/// changes it. That is not a layering preference: a ladder a player can
/// edit from their own device is decoration, and this one decides a
/// public leaderboard's order.
///
/// There is deliberately **no Dart copy of the ladder rules**. Nothing
/// here needs to *decide* a movement, only to display the standing the
/// server wrote, so a second implementation would buy nothing and could
/// drift — the cost `battle_scoring.js` already pays once for
/// RomajiConverter, which genuinely is needed on both sides.
class CardGameRank {
  final CardGameTier tier;

  /// 5 (V) down to 1 (I) for a tier with divisions. Unused — always 1 —
  /// for [CardGameTier.emerald], which has none.
  final int division;

  final int stars;

  final int season;

  /// Consecutive wins so far — a win from the third onward is worth 2
  /// stars instead of 1. Kept on the model (rather than left as a
  /// server-side detail) so the match-result screen can say *why* a win
  /// paid double instead of the number appearing to change at random.
  final int winStreak;

  CardGameRank({
    required this.tier,
    required this.division,
    required this.stars,
    required this.season,
    this.winStreak = 0,
  });

  /// "Bronze V", or just "Emerald" for the one tier with no divisions.
  /// Roman numerals because that's how every ranked game writes them,
  /// and how the mockups already drew them — note they count *down* as
  /// the player climbs, so V is the bottom of a tier and I the top.
  String get displayName => tier.hasDivisions
      ? '${tier.displayName} ${_romanNumerals[division] ?? '$division'}'
      : tier.displayName;

  static const _romanNumerals = {1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V'};

  /// Bronze V, 0 stars, season 1 — where every new player starts.
  factory CardGameRank.initial() => CardGameRank(
    tier: CardGameTier.bronze,
    division: 5,
    stars: 0,
    season: 1,
  );

  factory CardGameRank.fromMap(Map<String, dynamic>? map) {
    if (map == null) return CardGameRank.initial();
    return CardGameRank(
      tier: CardGameTierX.fromKey(map['tier'] as String?),
      division: map['division'] as int? ?? 5,
      stars: map['stars'] as int? ?? 0,
      season: map['season'] as int? ?? 1,
      winStreak: map['winStreak'] as int? ?? 0,
    );
  }

  /// Kept for round-tripping in tests and for reading a standing back
  /// out — **not** a write path. See this class's own doc comment: the
  /// app has no way to save a rank, by design.
  Map<String, dynamic> toMap() => {
    'tier': tier.key,
    'division': division,
    'stars': stars,
    'season': season,
    'winStreak': winStreak,
  };
}
