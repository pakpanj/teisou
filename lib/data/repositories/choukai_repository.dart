import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/choukai_clip.dart';
import '../models/jlpt_level.dart';

/// Loads the bundled Choukai clip set once and serves it from an in-memory
/// cache, mirrors [DokkaiRepository]. Currently always returns an empty
/// list — `assets/data/choukai_data.json` ships as `[]` until real clips
/// are authored; every screen downstream already handles an empty pool
/// gracefully (same "architecture ready, content later" shape as Kaiwa's
/// N4-N1 levels before they were authored).
class ChoukaiRepository {
  static const _assetPath = 'assets/data/choukai_data.json';

  List<ChoukaiClip>? _cache;

  Future<List<ChoukaiClip>> _loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => ChoukaiClip.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<List<ChoukaiClip>> getAll() => _loadAll();

  Future<List<ChoukaiClip>> getByLevel(JlptLevel level) async {
    final all = await _loadAll();
    return all.where((c) => c.jlptLevel == level).toList();
  }

  Future<ChoukaiClip?> getById(String id) async {
    final all = await _loadAll();
    for (final clip in all) {
      if (clip.id == id) return clip;
    }
    return null;
  }
}
