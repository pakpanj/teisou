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

final kanjiComboQuestionsProvider =
    FutureProvider.family<List<KanjiComboQuestion>, (JlptLevel, bool)>((ref, params) {
  final (level, combination) = params;
  return ref
      .watch(kanjiComboRepositoryProvider)
      .generateQuestions(level, combination: combination);
});
