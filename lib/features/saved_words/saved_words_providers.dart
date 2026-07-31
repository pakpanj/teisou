import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/saved_word.dart';

/// Merges Cam Detector's locally-saved words with dictionary bookmarks
/// (`savedItems`, written by the bookmark icon on the search-flow
/// `KanjiDetailScreen`/`KotobaDetailScreen`) into one list for
/// `SavedWordsScreen`. Before this, the screen only ever read the local
/// Cam Detector list — since Cam Detector is locked from navigation, that
/// list can never be filled, and bookmarking a word from Search silently
/// went nowhere as far as this screen was concerned, despite the write
/// itself succeeding and showing a "tersimpan ke Daftar Belajar" snackbar.
/// Same shape of bug as the exam-history fix: a write path that worked,
/// paired with a read path that never looked at it.
final unifiedSavedWordsProvider =
    FutureProvider.autoDispose<List<SavedWord>>((ref) async {
  final local = await ref.watch(savedWordsRepositoryProvider).getLocal();

  final uid = ref.watch(appStartupProvider).valueOrNull?.uid;
  if (uid == null) return local;

  final pointers = await ref.watch(progressRepositoryProvider).getSavedItems(uid);
  final kanjiRepo = ref.watch(kanjiRepositoryProvider);
  final kotobaRepo = ref.watch(kotobaRepositoryProvider);

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
      final entry = await kotobaRepo.getById(pointer.itemId);
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
    return null;
  }));

  final merged = [...local, ...resolved.whereType<SavedWord>()];
  merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged;
});
