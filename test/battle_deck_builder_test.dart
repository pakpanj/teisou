import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/battle_deck_builder.dart';
import 'package:kana_master/data/models/card_game_rank.dart';
import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/data/models/kana_character.dart';
import 'package:kana_master/data/models/kana_type.dart';
import 'package:kana_master/data/models/kanji_entry.dart';
import 'package:kana_master/data/repositories/kana_repository.dart';
import 'package:kana_master/data/repositories/kanji_repository.dart';

/// Runs against the real bundled kana/kanji datasets, the same
/// discipline `kana_keyboard_input_test.dart`/`romaji_converter_test.dart`
/// already established — a real content gap (too few eligible cards for
/// a tier) would show up here, not just in whichever screen eventually
/// builds a deck.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<KanaCharacter> allKana;
  late List<KanjiEntry> allKanji;

  setUpAll(() async {
    allKana = await KanaRepository().getAll();
    allKanji = await KanjiRepository().getAll();
  });

  group('buildDeckIds', () {
    test('every tier has enough real cards for a 20-card deck', () {
      for (final content in CardTierContent.values) {
        final deck = buildDeckIds(
          content: content,
          allKana: allKana,
          allKanji: allKanji,
        );
        expect(deck.length, 20, reason: '$content');
      }
    });

    test('a deck never repeats a card id', () {
      for (final content in CardTierContent.values) {
        final deck = buildDeckIds(
          content: content,
          allKana: allKana,
          allKanji: allKanji,
        );
        expect(deck.toSet().length, 20, reason: '$content');
      }
    });

    test('bronze (hiragana) draws only base hiragana, never katakana or '
        'a combo form', () {
      final deck = buildDeckIds(
        content: CardTierContent.hiragana,
        allKana: allKana,
        allKanji: allKanji,
      );
      for (final id in deck) {
        final kana = allKana.firstWhere((k) => k.id == id);
        expect(kana.type, KanaType.hiragana);
        expect(kana.row, lessThanOrEqualTo(10));
      }
    });

    test('silver draws only katakana or hiragana combo forms, never base '
        'hiragana', () {
      final deck = buildDeckIds(
        content: CardTierContent.katakanaAndKanaCombo,
        allKana: allKana,
        allKanji: allKanji,
      );
      for (final id in deck) {
        final kana = allKana.firstWhere((k) => k.id == id);
        final isKatakana = kana.type == KanaType.katakana;
        final isHiraganaCombo = kana.type == KanaType.hiragana && kana.row > 10;
        expect(isKatakana || isHiraganaCombo, isTrue, reason: id);
      }
    });

    test('kanji tiers draw only non-placeholder entries from the right '
        'JLPT levels', () {
      final n5Deck = buildDeckIds(
        content: CardTierContent.kanjiN5,
        allKana: allKana,
        allKanji: allKanji,
      );
      for (final id in n5Deck) {
        final kanjiId = id.split('|').first;
        final entry = allKanji.firstWhere((e) => e.id == kanjiId);
        expect(entry.jlptLevel, JlptLevel.n5);
        expect(entry.placeholder, isFalse);
      }

      final n4n3Deck = buildDeckIds(
        content: CardTierContent.kanjiN4N3,
        allKana: allKana,
        allKanji: allKanji,
      );
      for (final id in n4n3Deck) {
        final kanjiId = id.split('|').first;
        final entry = allKanji.firstWhere((e) => e.id == kanjiId);
        expect(entry.jlptLevel, anyOf(JlptLevel.n4, JlptLevel.n3));
      }
    });

    test('deck order is not just deck insertion order — proves it '
        'shuffles', () {
      final first = buildDeckIds(
        content: CardTierContent.hiragana,
        allKana: allKana,
        allKanji: allKanji,
      );
      final second = buildDeckIds(
        content: CardTierContent.hiragana,
        allKana: allKana,
        allKanji: allKanji,
      );
      // Vanishingly unlikely to be equal by chance across two independent
      // shuffles of a pool this size if it's genuinely random each call.
      expect(first, isNot(equals(second)));
    });
  });

  group('resolveCard', () {
    test('resolves a kana card id back to its character/romaji', () {
      final deck = buildDeckIds(
        content: CardTierContent.hiragana,
        allKana: allKana,
        allKanji: allKanji,
      );
      final card = resolveCard(deck.first, allKana, allKanji);
      expect(card, isNotNull);
      expect(card!.answerInHiragana, isFalse);
      expect(card.prompt, isNotEmpty);
      expect(card.correctRomaji, isNotEmpty);
    });

    test('resolves a kanji-word card id back to the word/reading, marked '
        'answerInHiragana', () {
      final deck = buildDeckIds(
        content: CardTierContent.kanjiN5,
        allKana: allKana,
        allKanji: allKanji,
      );
      final card = resolveCard(deck.first, allKana, allKanji);
      expect(card, isNotNull);
      expect(card!.answerInHiragana, isTrue);
      expect(card.prompt, isNotEmpty);
      expect(card.correctRomaji, isNotEmpty);
    });

    test('returns null for an id that doesn\'t resolve to anything real',
        () {
      expect(resolveCard('nonexistent_id', allKana, allKanji), isNull);
      expect(
        resolveCard('kanji_gaku_n5|nonexistent_word', allKana, allKanji),
        isNull,
      );
    });

    test('a full deck round-trips through resolveCard with no losses', () {
      for (final content in CardTierContent.values) {
        final deck = buildDeckIds(
          content: content,
          allKana: allKana,
          allKanji: allKanji,
        );
        for (final id in deck) {
          expect(
            resolveCard(id, allKana, allKanji),
            isNotNull,
            reason: '$content card $id',
          );
        }
      }
    });
  });
}
