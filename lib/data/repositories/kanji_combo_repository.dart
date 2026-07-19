import 'dart:math';

import '../models/jlpt_level.dart';
import '../models/kanji_combo_question.dart';
import '../models/kanji_entry.dart';
import '../models/kotoba_entry.dart';
import 'kanji_repository.dart';
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
class KanjiComboRepository {
  final KanjiRepository kanjiRepository;
  final KotobaRepository kotobaRepository;
  final Random _random;

  KanjiComboRepository({
    required this.kanjiRepository,
    required this.kotobaRepository,
    Random? random,
  }) : _random = random ?? Random();

  Future<List<KanjiEntry>> _singlePool(JlptLevel level) async {
    final all = await kanjiRepository.getByLevel(level);
    return all.where((k) => !k.placeholder && k.meanings.isNotEmpty).toList();
  }

  Future<List<KotobaEntry>> _compoundPool(JlptLevel level) async {
    final all = await kotobaRepository.getByLevel(level);
    return all
        .where((w) => !w.placeholder && _compoundPattern.hasMatch(w.kanji ?? ''))
        .toList();
  }

  Future<bool> isLevelAvailable(JlptLevel level, {required bool combination}) async {
    final pool = combination ? await _compoundPool(level) : await _singlePool(level);
    return pool.length >= _minPoolSize;
  }

  /// Builds [count] 4-option multiple-choice questions for [level]. Single
  /// mode asks "apa artinya" for one kanji (options = other kanjis'
  /// meanings); combination mode asks "bagaimana bacaannya" for a compound
  /// word (options = other compounds' readings).
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
      );
    }
    final pool = await _singlePool(level);
    return _buildQuestions(
      pool,
      count: count,
      promptOf: (k) => k.character,
      answerOf: (k) => k.meanings.first,
    );
  }

  List<KanjiComboQuestion> _buildQuestions<T>(
    List<T> pool, {
    required int count,
    required String Function(T) promptOf,
    required String Function(T) answerOf,
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
      );
    });
  }
}
