import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/kaiwa_progress_entry.dart';

/// "Sudah Dipelajari" marks for Kaiwa dialogues. Same local-first shape as
/// ParticleProgressRepository/BunpouProgressRepository/
/// KanjiProgressRepository/KotobaProgressRepository: SharedPreferences is
/// the source of truth this screen reads from, Firestore is a best-effort
/// mirror.
class KaiwaProgressRepository {
  static const _prefsKey = 'kaiwa_learned_ids';

  final FirebaseFirestore _firestore;

  KaiwaProgressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<KaiwaProgressEntry>> getLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    return raw
        .map((s) =>
            KaiwaProgressEntry.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> getLearnedIds() async {
    final entries = await getLocal();
    return entries.map((e) => e.kaiwaId).toSet();
  }

  Future<void> _saveLocalList(List<KaiwaProgressEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      entries.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  Future<void> markLearned(String kaiwaId, String category, {String? uid}) async {
    final current = await getLocal();
    if (current.any((e) => e.kaiwaId == kaiwaId)) return;
    final entry = KaiwaProgressEntry(
      kaiwaId: kaiwaId,
      category: category,
      learnedAt: DateTime.now(),
    );
    current.add(entry);
    await _saveLocalList(current);

    if (uid != null) {
      await _firestore
          .collection(FirestorePaths.kaiwaProgressCollection(uid))
          .doc(kaiwaId)
          .set(entry.toFirestoreMap());
    }
  }

  Future<void> unmarkLearned(String kaiwaId, {String? uid}) async {
    final current = await getLocal();
    current.removeWhere((e) => e.kaiwaId == kaiwaId);
    await _saveLocalList(current);

    if (uid != null) {
      await _firestore
          .collection(FirestorePaths.kaiwaProgressCollection(uid))
          .doc(kaiwaId)
          .delete();
    }
  }
}
