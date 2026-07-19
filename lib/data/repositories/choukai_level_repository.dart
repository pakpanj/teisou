import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/choukai_jlpt_level_info.dart';

/// Loads the bundled `_levels.json` metadata for Choukai's JLPT levels,
/// mirrors [DokkaiLevelRepository]/[KaiwaLevelRepository].
class ChoukaiLevelRepository {
  static const _assetPath = 'assets/data/choukai/_levels.json';

  List<ChoukaiJlptLevelInfo>? _cache;

  Future<List<ChoukaiJlptLevelInfo>> getAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => ChoukaiJlptLevelInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<ChoukaiJlptLevelInfo?> getById(String id) async {
    final all = await getAll();
    for (final level in all) {
      if (level.id == id) return level;
    }
    return null;
  }
}
