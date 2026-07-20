import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile.dart' show AvatarType, AvatarTypeX;

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
  final DateTime joinedAt;

  ClanMember({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.avatarType = AvatarType.google,
    this.avatarValue,
    required this.joinedAt,
  });

  factory ClanMember.fromMap(String uid, Map<String, dynamic> map) {
    return ClanMember(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Pelajar Kana',
      photoUrl: map['photoUrl'] as String?,
      avatarType: AvatarTypeX.fromKey(map['avatarType'] as String?),
      avatarValue: map['avatarValue'] as String?,
      joinedAt: _toDateTime(map['joinedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'avatarType': avatarType.key,
        'avatarValue': avatarValue,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
