import 'app_language.dart';

class KanjiExample {
  final String word;
  final String reading;
  final String meaning;
  final String? meaningEn;
  final String sentence;
  final String sentenceTranslation;

  final String? sentenceTranslationEn;

  KanjiExample({
    required this.word,
    required this.reading,
    required this.meaning,
    required this.sentence,
    required this.sentenceTranslation,
    this.meaningEn,
    this.sentenceTranslationEn,
  });

  String localizedMeaning(AppLanguage language) =>
      _pick(language, meaning, meaningEn);

  String localizedSentenceTranslation(AppLanguage language) =>
      _pick(language, sentenceTranslation, sentenceTranslationEn);

  static String _pick(AppLanguage language, String id, String? en) =>
      language == AppLanguage.english && en != null && en.isNotEmpty ? en : id;

  factory KanjiExample.fromJson(Map<String, dynamic> json) => KanjiExample(
        word: json['word'] as String,
        reading: json['reading'] as String,
        meaning: json['meaning'] as String,
        meaningEn: json['meaningEn'] as String?,
        sentence: json['sentence'] as String? ?? '',
        sentenceTranslation: json['sentenceTranslation'] as String? ?? '',
        sentenceTranslationEn: json['sentenceTranslationEn'] as String?,
      );
}
