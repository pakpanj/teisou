import 'package:cloud_firestore/cloud_firestore.dart';

/// One "sudah dipelajari" mark for a single kanji.
class KanjiProgressEntry {
  final String kanjiId;
  final String jlptLevel;
  final DateTime learnedAt;

  KanjiProgressEntry({
    required this.kanjiId,
    required this.jlptLevel,
    required this.learnedAt,
  });

  factory KanjiProgressEntry.fromJson(Map<String, dynamic> json) => KanjiProgressEntry(
        kanjiId: json['kanjiId'] as String,
        jlptLevel: json['jlptLevel'] as String? ?? '',
        learnedAt: DateTime.tryParse(json['learnedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'kanjiId': kanjiId,
        'jlptLevel': jlptLevel,
        'learnedAt': learnedAt.toIso8601String(),
      };

  factory KanjiProgressEntry.fromFirestore(Map<String, dynamic> map) => KanjiProgressEntry(
        kanjiId: map['kanjiId'] as String,
        jlptLevel: map['jlptLevel'] as String? ?? '',
        learnedAt: _toDateTime(map['learnedAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toFirestoreMap() => {
        'kanjiId': kanjiId,
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
