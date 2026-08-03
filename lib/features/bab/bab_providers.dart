import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/bab_entry.dart';
import '../../data/models/bunpou_entry.dart';
import '../../data/models/dokkai_passage.dart';
import '../../data/models/jlpt_level.dart';
import '../../data/models/kaiwa_entry.dart';
import '../../data/models/kanji_entry.dart';
import '../../data/models/kotoba_entry.dart';
import '../../data/models/particle_entry.dart';

final babAllProvider = FutureProvider<List<BabEntry>>((ref) {
  return ref.watch(babRepositoryProvider).getAll();
});

final babByLevelProvider = FutureProvider.family<List<BabEntry>, JlptLevel>((ref, level) {
  return ref.watch(babRepositoryProvider).getByLevel(level);
});

/// Ids of every Bab marked "Selesai". Invalidate this after marking/
/// unmarking so Home/Level/Detail screens pick up the change.
final babCompletedIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.watch(babProgressRepositoryProvider).getCompletedIds();
});

/// Next chapter the learner hasn't completed yet, ordered globally across
/// the whole curriculum — null once every authored chapter is done (or if
/// none exist yet). Drives the mascot guide's contextual message on Home
/// and the Bab level screen.
final babNextUpProvider = FutureProvider<BabEntry?>((ref) async {
  final all = [...await ref.watch(babAllProvider.future)]
    ..sort((a, b) => a.order.compareTo(b.order));
  if (all.isEmpty) return null;
  final completed = await ref.watch(babCompletedIdsProvider.future);
  for (final bab in all) {
    if (!completed.contains(bab.id)) return bab;
  }
  return null;
});

/// One Bab chapter with every referenced id resolved into its real object
/// from that module's own repository — the actual cross-module link this
/// project didn't have before Bab (see `KanjiEntry.relatedBunpou`, which is
/// display-only). A dangling id (shouldn't happen once
/// `generate_bab_seed.py`'s own validation is in place, but never trust
/// data blindly) is silently dropped rather than crashing the screen.
class ResolvedBab {
  final BabEntry bab;
  final List<KotobaEntry> kotoba;
  final List<KanjiEntry> kanji;
  final List<BunpouEntry> bunpou;
  final List<ParticleEntry> particles;
  final List<KaiwaEntry> kaiwa;
  final List<DokkaiPassage> dokkai;

  ResolvedBab({
    required this.bab,
    required this.kotoba,
    required this.kanji,
    required this.bunpou,
    required this.particles,
    required this.kaiwa,
    required this.dokkai,
  });
}

/// Every chapter in [level], fully resolved — the raw material the gate
/// quiz generator draws from (see `bab_gate_quiz_generator.dart`).
/// Resolving the whole level once and caching it here means retrying a
/// failed gate quiz doesn't repeat the same id-lookup pass over every
/// chapter each time.
final babAllResolvedProvider =
    FutureProvider.family<List<ResolvedBab>, JlptLevel>((ref, level) async {
  final chapters = await ref.watch(babByLevelProvider(level).future);
  return Future.wait(
    chapters.map((c) => ref.watch(babDetailProvider(c.id).future)),
  );
});

final babDetailProvider = FutureProvider.family<ResolvedBab, String>((ref, babId) async {
  final bab = await ref.watch(babRepositoryProvider).getById(babId);
  if (bab == null) {
    throw StateError('Bab not found: $babId');
  }

  final kotobaRepo = ref.watch(kotobaRepositoryProvider);
  final kanjiRepo = ref.watch(kanjiRepositoryProvider);
  final bunpouRepo = ref.watch(bunpouRepositoryProvider);
  final particleRepo = ref.watch(particleRepositoryProvider);
  final kaiwaRepo = ref.watch(kaiwaRepositoryProvider);
  final dokkaiRepo = ref.watch(dokkaiRepositoryProvider);

  final kotoba = (await Future.wait(bab.kotobaIds.map(kotobaRepo.getById)))
      .whereType<KotobaEntry>()
      .toList();
  final kanji = (await Future.wait(bab.kanjiIds.map(kanjiRepo.getById)))
      .whereType<KanjiEntry>()
      .toList();
  final bunpou = (await Future.wait(bab.bunpouIds.map(bunpouRepo.getById)))
      .whereType<BunpouEntry>()
      .toList();
  final particles = (await Future.wait(bab.particleIds.map(particleRepo.getById)))
      .whereType<ParticleEntry>()
      .toList();
  final kaiwa = (await Future.wait(bab.kaiwaIds.map(kaiwaRepo.getById)))
      .whereType<KaiwaEntry>()
      .toList();
  final dokkai = (await Future.wait(bab.dokkaiIds.map(dokkaiRepo.getById)))
      .whereType<DokkaiPassage>()
      .toList();

  return ResolvedBab(
    bab: bab,
    kotoba: kotoba,
    kanji: kanji,
    bunpou: bunpou,
    particles: particles,
    kaiwa: kaiwa,
    dokkai: dokkai,
  );
});
