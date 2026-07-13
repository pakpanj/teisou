import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/jlpt_level.dart';
import '../models/kotoba_entry.dart';

/// Loads the bundled kotoba dictionary once and serves it from an
/// in-memory cache, same pattern as [KanjiRepository]/[KanaRepository].
class KotobaRepository {
  static const _assetPath = 'assets/data/kotoba_data.json';

  List<KotobaEntry>? _cache;

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
}
