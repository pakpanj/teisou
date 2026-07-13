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
