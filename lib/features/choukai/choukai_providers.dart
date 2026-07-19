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
