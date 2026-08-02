import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/bab_progress_entry.dart';

/// "Bab Selesai" marks. Same local-first shape as [KanjiProgressRepository]
/// and the other four progress repositories: SharedPreferences is the
/// source of truth, Firestore is a best-effort mirror.
class BabProgressRepository {
  static const _prefsKey = 'bab_completed_ids';

  final FirebaseFirestore _firestore;

  BabProgressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<BabProgressEntry>> getLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    return raw
        .map((s) => BabProgressEntry.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> getCompletedIds() async {
    final entries = await getLocal();
    return entries.map((e) => e.babId).toSet();
  }

  Future<void> _saveLocalList(List<BabProgressEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      entries.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  Future<void> markCompleted(String babId, String jlptLevel, {String? uid}) async {
    final current = await getLocal();
    if (current.any((e) => e.babId == babId)) return;
    final entry = BabProgressEntry(
      babId: babId,
      jlptLevel: jlptLevel,
      completedAt: DateTime.now(),
    );
    current.add(entry);
    await _saveLocalList(current);

    if (uid != null) {
      try {
        await _firestore
            .collection(FirestorePaths.babProgressCollection(uid))
            .doc(babId)
            .set(entry.toFirestoreMap());
      } catch (_) {
        // Best-effort mirror only — the local write above is the source of
        // truth and already succeeded, so a network/Firestore failure here
        // must not propagate and get the caller's UI state stuck.
      }
    }
  }

  Future<void> unmarkCompleted(String babId, {String? uid}) async {
    final current = await getLocal();
    current.removeWhere((e) => e.babId == babId);
    await _saveLocalList(current);

    if (uid != null) {
      try {
        await _firestore
            .collection(FirestorePaths.babProgressCollection(uid))
            .doc(babId)
            .delete();
      } catch (_) {
        // Best-effort mirror only — see markCompleted above.
      }
    }
  }
}
