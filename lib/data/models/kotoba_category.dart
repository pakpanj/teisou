/// One of the 45 planned Kotoba vocab categories (Batch 6), grouped under
/// a broader theme (e.g. "Alam & Lingkungan"). Metadata only — the actual
/// word list lives in its own `assets/data/kotoba/{id}.json` file, loaded
/// separately (and only for [available] categories) via
/// `KotobaRepository.getVocabCategory`.
class KotobaCategory {
  final String id;
  final String name;
  final String group;
  final String icon;
  final bool available;

  /// Real word count for available categories; null for not-yet-authored
  /// ones rather than guessing a number that might be wrong.
  final int? wordCount;

  KotobaCategory({
    required this.id,
    required this.name,
    required this.group,
    required this.icon,
    required this.available,
    this.wordCount,
  });

  factory KotobaCategory.fromJson(Map<String, dynamic> json) => KotobaCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        group: json['group'] as String,
        icon: json['icon'] as String,
        available: json['available'] as bool? ?? false,
        wordCount: (json['wordCount'] as num?)?.toInt(),
      );
}
