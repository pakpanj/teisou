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
class SavedWordsRepository {
  static const _prefsKey = 'saved_words';

  final FirebaseFirestore _firestore;

  SavedWordsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<SavedWord>> getLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    return raw
        .map((s) => SavedWord.fromJson(json.decode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveLocalList(List<SavedWord> words) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      words.map((w) => json.encode(w.toJson())).toList(),
    );
  }

  Future<void> add(SavedWord word, {String? uid}) async {
    final current = await getLocal();
    current.removeWhere((w) => w.id == word.id);
    current.insert(0, word);
    await _saveLocalList(current);

    if (uid != null) {
      await _firestore
          .collection(FirestorePaths.savedWordsCollection(uid))
          .doc(word.id)
          .set(word.toFirestoreMap());
    }
  }

  Future<void> remove(String id, {String? uid}) async {
    final current = await getLocal();
    current.removeWhere((w) => w.id == id);
    await _saveLocalList(current);

    if (uid != null) {
      await _firestore
          .collection(FirestorePaths.savedWordsCollection(uid))
          .doc(id)
          .delete();
    }
  }
}
