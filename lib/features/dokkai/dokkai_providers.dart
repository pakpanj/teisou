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
