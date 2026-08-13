import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/card_game_rank.dart';

void main() {
  group('CardGameTier', () {
    test('key/fromKey round-trip for every tier', () {
      for (final tier in CardGameTier.values) {
        expect(CardGameTierX.fromKey(tier.key), tier);
      }
    });

    test('fromKey falls back to bronze for null or unknown keys', () {
      expect(CardGameTierX.fromKey(null), CardGameTier.bronze);
      expect(CardGameTierX.fromKey('nonsense'), CardGameTier.bronze);
    });

    test('promotion order matches the locked ladder: bronze -> silver -> '
        'gold -> diamond -> emerald -> nothing', () {
      expect(CardGameTier.bronze.next, CardGameTier.silver);
      expect(CardGameTier.silver.next, CardGameTier.gold);
      expect(CardGameTier.gold.next, CardGameTier.diamond);
      expect(CardGameTier.diamond.next, CardGameTier.emerald);
      expect(CardGameTier.emerald.next, isNull);
    });

    test('stars per division matches the locked table (3/4/5/6, emerald '
        'has none)', () {
      expect(CardGameTier.bronze.starsPerDivision, 3);
      expect(CardGameTier.silver.starsPerDivision, 4);
      expect(CardGameTier.gold.starsPerDivision, 5);
      expect(CardGameTier.diamond.starsPerDivision, 6);
      expect(CardGameTier.emerald.hasDivisions, isFalse);
    });

    test('only bronze and silver are loss-protected', () {
      expect(CardGameTier.bronze.lossProtected, isTrue);
      expect(CardGameTier.silver.lossProtected, isTrue);
      expect(CardGameTier.gold.lossProtected, isFalse);
      expect(CardGameTier.diamond.lossProtected, isFalse);
      expect(CardGameTier.emerald.lossProtected, isFalse);
    });

    test('card content follows the locked curriculum mapping', () {
      expect(CardGameTier.bronze.cardContent, CardTierContent.hiragana);
      expect(
        CardGameTier.silver.cardContent,
        CardTierContent.katakanaAndKanaCombo,
      );
      expect(CardGameTier.gold.cardContent, CardTierContent.kanjiN5);
      expect(CardGameTier.diamond.cardContent, CardTierContent.kanjiN4N3);
      expect(CardGameTier.emerald.cardContent, CardTierContent.kanjiN2N1);
    });

    test('only gold and up answer with the kana keyboard', () {
      expect(CardGameTier.bronze.answersWithKanaKeyboard, isFalse);
      expect(CardGameTier.silver.answersWithKanaKeyboard, isFalse);
      expect(CardGameTier.gold.answersWithKanaKeyboard, isTrue);
      expect(CardGameTier.diamond.answersWithKanaKeyboard, isTrue);
      expect(CardGameTier.emerald.answersWithKanaKeyboard, isTrue);
    });
  });

  group('CardGameRank', () {
    test('initial() is Bronze V, 0 stars, season 1', () {
      final rank = CardGameRank.initial();
      expect(rank.tier, CardGameTier.bronze);
      expect(rank.division, 5);
      expect(rank.stars, 0);
      expect(rank.season, 1);
    });

    test('fromMap(null) falls back to initial()', () {
      final rank = CardGameRank.fromMap(null);
      expect(rank.tier, CardGameTier.bronze);
      expect(rank.division, 5);
      expect(rank.stars, 0);
      expect(rank.season, 1);
    });

    test('toMap/fromMap round-trips every field', () {
      final rank = CardGameRank(
        tier: CardGameTier.diamond,
        division: 3,
        stars: 4,
        season: 7,
      );
      final roundTripped = CardGameRank.fromMap(rank.toMap());
      expect(roundTripped.tier, CardGameTier.diamond);
      expect(roundTripped.division, 3);
      expect(roundTripped.stars, 4);
      expect(roundTripped.season, 7);
    });

    test('fromMap defaults missing individual fields rather than throwing',
        () {
      final rank = CardGameRank.fromMap({'tier': 'gold'});
      expect(rank.tier, CardGameTier.gold);
      expect(rank.division, 5);
      expect(rank.stars, 0);
      expect(rank.season, 1);
    });
  });
}
