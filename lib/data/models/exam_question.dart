import 'kana_character.dart';

class ExamQuestion {
  final KanaCharacter kana;
  final List<String> options;

  ExamQuestion({required this.kana, required this.options});

  String get correctAnswer => kana.romaji;
}

class AnsweredQuestion {
  final ExamQuestion question;
  final String selectedAnswer;

  AnsweredQuestion({required this.question, required this.selectedAnswer});

  bool get isCorrect => selectedAnswer == question.correctAnswer;
}
