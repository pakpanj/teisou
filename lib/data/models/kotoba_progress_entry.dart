import 'package:cloud_firestore/cloud_firestore.dart';

/// One "sudah dipelajari" mark for a single Kotoba word.
class KotobaProgressEntry {
  final String wordId;
  final String categoryId;
  final DateTime learnedAt;

  KotobaProgressEntry({
    required this.wordId,
    required this.categoryId,
    required this.learnedAt,
  });

  factory KotobaProgressEntry.fromJson(Map<String, dynamic> json) => KotobaProgressEntry(
        wordId: json['wordId'] as String,
        categoryId: json['categoryId'] as String? ?? '',
        learnedAt: DateTime.tryParse(json['learnedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'wordId': wordId,
        'categoryId': categoryId,
        'learnedAt': learnedAt.toIso8601String(),
      };

  factory KotobaProgressEntry.fromFirestore(Map<String, dynamic> map) => KotobaProgressEntry(
        wordId: map['wordId'] as String,
        categoryId: map['categoryId'] as String? ?? '',
        learnedAt: _toDateTime(map['learnedAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toFirestoreMap() => {
        'wordId': wordId,
        'categoryId': categoryId,
        'learnedAt': Timestamp.fromDate(learnedAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
