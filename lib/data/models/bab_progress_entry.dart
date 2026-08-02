import 'package:cloud_firestore/cloud_firestore.dart';

/// One "Bab selesai" mark for a single chapter.
class BabProgressEntry {
  final String babId;
  final String jlptLevel;
  final DateTime completedAt;

  BabProgressEntry({
    required this.babId,
    required this.jlptLevel,
    required this.completedAt,
  });

  factory BabProgressEntry.fromJson(Map<String, dynamic> json) => BabProgressEntry(
        babId: json['babId'] as String,
        jlptLevel: json['jlptLevel'] as String? ?? '',
        completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'babId': babId,
        'jlptLevel': jlptLevel,
        'completedAt': completedAt.toIso8601String(),
      };

  factory BabProgressEntry.fromFirestore(Map<String, dynamic> map) => BabProgressEntry(
        babId: map['babId'] as String,
        jlptLevel: map['jlptLevel'] as String? ?? '',
        completedAt: _toDateTime(map['completedAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toFirestoreMap() => {
        'babId': babId,
        'jlptLevel': jlptLevel,
        'completedAt': Timestamp.fromDate(completedAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
