/// A Japanese example sentence with translation, shared by any dictionary
/// entry type that needs one (Kotoba words, Kanji entries) — kept
/// module-neutral rather than duplicated per module.
class SentenceExample {
  final String japanese;
  final String translation;
  final String? romaji;

  SentenceExample({
    required this.japanese,
    required this.translation,
    this.romaji,
  });

  factory SentenceExample.fromJson(Map<String, dynamic> json) =>
      SentenceExample(
        japanese: json['japanese'] as String,
        translation: json['translation'] as String,
        romaji: json['romaji'] as String?,
      );
}
