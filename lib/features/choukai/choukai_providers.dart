import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/choukai_clip.dart';
import '../../data/models/choukai_jlpt_level_info.dart';
import '../../data/models/jlpt_level.dart';

final choukaiLevelsProvider = FutureProvider<List<ChoukaiJlptLevelInfo>>((ref) {
  return ref.watch(choukaiLevelRepositoryProvider).getAll();
});

final choukaiByLevelProvider =
    FutureProvider.family<List<ChoukaiClip>, JlptLevel>((ref, level) {
  return ref.watch(choukaiRepositoryProvider).getByLevel(level);
});

/// Score a Choukai exam attempt needs to clear for its level to count as
/// "passed" for the sequential level lock — an explicit product decision
/// (70%), matching `dokkaiLevelPassThreshold`.
const double choukaiLevelPassThreshold = 70;

/// Standing for one JLPT level of the sequential level lock — same shape
/// as `DokkaiLevelGate`: Choukai has no per-clip completion concept
/// either, so the gate is "has this account ever scored >=70% on one full
/// exam attempt at this level", read from `choukaiExamHistory`.
class ChoukaiLevelGate {
  final JlptLevel level;
  final bool passed;
  final bool reachedByProgress;

  const ChoukaiLevelGate({
    required this.level,
    required this.passed,
    required this.reachedByProgress,
  });
}

/// Per-level lock standing across all five JLPT levels, in N5-first order.
/// Drives the level lock on [ChoukaiHomeScreen].
final choukaiLevelGateProvider = FutureProvider<List<ChoukaiLevelGate>>((ref) async {
  final user = await ref.watch(appStartupProvider.future);
  final repo = ref.watch(choukaiExamHistoryRepositoryProvider);

  final result = <ChoukaiLevelGate>[];
  // N5 has nothing in front of it, so it always starts open.
  var previousLevelsAllPassed = true;
  for (final level in JlptLevel.values) {
    final attempts = await repo.getByLevel(user.uid, level.key);
    final passed = attempts.any((a) => a.percentage >= choukaiLevelPassThreshold);
    result.add(ChoukaiLevelGate(
      level: level,
      passed: passed,
      reachedByProgress: previousLevelsAllPassed,
    ));
    previousLevelsAllPassed = previousLevelsAllPassed && passed;
  }
  return result;
});
