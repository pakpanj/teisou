import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/particle_category_info.dart';
import '../../data/models/particle_entry.dart';

final particleCategoriesProvider = FutureProvider<List<ParticleCategoryInfo>>((ref) {
  return ref.watch(particleCategoryRepositoryProvider).getAll();
});

/// Every particle across all categories — used to resolve
/// [ParticleEntry.similarParticles] ids to their display text, since a
/// similar particle can point at an entry from a different category than
/// the one currently being viewed. Built in from the start rather than
/// retrofitted later, unlike Bunpou's equivalent provider which was only
/// added after a "Pola Serupa shows raw ids" bug shipped.
final particleAllProvider = FutureProvider<List<ParticleEntry>>((ref) {
  return ref.watch(particleRepositoryProvider).getAll();
});

final particleByCategoryProvider =
    FutureProvider.family<List<ParticleEntry>, String>((ref, category) {
  return ref.watch(particleRepositoryProvider).getByCategory(category);
});

/// Ids of every particle marked "Sudah Dipelajari", across all categories.
/// Invalidate this after marking/unmarking so Home/Category screens (which
/// derive their progress badges from it) pick up the change.
final particleLearnedIdsProvider = FutureProvider<Set<String>>((ref) async {
  final user = await ref.watch(appStartupProvider.future);
  return ref.watch(particleProgressRepositoryProvider).getLearnedIds(user.uid);
});

/// (learned, total) particle count for one category — used for progress
/// badges on the home screen's category picker and the category screen's
/// app bar.
final particleCategoryProgressProvider =
    FutureProvider.family<(int, int), String>((ref, category) async {
  final entries = await ref.watch(particleByCategoryProvider(category).future);
  final real = entries.where((p) => !p.placeholder).toList();
  final learnedIds = await ref.watch(particleLearnedIdsProvider.future);
  final learned = real.where((p) => learnedIds.contains(p.id)).length;
  return (learned, real.length);
});
