import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/particle_progress_entry.dart';

/// "Sudah Dipelajari" marks for particles. Same local-first shape as
/// BunpouProgressRepository/KanjiProgressRepository/
/// KotobaProgressRepository: SharedPreferences is the source of truth this
/// screen reads from, Firestore is a best-effort mirror.
class ParticleProgressRepository {
  static const _prefsKey = 'particle_learned_ids';

  final FirebaseFirestore _firestore;

  ParticleProgressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<ParticleProgressEntry>> getLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    return raw
        .map((s) =>
            ParticleProgressEntry.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> getLearnedIds() async {
    final entries = await getLocal();
    return entries.map((e) => e.particleId).toSet();
  }

  Future<void> _saveLocalList(List<ParticleProgressEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      entries.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  Future<void> markLearned(String particleId, String category, {String? uid}) async {
    final current = await getLocal();
    if (current.any((e) => e.particleId == particleId)) return;
    final entry = ParticleProgressEntry(
      particleId: particleId,
      category: category,
      learnedAt: DateTime.now(),
    );
    current.add(entry);
    await _saveLocalList(current);

    if (uid != null) {
      await _firestore
          .collection(FirestorePaths.particleProgressCollection(uid))
          .doc(particleId)
          .set(entry.toFirestoreMap());
    }
  }

  Future<void> unmarkLearned(String particleId, {String? uid}) async {
    final current = await getLocal();
    current.removeWhere((e) => e.particleId == particleId);
    await _saveLocalList(current);

    if (uid != null) {
      await _firestore
          .collection(FirestorePaths.particleProgressCollection(uid))
          .doc(particleId)
          .delete();
    }
  }
}
