/// One wrong answer from a finished quiz/exam session — what was asked,
/// what the learner picked, and what the right answer actually was.
/// Deliberately transient (never persisted): it exists only to drive
/// [lib/features/exam/quiz_review_screen.dart] right after a session ends,
/// the same "session-scoped, not saved" treatment already given to
/// `ExamResult.newlyMasteredCount`.
class QuizReviewEntry {
  final String question;
  final String userAnswer;
  final String correctAnswer;

  const QuizReviewEntry({
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
  });
}
