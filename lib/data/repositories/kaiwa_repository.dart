import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/kaiwa_entry.dart';

/// Loads the bundled Kaiwa dialogue dataset once and serves it from an
/// in-memory cache, same pattern as ParticleRepository — static content,
/// identical for every user, so it lives as an asset rather than Firestore.
class KaiwaRepository {
  static const _assetPath = 'assets/data/kaiwa_data.json';

  List<KaiwaEntry>? _cache;

  Future<List<KaiwaEntry>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => KaiwaEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<List<KaiwaEntry>> getAll() => _loadAll();

  Future<List<KaiwaEntry>> getByCategory(String category) async {
    final all = await _loadAll();
    return all.where((e) => e.category == category).toList();
  }

  Future<KaiwaEntry?> getById(String id) async {
    final all = await _loadAll();
    for (final entry in all) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Case-insensitive search across the dialogue title, description, and
  /// every line's Japanese/translation text. Placeholder rows never match
  /// since they carry no content.
  Future<List<KaiwaEntry>> search(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];
    final all = await _loadAll();
    return all.where((e) {
      if (e.placeholder) return false;
      if (e.title.toLowerCase().contains(trimmed)) return true;
      if (e.description.toLowerCase().contains(trimmed)) return true;
      for (final line in e.lines) {
        if (line.npcLine?.japanese.toLowerCase().contains(trimmed) ?? false) {
          return true;
        }
        if (line.npcLine?.translation.toLowerCase().contains(trimmed) ??
            false) {
          return true;
        }
      }
      return false;
    }).toList();
  }
}
