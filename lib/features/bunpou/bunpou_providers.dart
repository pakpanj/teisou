import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/bunpou_entry.dart';
import '../../data/models/bunpou_level.dart';
import '../../data/models/jlpt_level.dart';

final bunpouLevelsProvider = FutureProvider<List<BunpouLevel>>((ref) {
  return ref.watch(bunpouLevelRepositoryProvider).getAll();
});

/// Every grammar pattern across all levels — used to resolve
/// [BunpouEntry.similarPatterns] ids to their display pattern text, since
/// a similar pattern can point at an entry from a different JLPT level
/// than the one currently being viewed.
final bunpouAllProvider = FutureProvider<List<BunpouEntry>>((ref) {
  return ref.watch(bunpouRepositoryProvider).getAll();
});

final bunpouByLevelProvider = FutureProvider.family<List<BunpouEntry>, JlptLevel>((ref, level) {
  return ref.watch(bunpouRepositoryProvider).getByLevel(level);
});

/// Ids of every grammar pattern marked "Sudah Dipelajari", across all
/// levels. Invalidate this after marking/unmarking so Home/Level screens
/// (which derive their progress badges from it) pick up the change.
final bunpouLearnedIdsProvider = FutureProvider<Set<String>>((ref) async {
  final user = await ref.watch(appStartupProvider.future);
  return ref.watch(bunpouProgressRepositoryProvider).getLearnedIds(user.uid);
});

/// (learned, total) pattern count for one level — used for progress badges
/// on the home screen's level picker and the level screen's app bar.
final bunpouLevelProgressProvider = FutureProvider.family<(int, int), JlptLevel>((ref, level) async {
  final entries = await ref.watch(bunpouByLevelProvider(level).future);
  final real = entries.where((b) => !b.placeholder).toList();
  final learnedIds = await ref.watch(bunpouLearnedIdsProvider.future);
  final learned = real.where((b) => learnedIds.contains(b.id)).length;
  return (learned, real.length);
});
