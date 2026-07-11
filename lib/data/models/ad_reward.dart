import 'package:cloud_firestore/cloud_firestore.dart';

/// Tracks a temporary preview unlock granted by watching a rewarded ad
/// (e.g. `adRewards.kanji_preview`), valid for 24 hours from [unlockedAt].
class AdReward {
  final String moduleId;
  final DateTime unlockedAt;
  final DateTime expiresAt;

  AdReward({
    required this.moduleId,
    required this.unlockedAt,
    required this.expiresAt,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  factory AdReward.unlockNow(String moduleId, {Duration duration = const Duration(hours: 24)}) {
    final now = DateTime.now();
    return AdReward(
      moduleId: moduleId,
      unlockedAt: now,
      expiresAt: now.add(duration),
    );
  }

  factory AdReward.fromMap(String moduleId, Map<String, dynamic> map) {
    return AdReward(
      moduleId: moduleId,
      unlockedAt: _toDateTime(map['unlockedAt']) ?? DateTime.now(),
      expiresAt: _toDateTime(map['expiresAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'unlockedAt': Timestamp.fromDate(unlockedAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
