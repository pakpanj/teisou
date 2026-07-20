import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kanji_combo_question.dart';

/// Family key: (level, combination) — combination=true asks for 2-3 kanji
/// compound-word readings, false asks for single-kanji meanings. Dart
/// records get structural `==`/`hashCode` for free, so this works directly
/// as a Riverpod `family` parameter.
final kanjiComboAvailabilityProvider =
    FutureProvider.family<bool, (JlptLevel, bool)>((ref, params) {
  final (level, combination) = params;
  return ref
      .watch(kanjiComboRepositoryProvider)
      .isLevelAvailable(level, combination: combination);
});

/// `autoDispose` so a fresh, freshly-shuffled set of 50 questions is
/// generated every time the exam screen is opened — without it, Riverpod
/// would cache the first result for a given (level, combination) key for
/// the app's whole lifetime, so re-entering the same exam (e.g. after
/// finishing and going back) would replay the exact same questions in the
/// exact same order instead of a new random draw.
final kanjiComboQuestionsProvider = FutureProvider.autoDispose
    .family<List<KanjiComboQuestion>, (JlptLevel, bool)>((ref, params) {
  final (level, combination) = params;
  return ref
      .watch(kanjiComboRepositoryProvider)
      .generateQuestions(level, combination: combination, count: 50);
});
