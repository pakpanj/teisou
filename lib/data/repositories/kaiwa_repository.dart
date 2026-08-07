import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;

import '../models/kaiwa_entry.dart';

/// Decodes the dialogue file and builds its models.
///
/// Top-level because [compute] can only be handed a top-level or static
/// function — it runs this in a background isolate, and a closure would
/// not be sendable.
///
/// **Why it is worth an isolate here.** This is the app's largest asset by
/// a wide margin: 10MB across 1,700 dialogues, measured at 185ms just to
/// decode on a desktop and several times that on a phone. Run on the main
/// isolate it stops every animation dead — which is exactly what the
/// startup loading screen looked like, a progress bar jumping between
/// frozen states instead of moving.
List<KaiwaEntry> parseKaiwaEntries(String raw) {
  final decoded = json.decode(raw) as List;
  return decoded
      .map((e) => KaiwaEntry.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// Loads the bundled Kaiwa dialogue dataset once and serves it from an
/// in-memory cache, same pattern as ParticleRepository — static content,
/// identical for every user, so it lives as an asset rather than Firestore.
class KaiwaRepository {
  static const _assetPath = 'assets/data/kaiwa_data.json';

  List<KaiwaEntry>? _cache;

  Future<List<KaiwaEntry>> _loadAll() async {
    if (_cache != null) return _cache!;
    // The string has to be read here — rootBundle goes through a platform
    // channel and is main-isolate only — but the parsing does not.
    final raw = await rootBundle.loadString(_assetPath);
    final all = await compute(parseKaiwaEntries, raw);
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
