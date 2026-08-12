import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/particle_progress_entry.dart';

/// "Sudah Dipelajari" marks for particles. Same local-first shape as
/// BunpouProgressRepository/KanjiProgressRepository/
/// KotobaProgressRepository: SharedPreferences is the source of truth this
/// screen reads from, Firestore is a best-effort mirror.
///
/// **Scoped per uid** — see `KanjiProgressRepository`'s doc comment for why:
/// an unscoped key let progress leak between accounts sharing a device.
/// [_migrateLegacyIfNeeded] carries the old shared list forward to
/// whichever uid reads first, once, then clears it.
class ParticleProgressRepository {
  static const _legacyPrefsKey = 'particle_learned_ids';

  final FirebaseFirestore _firestore;

  ParticleProgressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String _prefsKey(String uid) => '${_legacyPrefsKey}_$uid';

  Future<void> _migrateLegacyIfNeeded(SharedPreferences prefs, String uid) async {
    final legacy = prefs.getStringList(_legacyPrefsKey);
    if (legacy == null) return;
    if (prefs.getStringList(_prefsKey(uid)) == null) {
      await prefs.setStringList(_prefsKey(uid), legacy);
    }
    await prefs.remove(_legacyPrefsKey);
  }

  Future<List<ParticleProgressEntry>> getLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs, uid);
    final raw = prefs.getStringList(_prefsKey(uid)) ?? [];
    return raw
        .map((s) =>
            ParticleProgressEntry.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> getLearnedIds(String uid) async {
    final entries = await getLocal(uid);
    return entries.map((e) => e.particleId).toSet();
  }

  Future<void> _saveLocalList(String uid, List<ParticleProgressEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey(uid),
      entries.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  Future<void> markLearned(String uid, String particleId, String category) async {
    final current = await getLocal(uid);
    if (current.any((e) => e.particleId == particleId)) return;
    final entry = ParticleProgressEntry(
      particleId: particleId,
      category: category,
      learnedAt: DateTime.now(),
    );
    current.add(entry);
    await _saveLocalList(uid, current);

    try {
      await _firestore
          .collection(FirestorePaths.particleProgressCollection(uid))
          .doc(particleId)
          .set(entry.toFirestoreMap());
    } catch (_) {
      // Best-effort mirror only — the local write above is the source of
      // truth and already succeeded, so a network/Firestore failure here
      // must not propagate and get the caller's UI state stuck.
    }
  }

  Future<void> unmarkLearned(String uid, String particleId) async {
    final current = await getLocal(uid);
    current.removeWhere((e) => e.particleId == particleId);
    await _saveLocalList(uid, current);

    try {
      await _firestore
          .collection(FirestorePaths.particleProgressCollection(uid))
          .doc(particleId)
          .delete();
    } catch (_) {
      // Best-effort mirror only — see markLearned above.
    }
  }
}
