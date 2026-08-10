import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile.dart' show AvatarType, AvatarTypeX;

enum FriendRequestStatus { pending, accepted, declined }

extension FriendRequestStatusX on FriendRequestStatus {
  String get key {
    switch (this) {
      case FriendRequestStatus.pending:
        return 'pending';
      case FriendRequestStatus.accepted:
        return 'accepted';
      case FriendRequestStatus.declined:
        return 'declined';
    }
  }

  static FriendRequestStatus fromKey(String? key) {
    switch (key) {
      case 'accepted':
        return FriendRequestStatus.accepted;
      case 'declined':
        return FriendRequestStatus.declined;
      default:
        return FriendRequestStatus.pending;
    }
  }
}

/// A pending friend request at `users/{targetUid}/friendRequests/{id}` —
/// mirrors `ClanInvite`'s shape exactly. Written by
/// `FriendRepository.sendFriendRequest` after finding someone via
/// `LeaderboardRepository.searchPublicUsers` (by exact unique id, or a name
/// prefix); resolved by the invited learner via
/// `FriendRepository.respondToRequest`.
class FriendRequest {
  final String id;
  final String fromUid;
  final String fromName;
  final String? fromPhotoUrl;
  final AvatarType fromAvatarType;
  final String? fromAvatarValue;
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromName,
    this.fromPhotoUrl,
    this.fromAvatarType = AvatarType.google,
    this.fromAvatarValue,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
  });

  factory FriendRequest.fromMap(String id, Map<String, dynamic> map) {
    return FriendRequest(
      id: id,
      fromUid: map['fromUid'] as String? ?? '',
      fromName: map['fromName'] as String? ?? 'Pelajar Kana',
      fromPhotoUrl: map['fromPhotoUrl'] as String?,
      fromAvatarType: AvatarTypeX.fromKey(map['fromAvatarType'] as String?),
      fromAvatarValue: map['fromAvatarValue'] as String?,
      status: FriendRequestStatusX.fromKey(map['status'] as String?),
      createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'fromUid': fromUid,
        'fromName': fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'fromAvatarType': fromAvatarType.key,
        'fromAvatarValue': fromAvatarValue,
        'status': status.key,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
