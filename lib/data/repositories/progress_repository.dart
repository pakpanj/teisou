import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/ad_reward.dart';
import '../models/kana_progress.dart';
import '../models/kana_status.dart';
import '../models/kana_type.dart';
import '../models/kana_type_progress.dart';
import '../models/subscription.dart';
import '../models/user_profile.dart';

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
          'currentStreak': 0,
          'lastActiveDate': null,
          'customDisplayName': null,
          'avatarType': AvatarType.google.key,
          'avatarValue': null,
          'lastNameChangeAt': null,
        },
        'subscription': Subscription.free().toMap(),
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

  /// Bumps the daily learning streak: +1 if the user was last active
  /// yesterday, reset to 1 on a gap, unchanged if already active today.
  /// Call once per app startup.
  Future<void> recordDailyActivity(String uid) async {
    final doc = _userDoc(uid);
    final snapshot = await doc.get();
    final profile = snapshot.data()?['profile'] as Map<String, dynamic>?;
    final lastActiveDate = profile?['lastActiveDate'] as String?;
    final currentStreak = (profile?['currentStreak'] as num?)?.toInt() ?? 0;

    final today = DateTime.now();
    final todayKey = _dateKey(today);
    if (lastActiveDate == todayKey) return;

    final yesterdayKey = _dateKey(today.subtract(const Duration(days: 1)));
    final newStreak = lastActiveDate == yesterdayKey ? currentStreak + 1 : 1;

    await doc.set({
      'profile': {
        'lastActiveDate': todayKey,
        'currentStreak': newStreak,
      },
    }, SetOptions(merge: true));
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Sets the custom display name shown in place of the Firebase Auth
  /// displayName. Also stamps `lastNameChangeAt`.
  Future<void> updateCustomDisplayName(String uid, String name) {
    return _userDoc(uid).set({
      'profile': {
        'customDisplayName': name,
        'lastNameChangeAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  /// Sets which avatar the user has selected: [type] is the resolution kind
  /// (`google`/`preset_free`/`preset_premium`/`custom_upload`) and [value]
  /// is the preset id or Storage download URL, as applicable.
  Future<void> updateAvatar(String uid, AvatarType type, String? value) {
    return _userDoc(uid).set({
      'profile': {
        'avatarType': type.key,
        'avatarValue': value,
      },
    }, SetOptions(merge: true));
  }

  /// Raw `profile` map — displayName/isAnonymous/currentStreak/etc.
  Stream<Map<String, dynamic>> watchProfile(String uid) {
    return _userDoc(uid).snapshots().map(
          (snapshot) =>
              snapshot.data()?['profile'] as Map<String, dynamic>? ?? {},
        );
  }

  Stream<Subscription> watchSubscription(String uid) {
    return _userDoc(uid).snapshots().map(
          (snapshot) => Subscription.fromMap(
            snapshot.data()?['subscription'] as Map<String, dynamic>?,
          ),
        );
  }

  Future<Subscription> getSubscription(String uid) async {
    final snapshot = await _userDoc(uid).get();
    return Subscription.fromMap(
      snapshot.data()?['subscription'] as Map<String, dynamic>?,
    );
  }

  Future<void> setSubscription(String uid, Subscription subscription) {
    return _userDoc(
      uid,
    ).set({'subscription': subscription.toMap()}, SetOptions(merge: true));
  }

  Future<Map<String, AdReward>> getAdRewards(String uid) async {
    final snapshot = await _userDoc(uid).get();
    final raw = snapshot.data()?['adRewards'] as Map<String, dynamic>?;
    if (raw == null) return {};
    return raw.map(
      (moduleId, value) =>
          MapEntry(moduleId, AdReward.fromMap(moduleId, value)),
    );
  }

  /// Grants a 24h preview unlock for [moduleId] after a rewarded ad finishes.
  Future<void> unlockAdReward(String uid, String moduleId) {
    final reward = AdReward.unlockNow(moduleId);
    return _userDoc(uid).set({
      'adRewards': {moduleId: reward.toMap()},
    }, SetOptions(merge: true));
  }

  /// Records "Ingatkan Saya" interest for a coming-soon module.
  Future<void> recordModuleInterest(String uid, String moduleId) {
    return _userDoc(uid)
        .collection(FirestorePaths.moduleInterest)
        .doc(moduleId)
        .set({'interestedAt': FieldValue.serverTimestamp()});
  }

  /// Saves a kanji/kotoba dictionary entry to the user's learning list.
  /// [type] is `'kanji'` or `'kotoba'`; [itemId] is the entry's id.
  Future<void> saveDictionaryItem(
    String uid, {
    required String itemId,
    required String type,
  }) {
    return _userDoc(uid)
        .collection(FirestorePaths.savedItems)
        .doc(itemId)
        .set({
      'type': type,
      'itemId': itemId,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Wipes all hiragana/katakana learning progress back to a blank slate.
  /// Uses `update()` (not merge-`set`) so each type's map is replaced
  /// wholesale instead of merging old `items` back in.
  Future<void> resetAllProgress(String uid) {
    return _userDoc(uid).update({
      'progress.hiragana': {'lastIndex': 0, 'items': {}},
      'progress.katakana': {'lastIndex': 0, 'items': {}},
    });
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
