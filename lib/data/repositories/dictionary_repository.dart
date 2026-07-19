import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/dictionary_word.dart';

/// Loads the bundled comprehensive-search dictionary once and serves it
/// from an in-memory cache, same eager-cache-the-whole-file pattern as
/// [KanjiRepository]/[KotobaRepository] — at the ~10,000-word target this
/// is still only a few MB, well within what those two already parse at
/// startup, so no lazy/sharded loading is needed here.
class DictionaryRepository {
  static const _assetPath = 'assets/data/dictionary_data.json';

  List<DictionaryWord>? _cache;

  Future<List<DictionaryWord>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => DictionaryWord.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<List<DictionaryWord>> getAll() => _loadAll();

  /// Case-insensitive search across kanji, reading, and meaning.
  Future<List<DictionaryWord>> search(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];
    final all = await _loadAll();
    return all.where((w) {
      if (w.kanji?.toLowerCase().contains(trimmed) ?? false) return true;
      if (w.reading.toLowerCase().contains(trimmed)) return true;
      if (w.meaning.toLowerCase().contains(trimmed)) return true;
      return false;
    }).toList();
  }
}
