/// One completed attempt at a Dokkai passage, Choukai clip, or
/// Kanji-Kombinasi round. Shared across all three new Ujian exam types
/// (unlike the kana `ExamResult`, which carries kana-specific
/// wrongAnswers/progress fields) since their result shape is genuinely
/// identical — see `ExamHistoryRepository` for why this buys one shared
/// class instead of three copy-pasted ones.
class SimpleExamResult {
  final String itemId;
  final String jlptLevel;
  final int score;
  final int total;
  final DateTime completedAt;

  SimpleExamResult({
    required this.itemId,
    required this.jlptLevel,
    required this.score,
    required this.total,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'jlptLevel': jlptLevel,
        'score': score,
        'total': total,
        'completedAt': completedAt.toIso8601String(),
      };

  factory SimpleExamResult.fromMap(Map<String, dynamic> map) =>
      SimpleExamResult(
        itemId: map['itemId'] as String? ?? '',
        jlptLevel: map['jlptLevel'] as String? ?? 'N5',
        score: (map['score'] as num?)?.toInt() ?? 0,
        total: (map['total'] as num?)?.toInt() ?? 0,
        completedAt:
            DateTime.tryParse(map['completedAt'] as String? ?? '') ??
                DateTime.now(),
      );
}
