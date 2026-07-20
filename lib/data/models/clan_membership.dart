import 'package:cloud_firestore/cloud_firestore.dart';

/// A reverse-index entry at `users/{uid}/clanMemberships/{code}` — lets
/// "which clans am I in" be read directly from the user's own
/// subcollection instead of a Firestore collection-group query across
/// every clan's `members` subcollection (which would need extra index
/// setup this session can't verify against a live console).
class ClanMembership {
  final String code;
  final String name;
  final DateTime joinedAt;

  ClanMembership({
    required this.code,
    required this.name,
    required this.joinedAt,
  });

  factory ClanMembership.fromMap(String code, Map<String, dynamic> map) {
    return ClanMembership(
      code: code,
      name: map['name'] as String? ?? 'Clan',
      joinedAt: _toDateTime(map['joinedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
