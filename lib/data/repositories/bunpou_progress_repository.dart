import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/bunpou_progress_entry.dart';

/// "Sudah Dipelajari" marks for grammar patterns. Same local-first shape as
/// KanjiProgressRepository/KotobaProgressRepository: SharedPreferences is
/// the source of truth this screen reads from, Firestore is a best-effort
/// mirror.
class BunpouProgressRepository {
  static const _prefsKey = 'bunpou_learned_ids';

  final FirebaseFirestore _firestore;

  BunpouProgressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<BunpouProgressEntry>> getLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    return raw
        .map((s) => BunpouProgressEntry.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> getLearnedIds() async {
    final entries = await getLocal();
    return entries.map((e) => e.bunpouId).toSet();
  }

  Future<void> _saveLocalList(List<BunpouProgressEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      entries.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  Future<void> markLearned(String bunpouId, String jlptLevel, {String? uid}) async {
    final current = await getLocal();
    if (current.any((e) => e.bunpouId == bunpouId)) return;
    final entry = BunpouProgressEntry(
      bunpouId: bunpouId,
      jlptLevel: jlptLevel,
      learnedAt: DateTime.now(),
    );
    current.add(entry);
    await _saveLocalList(current);

    if (uid != null) {
      await _firestore
          .collection(FirestorePaths.bunpouProgressCollection(uid))
          .doc(bunpouId)
          .set(entry.toFirestoreMap());
    }
  }

  Future<void> unmarkLearned(String bunpouId, {String? uid}) async {
    final current = await getLocal();
    current.removeWhere((e) => e.bunpouId == bunpouId);
    await _saveLocalList(current);

    if (uid != null) {
      await _firestore
          .collection(FirestorePaths.bunpouProgressCollection(uid))
          .doc(bunpouId)
          .delete();
    }
  }
}
