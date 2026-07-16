import 'package:cloud_firestore/cloud_firestore.dart';

/// One "sudah dipelajari" mark for a single particle.
class ParticleProgressEntry {
  final String particleId;
  final String category;
  final DateTime learnedAt;

  ParticleProgressEntry({
    required this.particleId,
    required this.category,
    required this.learnedAt,
  });

  factory ParticleProgressEntry.fromJson(Map<String, dynamic> json) =>
      ParticleProgressEntry(
        particleId: json['particleId'] as String,
        category: json['category'] as String? ?? '',
        learnedAt:
            DateTime.tryParse(json['learnedAt'] as String? ?? '') ??
                DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'particleId': particleId,
        'category': category,
        'learnedAt': learnedAt.toIso8601String(),
      };

  factory ParticleProgressEntry.fromFirestore(Map<String, dynamic> map) =>
      ParticleProgressEntry(
        particleId: map['particleId'] as String,
        category: map['category'] as String? ?? '',
        learnedAt: _toDateTime(map['learnedAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toFirestoreMap() => {
        'particleId': particleId,
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
