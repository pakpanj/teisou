import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/saved_word.dart';

/// Personal "Daftar Belajar" word list from Cam Detector. Writes go to
/// SharedPreferences first (so saving works offline / before sign-in
/// resolves) and then mirror to `users/{uid}/savedWords` — following the
/// same "local write, best-effort cloud sync" shape as
/// ProgressRepository's other per-user writes.
///
/// **Scoped per uid** — see `KanjiProgressRepository`'s doc comment for the
/// full reasoning: an unscoped key let one account's saved-word list leak
/// into a different account signed in on the same device.
/// [_migrateLegacyIfNeeded] carries the old shared list forward to whichever
/// uid reads first, once, then clears it.
class SavedWordsRepository {
  static const _legacyPrefsKey = 'saved_words';

  final FirebaseFirestore _firestore;

  SavedWordsRepository({FirebaseFirestore? firestore})
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

  Future<List<SavedWord>> getLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyIfNeeded(prefs, uid);
    final raw = prefs.getStringList(_prefsKey(uid)) ?? [];
    return raw
        .map((s) => SavedWord.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveLocalList(String uid, List<SavedWord> words) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey(uid),
      words.map((w) => json.encode(w.toJson())).toList(),
    );
  }

  Future<void> add(String uid, SavedWord word) async {
    final current = await getLocal(uid);
    current.removeWhere((w) => w.id == word.id);
    current.insert(0, word);
    await _saveLocalList(uid, current);

    await _firestore
        .collection(FirestorePaths.savedWordsCollection(uid))
        .doc(word.id)
        .set(word.toFirestoreMap());
  }

  Future<void> remove(String uid, String id) async {
    final current = await getLocal(uid);
    current.removeWhere((w) => w.id == id);
    await _saveLocalList(uid, current);

    await _firestore
        .collection(FirestorePaths.savedWordsCollection(uid))
        .doc(id)
        .delete();
  }
}
