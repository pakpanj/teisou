import 'package:cloud_firestore/cloud_firestore.dart';

import 'kana_status.dart';

class KanaProgress {
  final String kanaId;
  final KanaStatus status;
  final int correctStreak;
  final DateTime? viewedAt;
  final DateTime? lastReviewedAt;

  KanaProgress({
    required this.kanaId,
    required this.status,
    required this.correctStreak,
    this.viewedAt,
    this.lastReviewedAt,
  });

  factory KanaProgress.initial(String kanaId) => KanaProgress(
        kanaId: kanaId,
        status: KanaStatus.newKana,
        correctStreak: 0,
      );

  factory KanaProgress.fromMap(String kanaId, Map<String, dynamic> map) {
    return KanaProgress(
      kanaId: kanaId,
      status: KanaStatusX.fromKey(map['status'] as String?),
      correctStreak: (map['correctStreak'] as num?)?.toInt() ?? 0,
      viewedAt: _toDateTime(map['viewedAt']),
      lastReviewedAt: _toDateTime(map['lastReviewedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.key,
        'correctStreak': correctStreak,
        if (viewedAt != null) 'viewedAt': Timestamp.fromDate(viewedAt!),
        if (lastReviewedAt != null)
          'lastReviewedAt': Timestamp.fromDate(lastReviewedAt!),
      };

  KanaProgress copyWith({
    KanaStatus? status,
    int? correctStreak,
    DateTime? viewedAt,
    DateTime? lastReviewedAt,
  }) {
    return KanaProgress(
      kanaId: kanaId,
      status: status ?? this.status,
      correctStreak: correctStreak ?? this.correctStreak,
      viewedAt: viewedAt ?? this.viewedAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
