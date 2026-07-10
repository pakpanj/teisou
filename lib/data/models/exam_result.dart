import 'package:cloud_firestore/cloud_firestore.dart';

import 'exam_mode.dart';

class WrongAnswerEntry {
  final String kanaId;
  final String userAnswer;
  final String correctAnswer;

  WrongAnswerEntry({
    required this.kanaId,
    required this.userAnswer,
    required this.correctAnswer,
  });

  Map<String, dynamic> toMap() => {
        'kanaId': kanaId,
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswer,
      };

  factory WrongAnswerEntry.fromMap(Map<String, dynamic> map) =>
      WrongAnswerEntry(
        kanaId: map['kanaId'] as String,
        userAnswer: map['userAnswer'] as String,
        correctAnswer: map['correctAnswer'] as String,
      );
}

class ExamResult {
  final ExamMode mode;
  final int score;
  final int total;
  final List<WrongAnswerEntry> wrongAnswers;
  final DateTime completedAt;

  ExamResult({
    required this.mode,
    required this.score,
    required this.total,
    required this.wrongAnswers,
    required this.completedAt,
  });

  int get correctCount => score;
  int get wrongCount => total - score;
  double get percentage => total == 0 ? 0 : (score / total) * 100;

  Map<String, dynamic> toMap() => {
        'type': mode.key,
        'score': score,
        'total': total,
        'percentage': percentage.round(),
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'wrongAnswers': wrongAnswers.map((e) => e.toMap()).toList(),
        'completedAt': Timestamp.fromDate(completedAt),
      };
}
