import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/dokkai_jlpt_level_info.dart';

/// Loads the bundled `_levels.json` metadata for Dokkai's JLPT levels, same
/// load-once-cache pattern as [KaiwaLevelRepository]/`BunpouLevelRepository`.
class DokkaiLevelRepository {
  static const _assetPath = 'assets/data/dokkai/_levels.json';

  List<DokkaiJlptLevelInfo>? _cache;

  Future<List<DokkaiJlptLevelInfo>> getAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => DokkaiJlptLevelInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<DokkaiJlptLevelInfo?> getById(String id) async {
    final all = await getAll();
    for (final level in all) {
      if (level.id == id) return level;
    }
    return null;
  }
}
