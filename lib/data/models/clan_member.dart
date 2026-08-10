import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile.dart' show AvatarType, AvatarTypeX;

/// A member's standing within one clan. `leader` is always exactly the
/// clan's own creator (`Clan.hostUid`) — this app has no host-transfer
/// feature, a deliberate scope decision carried over from when Clan first
/// shipped, so `leader` is set once at creation and never reassigned.
/// `coLeader` is a promotable role the leader alone can grant, letting a
/// second adult help invite/remove students without handing over the clan
/// itself. Plain `member` is the default for everyone who joins by code.
enum ClanRole { leader, coLeader, member }

extension ClanRoleX on ClanRole {
  String get key {
    switch (this) {
      case ClanRole.leader:
        return 'leader';
      case ClanRole.coLeader:
        return 'coLeader';
      case ClanRole.member:
        return 'member';
    }
  }

  static ClanRole fromKey(String? key) {
    switch (key) {
      case 'leader':
        return ClanRole.leader;
      case 'coLeader':
        return ClanRole.coLeader;
      default:
        return ClanRole.member;
    }
  }
}

/// One roster entry at `clans/{code}/members/{uid}`. Identity fields are
/// denormalized at join time (same reasoning as `LeaderboardEntry`) so the
/// clan ranking can always render a member's name/avatar even before/
/// without a `leaderboard/{uid}` doc existing for them.
class ClanMember {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final AvatarType avatarType;
  final String? avatarValue;
  final ClanRole role;
  final DateTime joinedAt;

  ClanMember({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.avatarType = AvatarType.google,
    this.avatarValue,
    this.role = ClanRole.member,
    required this.joinedAt,
  });

  /// [hostUid] backstops a `role` field missing from older rows, written
  /// before this field existed — the same "treat pre-existing data as
  /// leader-by-hostUid, not a data-loss event" fallback the Firestore rules
  /// use, kept in sync deliberately rather than trusting the stored field
  /// alone (see `firestore.rules`' own `actorRole` for the server-side
  /// half of this).
  factory ClanMember.fromMap(
    String uid,
    Map<String, dynamic> map, {
    String? hostUid,
  }) {
    final storedRole = map['role'] as String?;
    final role = storedRole != null
        ? ClanRoleX.fromKey(storedRole)
        : (uid == hostUid ? ClanRole.leader : ClanRole.member);
    return ClanMember(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Pelajar Kana',
      photoUrl: map['photoUrl'] as String?,
      avatarType: AvatarTypeX.fromKey(map['avatarType'] as String?),
      avatarValue: map['avatarValue'] as String?,
      role: role,
      joinedAt: _toDateTime(map['joinedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'avatarType': avatarType.key,
        'avatarValue': avatarValue,
        'role': role.key,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
