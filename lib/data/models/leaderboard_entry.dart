import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_profile.dart' show AvatarType, AvatarTypeX;

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final AvatarType avatarType;
  final String? avatarValue;
  final int totalMastered;
  final int examHighScore;
  final DateTime updatedAt;

  LeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.avatarType = AvatarType.google,
    this.avatarValue,
    required this.totalMastered,
    required this.examHighScore,
    required this.updatedAt,
  });

  factory LeaderboardEntry.fromMap(String uid, Map<String, dynamic> map) {
    return LeaderboardEntry(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Pelajar Kana',
      photoUrl: map['photoUrl'] as String?,
      avatarType: AvatarTypeX.fromKey(map['avatarType'] as String?),
      avatarValue: map['avatarValue'] as String?,
      totalMastered: (map['totalMastered'] as num?)?.toInt() ?? 0,
      examHighScore: (map['examHighScore'] as num?)?.toInt() ?? 0,
      updatedAt: _toDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
        'avatarType': avatarType.key,
        'avatarValue': avatarValue,
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
