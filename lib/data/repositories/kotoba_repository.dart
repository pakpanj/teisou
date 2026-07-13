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

  Future<KotobaEntry?> getById(String id) async {
    final all = await _loadAll();
    for (final entry in all) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Case-insensitive search across word, reading, romaji, and meaning.
  Future<List<KotobaEntry>> search(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];
    final all = await _loadAll();
    return all.where((k) {
      if (k.placeholder) return false;
      if (k.word.toLowerCase().contains(trimmed)) return true;
      if (k.kanji?.toLowerCase().contains(trimmed) ?? false) return true;
      if (k.reading.toLowerCase().contains(trimmed)) return true;
      if (k.romaji.toLowerCase().contains(trimmed)) return true;
      if (k.meaning.toLowerCase().contains(trimmed)) return true;
      return false;
    }).toList();
  }

  /// Exact match on [word] or [kanji] — used by the Cam Detector lookup,
  /// where the scanned text should map to one specific entry rather than
  /// a fuzzy search result list.
  Future<KotobaEntry?> findExact(String text) async {
    final all = await _loadAll();
    for (final entry in all) {
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
