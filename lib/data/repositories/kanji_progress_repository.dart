import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/kanji_progress_entry.dart';

/// "Sudah Dipelajari" marks for kanji. Same local-first shape as
/// KotobaProgressRepository: SharedPreferences is the source of truth this
/// screen reads from, Firestore is a best-effort mirror.
class KanjiProgressRepository {
  static const _prefsKey = 'kanji_learned_ids';

  final FirebaseFirestore _firestore;

  KanjiProgressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<KanjiProgressEntry>> getLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    return raw
        .map((s) => KanjiProgressEntry.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> getLearnedIds() async {
    final entries = await getLocal();
    return entries.map((e) => e.kanjiId).toSet();
  }

  Future<void> _saveLocalList(List<KanjiProgressEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      entries.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  Future<void> markLearned(String kanjiId, String jlptLevel, {String? uid}) async {
    final current = await getLocal();
    if (current.any((e) => e.kanjiId == kanjiId)) return;
    final entry = KanjiProgressEntry(
      kanjiId: kanjiId,
      jlptLevel: jlptLevel,
      learnedAt: DateTime.now(),
    );
    current.add(entry);
    await _saveLocalList(current);

    if (uid != null) {
      try {
        await _firestore
            .collection(FirestorePaths.kanjiProgressCollection(uid))
            .doc(kanjiId)
            .set(entry.toFirestoreMap());
      } catch (_) {
        // Best-effort mirror only — the local write above is the source of
        // truth and already succeeded, so a network/Firestore failure here
        // must not propagate and get the caller's UI state stuck.
      }
    }
  }

  Future<void> unmarkLearned(String kanjiId, {String? uid}) async {
    final current = await getLocal();
    current.removeWhere((e) => e.kanjiId == kanjiId);
    await _saveLocalList(current);

    if (uid != null) {
      try {
        await _firestore
            .collection(FirestorePaths.kanjiProgressCollection(uid))
            .doc(kanjiId)
            .delete();
      } catch (_) {
        // Best-effort mirror only — see markLearned above.
      }
    }
  }
}
