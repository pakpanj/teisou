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
final kaiwaLearnedIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.watch(kaiwaProgressRepositoryProvider).getLearnedIds();
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
