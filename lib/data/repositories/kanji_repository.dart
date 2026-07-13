import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/jlpt_level.dart';
import '../models/kanji_entry.dart';

/// Loads the bundled kanji dictionary once and serves it from an
/// in-memory cache, same pattern as [KanaRepository] — static data,
/// identical for every user, so it lives as an asset rather than
/// Firestore.
class KanjiRepository {
  static const _assetPath = 'assets/data/kanji_data.json';

  List<KanjiEntry>? _cache;

  Future<List<KanjiEntry>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => KanjiEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<List<KanjiEntry>> getAll() => _loadAll();

  Future<List<KanjiEntry>> getByLevel(JlptLevel level) async {
    final all = await _loadAll();
    return all.where((k) => k.jlptLevel == level).toList();
  }

  Future<KanjiEntry?> getById(String id) async {
    final all = await _loadAll();
    for (final entry in all) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Exact match on [character] — used by the Cam Detector lookup, where a
  /// single scanned kanji should map to one specific entry rather than a
  /// fuzzy search result list.
  Future<KanjiEntry?> findByCharacter(String character) async {
    final all = await _loadAll();
    for (final entry in all) {
      if (entry.placeholder) continue;
      if (entry.character == character) return entry;
    }
    return null;
  }

  /// Case-insensitive search across character, on'yomi, kun'yomi, and
  /// meanings. Placeholder rows never match since they carry no content.
  Future<List<KanjiEntry>> search(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];
    final all = await _loadAll();
    return all.where((k) {
      if (k.placeholder) return false;
      if (k.character.toLowerCase().contains(trimmed)) return true;
      if (k.onyomi.any((r) => r.toLowerCase().contains(trimmed))) return true;
      if (k.kunyomi.any((r) => r.toLowerCase().contains(trimmed))) return true;
      if (k.meanings.any((m) => m.toLowerCase().contains(trimmed))) return true;
      return false;
    }).toList();
  }
}
