import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/dokkai_passage.dart';
import '../models/jlpt_level.dart';

/// Loads the bundled Dokkai passage set once and serves it from an
/// in-memory cache, same pattern as [KanjiRepository]/[KotobaRepository].
class DokkaiRepository {
  static const _assetPath = 'assets/data/dokkai_data.json';

  List<DokkaiPassage>? _cache;

  Future<List<DokkaiPassage>> _loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => DokkaiPassage.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<List<DokkaiPassage>> getAll() => _loadAll();

  Future<List<DokkaiPassage>> getByLevel(JlptLevel level) async {
    final all = await _loadAll();
    return all.where((p) => p.jlptLevel == level).toList();
  }

  Future<DokkaiPassage?> getById(String id) async {
    final all = await _loadAll();
    for (final passage in all) {
      if (passage.id == id) return passage;
    }
    return null;
  }
}
