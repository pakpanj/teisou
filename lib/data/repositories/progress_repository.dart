import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../core/constants/avatars.dart';
import '../../core/constants/covers.dart';
import '../../core/constants/frames.dart';
import '../../core/firebase/firestore_paths.dart';
import '../models/ad_reward.dart';
import '../models/card_game_rank.dart';
import '../models/kana_progress.dart';
import '../models/kana_status.dart';
import '../models/kana_type.dart';
import '../models/kana_type_progress.dart';
import '../models/plan_intro_state.dart';
import '../models/saved_item_pointer.dart';
import '../models/subscription.dart';
import '../models/user_profile.dart';
import '../models/xp_progress.dart';

/// Reads and writes per-user progress (profile + per-kana learning state)
/// stored on the `users/{uid}` document.
class ProgressRepository {
  final FirebaseFirestore _firestore;
  final Random _random;
  final FirebaseFunctions _functions;

  ProgressRepository({
    FirebaseFirestore? firestore,
    Random? random,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _random = random ?? Random(),
       _functions = functions ?? FirebaseFunctions.instance;

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
      'profile': {'lastActiveDate': todayKey, 'currentStreak': newStreak},
    }, SetOptions(merge: true));

    // Once per calendar day the user is actually active — not gated on
    // whether the streak specifically continued vs. reset, since "opened
    // the app and did something today" is the thing being rewarded, not
    // the streak counter itself.
    await addXp(uid, XpAction.dailyActive);
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
      'profile': {'avatarType': type.key, 'avatarValue': value},
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

  /// Sets the card back this player wears in Card Game Mode. [cardSkinId]
  /// is one of [CardSkinPresets.all]'s ids, or `null` for the default.
  Future<void> updateCardSkin(String uid, String? cardSkinId) {
    return _userDoc(uid).set({
      'profile': {'cardSkinId': cardSkinId},
    }, SetOptions(merge: true));
  }

  /// Raw `profile` map — displayName/isAnonymous/currentStreak/etc.
  Stream<Map<String, dynamic>> watchProfile(String uid) {
    return _userDoc(uid).snapshots().map(
      (snapshot) => snapshot.data()?['profile'] as Map<String, dynamic>? ?? {},
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

  /// Reads the account's [PlanIntroState] — see that class's own doc
  /// comment for what the two fields mean and why this lives on the
  /// account rather than the device.
  Future<PlanIntroState> getPlanIntroState(String uid) async {
    final snapshot = await _userDoc(uid).get();
    return PlanIntroState.fromMap(
      snapshot.data()?['planIntro'] as Map<String, dynamic>?,
    );
  }

  /// Called when `PlanIntroFlow` is actually dismissed (either plan
  /// picked) — records that this account has now seen it, and stamps
  /// whether it was premium at that exact moment so a later lapse can be
  /// detected against it.
  Future<void> markPlanIntroSeen(String uid, {required bool premiumNow}) {
    return _userDoc(uid).set({
      'planIntro': PlanIntroState(
        seen: true,
        lastKnownPremium: premiumNow,
      ).toMap(),
    }, SetOptions(merge: true));
  }

  /// Refreshes `lastKnownPremium` on a launch where the intro was **not**
  /// shown, so a premium status the account reached some other way (e.g.
  /// buying Premium from `PaywallScreen` without ever revisiting this
  /// screen) is still on record — without this, a lapse reached that way
  /// could never be detected, since [markPlanIntroSeen] only ever runs
  /// when the intro itself is dismissed.
  Future<void> recordPlanIntroSubscriptionCheck(
    String uid, {
    required bool isPremium,
  }) {
    return _userDoc(uid).set({
      'planIntro': {'seen': true, 'lastKnownPremium': isPremium},
    }, SetOptions(merge: true));
  }

  /// Card skins this learner has bought.
  ///
  /// **Read-only from here on purpose.** `entitlements` is written by
  /// the `verifyPurchase` Cloud Function alone, and `firestore.rules`
  /// refuses every client write to it — so there is no setter to pair
  /// with this, and adding one would only produce writes the server
  /// rejects.
  Stream<Set<String>> watchOwnedSkins(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      final raw = snapshot.data()?['entitlements'] as Map<String, dynamic>?;
      final skins = raw?['skins'] as List?;
      return {for (final id in skins ?? const []) id as String};
    });
  }

  /// Card Game Mode standing (tier/division/stars/season) — defaults to
  /// [CardGameRank.initial] (Bronze V) for a player who has never had the
  /// field written, same fallback shape as [watchSubscription]/
  /// [getSubscription] default to [Subscription.free].
  Stream<CardGameRank> watchCardGameRank(String uid) {
    return _userDoc(uid).snapshots().map(
      (snapshot) => CardGameRank.fromMap(
        snapshot.data()?[FirestorePaths.fieldCardGameRank]
            as Map<String, dynamic>?,
      ),
    );
  }

  Future<CardGameRank> getCardGameRank(String uid) async {
    final snapshot = await _userDoc(uid).get();
    return CardGameRank.fromMap(
      snapshot.data()?[FirestorePaths.fieldCardGameRank]
          as Map<String, dynamic>?,
    );
  }

  /// Coin balance — read-only from the client, same reasoning as
  /// [watchCardGameRank]: `coins` is frozen against client writes in
  /// `firestore.rules` (`isAllowedPurchaseWrite`), so the only writers
  /// are `verifyPurchase` (a top-up pack, granted after Play confirms
  /// the token) and the weekly `awardTopGlobalCoins` Cloud Function (top
  /// 1-3 on Skor Global). Defaults to 0 for a learner who has never had
  /// the field written, same fallback shape as [watchSubscription].
  Stream<int> watchCoinBalance(String uid) {
    return _userDoc(uid).snapshots().map(
      (snapshot) => (snapshot.data()?['coins'] as num?)?.toInt() ?? 0,
    );
  }

  Future<int> getCoinBalance(String uid) async {
    final snapshot = await _userDoc(uid).get();
    return (snapshot.data()?['coins'] as num?)?.toInt() ?? 0;
  }

  // There is deliberately no setCardGameRank. Stars are moved only by
  // `functions/battle_stars.js` when a ranked match concludes, and
  // `firestore.rules` now rejects any client write that changes
  // `cardGameRank` — a setter here could only ever fail, which is worse
  // than not offering one. (One existed and was never called.)

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
    return _userDoc(uid).collection(FirestorePaths.savedItems).doc(itemId).set({
      'type': type,
      'itemId': itemId,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// One-shot fetch of every dictionary bookmark for [uid] — pointers only
  /// ({itemId, type}), not the resolved kanji/kotoba content; callers
  /// resolve those via `KanjiRepository`/`KotobaRepository`.
  Future<List<SavedItemPointer>> getSavedItems(String uid) async {
    final snapshot = await _userDoc(
      uid,
    ).collection(FirestorePaths.savedItems).get();
    return snapshot.docs
        .map((doc) => SavedItemPointer.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Removes one dictionary bookmark.
  Future<void> removeSavedItem(String uid, String itemId) {
    return _userDoc(
      uid,
    ).collection(FirestorePaths.savedItems).doc(itemId).delete();
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

  Future<XpProgress> getXpProgress(String uid) async {
    final snapshot = await _userDoc(uid).get();
    return XpProgress.fromMap(snapshot.data()?['xp'] as Map<String, dynamic>?);
  }

  Stream<XpProgress> watchXpProgress(String uid) {
    return _userDoc(uid).snapshots().map(
      (snapshot) =>
          XpProgress.fromMap(snapshot.data()?['xp'] as Map<String, dynamic>?),
    );
  }

  /// Awards the fixed XP amount for [action], via the `awardXp` Cloud
  /// Function — **not** a direct Firestore write. `xp.totalXp` is frozen
  /// against every client write (`firestore.rules`'
  /// `isAllowedPurchaseWrite`); the amount for each [XpAction] is decided
  /// server-side, in `functions/award_xp.js`'s `XP_AMOUNTS` table, not by
  /// this caller — see [XpAction]'s own doc comment for why. Best-effort
  /// and silent on failure, same reasoning as every other Firestore
  /// mirror in this repository: by the time this is called the real
  /// action (marking something learned, submitting an exam) has already
  /// succeeded, so a network hiccup awarding XP must never surface as an
  /// error on top of it.
  Future<void> addXp(String uid, XpAction action) async {
    try {
      await _functions.httpsCallable('awardXp').call({
        'action': action.name,
      });
    } catch (_) {}
  }

  /// Claims the reward for the next unclaimed level, via the
  /// `claimXpReward` Cloud Function — **not** a direct Firestore
  /// read-then-write. `xp.claimedLevel` and
  /// `xp.unlocked{Avatar,Frame,Cover}Ids` are frozen against every client
  /// write, same as `xp.totalXp`; the pool-building, the random pick, and
  /// consuming the pending-reward counter all happen server-side now,
  /// inside one Firestore transaction (so two concurrent claims can never
  /// double-grant — see `award_xp.js`'s own doc comment).
  ///
  /// **Option A — Premium Exclusive (locked product decision).** The
  /// server-side pool is built from each catalog's ad-tier and coin-tier
  /// ids only — a subscription-exclusive avatar/frame/cover
  /// (`isPremiumOnly`) is never in it, regardless of level. This method
  /// does not enforce that itself; it is enforced entirely by what
  /// `award_xp.js`'s `REWARD_POOL` contains.
  ///
  /// Returns null when there is nothing to claim, or the reward pool is
  /// exhausted (every ad/coin-tier preset already owned) — the second
  /// case still spends the pending reward server-side, so a claim that
  /// can't be filled doesn't stay stuck offering one forever. Throws on
  /// a genuine failure (signed out, network) — unlike [addXp], a claim is
  /// a direct user action with its own "you got X" UI, so silently
  /// swallowing a failure here would show nothing where the learner
  /// expects a reward.
  Future<XpReward?> claimLevelReward(String uid) async {
    final result = await _functions.httpsCallable('claimXpReward').call();
    final data = result.data;
    if (data is! Map || data['reward'] == null) return null;

    final reward = data['reward'] as Map;
    final kindName = reward['kind'] as String;
    final id = reward['id'] as String;
    final kind = XpRewardKind.values.byName(kindName);
    final label = switch (kind) {
      XpRewardKind.avatar => AvatarPresets.byId(id)?.emoji ?? '',
      XpRewardKind.frame => FramePresets.byId(id)?.label ?? '',
      XpRewardKind.cover => CoverPresets.byId(id)?.label ?? '',
    };
    return XpReward(kind: kind, id: id, label: label);
  }

  Future<Set<String>> getUnlockedAvatarIds(String uid) =>
      _getXpIdSet(uid, 'unlockedAvatarIds');
  Future<Set<String>> getUnlockedFrameIds(String uid) =>
      _getXpIdSet(uid, 'unlockedFrameIds');
  Future<Set<String>> getUnlockedCoverIds(String uid) =>
      _getXpIdSet(uid, 'unlockedCoverIds');

  Future<Set<String>> _getXpIdSet(String uid, String field) async {
    final snapshot = await _userDoc(uid).get();
    final xpMap = snapshot.data()?['xp'] as Map<String, dynamic>?;
    return _stringList(xpMap?[field]).toSet();
  }

  List<String> _stringList(dynamic value) =>
      (value as List<dynamic>?)?.cast<String>() ?? const [];
}
