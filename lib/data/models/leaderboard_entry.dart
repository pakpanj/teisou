import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final int totalMastered;
  final int examHighScore;
  final DateTime updatedAt;

  LeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.totalMastered,
    required this.examHighScore,
    required this.updatedAt,
  });

  factory LeaderboardEntry.fromMap(String uid, Map<String, dynamic> map) {
    return LeaderboardEntry(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Pelajar Kana',
      photoUrl: map['photoUrl'] as String?,
      totalMastered: (map['totalMastered'] as num?)?.toInt() ?? 0,
      examHighScore: (map['examHighScore'] as num?)?.toInt() ?? 0,
      updatedAt: _toDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'totalMastered': totalMastered,
        'examHighScore': examHighScore,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
