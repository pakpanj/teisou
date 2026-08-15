import 'dart:math';

import '../../data/models/card_game_rank.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kana_character.dart';
import '../../data/models/kana_type.dart';
import '../../data/models/kanji_entry.dart';

/// A single battle card, resolved from its opaque `cardId` (a
/// `TurnOrderEntry.cardId`) into what's actually needed to render it and
/// check the answer locally — the "fast path" from
/// `NOTES_CARD_GAME_MODE.md`, never authoritative. The real verdict is
/// the Cloud Function's job.
class BattleCard {
  final String id;

  /// What's shown to the answering player — a single kana character, or
  /// a kanji compound word ("kartu kanji berisi kata, bukan kanji
  /// tunggal").
  final String prompt;

  /// The correct answer in romaji. Kana cards compare a typed romaji
  /// answer to this directly; kanji cards are answered in hiragana (see
  /// [answerInHiragana]), so that answer needs converting to romaji
  /// first (via `RomajiConverter`) before comparing to this.
  final String correctRomaji;

  /// Whether this card is answered by typing hiragana (via
  /// `KanaKeyboard`) rather than romaji on the device's own keyboard —
  /// true for every kanji tier, false for both kana tiers.
  final bool answerInHiragana;

  BattleCard({
    required this.id,
    required this.prompt,
    required this.correctRomaji,
    required this.answerInHiragana,
  });
}

/// Builds a shuffled, unique 20-card deck (a list of card ids, matching
/// what `BattleRepository.createMatch` / `buildTurnOrder` expect) for a
/// tier's card content — see `NOTES_CARD_GAME_MODE.md`'s "Isi kartu
/// ditentukan oleh rank". Kana tiers draw straight from the kana
/// dataset; kanji tiers draw one word example per card, keyed
/// `"{kanjiId}|{word}"` — the same key shape this codebase's own
/// kanji-word-example translation rollout already uses, reused here
/// rather than inventing a second convention.
///
/// Throws an [ArgumentError] if the matching pool has fewer than 20
/// eligible entries — this should never happen against the real bundled
/// datasets (every kana tier's pool is dozens of entries; every kanji
/// tier's real, non-placeholder word-example pool is hundreds), so
/// hitting this in practice would mean the datasets themselves regressed,
/// not a normal runtime condition to design a fallback around.
List<String> buildDeckIds({
  required CardTierContent content,
  required List<KanaCharacter> allKana,
  required List<KanjiEntry> allKanji,
  Random? random,
}) {
  final pool = _poolFor(content, allKana, allKanji);
  if (pool.length < 20) {
    throw ArgumentError(
      'card pool for $content has only ${pool.length} entries, need at least 20',
    );
  }
  final rng = random ?? Random();
  final shuffled = List<String>.from(pool)..shuffle(rng);
  return shuffled.take(20).toList();
}

/// Every card a tier can deal, in id form — the deck is 20 drawn from
/// this. Exposed so the Deck tab can show a learner what they are about
/// to be tested on, which is the only honest thing that screen can do:
/// nothing about a deck is player-editable, so there is nothing to
/// manage, but there is plenty to study.
List<String> cardPoolFor(
  CardTierContent content,
  List<KanaCharacter> allKana,
  List<KanjiEntry> allKanji,
) =>
    _poolFor(content, allKana, allKanji);

List<String> _poolFor(
  CardTierContent content,
  List<KanaCharacter> allKana,
  List<KanjiEntry> allKanji,
) {
  switch (content) {
    case CardTierContent.hiragana:
      return allKana
          .where((k) => k.type == KanaType.hiragana && k.row <= 10)
          .map((k) => k.id)
          .toList();
    case CardTierContent.katakanaAndKanaCombo:
      return allKana
          .where(
            (k) =>
                k.type == KanaType.katakana ||
                (k.type == KanaType.hiragana && k.row > 10),
          )
          .map((k) => k.id)
          .toList();
    case CardTierContent.kanjiN5:
      return _kanjiWordIds(allKanji, {JlptLevel.n5});
    case CardTierContent.kanjiN4N3:
      return _kanjiWordIds(allKanji, {JlptLevel.n4, JlptLevel.n3});
    case CardTierContent.kanjiN2N1:
      return _kanjiWordIds(allKanji, {JlptLevel.n2, JlptLevel.n1});
  }
}

List<String> _kanjiWordIds(List<KanjiEntry> allKanji, Set<JlptLevel> levels) {
  final ids = <String>[];
  for (final entry in allKanji) {
    if (entry.placeholder) continue;
    if (!levels.contains(entry.jlptLevel)) continue;
    for (final word in entry.wordExamples) {
      ids.add('${entry.id}|${word.word}');
    }
  }
  return ids;
}

/// Resolves one [cardId] (produced by [buildDeckIds], stored as a
/// `TurnOrderEntry.cardId`) back into a [BattleCard] — needs the same
/// [allKana]/[allKanji] lists the deck was originally built from.
/// Returns `null` if [cardId] doesn't resolve to anything real (should
/// only happen if the dataset changed between deck creation and now).
BattleCard? resolveCard(
  String cardId,
  List<KanaCharacter> allKana,
  List<KanjiEntry> allKanji,
) {
  if (cardId.contains('|')) {
    final parts = cardId.split('|');
    if (parts.length != 2) return null;
    final kanjiId = parts[0];
    final word = parts[1];

    KanjiEntry? entry;
    for (final e in allKanji) {
      if (e.id == kanjiId) {
        entry = e;
        break;
      }
    }
    if (entry == null) return null;

    for (final example in entry.wordExamples) {
      if (example.word == word) {
        return BattleCard(
          id: cardId,
          prompt: word,
          correctRomaji: example.reading,
          answerInHiragana: true,
        );
      }
    }
    return null;
  }

  for (final kana in allKana) {
    if (kana.id == cardId) {
      return BattleCard(
        id: cardId,
        prompt: kana.character,
        correctRomaji: kana.romaji,
        answerInHiragana: false,
      );
    }
  }
  return null;
}
