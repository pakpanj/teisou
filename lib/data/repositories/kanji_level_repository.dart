import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/kanji_level.dart';

/// Loads the bundled `_levels.json` metadata for the 5 JLPT kanji levels,
/// same load-once-cache pattern as the other repositories.
class KanjiLevelRepository {
  static const _assetPath = 'assets/data/kanji/_levels.json';

  List<KanjiLevel>? _cache;

  Future<List<KanjiLevel>> getAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded.map((e) => KanjiLevel.fromJson(e as Map<String, dynamic>)).toList();
    _cache = all;
    return all;
  }

  Future<KanjiLevel?> getById(String id) async {
    final all = await getAll();
    for (final level in all) {
      if (level.id == id) return level;
    }
    return null;
  }
}
