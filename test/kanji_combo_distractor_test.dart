import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/data/repositories/kanji_combo_repository.dart';
import 'package:kana_master/data/repositories/kanji_repository.dart';
import 'package:kana_master/data/repositories/kotoba_category_repository.dart';
import 'package:kana_master/data/repositories/kotoba_repository.dart';

bool _isKatakanaChar(String r) => r.codeUnitAt(0) >= 0x30A1 && r.codeUnitAt(0) <= 0x30F6;
bool _isHiraganaChar(String r) => r.codeUnitAt(0) >= 0x3041 && r.codeUnitAt(0) <= 0x3096;

/// A reading's script — used to catch the reported bug: single-kanji
/// reading questions mixed onyomi (katakana) and kunyomi (hiragana)
/// distractors for the same question, so a hiragana correct answer could
/// come with katakana wrong options and vice versa. Ignores the '-'
/// okurigana marker, which carries no script of its own.
String _scriptOf(String reading) {
  final hasKatakana = reading.runes.map(String.fromCharCode).any(_isKatakanaChar);
  final hasHiragana = reading.runes.map(String.fromCharCode).any(_isHiraganaChar);
  if (hasKatakana && !hasHiragana) return 'katakana';
  if (hasHiragana && !hasKatakana) return 'hiragana';
  return 'mixed-or-neither';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KanjiComboRepository single-kanji reading questions', () {
    test('every option in a reading question shares the correct answer\'s script', () async {
      final repo = KanjiComboRepository(
        kanjiRepository: KanjiRepository(),
        kotobaRepository: KotobaRepository(),
        kotobaCategoryRepository: KotobaCategoryRepository(),
        random: Random(42),
      );
      const labels = KanjiComboLabels();

      // Several levels, several generations each - the bug was
      // probabilistic (only surfaced when a same-length cross-script
      // reading happened to tie for "closest" by raw edit distance), so
      // one run isn't enough to trust a green result.
      var readingQuestionsChecked = 0;
      for (final level in [JlptLevel.n5, JlptLevel.n4, JlptLevel.n1]) {
        for (var run = 0; run < 5; run++) {
          final questions = await repo.generateQuestions(
            level,
            combination: false,
            labels: labels,
            count: 50,
          );
          for (final q in questions) {
            if (q.promptLabel != labels.reading) continue;
            readingQuestionsChecked++;
            final correctAnswer = q.options[q.correctIndex];
            final correctScript = _scriptOf(correctAnswer);
            for (final option in q.options) {
              expect(
                _scriptOf(option),
                correctScript,
                reason: 'kanji "${q.prompt}": option "$option" is '
                    '${_scriptOf(option)} but the correct answer '
                    '"$correctAnswer" is $correctScript — '
                    'options: ${q.options}',
              );
            }
          }
        }
      }
      // Sanity check the test actually exercised the reading-question
      // path at all, not just meaning questions every time.
      expect(readingQuestionsChecked, greaterThan(50));
    });

    test('a kunyomi reading question shows the okurigana in the prompt, '
        'never the bare character alone', () async {
      // The reported bug: 終's kunyomi is ["お-わる", "お-える"] — two
      // genuinely different words (owaru "to end" vs oeru "to finish")
      // sharing one kanji. The prompt used to always be the bare
      // character with no okurigana, so a session that happened to test
      // おえる looked wrong to a learner who only knew おわる — nothing in
      // the question distinguished which of the two was actually being
      // asked. The prompt must now carry whichever okurigana matches the
      // reading actually marked correct.
      final repo = KanjiComboRepository(
        kanjiRepository: KanjiRepository(),
        kotobaRepository: KotobaRepository(),
        kotobaCategoryRepository: KotobaCategoryRepository(),
        random: Random(7),
      );
      const labels = KanjiComboLabels();

      var kunyomiReadingQuestionsChecked = 0;
      for (final level in [JlptLevel.n5, JlptLevel.n4, JlptLevel.n3, JlptLevel.n2, JlptLevel.n1]) {
        for (var run = 0; run < 8; run++) {
          final questions = await repo.generateQuestions(
            level,
            combination: false,
            labels: labels,
            count: 50,
          );
          for (final q in questions) {
            if (q.promptLabel != labels.reading) continue;
            final correctAnswer = q.options[q.correctIndex];
            final dash = correctAnswer.indexOf('-');
            if (dash == -1) continue; // onyomi — no okurigana to show
            kunyomiReadingQuestionsChecked++;
            final okurigana = correctAnswer.substring(dash + 1);
            expect(
              q.prompt.endsWith(okurigana),
              isTrue,
              reason: 'prompt "${q.prompt}" does not carry the okurigana '
                  'from its own correct answer "$correctAnswer"',
            );
            expect(
              q.prompt.length,
              greaterThan(1),
              reason: 'prompt "${q.prompt}" is just the bare character, '
                  'giving no way to tell which kunyomi is being asked',
            );
          }
        }
      }
      expect(kunyomiReadingQuestionsChecked, greaterThan(20));
    });

    test('an onyomi reading question still shows only the bare character '
        '— onyomi never carries okurigana to disambiguate with', () async {
      final repo = KanjiComboRepository(
        kanjiRepository: KanjiRepository(),
        kotobaRepository: KotobaRepository(),
        kotobaCategoryRepository: KotobaCategoryRepository(),
        random: Random(9),
      );
      const labels = KanjiComboLabels();

      var onyomiReadingQuestionsChecked = 0;
      for (var run = 0; run < 8; run++) {
        final questions = await repo.generateQuestions(
          JlptLevel.n1,
          combination: false,
          labels: labels,
          count: 50,
        );
        for (final q in questions) {
          if (q.promptLabel != labels.reading) continue;
          final correctAnswer = q.options[q.correctIndex];
          if (correctAnswer.contains('-')) continue; // kunyomi, covered above
          onyomiReadingQuestionsChecked++;
          expect(q.prompt.length, 1, reason: 'onyomi prompt "${q.prompt}" '
              'should be exactly the bare character');
        }
      }
      expect(onyomiReadingQuestionsChecked, greaterThan(20));
    });
  });

  group('generateMutationDistractors', () {
    test('never returns the correct answer itself', () {
      final random = Random(1);
      for (final reading in ['じじょう', 'きげん', 'せいしょうねん', 'つか']) {
        final distractors = generateMutationDistractors(reading, 3, random);
        expect(distractors.contains(reading), isFalse);
      }
    });

    test('never produces duplicates (enforced by Set, sanity-checked anyway)', () {
      final random = Random(2);
      final distractors = generateMutationDistractors('しょうがっこう', 3, random);
      expect(distractors.length, distractors.toSet().length);
    });

    test('preserves mora count for a typical multi-mora reading', () {
      final random = Random(3);
      const correct = 'じじょう'; // mora: じ, じょ, う
      final distractors = generateMutationDistractors(correct, 3, random);
      for (final d in distractors) {
        expect(_moraCount(d), _moraCount(correct));
      }
    });

    test('handles katakana onyomi and keeps the result in katakana', () {
      final random = Random(4);
      final distractors = generateMutationDistractors('セン', 3, random);
      for (final d in distractors) {
        expect(d.runes.every((r) => r >= 0x30A1 && r <= 0x30F6), isTrue);
      }
    });

    test('treats a hyphenated okurigana marker as immutable', () {
      final random = Random(5);
      final distractors = generateMutationDistractors('のこ-す', 5, random);
      for (final d in distractors) {
        expect(d.contains('-'), isTrue);
      }
    });

    test('never yields a distractor starting with ん/ン/を/ヲ', () {
      final random = Random(6);
      for (final reading in ['げんそう', 'んき', 'じじょう', 'きげん']) {
        final distractors = generateMutationDistractors(reading, 3, random);
        for (final d in distractors) {
          expect(isValidKotobaStart(d), isTrue, reason: '$d should not start with ん/ン/を/ヲ');
        }
      }
    });

    test('degrades gracefully (fewer than n) for a structurally limited reading', () {
      final random = Random(7);
      // わ has no dakuten pair, and its only other vowel-row members (を, ん)
      // are banned as word-initial - no valid single-mora mutation exists.
      final distractors = generateMutationDistractors('わ', 3, random);
      expect(distractors.length, lessThan(3));
    });
  });

  group('isValidKotobaStart', () {
    test('rejects ん/ン/を/ヲ as the first mora', () {
      expect(isValidKotobaStart('んき'), isFalse);
      expect(isValidKotobaStart('ンキ'), isFalse);
      expect(isValidKotobaStart('をんな'), isFalse);
      expect(isValidKotobaStart('ヲンナ'), isFalse);
    });

    test('accepts normal readings', () {
      expect(isValidKotobaStart('じじょう'), isTrue);
      expect(isValidKotobaStart('きん'), isTrue);
    });
  });
}

int _moraCount(String reading) {
  var count = 0;
  var i = 0;
  final chars = reading.runes.map(String.fromCharCode).toList();
  const smallY = {'ゃ', 'ゅ', 'ょ'};
  while (i < chars.length) {
    if (chars[i] == '-') {
      i += 1;
      continue;
    }
    count++;
    if (i + 1 < chars.length && smallY.contains(chars[i + 1])) {
      i += 2;
    } else {
      i += 1;
    }
  }
  return count;
}
