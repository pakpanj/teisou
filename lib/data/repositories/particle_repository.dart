import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/particle_entry.dart';

/// Loads the bundled particle dictionary once and serves it from an
/// in-memory cache, same pattern as BunpouRepository — static data,
/// identical for every user, so it lives as an asset rather than
/// Firestore.
class ParticleRepository {
  static const _assetPath = 'assets/data/particle_data.json';

  List<ParticleEntry>? _cache;

  Future<List<ParticleEntry>> _loadAll() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as List;
    final all = decoded
        .map((e) => ParticleEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = all;
    return all;
  }

  Future<List<ParticleEntry>> getAll() => _loadAll();

  Future<List<ParticleEntry>> getByCategory(String category) async {
    final all = await _loadAll();
    return all.where((p) => p.category == category).toList();
  }

  Future<ParticleEntry?> getById(String id) async {
    final all = await _loadAll();
    for (final entry in all) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Case-insensitive search across the particle text, overview, and every
  /// nested function's title/explanation. Placeholder rows never match
  /// since they carry no content.
  Future<List<ParticleEntry>> search(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return [];
    final all = await _loadAll();
    return all.where((p) {
      if (p.placeholder) return false;
      if (p.particle.toLowerCase().contains(trimmed)) return true;
      if (p.overview.toLowerCase().contains(trimmed)) return true;
      for (final fn in p.functions) {
        if (fn.title.toLowerCase().contains(trimmed)) return true;
        if (fn.explanation.toLowerCase().contains(trimmed)) return true;
      }
      return false;
    }).toList();
  }
}
