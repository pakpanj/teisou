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
final kanjiLearnedIdsProvider = FutureProvider<Set<String>>((ref) async {
  final user = await ref.watch(appStartupProvider.future);
  return ref.watch(kanjiProgressRepositoryProvider).getLearnedIds(user.uid);
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

/// Standing for one JLPT level of the sequential level lock — mirrors
/// `BabLevelProgress` exactly, same "a level opens only once every earlier
/// level is 100% learned" rule Bab already uses, just one layer down (per
/// kanji rather than per Bab chapter).
class KanjiLevelGate {
  final JlptLevel level;
  final int learned;
  final int total;
  final bool reachedByProgress;

  const KanjiLevelGate({
    required this.level,
    required this.learned,
    required this.total,
    required this.reachedByProgress,
  });

  /// A level with no real kanji yet is never "finished" — otherwise an
  /// unauthored level would silently unlock everything behind it.
  bool get isComplete => total > 0 && learned == total;
}

/// Per-level lock standing across all five JLPT levels, in N5-first order.
/// Drives the level lock on [KanjiHomeScreen].
final kanjiLevelGateProvider = FutureProvider<List<KanjiLevelGate>>((ref) async {
  final result = <KanjiLevelGate>[];
  // N5 has nothing in front of it, so it always starts open.
  var previousLevelsAllComplete = true;
  for (final level in JlptLevel.values) {
    final (learned, total) = await ref.watch(kanjiLevelProgressProvider(level).future);
    final gate = KanjiLevelGate(
      level: level,
      learned: learned,
      total: total,
      reachedByProgress: previousLevelsAllComplete,
    );
    result.add(gate);
    previousLevelsAllComplete = previousLevelsAllComplete && gate.isComplete;
  }
  return result;
});
