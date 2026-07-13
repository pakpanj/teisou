import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/kotoba_progress_entry.dart';

/// "Sudah Dipelajari" marks for Kotoba words. Same local-first shape as
/// SavedWordsRepository: SharedPreferences is the source of truth this
/// screen reads from, Firestore is a best-effort mirror.
class KotobaProgressRepository {
  static const _prefsKey = 'kotoba_learned_words';

  final FirebaseFirestore _firestore;

  KotobaProgressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<KotobaProgressEntry>> getLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    return raw
        .map((s) => KotobaProgressEntry.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> getLearnedIds() async {
    final entries = await getLocal();
    return entries.map((e) => e.wordId).toSet();
  }

  Future<void> _saveLocalList(List<KotobaProgressEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      entries.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  Future<void> markLearned(String wordId, String categoryId, {String? uid}) async {
    final current = await getLocal();
    if (current.any((e) => e.wordId == wordId)) return;
    final entry = KotobaProgressEntry(
      wordId: wordId,
      categoryId: categoryId,
      learnedAt: DateTime.now(),
    );
    current.add(entry);
    await _saveLocalList(current);

    if (uid != null) {
      await _firestore
          .collection(FirestorePaths.kotobaProgressCollection(uid))
          .doc(wordId)
          .set(entry.toFirestoreMap());
    }
  }

  Future<void> unmarkLearned(String wordId, {String? uid}) async {
    final current = await getLocal();
    current.removeWhere((e) => e.wordId == wordId);
    await _saveLocalList(current);

    if (uid != null) {
      await _firestore
          .collection(FirestorePaths.kotobaProgressCollection(uid))
          .doc(wordId)
          .delete();
    }
  }
}
