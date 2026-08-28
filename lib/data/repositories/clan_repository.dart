import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/clan.dart';
import '../models/clan_invite.dart';
import '../models/clan_member.dart';
import '../models/clan_membership.dart';
import '../models/user_profile.dart' show AvatarType, AvatarTypeX;

/// Manages clan/host creation, joining, leaving, and membership lookups.
/// Every write mirrors the read-then-write / batch style already
/// established by `LeaderboardRepository`/`ExamRepository`, except
/// `memberCount` which uses `FieldValue.increment` since it's a bare
/// counter (no averaging needed, unlike the Rekor feature's percentage
/// fields) — the right tool for that specific case, not an inconsistency.
class ClanRepository {
  static const _codeLength = 6;
  static const _codeAlphabet =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I — avoids read-aloud/write mixups
  static const _maxCodeAttempts = 5;

  final FirebaseFirestore _firestore;
  final Random _random;

  ClanRepository({FirebaseFirestore? firestore, Random? random})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _random = random ?? Random();

  CollectionReference<Map<String, dynamic>> get _clans =>
      _firestore.collection(FirestorePaths.clans);

  /// `clanFreeSlotUsed/{uid}` — the permanent, create-only marker proving
  /// an account has already spent its one free clan. Lives at the top
  /// level (not under `users/{uid}`) specifically so it falls outside the
  /// owner's own `users/{uid}/{document=**}` write wildcard: if it lived
  /// under the user's own doc, the same account that created it could also
  /// delete it and mint itself a fresh free slot. `firestore.rules` grants
  /// `create` only, never `update`/`delete`, to anyone (including the
  /// owner) — the doc's mere existence is the whole check.
  CollectionReference<Map<String, dynamic>> get _clanFreeSlotUsed =>
      _firestore.collection(FirestorePaths.clanFreeSlotUsed);

  CollectionReference<Map<String, dynamic>> _membersOf(String code) =>
      _clans.doc(code).collection(FirestorePaths.clanMembers);

  CollectionReference<Map<String, dynamic>> _membershipsOf(String uid) =>
      _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.clanMemberships);

  CollectionReference<Map<String, dynamic>> _invitesOf(String uid) =>
      _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.clanInvites);

  String _generateCode() => List.generate(
        _codeLength,
        (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
      ).join();

  /// Whether [hostUid] has already spent its one free clan creation — see
  /// [_clanFreeSlotUsed]'s own doc comment. Callers (e.g.
  /// `CreateClanDialog`) use this to decide whether to show the plain
  /// creation form or route through `PaywallScreen` first; `createClan`
  /// itself re-derives the same thing server-side via `firestore.rules`,
  /// so this client-side check is a UX head start, not the real gate.
  Future<bool> hasUsedFreeClanSlot(String hostUid) async {
    final doc = await _clanFreeSlotUsed.doc(hostUid).get();
    return doc.exists;
  }

  /// Creates a new clan, auto-joining [hostUid] as its first member. The
  /// clan's Firestore document id doubles as the join code, so retrying
  /// with a fresh random code on collision (checked via a plain `.get()`,
  /// the same non-transactional accepted trade-off used throughout this
  /// app) is the only "uniqueness" step needed — no separate lookup index.
  ///
  /// One account gets exactly one free clan. Every clan after that requires
  /// either an active premium subscription or a spent single-use rewarded
  /// ad unlock (`adRewards.clan_extra`) — enforced for real by
  /// `firestore.rules`' `canCreateClan`, not just by whatever the caller
  /// already checked via [hasUsedFreeClanSlot] and the subscription/ad-
  /// reward checks in `CreateClanDialog`, since a raw Firestore write could
  /// otherwise bypass a client-only check. The very first successful call
  /// for an account writes the permanent `clanFreeSlotUsed/{hostUid}` marker as
  /// part of the same batch; every call after that leaves it untouched
  /// (the rule only ever grants `create`, never `update`, on that doc, so
  /// re-writing it on a 2nd+ clan would fail the whole batch).
  Future<String> createClan({
    required String hostUid,
    required String name,
    required String hostDisplayName,
    String? photoUrl,
    AvatarType avatarType = AvatarType.google,
    String? avatarValue,
  }) async {
    final freeSlotUsed = await hasUsedFreeClanSlot(hostUid);

    for (var attempt = 0; attempt < _maxCodeAttempts; attempt++) {
      final code = _generateCode();
      final doc = _clans.doc(code);
      final existing = await doc.get();
      if (existing.exists) continue;

      final now = DateTime.now();
      final clan = Clan(
        code: code,
        name: name,
        hostUid: hostUid,
        hostDisplayName: hostDisplayName,
        memberCount: 1,
        createdAt: now,
      );
      final member = ClanMember(
        uid: hostUid,
        displayName: hostDisplayName,
        photoUrl: photoUrl,
        avatarType: avatarType,
        avatarValue: avatarValue,
        role: ClanRole.leader,
        joinedAt: now,
      );
      final membership =
          ClanMembership(code: code, name: name, joinedAt: now);

      final batch = _firestore.batch();
      batch.set(doc, clan.toMap());
      batch.set(_membersOf(code).doc(hostUid), member.toMap());
      batch.set(_membershipsOf(hostUid).doc(code), membership.toMap());
      if (!freeSlotUsed) {
        batch.set(_clanFreeSlotUsed.doc(hostUid), {
          'usedAt': Timestamp.fromDate(now),
        });
      }
      await batch.commit();
      return code;
    }
    throw StateError('Gagal membuat kode clan unik, coba lagi.');
  }

  Future<Clan?> findByCode(String code) async {
    final doc = await _clans.doc(code.trim().toUpperCase()).get();
    if (!doc.exists) return null;
    return Clan.fromMap(doc.id, doc.data()!);
  }

  /// No-op if [uid] is already a member — re-entering a code you've
  /// already joined shouldn't double-count `memberCount`.
  Future<void> joinClan({
    required String code,
    required String uid,
    required String displayName,
    String? photoUrl,
    AvatarType avatarType = AvatarType.google,
    String? avatarValue,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    final memberDoc = _membersOf(normalizedCode).doc(uid);
    final existingMember = await memberDoc.get();
    if (existingMember.exists) return;

    final clanDoc = await _clans.doc(normalizedCode).get();
    if (!clanDoc.exists) {
      throw StateError('Clan dengan kode tersebut tidak ditemukan.');
    }

    final now = DateTime.now();
    final clanName = clanDoc.data()?['name'] as String? ?? 'Clan';
    final member = ClanMember(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      avatarType: avatarType,
      avatarValue: avatarValue,
      joinedAt: now,
    );
    final membership =
        ClanMembership(code: normalizedCode, name: clanName, joinedAt: now);

    final batch = _firestore.batch();
    batch.set(memberDoc, member.toMap());
    batch.set(_membershipsOf(uid).doc(normalizedCode), membership.toMap());
    batch.update(_clans.doc(normalizedCode), {
      'memberCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// RISK-9 (closes RISK-8 BUG #2): used to be a plain batch — a
  /// non-transactional existence pre-check via `.get()` followed by an
  /// unconditional `FieldValue.increment(-1)` — so two concurrent calls for
  /// the same [uid] (a double-tap-then-double-confirm on the client, or any
  /// future caller that isn't as carefully guarded) each independently
  /// decremented `memberCount`, corrupting it to 2-too-low for a single
  /// leave. Now a transaction: it reads the member document as part of the
  /// transaction's own read set, and only deletes + decrements if that
  /// member still actually exists. A concurrent second transaction that
  /// raced past its own read before the first committed gets retried by
  /// Firestore's optimistic concurrency control, re-reads, finds the
  /// member already gone, and becomes a safe no-op — matching
  /// `BattleRepository.submitAnswer`'s own self-guarding-transaction shape
  /// elsewhere in this codebase.
  Future<void> leaveClan({required String code, required String uid}) async {
    final normalizedCode = code.trim().toUpperCase();
    final memberDoc = _membersOf(normalizedCode).doc(uid);
    final membershipDoc = _membershipsOf(uid).doc(normalizedCode);
    final clanDoc = _clans.doc(normalizedCode);

    await _firestore.runTransaction((transaction) async {
      final memberSnapshot = await transaction.get(memberDoc);
      if (!memberSnapshot.exists) return;
      transaction.delete(memberDoc);
      transaction.delete(membershipDoc);
      transaction.update(clanDoc, {
        'memberCount': FieldValue.increment(-1),
      });
    });
  }

  /// Disbands [code] entirely: every member removed, then the clan
  /// document itself deleted. Leader-only, and `firestore.rules` enforces
  /// that independently (`allow delete` on `clans/{code}` checks
  /// `hostUid`), so a client calling this without being the leader fails
  /// server-side rather than half-succeeding.
  ///
  /// **Firestore does not cascade**, so this walks the roster by hand.
  /// Two things about the order are load-bearing:
  ///
  /// - The **leader's own roster row goes last**, because `canKick` in
  ///   `firestore.rules` reads the *actor's* row to decide whether they
  ///   are the leader. Deleting it first would revoke the permission
  ///   needed to remove everyone else, mid-disband.
  /// - The **clan document goes last of all**, so a failure part-way
  ///   through leaves a clan that still exists and can simply be
  ///   disbanded again. The other order would leave members holding
  ///   `clanMemberships` rows pointing at a clan that is gone, which
  ///   nothing in the app can clean up afterwards.
  ///
  /// **What this deliberately does not do**: it does not delete
  /// `clanFreeSlotUsed/{hostUid}`. That marker exists so one account
  /// cannot mint unlimited free clans, and returning the slot on disband
  /// would make it exactly that — create, disband, create again. It also
  /// cannot delete the clan's chat messages or announcements:
  /// `firestore.rules` allows no delete on those at all, on purpose (so a
  /// leader cannot erase what was said), which means they survive as
  /// unreachable orphans. Nobody can read them afterwards — the rules
  /// gate reads on clan membership, and there are no members left — but
  /// they are still stored. Deleting them would mean weakening that rule
  /// for everyone, which is a worse trade than leaving data nobody can
  /// reach.
  Future<void> disbandClan({
    required String code,
    required String hostUid,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    final members = await getMembersOnce(normalizedCode);
    final others = members.where((m) => m.uid != hostUid).toList();

    // Two writes per member (roster row + their own reverse index), so
    // 250 members per batch against Firestore's 500-write ceiling.
    const perBatch = 250;
    for (var i = 0; i < others.length; i += perBatch) {
      final batch = _firestore.batch();
      for (final member in others.skip(i).take(perBatch)) {
        batch.delete(_membersOf(normalizedCode).doc(member.uid));
        // Not the other members' own membership rows — same rule, same
        // all-or-nothing batch, so including them meant disbanding a clan
        // with anyone else in it silently did nothing. They clean up
        // themselves via [reconcileMemberships].
      }
      await batch.commit();
    }

    final finalBatch = _firestore.batch();
    finalBatch.delete(_membersOf(normalizedCode).doc(hostUid));
    finalBatch.delete(_membershipsOf(hostUid).doc(normalizedCode));
    finalBatch.delete(_clans.doc(normalizedCode));
    await finalBatch.commit();
  }

  /// Live — kept small (one user's own clan list) so it can update
  /// instantly on create/join/leave without a manual refresh.
  Stream<List<ClanMembership>> watchMyClans(String uid) {
    return _membershipsOf(uid)
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClanMembership.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Drops this user's memberships whose clan or roster row is gone.
  ///
  /// The reverse index (`users/{uid}/clanMemberships`) and the roster
  /// (`clans/{code}/members/{uid}`) are two records of the same fact, and
  /// only their owner may write the first while a leader may delete the
  /// second — so being kicked, or having a clan disbanded under you,
  /// necessarily leaves the index behind. Nothing else can clean it.
  ///
  /// The cost of leaving it is not cosmetic: the chat screen subscribes
  /// from the index, while reads are authorised against the roster, so a
  /// stale entry means a clan that sits in the list and answers every
  /// read with permission-denied for ever. Observed on a real device as
  /// a steady stream of PERMISSION_DENIED for two clans.
  ///
  /// Best-effort and safe to call on every open: it only ever deletes
  /// rows whose roster row is confirmed absent.
  Future<void> reconcileMemberships(String uid) async {
    final memberships = await _membershipsOf(uid).get();
    for (final doc in memberships.docs) {
      final roster = await _membersOf(doc.id).doc(uid).get();
      if (roster.exists) continue;
      try {
        await _membershipsOf(uid).doc(doc.id).delete();
      } catch (_) {
        // Its owner is the only one who can, and this is that owner —
        // but a failure here must not stop the rest being checked.
      }
    }
  }

  /// One-shot fetch, not a live stream — a clan's roster can run into the
  /// dozens/hundreds for a whole school, and the ranking screen re-fetches
  /// on tab visit rather than holding that many realtime listeners open.
  ///
  /// Reads the clan doc first purely to pass `hostUid` into
  /// `ClanMember.fromMap`'s legacy-role fallback — a row written before the
  /// `role` field existed still resolves to `leader` correctly for the
  /// host, `member` for everyone else, instead of every pre-existing row
  /// silently defaulting to `member`.
  Future<List<ClanMember>> getMembersOnce(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    final clanDoc = await _clans.doc(normalizedCode).get();
    final hostUid = clanDoc.data()?['hostUid'] as String?;
    final snapshot = await _membersOf(normalizedCode).get();
    return snapshot.docs
        .map((doc) => ClanMember.fromMap(doc.id, doc.data(), hostUid: hostUid))
        .toList();
  }

  /// Refreshes [uid]'s identity fields (name/avatar) across every clan
  /// they're currently a member of.
  ///
  /// `ClanMember` is denormalized at join time on purpose (the ranking must
  /// render a member who has no `leaderboard/{uid}` doc at all yet), but
  /// that snapshot was never resynced afterward — a user who joined before
  /// ever setting a custom name, then set one later, kept showing their old
  /// (often Google-derived) name in any clan whose ranking fell back to this
  /// copy instead of a live `leaderboard/{uid}` entry. Call this alongside
  /// `LeaderboardRepository.syncProfileInfo` wherever a user changes their
  /// name or avatar, the same way that call already keeps the top-level
  /// leaderboard doc current.
  ///
  /// Reads the membership list first since a user can belong to more than
  /// one clan simultaneously — every membership gets the same update in one
  /// batch. Best-effort by design: the caller's own leaderboard sync is the
  /// one that matters for ranking correctness (see `clanRankingProvider`,
  /// which already prefers a live leaderboard entry over this snapshot), so
  /// a failure here must not surface as an error to a screen that already
  /// saved successfully.
  Future<void> syncMemberInfo({
    required String uid,
    required String displayName,
    String? photoUrl,
    required AvatarType avatarType,
    String? avatarValue,
  }) async {
    final memberships = await _membershipsOf(uid).get();
    if (memberships.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final membership in memberships.docs) {
      batch.set(
        _membersOf(membership.id).doc(uid),
        {
          'displayName': displayName,
          'photoUrl': photoUrl,
          'avatarType': avatarType.key,
          'avatarValue': avatarValue,
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  /// Promotes [targetUid] to co-leader or demotes them back to a plain
  /// member. Only the clan's leader may call this — enforced server-side
  /// by `firestore.rules`' `isClanLeader`, not just by the UI only showing
  /// the button to a leader, since a raw Firestore write could otherwise
  /// bypass a client-only check. The leader role itself is never granted
  /// or removed this way; it's fixed to `Clan.hostUid` for this clan's
  /// lifetime (no host-transfer feature — see the class doc comment).
  Future<void> setMemberRole({
    required String code,
    required String targetUid,
    required ClanRole role,
  }) {
    assert(role != ClanRole.leader, 'leadership is not reassignable');
    return _membersOf(code.trim().toUpperCase())
        .doc(targetUid)
        .set({'role': role.key}, SetOptions(merge: true));
  }

  /// Removes [targetUid] from [code] on someone else's behalf — a leader
  /// may kick anyone but themself, a co-leader may kick only a plain
  /// member (never the leader or another co-leader). Both rules are
  /// re-checked server-side by `firestore.rules`' `canKick`; this method
  /// does not itself decide who's allowed, only performs the removal once
  /// the write is permitted.
  ///
  /// Mirrors [leaveClan]'s batch shape exactly (roster row + the target's
  /// own reverse-index entry + the member-count decrement) since a kick is
  /// functionally "someone else initiates your leaveClan" — the target's
  /// `clanMemberships/{code}` row would otherwise survive the kick and
  /// keep showing this clan in their own "pilih clan" picker forever, with
  /// no membership left to back it.
  /// RISK-9 (closes RISK-8 BUG #1, PROVEN BY TEST): used to be a plain
  /// batch with no existence check at all and an unconditional
  /// `FieldValue.increment(-1)`, so two concurrent kicks of the same
  /// [targetUid] — a double-tap-then-double-confirm on
  /// `clan_members_screen.dart`'s confirm dialog, since fixed with a
  /// client-side `_kicking` guard, or any other caller — each
  /// independently decremented `memberCount`, corrupting it to 2-too-low
  /// for a single kick. Now a transaction, mirroring [leaveClan]'s own
  /// RISK-9 fix exactly: read the member document first, only delete +
  /// decrement if it still exists. A second concurrent transaction that
  /// raced in gets retried by Firestore once the first commits, re-reads,
  /// finds the member already gone, and becomes a safe no-op — so even a
  /// future client guard failure can't reintroduce the double-decrement.
  Future<void> kickMember({
    required String code,
    required String targetUid,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    // Only the roster row — **not** the target's own
    // `users/{targetUid}/clanMemberships` entry, which `firestore.rules`
    // lets nobody but its owner touch. Deleting it here did not merely
    // fail on its own: a Firestore batch is all-or-nothing, so the denied
    // write took the roster deletion and the memberCount down with it and
    // **kicking never worked at all**. The kicked member's stale
    // membership is cleaned up by [reconcileMemberships] the next time
    // their own app looks, which is the only place with the rights to do
    // it.
    final memberDoc = _membersOf(normalizedCode).doc(targetUid);
    final clanDoc = _clans.doc(normalizedCode);

    await _firestore.runTransaction((transaction) async {
      final memberSnapshot = await transaction.get(memberDoc);
      if (!memberSnapshot.exists) return;
      transaction.delete(memberDoc);
      transaction.update(clanDoc, {
        'memberCount': FieldValue.increment(-1),
      });
    });
  }

  /// Sends a clan invite to [targetUid], found via
  /// `LeaderboardRepository.searchPublicUsers`. Refuses a target who's
  /// already a member (no point inviting them again) — everything past
  /// that is left to `firestore.rules`' `isClanLeaderOrCoLeader` check on
  /// the actual write, which is the one that matters since this method's
  /// own guard is just a client-side head start, not the real gate.
  Future<void> sendInvite({
    required String code,
    required String clanName,
    required String targetUid,
    required String invitedByUid,
    required String invitedByName,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    final alreadyMember =
        await _membersOf(normalizedCode).doc(targetUid).get();
    if (alreadyMember.exists) {
      throw StateError('Learner ini sudah ada di dalam clan.');
    }

    final invite = ClanInvite(
      id: '',
      code: normalizedCode,
      clanName: clanName,
      invitedByUid: invitedByUid,
      invitedByName: invitedByName,
      createdAt: DateTime.now(),
    );
    await _invitesOf(targetUid).add(invite.toMap());
  }

  /// Live, and deliberately scoped to `status == pending` server-side —
  /// once a learner has answered an invite there's nothing left to act on,
  /// so there's no reason to keep streaming resolved ones down to a screen
  /// that only ever renders the pending list.
  ///
  /// **No server-side `orderBy`, on purpose** — see
  /// `FriendRepository.watchMyRequests`'s doc comment, which documents the
  /// exact same query shape hitting a real `FAILED_PRECONDITION: The query
  /// requires an index` on-device (this collection has the identical
  /// `where`-on-one-field-plus-`orderBy`-on-another shape a Firestore
  /// composite index is required for, and none exists here either). Fixed
  /// the same way before this ever shipped broken: sorted client-side
  /// instead, safe for a single learner's own short pending-invite list.
  Stream<List<ClanInvite>> watchMyInvites(String uid) {
    return _invitesOf(uid)
        .where('status', isEqualTo: ClanInviteStatus.pending.key)
        .snapshots()
        .map((snapshot) {
          final invites = snapshot.docs
              .map((doc) => ClanInvite.fromMap(doc.id, doc.data()))
              .toList();
          invites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return invites;
        });
  }

  /// Accepts or declines [invite]. Accepting reuses [joinClan] itself
  /// (same no-op-if-already-a-member guard, same batch shape) rather than
  /// duplicating its join logic — an invite is just one more way to learn
  /// a join code, not a different membership mechanism.
  Future<void> respondToInvite({
    required String uid,
    required ClanInvite invite,
    required bool accept,
    required String displayName,
    String? photoUrl,
    AvatarType avatarType = AvatarType.google,
    String? avatarValue,
  }) async {
    if (accept) {
      await joinClan(
        code: invite.code,
        uid: uid,
        displayName: displayName,
        photoUrl: photoUrl,
        avatarType: avatarType,
        avatarValue: avatarValue,
      );
    }
    await _invitesOf(uid).doc(invite.id).set({
      'status': (accept ? ClanInviteStatus.accepted : ClanInviteStatus.declined)
          .key,
    }, SetOptions(merge: true));
  }

  /// Refreshes [code]'s [Clan.totalScore] to [value] — see that field's own
  /// doc comment for why this is a self-heal-on-read update (called from
  /// `clanRankingProvider` after it already fetched every member's live
  /// score) rather than a live increment on every exam.
  Future<void> updateTotalScore(String code, double value) {
    return _clans
        .doc(code.trim().toUpperCase())
        .set({'totalScore': value}, SetOptions(merge: true));
  }

  /// Sets [code]'s [Clan.iconValue] — a `ClanIconPresets` key, never a
  /// free-form uploaded image (see [Clan.iconValue]'s own doc comment).
  /// Leader-only, enforced by `firestore.rules`' existing `clans/{code}`
  /// update rule (any field outside its `hasOnly` allowlist already
  /// requires an exact `hostUid` match) — no rules change was needed for
  /// this method or [updateClanDescription] below, unlike the new
  /// `announcements` subcollection, which did need one.
  Future<void> updateClanIcon(String code, String? iconValue) {
    return _clans
        .doc(code.trim().toUpperCase())
        .set({'iconValue': iconValue}, SetOptions(merge: true));
  }

  /// Sets [code]'s [Clan.description]. Same leader-only enforcement as
  /// [updateClanIcon] — see that method's doc comment.
  Future<void> updateClanDescription(String code, String? description) {
    final trimmed = description?.trim();
    return _clans.doc(code.trim().toUpperCase()).set({
      'description': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    }, SetOptions(merge: true));
  }

  /// Top 100 clans by [Clan.totalScore] — the cross-clan counterpart to
  /// `leaderboardTopProvider`'s top-20-individuals ranking.
  Stream<List<Clan>> watchTopClans({int limit = 100}) {
    return _clans
        .orderBy('totalScore', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Clan.fromMap(doc.id, doc.data())).toList(),
        );
  }
}
