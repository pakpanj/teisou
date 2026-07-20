import 'dart:math';

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

const _smallY = {'ゃ', 'ゅ', 'ょ'};

/// Mora a real Japanese reading may never *start* with - ん/ン never opens
/// a word, and を/ヲ exists only as the object-marker particle, never as a
/// word's first syllable. A distractor starting with one of these would
/// look immediately, obviously fake to a learner.
const _invalidStartMora = {'ん', 'ン', 'を', 'ヲ'};

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

  static const _meaningLabel = 'Apa artinya kanji ini?';
  static const _readingLabel = 'Bagaimana bacaan kanji ini?';
  static const _compoundLabel = 'Bagaimana bacaan kata ini?';

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
  Future<List<KanjiComboQuestion>> generateQuestions(
    JlptLevel level, {
    required bool combination,
    int count = 50,
  }) async {
    if (combination) {
      final pool = await _compoundPool(level);
      return _buildQuestions(
        pool,
        count: count,
        promptOf: (w) => w.kanji!,
        answerOf: (w) => w.reading,
        promptLabel: _compoundLabel,
      );
    }
    final pool = await _singlePool(level);
    return _buildSingleKanjiQuestions(pool, count: count);
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

  /// One random reading (onyomi or kunyomi) for [entry] — every real
  /// (non-placeholder) kanji in the dataset has at least one of either, so
  /// this never returns null for pool entries.
  String _randomReading(KanjiEntry entry) {
    final readings = [...entry.onyomi, ...entry.kunyomi];
    return readings[_random.nextInt(readings.length)];
  }

  List<KanjiComboQuestion> _buildSingleKanjiQuestions(
    List<KanjiEntry> pool, {
    required int count,
  }) {
    if (pool.length < 2) return [];
    final shuffled = List<KanjiEntry>.from(pool)..shuffle(_random);
    final selected = shuffled.take(min(count, shuffled.length)).toList();

    return List.generate(selected.length, (i) {
      final item = selected[i];
      final askReading = _random.nextBool();
      final String Function(KanjiEntry) answerOf =
          askReading ? _randomReading : (k) => k.meanings.first;
      final correctAnswer = answerOf(item);

      // Excludes item itself - one of its *other* on'yomi/kun'yomi
      // readings (or meanings) would otherwise leak in as a "wrong"
      // answer that's technically still valid for this exact kanji.
      final otherEntries = pool.where((k) => !identical(k, item));
      final distractors = askReading
          ? _pickReadingDistractors(
              correctAnswer,
              otherEntries.expand((k) => [...k.onyomi, ...k.kunyomi]),
              3,
            )
          : _pickRandomDistractors(
              correctAnswer,
              otherEntries.map((k) => k.meanings.first),
              3,
            );
      final options = [correctAnswer, ...distractors]..shuffle(_random);
      return KanjiComboQuestion(
        id: 'kombo_$i',
        prompt: item.character,
        options: options,
        correctIndex: options.indexOf(correctAnswer),
        promptLabel: askReading ? _readingLabel : _meaningLabel,
      );
    });
  }
}
