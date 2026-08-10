import 'package:cloud_firestore/cloud_firestore.dart';

/// A clan/host document at `clans/{code}` — [code] is both the Firestore
/// document id and the short join code shared with members, so joining
/// never needs a query (`clans.doc(code).get()`).
class Clan {
  final String code;
  final String name;
  final String hostUid;
  final String hostDisplayName;
  final int memberCount;

  /// Sum of every member's `LeaderboardEntry.computedGlobalScore` — the
  /// sort key for the Top Clan ranking (`topClansProvider`). Recomputed as
  /// a side effect of `clanRankingProvider` (the same "self-heal on read"
  /// shape already used for `LeaderboardEntry.globalScore`), not kept live
  /// on every exam: that would mean fanning out a write to every clan a
  /// user belongs to on every single exam completion, which is a much
  /// bigger cost for a number nobody needs millisecond-fresh. It's only as
  /// current as the last time someone opened that clan's own ranking tab.
  final double totalScore;

  final DateTime createdAt;

  Clan({
    required this.code,
    required this.name,
    required this.hostUid,
    required this.hostDisplayName,
    required this.memberCount,
    this.totalScore = 0,
    required this.createdAt,
  });

  factory Clan.fromMap(String code, Map<String, dynamic> map) {
    return Clan(
      code: code,
      name: map['name'] as String? ?? 'Clan',
      hostUid: map['hostUid'] as String? ?? '',
      hostDisplayName: map['hostDisplayName'] as String? ?? 'Host',
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
      totalScore: (map['totalScore'] as num?)?.toDouble() ?? 0,
      createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'hostUid': hostUid,
        'hostDisplayName': hostDisplayName,
        'memberCount': memberCount,
        'totalScore': totalScore,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
