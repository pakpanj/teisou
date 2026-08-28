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

  /// Raw, per-question submissions — `[{contentId, selectedIndex}]` — the
  /// real content item asked about and which option index was picked.
  /// **Untrusted, exactly like [score]/[total] above**: this is what lets
  /// a server-side grader (see `functions/exam_grading.js`) independently
  /// recompute the true score from its own copy of the same content
  /// dataset, rather than trusting this class's own [score]/[total]
  /// fields, which remain purely for instant, optimistic UI display — see
  /// `TEISOU_ROADMAP_MASTER.md`'s exam-history server-authority sections
  /// for the full design.
  final List<Map<String, dynamic>> answers;

  SimpleExamResult({
    required this.itemId,
    required this.jlptLevel,
    required this.score,
    required this.total,
    required this.completedAt,
    this.answers = const [],
  });

  double get percentage => total == 0 ? 0 : (score / total) * 100;

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'jlptLevel': jlptLevel,
        'score': score,
        'total': total,
        'completedAt': completedAt.toIso8601String(),
        'answers': answers,
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
        answers: (map['answers'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            const [],
      );
}
