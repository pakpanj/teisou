import 'package:cloud_firestore/cloud_firestore.dart';

enum ClanInviteStatus { pending, accepted, declined }

extension ClanInviteStatusX on ClanInviteStatus {
  String get key {
    switch (this) {
      case ClanInviteStatus.pending:
        return 'pending';
      case ClanInviteStatus.accepted:
        return 'accepted';
      case ClanInviteStatus.declined:
        return 'declined';
    }
  }

  static ClanInviteStatus fromKey(String? key) {
    switch (key) {
      case 'accepted':
        return ClanInviteStatus.accepted;
      case 'declined':
        return ClanInviteStatus.declined;
      default:
        return ClanInviteStatus.pending;
    }
  }
}

/// A pending clan invitation at `users/{targetUid}/clanInvites/{id}` —
/// mirrors `ClanMembership`'s "read from your own subcollection, not a
/// cross-user query" shape. Written by a clan's leader/co-leader after
/// finding a learner via `LeaderboardRepository.searchPublicUsers`;
/// resolved by the invited learner via `ClanRepository.respondToInvite`.
class ClanInvite {
  final String id;
  final String code;
  final String clanName;
  final String invitedByUid;
  final String invitedByName;
  final ClanInviteStatus status;
  final DateTime createdAt;

  ClanInvite({
    required this.id,
    required this.code,
    required this.clanName,
    required this.invitedByUid,
    required this.invitedByName,
    this.status = ClanInviteStatus.pending,
    required this.createdAt,
  });

  factory ClanInvite.fromMap(String id, Map<String, dynamic> map) {
    return ClanInvite(
      id: id,
      code: map['code'] as String? ?? '',
      clanName: map['clanName'] as String? ?? 'Clan',
      invitedByUid: map['invitedByUid'] as String? ?? '',
      invitedByName: map['invitedByName'] as String? ?? 'Host',
      status: ClanInviteStatusX.fromKey(map['status'] as String?),
      createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'clanName': clanName,
        'invitedByUid': invitedByUid,
        'invitedByName': invitedByName,
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
