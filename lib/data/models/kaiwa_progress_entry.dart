import 'package:cloud_firestore/cloud_firestore.dart';

/// One "sudah dipelajari" mark for a single Kaiwa dialogue.
class KaiwaProgressEntry {
  final String kaiwaId;
  final String category;
  final DateTime learnedAt;

  KaiwaProgressEntry({
    required this.kaiwaId,
    required this.category,
    required this.learnedAt,
  });

  factory KaiwaProgressEntry.fromJson(Map<String, dynamic> json) =>
      KaiwaProgressEntry(
        kaiwaId: json['kaiwaId'] as String,
        category: json['category'] as String? ?? '',
        learnedAt:
            DateTime.tryParse(json['learnedAt'] as String? ?? '') ??
                DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'kaiwaId': kaiwaId,
        'category': category,
        'learnedAt': learnedAt.toIso8601String(),
      };

  factory KaiwaProgressEntry.fromFirestore(Map<String, dynamic> map) =>
      KaiwaProgressEntry(
        kaiwaId: map['kaiwaId'] as String,
        category: map['category'] as String? ?? '',
        learnedAt: _toDateTime(map['learnedAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toFirestoreMap() => {
        'kaiwaId': kaiwaId,
        'category': category,
        'learnedAt': Timestamp.fromDate(learnedAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
