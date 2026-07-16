import 'package:cloud_firestore/cloud_firestore.dart';

/// One "sudah dipelajari" mark for a single grammar pattern.
class BunpouProgressEntry {
  final String bunpouId;
  final String jlptLevel;
  final DateTime learnedAt;

  BunpouProgressEntry({
    required this.bunpouId,
    required this.jlptLevel,
    required this.learnedAt,
  });

  factory BunpouProgressEntry.fromJson(Map<String, dynamic> json) => BunpouProgressEntry(
        bunpouId: json['bunpouId'] as String,
        jlptLevel: json['jlptLevel'] as String? ?? '',
        learnedAt: DateTime.tryParse(json['learnedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'bunpouId': bunpouId,
        'jlptLevel': jlptLevel,
        'learnedAt': learnedAt.toIso8601String(),
      };

  factory BunpouProgressEntry.fromFirestore(Map<String, dynamic> map) => BunpouProgressEntry(
        bunpouId: map['bunpouId'] as String,
        jlptLevel: map['jlptLevel'] as String? ?? '',
        learnedAt: _toDateTime(map['learnedAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toFirestoreMap() => {
        'bunpouId': bunpouId,
        'jlptLevel': jlptLevel,
        'learnedAt': Timestamp.fromDate(learnedAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
