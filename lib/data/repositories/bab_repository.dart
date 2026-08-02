import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/bab_entry.dart';
import '../models/jlpt_level.dart';

/// Loads the bundled Bab (curriculum chapter) list once and serves it from
/// an in-memory cache, same pattern as [KanjiRepository] — the dataset is
/// tiny (a handful of chapters for a long time), so no per-level asset
/// sharding is needed the way the larger modules use.
class BabRepository {
  static const _assetPath = 'assets/data/bab_data.json';

  List<BabEntry>? _cache;

  Future<List<BabEntry>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded.map((e) => BabEntry.fromJson(e as Map<String, dynamic>)).toList();
    _cache = all;
    return all;
  }

  Future<List<BabEntry>> getAll() => _loadAll();

  Future<List<BabEntry>> getByLevel(JlptLevel level) async {
    final all = await _loadAll();
    final filtered = all.where((b) => b.level == level).toList();
    filtered.sort((a, b) => a.order.compareTo(b.order));
    return filtered;
  }

  Future<BabEntry?> getById(String id) async {
    final all = await _loadAll();
    for (final entry in all) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}
