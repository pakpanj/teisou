class KotobaSentenceExample {
  final String japanese;
  final String translation;

  KotobaSentenceExample({required this.japanese, required this.translation});

  factory KotobaSentenceExample.fromJson(Map<String, dynamic> json) =>
      KotobaSentenceExample(
        japanese: json['japanese'] as String,
        translation: json['translation'] as String,
      );
}
