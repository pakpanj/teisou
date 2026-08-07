import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;

import '../models/dokkai_passage.dart';
import '../models/jlpt_level.dart';

/// Loads the bundled Dokkai passage set once and serves it from an
/// in-memory cache, same pattern as [KanjiRepository]/[KotobaRepository].
/// Decodes the dataset and builds its models.
///
/// Top-level because [compute] can only be handed a top-level or
/// static function — it runs this in a background isolate, and a
/// closure would not be sendable.
///
/// Worth an isolate at 0.8MB across 500 passages: 15ms just to decode on a desktop, and
/// several times that on a phone. Run on the main isolate it stops
/// every animation for its whole duration, which on the startup
/// loading screen means a progress bar that jumps between frozen
/// states instead of moving.
List<DokkaiPassage> parseDokkaiPassages(String raw) {
  final decoded = json.decode(raw) as List;
  return decoded
      .map((e) => DokkaiPassage.fromJson(e as Map<String, dynamic>))
      .toList();
}

class DokkaiRepository {
  static const _assetPath = 'assets/data/dokkai_data.json';

  List<DokkaiPassage>? _cache;

  Future<List<DokkaiPassage>> _loadAll() async {
    final cached = _cache;
    if (cached != null) return cached;
    // The string has to be read here — rootBundle goes through a
    // platform channel and is main-isolate only — but not parsed.
    final raw = await rootBundle.loadString(_assetPath);
    final all = await compute(parseDokkaiPassages, raw);
    _cache = all;
    return all;
  }

  Future<List<DokkaiPassage>> getAll() => _loadAll();

  Future<List<DokkaiPassage>> getByLevel(JlptLevel level) async {
    final all = await _loadAll();
    return all.where((p) => p.jlptLevel == level).toList();
  }

  Future<DokkaiPassage?> getById(String id) async {
    final all = await _loadAll();
    for (final passage in all) {
      if (passage.id == id) return passage;
    }
    return null;
  }
}
