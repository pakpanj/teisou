import 'app_language.dart';
import 'jlpt_level.dart';

class DokkaiQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  DokkaiQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  factory DokkaiQuestion.fromJson(Map<String, dynamic> json) =>
      DokkaiQuestion(
        id: json['id'] as String,
        prompt: json['prompt'] as String,
        options: (json['options'] as List).cast<String>(),
        correctIndex: (json['correctIndex'] as num).toInt(),
      );
}

/// One reading-comprehension passage: a short Japanese text plus a set of
/// multiple-choice questions about it. Mirrors Kanji/Kotoba/Bunpou's
/// bundled-JSON + Repository loading pattern.
class DokkaiPassage {
  final String id;
  final String title;
  final JlptLevel jlptLevel;
  final String passageJapanese;
  final String passageTranslation;

  /// English renderings of [title]/[passageTranslation], null until
  /// authored — the passage itself is Japanese and needs no translating.
  final String? titleEn;
  final String? passageTranslationEn;
  final List<DokkaiQuestion> questions;

  DokkaiPassage({
    required this.id,
    required this.title,
    required this.jlptLevel,
    required this.passageJapanese,
    required this.passageTranslation,
    required this.questions,
    this.titleEn,
    this.passageTranslationEn,
  });

  String localizedTitle(AppLanguage language) => _pick(language, title, titleEn);

  String localizedPassageTranslation(AppLanguage language) =>
      _pick(language, passageTranslation, passageTranslationEn);

  static String _pick(AppLanguage language, String id, String? en) =>
      language == AppLanguage.english && en != null && en.isNotEmpty ? en : id;

  factory DokkaiPassage.fromJson(Map<String, dynamic> json) => DokkaiPassage(
        id: json['id'] as String,
        title: json['title'] as String,
        jlptLevel: JlptLevelX.fromKey(json['jlptLevel'] as String?),
        passageJapanese: json['passageJapanese'] as String,
        passageTranslation: json['passageTranslation'] as String,
        titleEn: json['titleEn'] as String?,
        passageTranslationEn: json['passageTranslationEn'] as String?,
        questions: (json['questions'] as List)
            .map((e) => DokkaiQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
