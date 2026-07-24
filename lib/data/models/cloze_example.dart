import 'app_language.dart';

/// A Japanese sentence with one particle blanked out, used by the Partikel
/// mini-game. Deliberately authored explicitly (before/after split at
/// content-authoring time) rather than derived at runtime by searching a
/// [SentenceExample] for the particle substring — a 1-2 character hiragana
/// particle can coincidentally appear inside an unrelated word or verb
/// conjugation, so a runtime search-and-replace would be fragile.
class ClozeExample {
  final String sentenceBefore;
  final String sentenceAfter;
  final String answer;
  final String translation;

  /// English rendering of [translation], null until authored.
  final String? translationEn;

  final String? romaji;

  ClozeExample({
    required this.sentenceBefore,
    required this.sentenceAfter,
    required this.answer,
    required this.translation,
    this.translationEn,
    this.romaji,
  });

  String localizedTranslation(AppLanguage language) =>
      language == AppLanguage.english &&
              translationEn != null &&
              translationEn!.isNotEmpty
          ? translationEn!
          : translation;

  factory ClozeExample.fromJson(Map<String, dynamic> json) => ClozeExample(
        sentenceBefore: json['sentenceBefore'] as String,
        sentenceAfter: json['sentenceAfter'] as String,
        answer: json['answer'] as String,
        translation: json['translation'] as String,
        translationEn: json['translationEn'] as String?,
        romaji: json['romaji'] as String?,
      );
}
