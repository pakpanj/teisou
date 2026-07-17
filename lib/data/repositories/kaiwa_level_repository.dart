import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/kaiwa_jlpt_level_info.dart';

/// Loads the bundled `_levels.json` metadata for Kaiwa's JLPT levels, same
/// load-once-cache pattern as `BunpouLevelRepository`.
class KaiwaLevelRepository {
  static const _assetPath = 'assets/data/kaiwa/_levels.json';

  List<KaiwaJlptLevelInfo>? _cache;

  Future<List<KaiwaJlptLevelInfo>> getAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => KaiwaJlptLevelInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<KaiwaJlptLevelInfo?> getById(String id) async {
    final all = await getAll();
    for (final level in all) {
      if (level.id == id) return level;
    }
    return null;
  }
}
