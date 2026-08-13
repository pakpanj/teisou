import 'package:flutter_test/flutter_test.dart';
import 'package:kana_master/core/localization/app_strings.dart';
import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/models/card_game_rank.dart';
import 'package:kana_master/data/models/leaderboard_entry.dart';
import 'package:kana_master/features/leaderboard/leaderboard_screen.dart';

/// Covers the leaderboard's Card Game Mode star ranking tab — the
/// separate ranking `NOTES_CARD_GAME_MODE.md`'s "Papan peringkat
/// bintang berdiri sendiri" describes, mirroring
/// `leaderboard_global_score_test.dart`'s coverage shape for the
/// existing global-score tab.
void main() {
  const id = AppStrings(AppLanguage.indonesian);
  const en = AppStrings(AppLanguage.english);

  LeaderboardEntry entry({
    CardGameTier tier = CardGameTier.bronze,
    int division = 5,
    int stars = 0,
    int season = 1,
    int? starTotal,
  }) =>
      LeaderboardEntry(
        uid: 'u1',
        displayName: 'Budi',
        totalMastered: 0,
        examHighScore: 0,
        cardGameTier: tier,
        cardGameDivision: division,
        cardGameStars: stars,
        cardGameSeason: season,
        cardGameStarTotal: starTotal,
        updatedAt: DateTime(2026, 8, 14),
      );

  test('a player who has never played reads as "never played", not zero '
      'stars', () {
    final e = entry();
    expect(e.hasPlayedCardGame, isFalse);
    expect(cardGameStarValueLabel(e, id), 'Belum pernah bertanding Mode Kartu.');
    expect(cardGameStarSubtitle(e, id), isEmpty);
  });

  test('a genuine zero-star standing still ranks as having played', () {
    final e = entry(starTotal: 0);
    expect(e.hasPlayedCardGame, isTrue);
    expect(cardGameStarValueLabel(e, id), '0 bintang');
    expect(cardGameStarValueLabel(e, en), '0 stars');
  });

  test('value label shows the total, following the language toggle', () {
    final e = entry(tier: CardGameTier.gold, division: 2, stars: 3, starTotal: 42);
    expect(cardGameStarValueLabel(e, id), '42 bintang');
    expect(cardGameStarValueLabel(e, en), '42 stars');
  });

  test('subtitle shows tier + division + stars-within-division for a '
      'tier with divisions', () {
    final e = entry(
      tier: CardGameTier.silver,
      division: 3,
      stars: 2,
      starTotal: 20,
    );
    expect(cardGameStarSubtitle(e, id), 'Silver III · 2/4 bintang');
    expect(cardGameStarSubtitle(e, en), 'Silver III · 2/4 stars');
  });

  test('subtitle uses the uncapped stars form for Emerald, which has no '
      'divisions', () {
    final e = entry(tier: CardGameTier.emerald, stars: 91, starTotal: 91);
    expect(cardGameStarSubtitle(e, id), 'Emerald · 91 bintang');
    expect(cardGameStarSubtitle(e, en), 'Emerald · 91 stars');
  });

  test('an absent cardGameStarTotal is distinguishable from a stored '
      'zero, mirroring globalScore\'s own absent-vs-zero distinction', () {
    final absent = LeaderboardEntry.fromMap('u1', {'displayName': 'Budi'});
    expect(absent.cardGameStarTotal, isNull);
    expect(absent.hasPlayedCardGame, isFalse);

    final storedZero = LeaderboardEntry.fromMap(
      'u1',
      {'displayName': 'Budi', 'cardGameStarTotal': 0},
    );
    expect(storedZero.cardGameStarTotal, 0);
    expect(storedZero.hasPlayedCardGame, isTrue);
  });

  test('cardGameRankStanding reconstructs the same CardGameRank the Home '
      'card and match-result screen already render', () {
    final e = entry(
      tier: CardGameTier.diamond,
      division: 4,
      stars: 5,
      season: 2,
      starTotal: 60,
    );
    final standing = e.cardGameRankStanding;
    expect(standing.tier, CardGameTier.diamond);
    expect(standing.division, 4);
    expect(standing.stars, 5);
    expect(standing.season, 2);
    expect(standing.displayName, 'Diamond IV');
  });

  test('tab label is non-empty in both languages', () {
    for (final strings in [id, en]) {
      expect(strings.tabCardGameStars, isNotEmpty);
    }
    expect(id.tabCardGameStars, 'Bintang');
    expect(en.tabCardGameStars, 'Stars');
  });
}
