import 'dart:math';

import '../models/app_language.dart';
import '../models/jlpt_level.dart';
import '../models/kanji_combo_question.dart';
import '../models/kanji_entry.dart';
import '../models/kotoba_entry.dart';
import 'kanji_repository.dart';
import 'kotoba_category_repository.dart';
import 'kotoba_repository.dart';

/// A 2-3 raw-kanji compound word, no kana mixed in (e.g. 図書館, 電話) —
/// matches the same character range KanjiVG/this app's kanji dataset uses.
final _compoundPattern = RegExp(r'^[一-鿿]{2,3}$');

const _minPoolSize = 4;

/// Kana pairs that only differ by a dakuten/handakuten (voicing) mark,
/// grouped so a mutation can jump from any member to any other in the same
/// group (e.g. か -> が, は -> ば -> ぱ). Includes small-y digraphs (きゃ,
/// しゅ, etc.) as their own tokens since they're single mora, not two.
const _dakutenGroups = <List<String>>[
  ['か', 'が'], ['き', 'ぎ'], ['く', 'ぐ'], ['け', 'げ'], ['こ', 'ご'],
  ['さ', 'ざ'], ['し', 'じ'], ['す', 'ず'], ['せ', 'ぜ'], ['そ', 'ぞ'],
  ['た', 'だ'], ['ち', 'ぢ'], ['つ', 'づ'], ['て', 'で'], ['と', 'ど'],
  ['は', 'ば', 'ぱ'], ['ひ', 'び', 'ぴ'], ['ふ', 'ぶ', 'ぷ'], ['へ', 'べ', 'ぺ'], ['ほ', 'ぼ', 'ぽ'],
  ['きゃ', 'ぎゃ'], ['きゅ', 'ぎゅ'], ['きょ', 'ぎょ'],
  ['しゃ', 'じゃ'], ['しゅ', 'じゅ'], ['しょ', 'じょ'],
  ['ちゃ', 'ぢゃ'], ['ちゅ', 'ぢゅ'], ['ちょ', 'ぢょ'],
  ['ひゃ', 'びゃ', 'ぴゃ'], ['ひゅ', 'びゅ', 'ぴゅ'], ['ひょ', 'びょ', 'ぴょ'],
];

/// Kana that share the same consonant but differ in vowel, grouped by row
/// (e.g. さしすせそ) so a mutation can swap the vowel while keeping the
/// consonant. Includes や/ゆ/よ as their own (incomplete, historically
/// defective) row - it's still a real phonetic neighborhood even without
/// an い/え member.
const _vowelRowGroups = <List<String>>[
  ['あ', 'い', 'う', 'え', 'お'],
  ['か', 'き', 'く', 'け', 'こ'], ['が', 'ぎ', 'ぐ', 'げ', 'ご'],
  ['さ', 'し', 'す', 'せ', 'そ'], ['ざ', 'じ', 'ず', 'ぜ', 'ぞ'],
  ['た', 'ち', 'つ', 'て', 'と'], ['だ', 'ぢ', 'づ', 'で', 'ど'],
  ['な', 'に', 'ぬ', 'ね', 'の'],
  ['は', 'ひ', 'ふ', 'へ', 'ほ'], ['ば', 'び', 'ぶ', 'べ', 'ぼ'], ['ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ'],
  ['ま', 'み', 'む', 'め', 'も'],
  ['ら', 'り', 'る', 'れ', 'ろ'],
  ['や', 'ゆ', 'よ'],
];

/// Both scripts — onyomi are written in katakana throughout this dataset
/// (ギョウ, ビャク, シュウ), and a hiragana-only set here mis-segments a
/// katakana contraction into two separate mora (ギ, ョ, ウ instead of
/// ギョ, ウ), which then lets the orphaned small-y drift onto an
/// unrelated consonant during mutation — a real, reported bug (行 -> a
/// stray ョ; 白's ビャク -> ボャク/ベャク/ビャグ; see
/// `test/kanji_combo_distractor_test.dart`'s "Q1 regression" group for
/// the exact reproduction).
const _smallY = {'ゃ', 'ゅ', 'ょ', 'ャ', 'ュ', 'ョ'};

/// Mora a real Japanese reading may never *start* with - ん/ン never opens
/// a word, and を/ヲ exists only as the object-marker particle, never as a
/// word's first syllable. A distractor starting with one of these would
/// look immediately, obviously fake to a learner.
///
/// Also includes a bare small-y (ゃゅょ/ャュョ) on its own — not a real
/// mora at all, only ever valid merged onto a preceding consonant
/// (きゃ/ギョ etc., handled by [_splitMora]). Defense-in-depth alongside
/// the Q1 fix to [_smallY]: with mora segmentation now correct, a
/// mutation should never isolate one on its own again, but a distractor
/// starting with a lone small-y would be an immediately obvious fake to
/// a learner the same way ん/を is, so it stays rejected here too rather
/// than relying on segmentation alone to prevent it.
const _invalidStartMora = {'ん', 'ン', 'を', 'ヲ', 'ゃ', 'ゅ', 'ょ', 'ャ', 'ュ', 'ョ'};

String _toHiragana(String s) => String.fromCharCodes(
      s.runes.map((r) => (r >= 0x30A1 && r <= 0x30F6) ? r - 0x60 : r),
    );

String _toKatakana(String s) => String.fromCharCodes(
      s.runes.map((r) => (r >= 0x3041 && r <= 0x3096) ? r + 0x60 : r),
    );

bool _isKatakana(String s) => s.runes.any((r) => r >= 0x30A1 && r <= 0x30F6);

/// Splits a reading into mora tokens. A standalone "-" (the okurigana
/// boundary marker some kunyomi entries use, e.g. "のこ-す") is kept as its
/// own immutable token so mutation never touches it. Small-y kana combine
/// with the preceding consonant-kana into one two-character mora (きゃ,
/// しゅ, etc.) rather than being split into two mora.
List<String> _splitMora(String reading) {
  final chars = reading.runes.map(String.fromCharCode).toList();
  final mora = <String>[];
  var i = 0;
  while (i < chars.length) {
    if (chars[i] == '-') {
      mora.add('-');
      i += 1;
      continue;
    }
    if (i + 1 < chars.length && _smallY.contains(chars[i + 1])) {
      mora.add(chars[i] + chars[i + 1]);
      i += 2;
    } else {
      mora.add(chars[i]);
      i += 1;
    }
  }
  return mora;
}

List<String>? _mutateDakuten(List<String> mora, int idx, Random random) {
  final token = mora[idx];
  final wasKatakana = _isKatakana(token);
  final base = _toHiragana(token);
  final group = _dakutenGroups.firstWhere((g) => g.contains(base), orElse: () => const []);
  if (group.isEmpty) return null;
  final options = group.where((m) => m != base).toList();
  if (options.isEmpty) return null;
  final replacement = options[random.nextInt(options.length)];
  final copy = List<String>.from(mora);
  copy[idx] = wasKatakana ? _toKatakana(replacement) : replacement;
  return copy;
}

List<String>? _mutateVowel(List<String> mora, int idx, Random random) {
  final token = mora[idx];
  final wasKatakana = _isKatakana(token);
  final base = _toHiragana(token);
  final group = _vowelRowGroups.firstWhere((g) => g.contains(base), orElse: () => const []);
  if (group.isEmpty) return null;
  final options = group.where((m) => m != base).toList();
  if (options.isEmpty) return null;
  final replacement = options[random.nextInt(options.length)];
  final copy = List<String>.from(mora);
  copy[idx] = wasKatakana ? _toKatakana(replacement) : replacement;
  return copy;
}

List<String>? _mutateSwap(List<String> mora, int idx, Random random) {
  if (idx + 1 >= mora.length) return null;
  if (mora[idx] == '-' || mora[idx + 1] == '-') return null;
  final copy = List<String>.from(mora);
  final tmp = copy[idx];
  copy[idx] = copy[idx + 1];
  copy[idx + 1] = tmp;
  return copy;
}

/// True if [reading] is a plausible word-initial kana string - its first
/// mora (skipping a leading "-", which shouldn't occur but is guarded
/// anyway) is not in [_invalidStartMora].
bool isValidKotobaStart(String reading) {
  for (final m in _splitMora(reading)) {
    if (m == '-') continue;
    return !_invalidStartMora.contains(m);
  }
  return true;
}

/// Generates up to [n] distinct kana-mutation distractors for
/// [correctReading] by mutating the reading itself - toggling a mora's
/// dakuten/handakuten mark, shifting a mora's vowel within its consonant
/// row, or swapping two adjacent mora - rather than searching the pool for
/// a close match. Every result is therefore guaranteed same mora-length as
/// the original and differs by exactly one small step, and any candidate
/// that fails [isValidKotobaStart] (would start with ん/ン/を/ヲ) is
/// discarded and another mutation attempted instead. May return fewer than
/// [n] for very short readings that don't have enough valid mutable
/// positions (e.g. a single-mora わ reading has no dakuten pair and no
/// other valid same-row neighbor) - callers should top up any shortfall
/// from another source.
Set<String> generateMutationDistractors(String correctReading, int n, Random random) {
  final mora = _splitMora(correctReading);
  final mutablePositions = [
    for (var i = 0; i < mora.length; i++)
      if (mora[i] != '-') i
  ];
  if (mutablePositions.isEmpty) return {};

  final results = <String>{};
  var guard = 0;
  while (results.length < n && guard < 300) {
    guard++;
    final idx = mutablePositions[random.nextInt(mutablePositions.length)];
    final strategy = random.nextInt(3);
    List<String>? mutated;
    switch (strategy) {
      case 0:
        mutated = _mutateDakuten(mora, idx, random);
        break;
      case 1:
        mutated = _mutateVowel(mora, idx, random);
        break;
      default:
        mutated = _mutateSwap(mora, idx, random);
    }
    if (mutated == null) continue;
    final candidate = mutated.join();
    if (candidate == correctReading) continue;
    if (!isValidKotobaStart(candidate)) continue;
    results.add(candidate);
  }
  return results;
}

/// Kanji-Kombinasi exam content, generated at runtime from the existing
/// Kanji and Kotoba datasets rather than a bundled dataset of its own —
/// single-kanji questions come straight from [KanjiRepository]; compound
/// questions are mined from [KotobaEntry.kanji] entries that are exactly a
/// 2-3 character kanji compound with a real (non-placeholder) reading
/// already authored. No new content-authoring pipeline needed for either
/// mode.
///
/// Compound candidates are pooled from the full 519-word Batch 6 vocab
/// module (`assets/data/kotoba/{category}.json`, via
/// [KotobaRepository.getVocabCategory] across every category
/// [KotobaCategoryRepository] marks available) rather than the ~30-entry
/// Batch 4 dictionary seed (`kotoba_data.json`, [KotobaRepository.getByLevel])
/// — the seed file is N5-only and was never meant as this feature's real
/// data source; using it left Kombinasi mode locked behind a "Segera" badge
/// for N4/N3/N2/N1 with only 0-8 eligible words per level. Pooling from the
/// vocab module instead raises that to 53/56/61/19 words for N5/N4/N3/N2
/// respectively — only N1 stays locked, since the vocab module itself has
/// just 1 N1-tagged word so far (a content gap in Kotoba itself, not
/// something this repository can work around).
/// Language-dependent inputs for [KanjiComboRepository.generateQuestions]:
/// the three prompt wordings, plus the language the meaning options should
/// be drawn in. Defaults keep the original Indonesian wording so callers
/// that don't care (tests, tooling) need no extra argument.
class KanjiComboLabels {
  final String meaning;
  final String reading;
  final String compound;
  final AppLanguage language;

  const KanjiComboLabels({
    this.meaning = 'Apa artinya kanji ini?',
    this.reading = 'Bagaimana bacaan kanji ini?',
    this.compound = 'Bagaimana bacaan kata ini?',
    this.language = AppLanguage.indonesian,
  });
}

class KanjiComboRepository {
  final KanjiRepository kanjiRepository;
  final KotobaRepository kotobaRepository;
  final KotobaCategoryRepository kotobaCategoryRepository;
  final Random _random;

  KanjiComboRepository({
    required this.kanjiRepository,
    required this.kotobaRepository,
    required this.kotobaCategoryRepository,
    Random? random,
  }) : _random = random ?? Random();

  List<KotobaEntry>? _vocabWordsCache;

  Future<List<KotobaEntry>> _allVocabWords() async {
    final cached = _vocabWordsCache;
    if (cached != null) return cached;
    final categories = await kotobaCategoryRepository.getAll();
    final words = <KotobaEntry>[];
    for (final category in categories) {
      if (!category.available) continue;
      words.addAll(await kotobaRepository.getVocabCategory(category.id));
    }
    _vocabWordsCache = words;
    return words;
  }

  Future<List<KanjiEntry>> _singlePool(JlptLevel level) async {
    final all = await kanjiRepository.getByLevel(level);
    return all.where((k) => !k.placeholder && k.meanings.isNotEmpty).toList();
  }

  Future<List<KotobaEntry>> _compoundPool(JlptLevel level) async {
    final all = await _allVocabWords();
    return all
        .where((w) =>
            w.jlptLevel == level &&
            !w.placeholder &&
            _compoundPattern.hasMatch(w.kanji ?? ''))
        .toList();
  }

  Future<bool> isLevelAvailable(JlptLevel level, {required bool combination}) async {
    final pool = combination ? await _compoundPool(level) : await _singlePool(level);
    return pool.length >= _minPoolSize;
  }

  /// Character-level Levenshtein distance. Hiragana readings are short
  /// enough (2-6 characters) that this approximates mora-level distance
  /// well without needing real mora segmentation — most mora are exactly
  /// one character, small-y digraphs (きゃ, しゅ, etc.) are two.
  static int _editDistance(String a, String b) {
    final la = a.length, lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;
    var prev = List<int>.generate(lb + 1, (j) => j);
    for (var i = 1; i <= la; i++) {
      final curr = List<int>.filled(lb + 1, 0);
      curr[0] = i;
      for (var j = 1; j <= lb; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        curr[j] = [prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost].reduce(min);
      }
      prev = curr;
    }
    return prev[lb];
  }

  /// Picks [n] distractors that read *similarly* to [correctAnswer] from a
  /// pool of candidates, ranked by edit distance rather than picked
  /// uniformly at random. Used as [_pickReadingDistractors]'s fallback
  /// top-up for readings too short/structurally limited for
  /// [generateMutationDistractors] to produce enough valid mutations on its
  /// own. Picks randomly *among* the closest matches (not always the single
  /// closest) so repeated attempts at the same word don't always show the
  /// same four options.
  Set<String> _pickCloseDistractors(String correctAnswer, Iterable<String> candidates, int n) {
    final unique = candidates.toSet()..remove(correctAnswer);
    if (unique.length <= n) return unique;
    final ranked = unique.toList()
      ..sort((a, b) => _editDistance(a, correctAnswer).compareTo(_editDistance(b, correctAnswer)));
    final closePoolSize = min(ranked.length, max(n * 3, 8));
    final closePool = ranked.take(closePoolSize).toList()..shuffle(_random);
    return closePool.take(n).toSet();
  }

  /// Picks [n] distractors for a *reading* question: mutation-based
  /// ([generateMutationDistractors]) first, since a single-kana-step
  /// mutation of the real reading is a closer, more deliberately-crafted
  /// near-miss than anything a pool search can offer. If the reading is too
  /// short/structurally limited to yield [n] valid mutations on its own
  /// (e.g. single-mora わ has no dakuten pair and を/ん are the only other
  /// members of its row, both banned as word-initial by
  /// [isValidKotobaStart]), the shortfall is topped up from [poolCandidates]
  /// via the old edit-distance closeness ranking - the pool always has
  /// hundreds of other readings per level, so this always reaches [n].
  Set<String> _pickReadingDistractors(String correctAnswer, Iterable<String> poolCandidates, int n) {
    final mutated = generateMutationDistractors(correctAnswer, n, _random);
    if (mutated.length >= n) return mutated;
    final remainingPool = poolCandidates.where((c) => c != correctAnswer && !mutated.contains(c));
    final topUp = _pickCloseDistractors(correctAnswer, remainingPool, n - mutated.length);
    return {...mutated, ...topUp};
  }

  /// Picks [n] distractors uniformly at random - used for meaning options,
  /// where "closeness" isn't a phonetic concept the way it is for readings.
  Set<String> _pickRandomDistractors(String correctAnswer, Iterable<String> candidates, int n) {
    final distractors = <String>{};
    final shuffled = candidates.toList()..shuffle(_random);
    for (final c in shuffled) {
      if (distractors.length >= n) break;
      if (c == correctAnswer) continue;
      distractors.add(c);
    }
    return distractors;
  }

  /// Builds [count] 4-option multiple-choice questions for [level].
  /// Combination mode asks "bagaimana bacaannya" for a compound word
  /// (options = other compounds' readings). Single mode mixes two question
  /// kinds per exam — "apa artinya" (options = other kanjis' meanings) and
  /// "bagaimana bacaannya" (options = other kanjis' onyomi/kunyomi readings)
  /// — chosen per question rather than fixed for the whole session, so a
  /// single-kanji exam actually exercises both fields of [KanjiEntry]
  /// instead of only ever testing meaning.
  /// [labels] carries the exam's prompt wording and the app's current
  /// language, so both the question text and the meaning options follow the
  /// language toggle instead of always being Indonesian.
  Future<List<KanjiComboQuestion>> generateQuestions(
    JlptLevel level, {
    required bool combination,
    KanjiComboLabels labels = const KanjiComboLabels(),
    int count = 50,
  }) async {
    if (combination) {
      final pool = await _compoundPool(level);
      return _buildQuestions(
        pool,
        count: count,
        promptOf: (w) => w.kanji!,
        answerOf: (w) => w.reading,
        promptLabel: labels.compound,
      );
    }
    final pool = await _singlePool(level);
    return _buildSingleKanjiQuestions(pool, count: count, labels: labels);
  }

  List<KanjiComboQuestion> _buildQuestions<T>(
    List<T> pool, {
    required int count,
    required String Function(T) promptOf,
    required String Function(T) answerOf,
    required String promptLabel,
  }) {
    if (pool.length < 2) return [];
    final shuffled = List<T>.from(pool)..shuffle(_random);
    final selected = shuffled.take(min(count, shuffled.length)).toList();
    final allAnswers = pool.map(answerOf);

    return List.generate(selected.length, (i) {
      final item = selected[i];
      final correctAnswer = answerOf(item);
      final distractors = _pickReadingDistractors(correctAnswer, allAnswers, 3);
      final options = [correctAnswer, ...distractors]..shuffle(_random);
      return KanjiComboQuestion(
        id: 'kombo_$i',
        prompt: promptOf(item),
        options: options,
        correctIndex: options.indexOf(correctAnswer),
        promptLabel: promptLabel,
      );
    });
  }

  /// One random reading for [entry], reporting whether it came from
  /// [KanjiEntry.onyomi] or [KanjiEntry.kunyomi] — every real
  /// (non-placeholder) kanji in the dataset has at least one of either, so
  /// this never throws for pool entries.
  ///
  /// The kind matters to the caller because onyomi is written in katakana
  /// and kunyomi in hiragana throughout this dataset (イチ vs ひと, never
  /// mixed within one kanji's own entry) — a real, reported bug was a
  /// hiragana correct answer showing katakana options, traced to
  /// [_buildSingleKanjiQuestions] drawing distractors from *both* pooled
  /// together. Keeping distractors confined to the same kind as the
  /// correct answer fixes it at the source, not by filtering afterward.
  ///
  /// **Also fixes a second, separately-reported bug**: 340 of the 2425
  /// kanji in this dataset (14%) carry more than one kunyomi — e.g. 終's
  /// kunyomi is `["お-わる", "お-える"]`, おわる (intransitive "to end") and
  /// おえる (transitive "to finish") being genuinely different words that
  /// happen to share a kanji. The question used to show only the bare
  /// character with no okurigana, so a session that happened to land on
  /// おえる looked wrong to a learner who only knew おわる — both were
  /// really being tested, just never distinguishable from the prompt
  /// alone. [_buildSingleKanjiQuestions] now rebuilds the prompt with the
  /// picked reading's own okurigana attached (終える vs 終わる) whenever one
  /// exists, which is the normal way a dictionary or textbook disambiguates
  /// this too. Onyomi carries no okurigana at all (0 of the dataset's
  /// onyomi entries contain "-"), so that half of the ambiguity can't be
  /// fixed the same way — for a kind with more than one reading and no
  /// okurigana to attach (167 kanji with 2+ onyomi, plus 37 more kanji
  /// whose 2+ kunyomi are *all* okurigana-less), this always resolves to
  /// that kind's first-listed reading instead of a random one, since the
  /// dataset's own generator authors the primary reading first — the same
  /// "test the one thing every source agrees on" fallback, just without a
  /// visual prompt change to go with it.
  ({String reading, bool isOnyomi}) _randomReadingWithKind(KanjiEntry entry) {
    final combined = [...entry.onyomi, ...entry.kunyomi];
    final index = _random.nextInt(combined.length);
    final isOnyomi = index < entry.onyomi.length;
    var reading = combined[index];
    if (!reading.contains('-')) {
      final sameKind = isOnyomi ? entry.onyomi : entry.kunyomi;
      if (sameKind.length > 1) reading = sameKind.first;
    }
    return (reading: reading, isOnyomi: isOnyomi);
  }

  /// What to actually show for a reading question — the bare character
  /// for onyomi (never carries okurigana), or the character with its
  /// picked kunyomi's okurigana attached (終 + わる = 終わる) so a kanji with
  /// more than one kunyomi shows which one is being asked, rather than
  /// leaving the learner to guess between e.g. 終わる and 終える. See
  /// [_randomReadingWithKind]'s doc comment for the bug this closes.
  String _readingPrompt(KanjiEntry entry, String reading) {
    final dash = reading.indexOf('-');
    if (dash == -1) return entry.character;
    return entry.character + reading.substring(dash + 1);
  }

  /// Strips the internal okurigana boundary marker ("-", e.g. "お-える")
  /// before a reading is ever shown as an answer option — the marker is
  /// bookkeeping [_splitMora]/[generateMutationDistractors] need to know
  /// where a mutation may not touch, never something a learner should
  /// see. [_readingPrompt] already strips it for the *prompt*; this is
  /// the equivalent for *options*, a real, reported gap (a kunyomi
  /// reading question displayed raw strings like "お-える"/"お-ある", the
  /// dash misread as a chōonpu — see `test/kanji_combo_distractor_test.dart`'s
  /// "Q2 regression" group for the exact reproduction). Onyomi readings
  /// never contain "-" at all, so this is a no-op for them.
  String _stripOkuriganaMarker(String reading) => reading.replaceAll('-', '');

  List<KanjiComboQuestion> _buildSingleKanjiQuestions(
    List<KanjiEntry> pool, {
    required int count,
    required KanjiComboLabels labels,
  }) {
    if (pool.length < 2) return [];
    final shuffled = List<KanjiEntry>.from(pool)..shuffle(_random);
    final selected = shuffled.take(min(count, shuffled.length)).toList();

    return List.generate(selected.length, (i) {
      final item = selected[i];
      final askReading = _random.nextBool();

      // Excludes item itself - one of its *other* on'yomi/kun'yomi
      // readings (or meanings) would otherwise leak in as a "wrong"
      // answer that's technically still valid for this exact kanji.
      final otherEntries = pool.where((k) => !identical(k, item));

      final String correctAnswer;
      Set<String> distractors;
      var prompt = item.character;
      if (askReading) {
        final picked = _randomReadingWithKind(item);
        correctAnswer = picked.reading;
        prompt = _readingPrompt(item, picked.reading);
        // Same kind only (onyomi vs kunyomi) — see _randomReadingWithKind's
        // doc comment for why mixing them produced wrong-script options.
        distractors = _pickReadingDistractors(
          correctAnswer,
          otherEntries.expand((k) => picked.isOnyomi ? k.onyomi : k.kunyomi),
          3,
        );
      } else {
        correctAnswer = item.localizedMeaning(labels.language);
        distractors = _pickRandomDistractors(
          correctAnswer,
          otherEntries.map((k) => k.localizedMeaning(labels.language)),
          3,
        );
      }
      // Distractors/correctAnswer for a reading question are generated
      // and mutated against the RAW reading (with its "-" okurigana
      // marker still in place, since generateMutationDistractors needs
      // it to know which position is immutable) — stripped only here,
      // right before anything is actually shown to the learner. Meaning
      // questions never contain "-" to begin with, so this is a no-op
      // for them.
      final displayAnswer =
          askReading ? _stripOkuriganaMarker(correctAnswer) : correctAnswer;
      final displayDistractors = askReading
          ? distractors.map(_stripOkuriganaMarker).toSet()
          : distractors;
      final options = [displayAnswer, ...displayDistractors]..shuffle(_random);
      return KanjiComboQuestion(
        id: 'kombo_$i',
        prompt: prompt,
        options: options,
        correctIndex: options.indexOf(displayAnswer),
        promptLabel: askReading ? labels.reading : labels.meaning,
      );
    });
  }
}
