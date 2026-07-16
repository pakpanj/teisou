import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/bunpou_entry.dart';
import '../models/jlpt_level.dart';

/// Loads the bundled grammar dictionary once and serves it from an
/// in-memory cache, same pattern as [KanjiRepository] — static data,
/// identical for every user, so it lives as an asset rather than
/// Firestore.
class BunpouRepository {
  static const _assetPath = 'assets/data/bunpou_data.json';

  List<BunpouEntry>? _cache;

  Future<List<BunpouEntry>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => BunpouEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<List<BunpouEntry>> getAll() => _loadAll();

  Future<List<BunpouEntry>> getByLevel(JlptLevel level) async {
    final all = await _loadAll();
    return all.where((b) => b.jlptLevel == level).toList();
  }

  Future<BunpouEntry?> getById(String id) async {
    final all = await _loadAll();
    for (final entry in all) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Case-insensitive search across pattern, meaning, formation, and usage
  /// notes. Placeholder rows never match since they carry no content.
  Future<List<BunpouEntry>> search(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];
    final all = await _loadAll();
    return all.where((b) {
      if (b.placeholder) return false;
      if (b.pattern.toLowerCase().contains(trimmed)) return true;
      if (b.meaning.toLowerCase().contains(trimmed)) return true;
      if (b.formation.toLowerCase().contains(trimmed)) return true;
      if (b.usageNotes.toLowerCase().contains(trimmed)) return true;
      return false;
    }).toList();
  }
}
