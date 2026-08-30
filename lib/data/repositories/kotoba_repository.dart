import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/jlpt_level.dart';
import '../models/kotoba_entry.dart';

/// Loads the bundled kotoba dictionary once and serves it from an
/// in-memory cache, same pattern as [KanjiRepository]/[KanaRepository].
class KotobaRepository {
  static const _assetPath = 'assets/data/kotoba_data.json';

  List<KotobaEntry>? _cache;

  /// Batch 6 vocab categories, keyed by category id, loaded lazily one
  /// file at a time from `assets/data/kotoba/{categoryId}.json` — unlike
  /// [_cache], which eagerly loads the single Batch 4 [_assetPath] file.
  /// Both populate the same [KotobaEntry] model from bundled JSON; this is
  /// just a second, per-category loading strategy for the same repository.
  final Map<String, List<KotobaEntry>> _vocabCategoryCache = {};

  Future<List<KotobaEntry>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => KotobaEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<List<KotobaEntry>> getAll() => _loadAll();

  Future<List<KotobaEntry>> getByLevel(JlptLevel level) async {
    final all = await _loadAll();
    return all.where((k) => k.jlptLevel == level).toList();
  }

  Future<List<KotobaEntry>> getByCategory(String category) async {
    final all = await _loadAll();
    return all.where((k) => k.category == category).toList();
  }

  List<String>? _vocabCategoryIdsCache;

  Future<List<String>> _vocabCategoryIds() async {
    final cached = _vocabCategoryIdsCache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/data/kotoba/_categories.json');
    final decoded = json.decode(raw) as List;
    final ids = decoded.map((e) => (e as Map<String, dynamic>)['id'] as String).toList();
    _vocabCategoryIdsCache = ids;
    return ids;
  }

  /// [_loadAll]'s legacy Batch 4 seed only has ~30 entries — the real
  /// 1,682-word vocab module lives in the 46 per-category files instead
  /// (see [getVocabCategory]), so this falls back to scanning those too
  /// whenever an id isn't found in the small legacy list. Each category's
  /// results are cached by [getVocabCategory] itself, so repeat lookups
  /// (e.g. resolving several ids from the same Bab chapter) stay cheap
  /// after the first full scan.
  Future<KotobaEntry?> getById(String id) async {
    final all = await _loadAll();
    for (final entry in all) {
      if (entry.id == id) return entry;
    }
    for (final categoryId in await _vocabCategoryIds()) {
      for (final entry in await getVocabCategory(categoryId)) {
        if (entry.id == id) return entry;
      }
    }
    return null;
  }

  List<KotobaEntry>? _allVocabCache;

  /// Every real vocab-module word across all 46 categories, concatenated —
  /// used by `FuriganaDictionary` to build a word->kana-reading lookup for
  /// annotating example sentences. Not used by [getAll]/[getById]'s
  /// per-category fallback scan, which stays lazy on purpose; this one is
  /// meant to be called once and kept, so it eagerly loads every category.
  Future<List<KotobaEntry>> getAllVocab() async {
    final cached = _allVocabCache;
    if (cached != null) return cached;
    final all = <KotobaEntry>[];
    for (final categoryId in await _vocabCategoryIds()) {
      all.addAll(await getVocabCategory(categoryId));
    }
    _allVocabCache = all;
    return all;
  }

  bool _matches(KotobaEntry k, String trimmed) {
    if (k.placeholder) return false;
    if (k.word.toLowerCase().contains(trimmed)) return true;
    if (k.kanji?.toLowerCase().contains(trimmed) ?? false) return true;
    if (k.reading.toLowerCase().contains(trimmed)) return true;
    if (k.romaji.toLowerCase().contains(trimmed)) return true;
    if (k.meaning.toLowerCase().contains(trimmed)) return true;
    if ((k.meaningEn ?? '').toLowerCase().contains(trimmed)) return true;
    return false;
  }

  /// Case-insensitive search across word, reading, romaji, and meaning —
  /// across the **whole** dictionary, not just [_loadAll]'s ~30-entry
  /// legacy seed. `SearchScreen` (the app's main Kamus feature) calls this
  /// directly, so before this fix a search here could only ever find
  /// ~30 of the real 1,682 vocab-module words — the same class of gap
  /// [getById] was already fixed for, just never applied here too. Legacy
  /// entries are checked first (cheap, already in memory) and the vocab
  /// module's ids are skipped if a legacy entry with the same id already
  /// matched, so an id present in both can't appear twice in the results.
  Future<List<KotobaEntry>> search(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];
    final legacy = await _loadAll();
    final results = legacy.where((k) => _matches(k, trimmed)).toList();
    final seenIds = results.map((k) => k.id).toSet();
    for (final entry in await getAllVocab()) {
      if (seenIds.contains(entry.id)) continue;
      if (_matches(entry, trimmed)) results.add(entry);
    }
    return results;
  }

  /// Exact match on [word] or [kanji] — used by the Cam Detector lookup,
  /// where the scanned text should map to one specific entry rather than
  /// a fuzzy search result list. Same legacy-then-vocab-module fallback as
  /// [search] — a scanned word outside the ~30-entry legacy seed used to
  /// silently miss even when it's one of the 1,682 real vocab-module words.
  Future<KotobaEntry?> findExact(String text) async {
    final legacy = await _loadAll();
    for (final entry in legacy) {
      if (entry.placeholder) continue;
      if (entry.word == text || entry.kanji == text) return entry;
    }
    for (final entry in await getAllVocab()) {
      if (entry.placeholder) continue;
      if (entry.word == text || entry.kanji == text) return entry;
    }
    return null;
  }

  /// Batch 6: loads one vocab category's word list from its own bundled
  /// file. Returns an empty list (not an error) if the file doesn't exist
  /// yet — expected for categories still marked `available: false` in
  /// `_categories.json`.
  Future<List<KotobaEntry>> getVocabCategory(String categoryId) async {
    final cached = _vocabCategoryCache[categoryId];
    if (cached != null) return cached;
    try {
      final raw = await rootBundle.loadString('assets/data/kotoba/$categoryId.json');
      final decoded = json.decode(raw) as List;
      final entries = decoded
          .map((e) => KotobaEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _vocabCategoryCache[categoryId] = entries;
      return entries;
    } catch (_) {
      return const [];
    }
  }
}
