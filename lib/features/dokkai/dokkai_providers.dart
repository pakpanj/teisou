import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/dokkai_jlpt_level_info.dart';
import '../../data/models/dokkai_passage.dart';
import '../../data/models/jlpt_level.dart';

final dokkaiLevelsProvider = FutureProvider<List<DokkaiJlptLevelInfo>>((ref) {
  return ref.watch(dokkaiLevelRepositoryProvider).getAll();
});

final dokkaiByLevelProvider =
    FutureProvider.family<List<DokkaiPassage>, JlptLevel>((ref, level) {
  return ref.watch(dokkaiRepositoryProvider).getByLevel(level);
});

/// Score a Dokkai exam attempt needs to clear for its level to count as
/// "passed" for the sequential level lock — an explicit product decision
/// (70%), not derived from anything in the dataset.
const double dokkaiLevelPassThreshold = 70;

/// Standing for one JLPT level of the sequential level lock. Unlike Bab/
/// Kanji/Kaiwa (which gate on 100% of items marked "learned"), Dokkai has
/// no per-passage completion concept at all — a session is always a fresh
/// random draw from the whole level pool (see `DokkaiHomeScreen`'s own
/// doc comment) — so there is nothing to mark "learned" and check for
/// 100%. The gate here is instead "has this account ever scored >=70% on
/// one full exam attempt at this level", read from `dokkaiExamHistory`.
class DokkaiLevelGate {
  final JlptLevel level;
  final bool passed;
  final bool reachedByProgress;

  const DokkaiLevelGate({
    required this.level,
    required this.passed,
    required this.reachedByProgress,
  });
}

/// Per-level lock standing across all five JLPT levels, in N5-first order.
/// Drives the level lock on [DokkaiHomeScreen].
final dokkaiLevelGateProvider = FutureProvider<List<DokkaiLevelGate>>((ref) async {
  final user = await ref.watch(appStartupProvider.future);
  final repo = ref.watch(dokkaiExamHistoryRepositoryProvider);

  final result = <DokkaiLevelGate>[];
  // N5 has nothing in front of it, so it always starts open.
  var previousLevelsAllPassed = true;
  for (final level in JlptLevel.values) {
    final attempts = await repo.getByLevel(user.uid, level.key);
    final passed = attempts.any((a) => a.percentage >= dokkaiLevelPassThreshold);
    result.add(DokkaiLevelGate(
      level: level,
      passed: passed,
      reachedByProgress: previousLevelsAllPassed,
    ));
    previousLevelsAllPassed = previousLevelsAllPassed && passed;
  }
  return result;
});
