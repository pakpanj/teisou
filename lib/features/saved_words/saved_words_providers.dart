import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/kotoba_entry.dart';
import '../../data/models/saved_word.dart';
import '../../data/repositories/kotoba_repository.dart';

/// Merges Cam Detector's locally-saved words with dictionary bookmarks
/// (`savedItems`, written by the bookmark icon on the search-flow
/// `KanjiDetailScreen`/`KotobaDetailScreen`, and — since extended — the
/// browse-flow `KanjiWordDetailScreen`/`KotobaWordDetailScreen`/
/// `BunpouDetailScreen`/`ParticleDetailScreen`) into one list for
/// `SavedWordsScreen`. Before this, the screen only ever read the local
/// Cam Detector list — since Cam Detector is locked from navigation, that
/// list can never be filled, and bookmarking a word from Search silently
/// went nowhere as far as this screen was concerned, despite the write
/// itself succeeding and showing a "tersimpan ke Daftar Belajar" snackbar.
/// Same shape of bug as the exam-history fix: a write path that worked,
/// paired with a read path that never looked at it.
final unifiedSavedWordsProvider =
    FutureProvider.autoDispose<List<SavedWord>>((ref) async {
  final user = await ref.watch(appStartupProvider.future);
  final uid = user.uid;
  final local = await ref.watch(savedWordsRepositoryProvider).getLocal(uid);

  final pointers = await ref.watch(progressRepositoryProvider).getSavedItems(uid);
  final kanjiRepo = ref.watch(kanjiRepositoryProvider);
  final kotobaRepo = ref.watch(kotobaRepositoryProvider);
  final bunpouRepo = ref.watch(bunpouRepositoryProvider);
  final particleRepo = ref.watch(particleRepositoryProvider);

  final resolved = await Future.wait(pointers.map((pointer) async {
    if (pointer.type == 'kanji') {
      final entry = await kanjiRepo.getById(pointer.itemId);
      if (entry == null) return null;
      return SavedWord(
        id: pointer.itemId,
        text: entry.character,
        romaji: entry.onyomi.isNotEmpty
            ? entry.onyomi.first
            : (entry.kunyomi.isNotEmpty ? entry.kunyomi.first : ''),
        meaning: entry.meanings.isNotEmpty ? entry.meanings.first : '',
        source: 'kanji',
        createdAt: pointer.savedAt,
      );
    }
    if (pointer.type == 'kotoba') {
      // getById only searches the small legacy kotoba_data.json (Batch 4
      // seed, ~30 words) — bookmarks from KotobaWordDetailScreen (the
      // module browse flow) carry ids from the real 1682-word vocab
      // module instead, split across 46 per-category files, so those
      // need the fallback below or they'd silently vanish from this list.
      final entry = await kotobaRepo.getById(pointer.itemId) ??
          await _findInVocabModule(ref, kotobaRepo, pointer.itemId);
      if (entry == null) return null;
      return SavedWord(
        id: pointer.itemId,
        text: entry.kanji ?? entry.word,
        romaji: entry.romaji,
        meaning: entry.meaning,
        source: 'kotoba',
        createdAt: pointer.savedAt,
      );
    }
    if (pointer.type == 'bunpou') {
      final entry = await bunpouRepo.getById(pointer.itemId);
      if (entry == null) return null;
      return SavedWord(
        id: pointer.itemId,
        text: entry.pattern,
        romaji: entry.patternRomaji,
        meaning: entry.meaning,
        source: 'bunpou',
        createdAt: pointer.savedAt,
      );
    }
    if (pointer.type == 'particle') {
      final entry = await particleRepo.getById(pointer.itemId);
      if (entry == null) return null;
      return SavedWord(
        id: pointer.itemId,
        text: entry.particle,
        romaji: entry.particleRomaji,
        meaning: entry.overview,
        source: 'particle',
        createdAt: pointer.savedAt,
      );
    }
    return null;
  }));

  final merged = [...local, ...resolved.whereType<SavedWord>()];
  merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged;
});

/// Scans every real vocab category (`assets/data/kotoba/{id}.json`) for
/// [id] — the fallback [KotobaRepository.getById] can't cover, since that
/// only searches the legacy Batch 4 seed file. Bounded, one-shot, and only
/// runs for saved-word resolution (a short list), so a linear scan across
/// 46 small category files is an acceptable cost here.
Future<KotobaEntry?> _findInVocabModule(
  Ref ref,
  KotobaRepository kotobaRepo,
  String id,
) async {
  final categories = await ref.read(kotobaCategoryRepositoryProvider).getAll();
  for (final category in categories) {
    final entries = await kotobaRepo.getVocabCategory(category.id);
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
  }
  return null;
}
