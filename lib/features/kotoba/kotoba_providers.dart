import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/kotoba_category.dart';
import '../../data/models/kotoba_entry.dart';

final kotobaCategoryGroupsProvider =
    FutureProvider<Map<String, List<KotobaCategory>>>((ref) {
  return ref.watch(kotobaCategoryRepositoryProvider).getGrouped();
});

final kotobaVocabCategoryProvider =
    FutureProvider.family<List<KotobaEntry>, String>((ref, categoryId) {
  return ref.watch(kotobaRepositoryProvider).getVocabCategory(categoryId);
});

/// Ids of every word marked "Sudah Dipelajari", across all categories.
/// Invalidate this after marking/unmarking so Category/Home screens (which
/// derive their progress badges from it) pick up the change.
final kotobaLearnedIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.watch(kotobaProgressRepositoryProvider).getLearnedIds();
});

/// (learned, total) word count for one category — used for progress badges
/// on the home screen's category grid and the category screen's app bar.
final kotobaCategoryProgressProvider =
    FutureProvider.family<(int, int), String>((ref, categoryId) async {
  final words = await ref.watch(kotobaVocabCategoryProvider(categoryId).future);
  final learnedIds = await ref.watch(kotobaLearnedIdsProvider.future);
  final learned = words.where((w) => learnedIds.contains(w.id)).length;
  return (learned, words.length);
});
