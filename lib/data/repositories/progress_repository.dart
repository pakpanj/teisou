import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/kana_progress.dart';
import '../models/kana_status.dart';
import '../models/kana_type.dart';
import '../models/kana_type_progress.dart';

/// Reads and writes per-user progress (profile + per-kana learning state)
/// stored on the `users/{uid}` document.
class ProgressRepository {
  final FirebaseFirestore _firestore;

  ProgressRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(FirestorePaths.users).doc(uid);

  /// Creates the user doc profile on first launch, or refreshes
  /// `lastLoginAt`/`linkedGoogle` on subsequent launches.
  Future<void> ensureUserProfile(
    String uid, {
    required bool isAnonymous,
    String? displayName,
  }) async {
    final doc = _userDoc(uid);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      await doc.set({
        'profile': {
          'displayName': displayName,
          'isAnonymous': isAnonymous,
          'linkedGoogle': !isAnonymous,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        },
      });
    } else {
      await doc.set({
        'profile': {
          'displayName': displayName,
          'isAnonymous': isAnonymous,
          'linkedGoogle': !isAnonymous,
          'lastLoginAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    }
  }

  Future<KanaTypeProgress> getTypeProgress(String uid, KanaType type) async {
    final snapshot = await _userDoc(uid).get();
    final progress = snapshot.data()?['progress'] as Map<String, dynamic>?;
    return KanaTypeProgress.fromMap(
      progress?[type.key] as Map<String, dynamic>?,
    );
  }

  Stream<KanaTypeProgress> watchTypeProgress(String uid, KanaType type) {
    return _userDoc(uid).snapshots().map((snapshot) {
      final progress = snapshot.data()?['progress'] as Map<String, dynamic>?;
      return KanaTypeProgress.fromMap(
        progress?[type.key] as Map<String, dynamic>?,
      );
    });
  }

  Future<void> setLastIndex(String uid, KanaType type, int index) {
    return _userDoc(uid).set({
      'progress': {
        type.key: {'lastIndex': index},
      },
    }, SetOptions(merge: true));
  }

  /// Marks a flashcard as viewed. Only transitions `new` -> `learning` and
  /// stamps `viewedAt` the first time a card is opened; later views are a
  /// no-op so we don't spend a write on every flip.
  Future<void> recordCardViewed(
    String uid,
    KanaType type,
    String kanaId,
    KanaProgress current,
  ) async {
    if (current.status != KanaStatus.newKana) return;

    final updated = current.copyWith(
      status: KanaStatus.learning,
      viewedAt: DateTime.now(),
    );

    await _userDoc(uid).set({
      'progress': {
        type.key: {
          'items': {kanaId: updated.toMap()},
        },
      },
    }, SetOptions(merge: true));
  }
}
