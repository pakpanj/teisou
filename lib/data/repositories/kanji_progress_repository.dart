import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/kanji_progress_entry.dart';

/// "Sudah Dipelajari" marks for kanji. Same local-first shape as
/// KotobaProgressRepository: SharedPreferences is the source of truth this
/// screen reads from, Firestore is a best-effort mirror.
///
/// **Scoped per uid, not a single global key**: the local list used to live
/// under one unscoped `kanji_learned_ids` key shared by every account that
/// ever signed in on the device. `AuthService.signOut()` never clears
/// SharedPreferences, so switching accounts on the same device (a
/// credential-already-in-use fallback landing on a different uid, or simply
/// signing out and a different tester signing in) silently carried over
/// progress — and the level gate (`kanjiLevelGateProvider`) reads this same
/// list, so a level unlocked by one account showed unlocked for the next
/// one too, despite that account never having touched it. Fixed by
/// namespacing the key with the uid; [_migrateLegacyIfNeeded] carries
/// forward whatever was under the old shared key exactly once, to whichever
/// uid happens to read first after this shipped, then clears it so a
/// second account can never inherit it too.
class KanjiProgressRepository {
  static const _legacyPrefsKey = 'kanji_learned_ids';

  final FirebaseFirestore _firestore;

  KanjiProgressRepository({FirebaseFirestore? firestore})
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

  Future<List<KanjiProgressEntry>> getLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs, uid);
    final raw = prefs.getStringList(_prefsKey(uid)) ?? [];
    return raw
        .map((s) => KanjiProgressEntry.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<Set<String>> getLearnedIds(String uid) async {
    final entries = await getLocal(uid);
    return entries.map((e) => e.kanjiId).toSet();
  }

  Future<void> _saveLocalList(String uid, List<KanjiProgressEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey(uid),
      entries.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  Future<void> markLearned(String uid, String kanjiId, String jlptLevel) async {
    final current = await getLocal(uid);
    if (current.any((e) => e.kanjiId == kanjiId)) return;
    final entry = KanjiProgressEntry(
      kanjiId: kanjiId,
      jlptLevel: jlptLevel,
      learnedAt: DateTime.now(),
    );
    current.add(entry);
    await _saveLocalList(uid, current);

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

  Future<void> unmarkLearned(String uid, String kanjiId) async {
    final current = await getLocal(uid);
    current.removeWhere((e) => e.kanjiId == kanjiId);
    await _saveLocalList(uid, current);

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
