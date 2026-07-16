import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/kaiwa_category_info.dart';
import '../../data/models/kaiwa_entry.dart';

final kaiwaCategoriesProvider = FutureProvider<List<KaiwaCategoryInfo>>((ref) {
  return ref.watch(kaiwaCategoryRepositoryProvider).getAll();
});

final kaiwaByCategoryProvider =
    FutureProvider.family<List<KaiwaEntry>, String>((ref, category) {
  return ref.watch(kaiwaRepositoryProvider).getByCategory(category);
});

/// Ids of every dialogue marked "Sudah Dipelajari", across all categories.
/// Invalidate this after marking/unmarking so Home/Category screens (which
/// derive their progress badges from it) pick up the change.
final kaiwaLearnedIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.watch(kaiwaProgressRepositoryProvider).getLearnedIds();
});

/// (learned, total) dialogue count for one category — used for progress
/// badges on the home screen's category picker and the category screen's
/// app bar.
final kaiwaCategoryProgressProvider =
    FutureProvider.family<(int, int), String>((ref, category) async {
  final entries = await ref.watch(kaiwaByCategoryProvider(category).future);
  final real = entries.where((e) => !e.placeholder).toList();
  final learnedIds = await ref.watch(kaiwaLearnedIdsProvider.future);
  final learned = real.where((e) => learnedIds.contains(e.id)).length;
  return (learned, real.length);
});
