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
/// This is deliberately just the *field* — no promotion/demotion, streak
/// bonus, loss-protection, or season-rollover logic lives here yet (see
/// `NOTES_CARD_GAME_MODE.md`'s "Tahap 1 butir 2": that logic only
/// matters once real matches exist to trigger it, and belongs with the
/// Cloud Function scoring work in Tahap 2). What's here is enough for
/// anything built in the meantime to read "which tier is this player in
/// right now, so which card content applies" — [CardGameTierX.cardContent]
/// is the reason this needed to exist before the match screen does.
class CardGameRank {
  final CardGameTier tier;

  /// 5 (V) down to 1 (I) for a tier with divisions. Unused — always 1 —
  /// for [CardGameTier.emerald], which has none.
  final int division;

  final int stars;

  final int season;

  CardGameRank({
    required this.tier,
    required this.division,
    required this.stars,
    required this.season,
  });

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
    );
  }

  Map<String, dynamic> toMap() => {
    'tier': tier.key,
    'division': division,
    'stars': stars,
    'season': season,
  };
}
