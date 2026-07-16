import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/kaiwa_category_info.dart';

/// Loads the bundled `_categories.json` metadata for the Kaiwa scenario
/// categories, same load-once-cache pattern as ParticleCategoryRepository.
class KaiwaCategoryRepository {
  static const _assetPath = 'assets/data/kaiwa/_categories.json';

  List<KaiwaCategoryInfo>? _cache;

  Future<List<KaiwaCategoryInfo>> getAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => KaiwaCategoryInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<KaiwaCategoryInfo?> getById(String id) async {
    final all = await getAll();
    for (final category in all) {
      if (category.id == id) return category;
    }
    return null;
  }
}
