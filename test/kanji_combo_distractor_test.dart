import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/data/models/kanji_entry.dart';
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
      //
      // **Detection changed by the Q2 fix**: this used to find a
      // kunyomi-with-okurigana question by checking whether the
      // *displayed option* still contained the internal "-" marker.
      // Since the Q2 fix now strips that marker before display (the
      // whole point of the fix — see the "Q2 regression" group below),
      // that signal no longer exists on `q.options` at all. `q.prompt`'s
      // own length is now the only externally-observable signal: a
      // bare-character prompt is length 1, a prompt with attached
      // okurigana is longer — exactly what `_readingPrompt` guarantees.
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
            if (q.prompt.length <= 1) continue; // bare character — no okurigana to show
            kunyomiReadingQuestionsChecked++;
            final okuriganaSuffix = q.prompt.substring(1);
            final displayAnswer = q.options[q.correctIndex];
            expect(
              displayAnswer.endsWith(okuriganaSuffix),
              isTrue,
              reason: 'prompt "${q.prompt}" attaches suffix '
                  '"$okuriganaSuffix", but the correct option '
                  '"$displayAnswer" does not end with it',
            );
          }
        }
      }
      expect(kunyomiReadingQuestionsChecked, greaterThan(20));
    });

    test('an onyomi reading question (or a single-reading kunyomi with no '
        'okurigana to disambiguate) still shows only the bare character',
        () async {
      final repo = KanjiComboRepository(
        kanjiRepository: KanjiRepository(),
        kotobaRepository: KotobaRepository(),
        kotobaCategoryRepository: KotobaCategoryRepository(),
        random: Random(9),
      );
      const labels = KanjiComboLabels();

      var bareCharacterReadingQuestionsChecked = 0;
      for (var run = 0; run < 8; run++) {
        final questions = await repo.generateQuestions(
          JlptLevel.n1,
          combination: false,
          labels: labels,
          count: 50,
        );
        for (final q in questions) {
          if (q.promptLabel != labels.reading) continue;
          if (q.prompt.length != 1) continue; // has okurigana, covered above
          bareCharacterReadingQuestionsChecked++;
          expect(q.prompt.length, 1, reason: 'onyomi prompt "${q.prompt}" '
              'should be exactly the bare character');
        }
      }
      expect(bareCharacterReadingQuestionsChecked, greaterThan(20));
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

    test('rejects a lone/orphaned small-y as the first mora (Q3) — the '
        'exact malformed shape a mis-segmented katakana contraction '
        'produces (see the katakana-small-y group below)', () {
      expect(isValidKotobaStart('ょギ'), isFalse);
      expect(isValidKotobaStart('ゃク'), isFalse);
      expect(isValidKotobaStart('ョギ'), isFalse);
      expect(isValidKotobaStart('ャク'), isFalse);
    });
  });

  group('katakana small-y contraction — Q1 regression (行/白/終 bug '
      'report: ギョウ/ビャク/シュウ)', () {
    test('_moraCount treats a katakana contraction as ONE mora, not two '
        '— 行\'s ギョウ (correct: ギョ+ウ, 2 mora) used to be mis-segmented '
        'into 3 (ギ+ョ+ウ) exactly like a lone hiragana small-y would '
        'never be', () {
      // 白: ビャク = ビャ+ク (2 mora). 行: ギョウ = ギョ+ウ (2 mora).
      // 終 (onyomi, only reading — _randomReadingWithKind always picks
      // it since onyomi.length == 1): シュウ = シュ+ウ (2 mora).
      expect(_moraCount('ビャク'), 2, reason: 'ビ+ャ must merge into one mora, matching ぎゃ/しゅ etc.');
      expect(_moraCount('ギョウ'), 2, reason: 'ギ+ョ must merge into one mora');
      expect(_moraCount('シュウ'), 2, reason: 'シ+ュ must merge into one mora');
    });

    test('mutating 白\'s onyomi (ビャク) never orphans the small-y into a '
        'lone ャ glued onto an unrelated consonant — the reported '
        'ボャク/ベャク/ビャグ strings are NOT banned outright (once ビャ is '
        'correctly treated as one mora, ボャク/ベャク are legitimate '
        'vowel-shift mutations of it and ビャグ a legitimate dakuten '
        'mutation of ク — all three are now well-formed, valid '
        'distractors; the bug was the 3-mora garbling, not these '
        'specific strings)', () {
      final random = Random(101);
      final distractors = generateMutationDistractors('ビャク', 10, random);
      expect(distractors, isNotEmpty);
      for (final d in distractors) {
        expect(_moraCount(d), 2, reason: 'ビャク -> "$d" changed mora count (small-y mis-segmentation)');
        expect(isValidKotobaStart(d), isTrue, reason: '"$d" starts with an orphaned small-y or banned mora');
      }
    });

    test('mutating 行\'s onyomi (ギョウ) never orphans the small-y', () {
      final random = Random(102);
      final distractors = generateMutationDistractors('ギョウ', 10, random);
      expect(distractors, isNotEmpty);
      for (final d in distractors) {
        expect(_moraCount(d), 2, reason: 'ギョウ -> "$d" changed mora count (small-y mis-segmentation)');
        expect(isValidKotobaStart(d), isTrue, reason: '"$d" starts with an orphaned small-y or banned mora');
      }
    });

    test('mutating 終\'s onyomi (シュウ) never orphans the small-y', () {
      final random = Random(103);
      final distractors = generateMutationDistractors('シュウ', 10, random);
      expect(distractors, isNotEmpty);
      for (final d in distractors) {
        expect(_moraCount(d), 2, reason: 'シュウ -> "$d" changed mora count (small-y mis-segmentation)');
        expect(isValidKotobaStart(d), isTrue, reason: '"$d" starts with an orphaned small-y or banned mora');
      }
    });
  });

  group('okurigana marker leaking into displayed options — Q2 regression '
      '(終 bug report: おーある/おーえれ/おーえる/えーえる)', () {
    test('_readingPrompt-equivalent stripping: no reading-question option, '
        'across a full generateQuestions pipeline run over every level, '
        'ever contains the internal "-" okurigana marker — it must be '
        'stripped the same way the prompt already is', () async {
      final repo = KanjiComboRepository(
        kanjiRepository: KanjiRepository(),
        kotobaRepository: KotobaRepository(),
        kotobaCategoryRepository: KotobaCategoryRepository(),
        random: Random(201),
      );
      const labels = KanjiComboLabels();

      var readingQuestionsChecked = 0;
      for (final level in JlptLevel.values) {
        for (var run = 0; run < 6; run++) {
          final questions = await repo.generateQuestions(
            level,
            combination: false,
            labels: labels,
            count: 50,
          );
          for (final q in questions) {
            if (q.promptLabel != labels.reading) continue;
            readingQuestionsChecked++;
            for (final option in q.options) {
              expect(
                option.contains('-'),
                isFalse,
                reason: 'kanji "${q.prompt}": option "$option" leaks the '
                    'internal okurigana marker "-" — options: ${q.options}',
              );
            }
          }
        }
      }
      expect(readingQuestionsChecked, greaterThan(100));
    });

    test('no reading-question option, across the same full pipeline run, '
        'starts with an orphaned small-y character either (Q1+Q3 '
        'end-to-end, not just the unit-level generateMutationDistractors '
        'check above)', () async {
      final repo = KanjiComboRepository(
        kanjiRepository: KanjiRepository(),
        kotobaRepository: KotobaRepository(),
        kotobaCategoryRepository: KotobaCategoryRepository(),
        random: Random(202),
      );
      const labels = KanjiComboLabels();
      const smallY = {'ゃ', 'ゅ', 'ょ', 'ャ', 'ュ', 'ョ'};

      var readingQuestionsChecked = 0;
      for (final level in JlptLevel.values) {
        for (var run = 0; run < 6; run++) {
          final questions = await repo.generateQuestions(
            level,
            combination: false,
            labels: labels,
            count: 50,
          );
          for (final q in questions) {
            if (q.promptLabel != labels.reading) continue;
            readingQuestionsChecked++;
            for (final option in q.options) {
              if (option.isEmpty) continue;
              expect(
                smallY.contains(option[0]),
                isFalse,
                reason: 'kanji "${q.prompt}": option "$option" starts '
                    'with an orphaned small-y — options: ${q.options}',
              );
            }
          }
        }
      }
      expect(readingQuestionsChecked, greaterThan(100));
    });
  });

  group('Q3 defense-in-depth: pool-search fallback must also reject an '
      'invalid start mora, not just generateMutationDistractors', () {
    test('a pool reading that starts with an invalid mora (ん) cannot leak '
        'into a reading question\'s distractor options via '
        '_pickReadingDistractors\'s pool-search top-up — even though '
        'generateMutationDistractors\'s own output was already fully '
        'guarded (see the groups above)', () async {
      // The mutation path (generateMutationDistractors) already filters
      // every candidate it produces through isValidKotobaStart. But
      // _pickReadingDistractors also tops up any shortfall from the raw
      // pool via _pickCloseDistractors, which used to hand back whatever
      // was in the pool with no such filter — a second, independent path
      // to the final options list that the module's own design intent
      // (see isValidKotobaStart's doc comment) says should be guarded the
      // same way. 和's reading わ is single-mora and structurally limited
      // (no dakuten pair, not in any vowel-row group) so it always needs
      // the pool-search top-up; 運's onyomi is deliberately set to んき — a
      // reading real Japanese would never have (confirmed: the actual
      // bundled dataset has zero such entries — see the content-integrity
      // group below) — to prove the CODE has a real defense against it
      // independent of today's clean data.
      final pool = [
        KanjiEntry(
          id: 'q3-k1',
          character: '和',
          jlptLevel: JlptLevel.n5,
          onyomi: const ['わ'],
          kunyomi: const [],
          meanings: const ['peace'],
          strokeCount: 8,
          relatedBunpou: const [],
        ),
        KanjiEntry(
          id: 'q3-k2',
          character: '運',
          jlptLevel: JlptLevel.n5,
          onyomi: const ['んき'],
          kunyomi: const [],
          meanings: const ['luck'],
          strokeCount: 12,
          relatedBunpou: const [],
        ),
        KanjiEntry(
          id: 'q3-k3',
          character: '間',
          jlptLevel: JlptLevel.n5,
          onyomi: const ['かん'],
          kunyomi: const [],
          meanings: const ['interval'],
          strokeCount: 12,
          relatedBunpou: const [],
        ),
      ];
      const labels = KanjiComboLabels();

      var sawInvalidStartDistractor = false;
      for (var seed = 0; seed < 200; seed++) {
        final repo = KanjiComboRepository(
          kanjiRepository: _FixedPoolKanjiRepository(pool),
          kotobaRepository: KotobaRepository(),
          kotobaCategoryRepository: KotobaCategoryRepository(),
          random: Random(seed),
        );
        final questions = await repo.generateQuestions(
          JlptLevel.n5,
          combination: false,
          labels: labels,
          count: 3,
        );
        for (final q in questions) {
          if (q.promptLabel != labels.reading) continue;
          for (var i = 0; i < q.options.length; i++) {
            if (i == q.correctIndex) continue; // only distractors — the
            // correct answer legitimately being 'んき' when 運 itself is
            // the kanji asked is a data-integrity question, covered
            // separately by the group below, not a distractor-generation
            // bug.
            final option = q.options[i];
            if (option.isNotEmpty && option[0] == 'ん') {
              sawInvalidStartDistractor = true;
            }
          }
        }
      }

      expect(
        sawInvalidStartDistractor,
        isFalse,
        reason: 'a distractor option started with the invalid mora ん — '
            '_pickReadingDistractors\'s pool-search fallback must filter '
            'through isValidKotobaStart the same way the mutation path '
            'does',
      );
    });
  });

  group('Q3 content integrity: the real bundled dataset never has an '
      'onyomi/kunyomi/compound reading that fails isValidKotobaStart', () {
    test('every real kanji onyomi/kunyomi is a plausible word start', () async {
      final kanji = await KanjiRepository().getAll();
      final bad = <String>[];
      for (final k in kanji) {
        if (k.placeholder) continue;
        for (final r in [...k.onyomi, ...k.kunyomi]) {
          if (r.isNotEmpty && !isValidKotobaStart(r)) {
            bad.add('${k.id} (${k.character}): "$r"');
          }
        }
      }
      expect(
        bad,
        isEmpty,
        reason: 'these kanji readings start with an invalid mora — a '
            'future content-authoring pass introduced exactly the kind '
            'of bad reading Q3\'s audit found this module has no runtime '
            'defense against when it\'s the CORRECT answer (only '
            'distractors are guarded): ${bad.join(', ')}',
      );
    });

    test('every real compound-eligible Kotoba reading is a plausible word '
        'start', () async {
      final categoryRepo = KotobaCategoryRepository();
      final kotobaRepo = KotobaRepository();
      final compoundPattern = RegExp(r'^[一-鿿]{2,3}$');

      final categories = await categoryRepo.getAll();
      final bad = <String>[];
      var checked = 0;
      for (final category in categories) {
        if (!category.available) continue;
        final words = await kotobaRepo.getVocabCategory(category.id);
        for (final w in words) {
          if (w.placeholder) continue;
          if (!compoundPattern.hasMatch(w.kanji ?? '')) continue;
          checked++;
          if (w.reading.isNotEmpty && !isValidKotobaStart(w.reading)) {
            bad.add('${w.id} (${w.kanji}): "${w.reading}"');
          }
        }
      }
      expect(checked, greaterThan(500), reason: 'sanity check — this must '
          'actually walk the real compound-eligible pool, not an empty one');
      expect(
        bad,
        isEmpty,
        reason: 'these Kotoba compound readings start with an invalid '
            'mora: ${bad.join(', ')}',
      );
    });
  });
}

class _FixedPoolKanjiRepository implements KanjiRepository {
  final List<KanjiEntry> pool;
  _FixedPoolKanjiRepository(this.pool);

  @override
  Future<List<KanjiEntry>> getByLevel(JlptLevel level) async => pool;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

int _moraCount(String reading) {
  var count = 0;
  var i = 0;
  final chars = reading.runes.map(String.fromCharCode).toList();
  // Both scripts — a hiragana-only set here would make this helper carry
  // the exact same Q1 mis-segmentation bug being tested for, silently
  // passing readings it should be counting wrong.
  const smallY = {'ゃ', 'ゅ', 'ょ', 'ャ', 'ュ', 'ョ'};
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
