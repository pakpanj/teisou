import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/ad_reward.dart';
import '../models/kana_progress.dart';
import '../models/kana_status.dart';
import '../models/kana_type.dart';
import '../models/kana_type_progress.dart';
import '../models/saved_item_pointer.dart';
import '../models/subscription.dart';
import '../models/user_profile.dart';

/// Reads and writes per-user progress (profile + per-kana learning state)
/// stored on the `users/{uid}` document.
class ProgressRepository {
  final FirebaseFirestore _firestore;
  final Random _random;

  ProgressRepository({FirebaseFirestore? firestore, Random? random})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _random = random ?? Random();

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(FirestorePaths.users).doc(uid);

  static const _userIdLength = 8;
  static const _userIdAlphabet =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I — same reasoning as ClanRepository's join code
  static const _maxUserIdAttempts = 5;

  String _generateUserIdCandidate() => List.generate(
        _userIdLength,
        (_) => _userIdAlphabet[_random.nextInt(_userIdAlphabet.length)],
      ).join();

  /// A short, unique, human-shareable id for [uid] — separate from the
  /// Firebase Auth uid itself (long, opaque, never meant to be typed by a
  /// hand). Exists because many accounts share the exact same display name
  /// (every user who never customized one defaults to the same "Pelajar
  /// Kana"), which made `LeaderboardRepository.searchPublicUsers` unable to
  /// tell two same-named learners apart — a real gap found by actually
  /// searching on a device, not a hypothetical one.
  ///
  /// Uniqueness is enforced the same way `ClanRepository.createClan`
  /// enforces its join code being unique: a reservation document at
  /// `userIds/{code}` whose *existence* is the uniqueness check, created in
  /// the same batch as the profile write so the two can never disagree —
  /// there is no separate index to keep in sync.
  Future<String> _reserveUserId(WriteBatch batch, String uid) async {
    final userIds = _firestore.collection(FirestorePaths.userIds);
    for (var attempt = 0; attempt < _maxUserIdAttempts; attempt++) {
      final candidate = _generateUserIdCandidate();
      final reservation = userIds.doc(candidate);
      final existing = await reservation.get();
      if (existing.exists) continue;
      batch.set(reservation, {'uid': uid});
      return candidate;
    }
    throw StateError('Gagal membuat ID unik, coba lagi.');
  }

  /// Creates the user doc profile on first launch, or refreshes
  /// `lastLoginAt`/`linkedGoogle` on subsequent launches.
  ///
  /// The `userId` reservation is deliberately a *separate* best-effort step
  /// after the core profile write, not bundled into the same atomic batch —
  /// found the hard way on a device: `userIds/{code}`'s own `firestore.rules`
  /// block is new (added alongside this feature) and, until it's actually
  /// deployed to the live project, every write to that collection comes back
  /// `permission-denied`. Firestore batches are all-or-nothing, so bundling
  /// the reservation into the profile-creation batch meant a not-yet-deployed
  /// rules file silently broke account creation *entirely* for every new
  /// user — not just left them without an id. Splitting the two means a
  /// missing/stale rules deploy only costs the id (self-healed on the next
  /// launch once rules do land), never the profile itself.
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

    try {
      await _backfillUserIdIfMissing(uid, snapshot);
    } catch (_) {
      // Best-effort, see the doc comment above — the next launch retries.
    }
  }

  /// Reserves and writes a `userId` for [uid] if its profile doesn't already
  /// have one — covers both a brand-new account (whose `snapshot` predates
  /// this call, so it never has `userId`) and an existing account that
  /// predates the field entirely, the same "backfill on the next natural
  /// touchpoint" shape already used for `LeaderboardEntry.globalScore`/
  /// `displayNameLower` elsewhere in this app, rather than a one-off
  /// migration script this project has no way to run against live data.
  Future<void> _backfillUserIdIfMissing(
    String uid,
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final existingProfile =
        snapshot.data()?['profile'] as Map<String, dynamic>?;
    if ((existingProfile?['userId'] as String?) != null) return;

    final batch = _firestore.batch();
    final userId = await _reserveUserId(batch, uid);
    batch.set(_userDoc(uid), {
      'profile': {'userId': userId},
    }, SetOptions(merge: true));
    await batch.commit();
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
  /// (`google`/`preset_free`/`preset_premium`) and [value]
  /// is the preset id or Storage download URL, as applicable.
  Future<void> updateAvatar(String uid, AvatarType type, String? value) {
    return _userDoc(uid).set({
      'profile': {
        'avatarType': type.key,
        'avatarValue': value,
      },
    }, SetOptions(merge: true));
  }

  /// Sets which Profile-header cover the user has selected. [coverId] is
  /// one of [CoverPresets.all]'s ids, or `null` to fall back to the
  /// fallback cover ([CoverPresets.fallback]).
  Future<void> updateCover(String uid, String? coverId) {
    return _userDoc(uid).set({
      'profile': {'coverId': coverId},
    }, SetOptions(merge: true));
  }

  /// Sets which avatar frame/border the user has selected. [frameId] is
  /// one of [FramePresets.all]'s ids, or `null` for no frame.
  Future<void> updateFrame(String uid, String? frameId) {
    return _userDoc(uid).set({
      'profile': {'frameId': frameId},
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
  /// The 24h window is a backstop expiry, not the intended usage model for
  /// every caller — some callers (e.g. the avatar picker) revoke this via
  /// [consumeAdReward] the moment it's spent once, well before it would
  /// naturally expire.
  Future<void> unlockAdReward(String uid, String moduleId) {
    final reward = AdReward.unlockNow(moduleId);
    return _userDoc(uid).set({
      'adRewards': {moduleId: reward.toMap()},
    }, SetOptions(merge: true));
  }

  /// Revokes an ad-reward unlock immediately after it's been spent on one
  /// action, instead of leaving it active until its 24h expiry. Used where
  /// "watch an ad" is meant to grant a single use, not a time window.
  Future<void> consumeAdReward(String uid, String moduleId) {
    return _userDoc(uid).update({'adRewards.$moduleId': FieldValue.delete()});
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

  /// One-shot fetch of every dictionary bookmark for [uid] — pointers only
  /// ({itemId, type}), not the resolved kanji/kotoba content; callers
  /// resolve those via `KanjiRepository`/`KotobaRepository`.
  Future<List<SavedItemPointer>> getSavedItems(String uid) async {
    final snapshot =
        await _userDoc(uid).collection(FirestorePaths.savedItems).get();
    return snapshot.docs
        .map((doc) => SavedItemPointer.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Removes one dictionary bookmark.
  Future<void> removeSavedItem(String uid, String itemId) {
    return _userDoc(uid)
        .collection(FirestorePaths.savedItems)
        .doc(itemId)
        .delete();
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
