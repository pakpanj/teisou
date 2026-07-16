import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/particle_category_info.dart';

/// Loads the bundled `_categories.json` metadata for the Partikel
/// categories, same load-once-cache pattern as BunpouLevelRepository.
class ParticleCategoryRepository {
  static const _assetPath = 'assets/data/particle/_categories.json';

  List<ParticleCategoryInfo>? _cache;

  Future<List<ParticleCategoryInfo>> getAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => ParticleCategoryInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<ParticleCategoryInfo?> getById(String id) async {
    final all = await getAll();
    for (final category in all) {
      if (category.id == id) return category;
    }
    return null;
  }
}
