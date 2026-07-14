/// Metadata for one JLPT kanji level (N5-N1) — the actual kanji live in
/// `kanji_data.json`, filtered by level; this is just what
/// `KanjiHomeScreen` needs to render the level picker without loading the
/// full dataset first.
class KanjiLevel {
  final String id;
  final String name;
  final bool available;

  /// Real kanji count for available levels; null for not-yet-authored
  /// ones rather than guessing a number that might be wrong.
  final int? kanjiCount;

  KanjiLevel({
    required this.id,
    required this.name,
    required this.available,
    this.kanjiCount,
  });

  factory KanjiLevel.fromJson(Map<String, dynamic> json) => KanjiLevel(
        id: json['id'] as String,
        name: json['name'] as String,
        available: json['available'] as bool? ?? false,
        kanjiCount: (json['kanjiCount'] as num?)?.toInt(),
      );
}
