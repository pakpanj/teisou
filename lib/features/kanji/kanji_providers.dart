import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kanji_entry.dart';
import '../../data/models/kanji_level.dart';

final kanjiLevelsProvider = FutureProvider<List<KanjiLevel>>((ref) {
  return ref.watch(kanjiLevelRepositoryProvider).getAll();
});

final kanjiByLevelProvider = FutureProvider.family<List<KanjiEntry>, JlptLevel>((ref, level) {
  return ref.watch(kanjiRepositoryProvider).getByLevel(level);
});

/// Ids of every kanji marked "Sudah Dipelajari", across all levels.
/// Invalidate this after marking/unmarking so Home/Level screens (which
/// derive their progress badges from it) pick up the change.
final kanjiLearnedIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.watch(kanjiProgressRepositoryProvider).getLearnedIds();
});

/// (learned, total) kanji count for one level — used for progress badges on
/// the home screen's level picker and the level screen's app bar.
final kanjiLevelProgressProvider = FutureProvider.family<(int, int), JlptLevel>((ref, level) async {
  final kanji = await ref.watch(kanjiByLevelProvider(level).future);
  final real = kanji.where((k) => !k.placeholder).toList();
  final learnedIds = await ref.watch(kanjiLearnedIdsProvider.future);
  final learned = real.where((k) => learnedIds.contains(k.id)).length;
  return (learned, real.length);
});
