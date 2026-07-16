import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/bunpou_level.dart';

/// Loads the bundled `_levels.json` metadata for the JLPT grammar levels,
/// same load-once-cache pattern as [KanjiLevelRepository].
class BunpouLevelRepository {
  static const _assetPath = 'assets/data/bunpou/_levels.json';

  List<BunpouLevel>? _cache;

  Future<List<BunpouLevel>> getAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all =
        decoded.map((e) => BunpouLevel.fromJson(e as Map<String, dynamic>)).toList();
    _cache = all;
    return all;
  }

  Future<BunpouLevel?> getById(String id) async {
    final all = await getAll();
    for (final level in all) {
      if (level.id == id) return level;
    }
    return null;
  }
}
