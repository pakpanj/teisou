import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile.dart' show AvatarType, AvatarTypeX;

/// One entry in `users/{uid}/friends/{friendUid}` — a denormalized snapshot
/// of the *other* person's identity, mirroring `ClanMember`'s reasoning
/// exactly: a friend list has to render even without a live
/// `leaderboard/{friendUid}` fetch, and it's written once on both sides the
/// moment a friend request is accepted (`FriendRepository.
/// respondToRequest`), not kept live-synced afterward — same
/// accepted-staleness trade-off `ClanMember` already documents, resynced
/// only via `FriendRepository.syncFriendInfo` wherever a user changes their
/// name/avatar (mirrors `ClanRepository.syncMemberInfo`).
class Friend {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final AvatarType avatarType;
  final String? avatarValue;
  final DateTime addedAt;

  Friend({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.avatarType = AvatarType.google,
    this.avatarValue,
    required this.addedAt,
  });

  factory Friend.fromMap(String uid, Map<String, dynamic> map) {
    return Friend(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Pelajar Kana',
      photoUrl: map['photoUrl'] as String?,
      avatarType: AvatarTypeX.fromKey(map['avatarType'] as String?),
      avatarValue: map['avatarValue'] as String?,
      addedAt: _toDateTime(map['addedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'avatarType': avatarType.key,
        'avatarValue': avatarValue,
        'addedAt': FieldValue.serverTimestamp(),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
