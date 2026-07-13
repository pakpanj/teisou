import 'package:cloud_firestore/cloud_firestore.dart';

class SavedWord {
  final String id;
  final String text;
  final String romaji;
  final String meaning;
  final String? exampleSentence;
  final String source;
  final DateTime createdAt;

  SavedWord({
    required this.id,
    required this.text,
    required this.romaji,
    required this.meaning,
    this.exampleSentence,
    required this.source,
    required this.createdAt,
  });

  factory SavedWord.fromJson(Map<String, dynamic> json) => SavedWord(
        id: json['id'] as String,
        text: json['text'] as String,
        romaji: json['romaji'] as String? ?? '',
        meaning: json['meaning'] as String? ?? '',
        exampleSentence: json['exampleSentence'] as String?,
        source: json['source'] as String? ?? 'cam_detector',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'romaji': romaji,
        'meaning': meaning,
        'exampleSentence': exampleSentence,
        'source': source,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedWord.fromFirestore(Map<String, dynamic> map) => SavedWord(
        id: map['id'] as String,
        text: map['text'] as String,
        romaji: map['romaji'] as String? ?? '',
        meaning: map['meaning'] as String? ?? '',
        exampleSentence: map['exampleSentence'] as String?,
        source: map['source'] as String? ?? 'cam_detector',
        createdAt: _toDateTime(map['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toFirestoreMap() => {
        'id': id,
        'text': text,
        'romaji': romaji,
        'meaning': meaning,
        'exampleSentence': exampleSentence,
        'source': source,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
