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
    int count = 5,
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

    return List.generate(selected.length, (i) {
      final item = selected[i];
      final correctAnswer = answerOf(item);
      final distractors = <String>{};
      final candidates = List<T>.from(pool)..shuffle(_random);
      for (final candidate in candidates) {
        if (distractors.length >= 3) break;
        final candidateAnswer = answerOf(candidate);
        if (candidateAnswer == correctAnswer) continue;
        distractors.add(candidateAnswer);
      }
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

      final distractors = <String>{};
      final candidates = List<KanjiEntry>.from(pool)..shuffle(_random);
      for (final candidate in candidates) {
        if (distractors.length >= 3) break;
        if (identical(candidate, item)) continue;
        final candidateAnswer = answerOf(candidate);
        if (candidateAnswer == correctAnswer) continue;
        distractors.add(candidateAnswer);
      }
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
