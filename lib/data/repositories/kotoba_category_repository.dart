import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/kotoba_category.dart';

/// Loads the bundled `_categories.json` metadata for all 45 planned Kotoba
/// vocab categories, same load-once-cache pattern as the other repositories.
class KotobaCategoryRepository {
  static const _assetPath = 'assets/data/kotoba/_categories.json';

  /// Display order for category groups — matches the roadmap's grouping,
  /// not alphabetical or JSON insertion order.
  static const groupOrder = [
    'Alam & Lingkungan',
    'Makanan & Minuman',
    'Tubuh & Kesehatan',
    'Tempat & Transportasi',
    'Manusia & Sosial',
    'Pendidikan & Pekerjaan',
    'Waktu & Angka',
  ];

  List<KotobaCategory>? _cache;

  Future<List<KotobaCategory>> getAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => KotobaCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  /// All categories grouped by [KotobaCategory.group], ordered per
  /// [groupOrder] with each group's categories in their JSON file order.
  Future<Map<String, List<KotobaCategory>>> getGrouped() async {
    final all = await getAll();
    final grouped = <String, List<KotobaCategory>>{};
    for (final group in groupOrder) {
      final inGroup = all.where((c) => c.group == group).toList();
      if (inGroup.isNotEmpty) grouped[group] = inGroup;
    }
    return grouped;
  }

  Future<KotobaCategory?> getById(String id) async {
    final all = await getAll();
    for (final category in all) {
      if (category.id == id) return category;
    }
    return null;
  }
}
