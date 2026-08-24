import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/battle_invite.dart';

/// Manages `users/{targetUid}/battleInvites/{id}` — Card Game Mode's
/// friend/clan "Tantang" challenge, see `NOTES_CARD_GAME_MODE.md`'s
/// "Cara mengundang teman/clan bertanding". Mirrors
/// `ClanRepository`/`FriendRepository`'s invite/request handling almost
/// exactly; the one real difference is that the match this invite points
/// at is already created by the time [sendInvite] is called (see
/// `BattleInvite.matchId`'s own doc comment), so this repository never
/// touches `battleMatches` itself.
class BattleInviteRepository {
  final FirebaseFirestore _firestore;

  BattleInviteRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _invitesOf(String uid) => _firestore
      .collection(FirestorePaths.users)
      .doc(uid)
      .collection(FirestorePaths.battleInvites);

  /// Writes the invite under [targetUid]'s own subcollection. The match
  /// [invite.matchId] points at must already exist with both
  /// [invite.fromUid] and [targetUid] in its `players` — enforced by
  /// `firestore.rules`, not re-checked here (this call fails outright
  /// on a rules rejection, same as every other write in this app).
  Future<void> sendInvite({
    required String targetUid,
    required BattleInvite invite,
  }) {
    return _invitesOf(targetUid).add(invite.toMap());
  }

  /// Live, scoped to `status == pending` server-side, expired ones
  /// filtered out client-side (self-heal-on-read, per
  /// `BattleInvite.expiresAt`'s own doc comment) — same "no server-side
  /// `orderBy`, sort client-side" shape as
  /// `ClanRepository.watchMyInvites`/`FriendRepository.watchMyRequests`,
  /// for the identical composite-index reason documented there.
  Stream<List<BattleInvite>> watchMyInvites(String uid) {
    return _invitesOf(uid)
        .where('status', isEqualTo: BattleInviteStatus.pending.key)
        .snapshots()
        .map((snapshot) {
          final invites = snapshot.docs
              .map((doc) => BattleInvite.fromMap(doc.id, doc.data()))
              .where((invite) => !invite.isExpired)
              .toList();
          invites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return invites;
        });
  }

  /// Marks [invite] accepted/declined. Deliberately does **not** create
  /// or join the match itself — [invite.matchId] already points at a
  /// live match; the caller (UI layer) navigates into
  /// `BattleScreen(matchId: invite.matchId)` directly on accept. This
  /// mirrors [respondToInvite]'s name but not its shape: unlike
  /// `ClanRepository.respondToInvite`, there is no side effect to
  /// perform here beyond the status write itself.
  Future<void> respondToInvite({
    required String uid,
    required BattleInvite invite,
    required bool accept,
  }) {
    return _invitesOf(uid).doc(invite.id).set({
      'status':
          (accept ? BattleInviteStatus.accepted : BattleInviteStatus.declined)
              .key,
    }, SetOptions(merge: true));
  }

  /// The other direction from [respondToInvite]: the **sender** retracting
  /// their own still-pending invite(s) for [matchId] under [targetUid] —
  /// called when the challenger cancels, backs out, or the countdown in
  /// `BattleInviteWaitingScreen` runs out. `respondToMatchInvite` alone
  /// (see `BattleRepository`) only ever updates the `battleMatches` doc,
  /// never this one, so without this the target's own pending-invite row
  /// stayed stuck showing "menantangmu" long after the challenger had
  /// already left — nobody ever wrote `status: declined` here.
  ///
  /// Queried by [matchId] rather than by the invite's own id: [sendInvite]
  /// never hands that id back to the caller, and a match-scoped query
  /// self-heals the same "find whatever's actually pending" way this
  /// app's other invite lists already do, rather than threading one more
  /// id through `sendBattleChallenge` -> `BattleInviteWaitingScreen`.
  /// Filters `status == pending` client-side, not in the query, to avoid
  /// a composite index the same way `watchMyInvites` already does.
  Future<void> declineInvitesForMatch({
    required String targetUid,
    required String matchId,
  }) async {
    final snapshot = await _invitesOf(
      targetUid,
    ).where('matchId', isEqualTo: matchId).get();
    final pending = snapshot.docs.where(
      (doc) =>
          (doc.data()['status'] as String?) == BattleInviteStatus.pending.key,
    );
    if (pending.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in pending) {
      batch.update(doc.reference, {'status': BattleInviteStatus.declined.key});
    }
    await batch.commit();
  }
}
