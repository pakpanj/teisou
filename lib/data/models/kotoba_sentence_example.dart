class KotobaSentenceExample {
  final String japanese;
  final String translation;
  final String? romaji;

  KotobaSentenceExample({
    required this.japanese,
    required this.translation,
    this.romaji,
  });

  factory KotobaSentenceExample.fromJson(Map<String, dynamic> json) =>
      KotobaSentenceExample(
        japanese: json['japanese'] as String,
        translation: json['translation'] as String,
        romaji: json['romaji'] as String?,
      );
}
