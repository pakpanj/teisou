import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kaiwa_category_info.dart';
import '../../data/models/kaiwa_entry.dart';
import '../../data/models/kaiwa_jlpt_level_info.dart';

final kaiwaLevelsProvider = FutureProvider<List<KaiwaJlptLevelInfo>>((ref) {
  return ref.watch(kaiwaLevelRepositoryProvider).getAll();
});

final kaiwaCategoriesProvider = FutureProvider<List<KaiwaCategoryInfo>>((ref) {
  return ref.watch(kaiwaCategoryRepositoryProvider).getAll();
});

/// Themes (categories) belonging to one JLPT level — what `KaiwaLevelScreen`
/// renders as its theme picker.
final kaiwaCategoriesByLevelProvider =
    FutureProvider.family<List<KaiwaCategoryInfo>, JlptLevel>((ref, level) async {
  final all = await ref.watch(kaiwaCategoriesProvider.future);
  return all.where((c) => c.level == level).toList();
});

final kaiwaByCategoryProvider =
    FutureProvider.family<List<KaiwaEntry>, String>((ref, category) {
  return ref.watch(kaiwaRepositoryProvider).getByCategory(category);
});

/// Ids of every dialogue marked "Sudah Dipelajari", across all levels and
/// themes. Invalidate this after marking/unmarking so Home/Level/Category
/// screens (which derive their progress badges from it) pick up the change.
final kaiwaLearnedIdsProvider = FutureProvider<Set<String>>((ref) async {
  final user = await ref.watch(appStartupProvider.future);
  return ref.watch(kaiwaProgressRepositoryProvider).getLearnedIds(user.uid);
});

/// (learned, total) dialogue count for one theme — used for progress
/// badges on the level screen's theme picker and the category screen's app
/// bar.
final kaiwaCategoryProgressProvider =
    FutureProvider.family<(int, int), String>((ref, category) async {
  final entries = await ref.watch(kaiwaByCategoryProvider(category).future);
  final real = entries.where((e) => !e.placeholder).toList();
  final learnedIds = await ref.watch(kaiwaLearnedIdsProvider.future);
  final learned = real.where((e) => learnedIds.contains(e.id)).length;
  return (learned, real.length);
});

/// (learned, total) dialogue count aggregated across every available theme
/// in one JLPT level — used for progress badges on the home screen's level
/// picker.
final kaiwaLevelProgressProvider =
    FutureProvider.family<(int, int), JlptLevel>((ref, level) async {
  final categories = await ref.watch(kaiwaCategoriesByLevelProvider(level).future);
  final learnedIds = await ref.watch(kaiwaLearnedIdsProvider.future);
  var learned = 0;
  var total = 0;
  for (final category in categories) {
    if (!category.available) continue;
    final entries = await ref.watch(kaiwaByCategoryProvider(category.id).future);
    final real = entries.where((e) => !e.placeholder).toList();
    total += real.length;
    learned += real.where((e) => learnedIds.contains(e.id)).length;
  }
  return (learned, total);
});

/// Standing for one JLPT level of the sequential level lock — same "opens
/// once every earlier level is 100% learned" rule Bab/Kanji already use,
/// one layer down (per Kaiwa dialogue rather than per chapter/kanji).
class KaiwaLevelGate {
  final JlptLevel level;
  final int learned;
  final int total;
  final bool reachedByProgress;

  const KaiwaLevelGate({
    required this.level,
    required this.learned,
    required this.total,
    required this.reachedByProgress,
  });

  /// A level with no real dialogues yet is never "finished" — otherwise an
  /// unauthored level would silently unlock everything behind it.
  bool get isComplete => total > 0 && learned == total;
}

/// Per-level lock standing across all five JLPT levels, in N5-first order.
/// Drives the level lock on [KaiwaHomeScreen].
final kaiwaLevelGateProvider = FutureProvider<List<KaiwaLevelGate>>((ref) async {
  final result = <KaiwaLevelGate>[];
  // N5 has nothing in front of it, so it always starts open.
  var previousLevelsAllComplete = true;
  for (final level in JlptLevel.values) {
    final (learned, total) = await ref.watch(kaiwaLevelProgressProvider(level).future);
    final gate = KaiwaLevelGate(
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
