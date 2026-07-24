import 'app_language.dart';

/// A Japanese example sentence with translation, shared by any dictionary
/// entry type that needs one (Kotoba words, Kanji entries) — kept
/// module-neutral rather than duplicated per module.
class SentenceExample {
  final String japanese;
  final String translation;

  /// English rendering of [translation]. Null until that sentence has been
  /// translated — the datasets were authored in Indonesian only, and the
  /// English pass runs module by module, so [localizedTranslation] falls
  /// back to [translation] rather than rendering blank mid-rollout.
  final String? translationEn;

  final String? romaji;

  SentenceExample({
    required this.japanese,
    required this.translation,
    this.translationEn,
    this.romaji,
  });

  /// [translationEn] when [language] is English and a translation exists,
  /// else the original Indonesian [translation].
  String localizedTranslation(AppLanguage language) =>
      language == AppLanguage.english &&
              translationEn != null &&
              translationEn!.isNotEmpty
          ? translationEn!
          : translation;

  factory SentenceExample.fromJson(Map<String, dynamic> json) =>
      SentenceExample(
        japanese: json['japanese'] as String,
        translation: json['translation'] as String,
        translationEn: json['translationEn'] as String?,
        romaji: json['romaji'] as String?,
      );
}
