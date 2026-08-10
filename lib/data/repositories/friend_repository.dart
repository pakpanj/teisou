import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/firebase/firestore_paths.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../models/user_profile.dart' show AvatarType, AvatarTypeX;

/// Manages mutual friend relationships and the friend-request handshake
/// that creates them — the "personal friend" counterpart to
/// `ClanRepository`'s clan membership, found the same deliberate way: by
/// searching someone's exact short unique id or name
/// (`LeaderboardRepository.searchPublicUsers`), not by browsing a public
/// directory. Requiring the target to actively accept a request — rather
/// than opening a chat the moment two names cross paths in search — is
/// what keeps this different from the open "message any stranger" feature
/// this project already declined once (see `ClanMessageRepository`'s doc
/// comment). See `DirectMessageRepository` for the chat this unlocks.
class FriendRepository {
  final FirebaseFirestore _firestore;

  FriendRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _friendsOf(String uid) =>
      _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.friends);

  CollectionReference<Map<String, dynamic>> _requestsOf(String uid) =>
      _firestore
          .collection(FirestorePaths.users)
          .doc(uid)
          .collection(FirestorePaths.friendRequests);

  /// Sends a friend request to [targetUid]. Refuses a target who's already
  /// a friend — a client-side head start read from [fromUid]'s **own**
  /// `friends` collection, which `firestore.rules`' `users/{uid}/
  /// {document=**}` wildcard already lets its owner read.
  ///
  /// **Deliberately does not also check for an already-pending request**,
  /// unlike an earlier version of this method — that check queried
  /// `targetUid`'s `friendRequests` collection filtered by `fromUid`, and
  /// `firestore.rules` only grants read access to a `friendRequests`
  /// collection to its own owner (by design: pending requests are private
  /// until answered, the same as `clanInvites`). That query was rejected
  /// with `PERMISSION_DENIED` on every single call — not an occasional
  /// edge case, an unconditional failure — which silently broke sending
  /// *any* friend request at all, confirmed via on-device logcat. Removed
  /// rather than special-cased with a new rule: `ClanRepository.sendInvite`
  /// never had an equivalent "already invited" check either, so a
  /// duplicate pending request is an accepted, pre-existing trade-off in
  /// this codebase, not a gap unique to this method.
  Future<void> sendFriendRequest({
    required String fromUid,
    required String fromName,
    String? fromPhotoUrl,
    AvatarType fromAvatarType = AvatarType.google,
    String? fromAvatarValue,
    required String targetUid,
  }) async {
    if (fromUid == targetUid) {
      throw StateError('Tidak bisa menambah diri sendiri sebagai teman.');
    }
    final alreadyFriend = await _friendsOf(fromUid).doc(targetUid).get();
    if (alreadyFriend.exists) {
      throw StateError('already_friend');
    }

    final request = FriendRequest(
      id: '',
      fromUid: fromUid,
      fromName: fromName,
      fromPhotoUrl: fromPhotoUrl,
      fromAvatarType: fromAvatarType,
      fromAvatarValue: fromAvatarValue,
      createdAt: DateTime.now(),
    );
    await _requestsOf(targetUid).add(request.toMap());
  }

  /// Live, scoped to `status == pending` server-side. **Deliberately no
  /// server-side `orderBy`** — combining a `where` on one field with an
  /// `orderBy` on a different one needs a Firestore composite index, and
  /// this collection had none: confirmed on-device via
  /// `FAILED_PRECONDITION: The query requires an index`, which meant this
  /// stream never emitted anything at all and every incoming friend
  /// request was invisible to its recipient (read as "confirmation is
  /// broken", not "the query crashed"). Sorted here instead, client-side —
  /// safe for what's always one person's own short pending-request list,
  /// and it sidesteps needing an index deploy this environment has no way
  /// to perform on the user's behalf anyway.
  Stream<List<FriendRequest>> watchMyRequests(String uid) {
    return _requestsOf(uid)
        .where('status', isEqualTo: FriendRequestStatus.pending.key)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => FriendRequest.fromMap(doc.id, doc.data()))
              .toList();
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  /// Accepting writes both sides of the friendship in one batch — a friend
  /// list has to be mutual and instant on both accounts, not just the
  /// accepter's. [myName]/[myPhotoUrl]/[myAvatarType]/[myAvatarValue] are
  /// what the *other* person's row will show for the accepter, mirroring
  /// exactly how `ClanMember` is denormalized at join time.
  Future<void> respondToRequest({
    required String uid,
    required FriendRequest request,
    required bool accept,
    required String myName,
    String? myPhotoUrl,
    AvatarType myAvatarType = AvatarType.google,
    String? myAvatarValue,
  }) async {
    if (accept) {
      final now = DateTime.now();
      final batch = _firestore.batch();
      batch.set(
        _friendsOf(uid).doc(request.fromUid),
        Friend(
          uid: request.fromUid,
          displayName: request.fromName,
          photoUrl: request.fromPhotoUrl,
          avatarType: request.fromAvatarType,
          avatarValue: request.fromAvatarValue,
          addedAt: now,
        ).toMap(),
      );
      batch.set(
        _friendsOf(request.fromUid).doc(uid),
        Friend(
          uid: uid,
          displayName: myName,
          photoUrl: myPhotoUrl,
          avatarType: myAvatarType,
          avatarValue: myAvatarValue,
          addedAt: now,
        ).toMap(),
      );
      await batch.commit();
    }
    await _requestsOf(uid).doc(request.id).set({
      'status':
          (accept ? FriendRequestStatus.accepted : FriendRequestStatus.declined)
              .key,
    }, SetOptions(merge: true));
  }

  /// Live — one user's own friend list, small enough to keep streaming so
  /// it updates instantly the moment a request is accepted.
  Stream<List<Friend>> watchFriends(String uid) {
    return _friendsOf(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Friend.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Removes the friendship on both sides at once. `DirectMessageRepository`
  /// gates its chat on live friendship (re-checked on every read/write, not
  /// just at conversation-creation time), so this is also the real "block"
  /// for this feature: once unfriended, neither side can read or write the
  /// old conversation anymore — not just hide it client-side the way clan
  /// chat's block does.
  Future<void> removeFriend({
    required String uid,
    required String friendUid,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_friendsOf(uid).doc(friendUid));
    batch.delete(_friendsOf(friendUid).doc(uid));
    await batch.commit();
  }

  /// Refreshes [uid]'s identity fields (name/avatar) across every friend's
  /// own copy of their row — mirrors `ClanRepository.syncMemberInfo`
  /// exactly, same reasoning: a [Friend] row is denormalized once at
  /// acceptance time and never resynced on its own.
  Future<void> syncFriendInfo({
    required String uid,
    required String displayName,
    String? photoUrl,
    required AvatarType avatarType,
    String? avatarValue,
  }) async {
    final friends = await _friendsOf(uid).get();
    if (friends.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final friend in friends.docs) {
      batch.set(
        _friendsOf(friend.id).doc(uid),
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
}
