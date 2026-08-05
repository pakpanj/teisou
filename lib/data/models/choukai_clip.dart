import 'app_language.dart';
import 'jlpt_level.dart';

class ChoukaiQuestion {
  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;

  ChoukaiQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  factory ChoukaiQuestion.fromJson(Map<String, dynamic> json) =>
      ChoukaiQuestion(
        id: json['id'] as String,
        prompt: json['prompt'] as String,
        options: (json['options'] as List).cast<String>(),
        correctIndex: (json['correctIndex'] as num).toInt(),
      );
}

/// One listening-comprehension clip: a Japanese script spoken via
/// [ttsServiceProvider] (there is no recorded-audio pipeline in this app —
/// see CLAUDE.md) plus a set of multiple-choice questions about it. Mirrors
/// [DokkaiPassage] field-for-field, except the script text ([audioText])
/// is deliberately never shown on screen during the exam — only played —
/// consistent with Kaiwa's "no visible text for audio-source content"
/// design; it's revealed on the result screen for review afterwards.
class ChoukaiClip {
  final String id;
  final String title;
  final JlptLevel jlptLevel;
  final String audioText;
  final String audioTranslation;

  /// English renderings of [title]/[audioTranslation]. The script itself
  /// ([audioText]) is Japanese and needs no translating — same split as
  /// [DokkaiPassage]'s titleEn/passageTranslationEn.
  final String? titleEn;
  final String? audioTranslationEn;
  final List<ChoukaiQuestion> questions;

  ChoukaiClip({
    required this.id,
    required this.title,
    required this.jlptLevel,
    required this.audioText,
    required this.audioTranslation,
    required this.questions,
    this.titleEn,
    this.audioTranslationEn,
  });

  String localizedTitle(AppLanguage language) => _pick(language, title, titleEn);

  String localizedAudioTranslation(AppLanguage language) =>
      _pick(language, audioTranslation, audioTranslationEn);

  static String _pick(AppLanguage language, String id, String? en) =>
      language == AppLanguage.english && en != null && en.isNotEmpty ? en : id;

  factory ChoukaiClip.fromJson(Map<String, dynamic> json) => ChoukaiClip(
        id: json['id'] as String,
        title: json['title'] as String,
        jlptLevel: JlptLevelX.fromKey(json['jlptLevel'] as String?),
        audioText: json['audioText'] as String,
        audioTranslation: json['audioTranslation'] as String,
        titleEn: json['titleEn'] as String?,
        audioTranslationEn: json['audioTranslationEn'] as String?,
        questions: (json['questions'] as List)
            .map((e) => ChoukaiQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
