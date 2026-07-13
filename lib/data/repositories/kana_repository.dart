import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/kana_character.dart';
import '../models/kana_type.dart';

/// Loads the bundled kana dataset once and serves it from an in-memory
/// cache. The dataset is static and identical for every user, so it lives
/// as an asset rather than in Firestore.
class KanaRepository {
  static const _assetPath = 'assets/data/kana_data.json';

  List<KanaCharacter>? _cache;

  Future<List<KanaCharacter>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => KanaCharacter.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<List<KanaCharacter>> getAll() => _loadAll();

  /// Returns all kana of [type], sorted by gojuon row then column so
  /// flashcard order and "X/46" progress stay consistent.
  Future<List<KanaCharacter>> getByType(KanaType type) async {
    final all = await _loadAll();
    final filtered = all.where((k) => k.type == type).toList()
      ..sort((a, b) {
        final rowCompare = a.row.compareTo(b.row);
        if (rowCompare != 0) return rowCompare;
        return a.column.compareTo(b.column);
      });
    return filtered;
  }

  Future<KanaCharacter?> getById(String id) async {
    final all = await _loadAll();
    for (final kana in all) {
      if (kana.id == id) return kana;
    }
    return null;
  }
}
