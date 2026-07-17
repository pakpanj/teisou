/// Metadata for one JLPT level (N5-N1) within Kaiwa — the actual themes
/// live in `assets/data/kaiwa/_categories.json`, filtered by `level`; this
/// is just what `KaiwaHomeScreen` needs to render the level picker without
/// loading the full category/dialogue data first. Mirrors `BunpouLevel`.
class KaiwaJlptLevelInfo {
  final String id;
  final String name;
  final bool available;

  /// Real theme count for available levels; null for not-yet-authored
  /// ones rather than guessing a number that might be wrong.
  final int? themeCount;

  KaiwaJlptLevelInfo({
    required this.id,
    required this.name,
    required this.available,
    this.themeCount,
  });

  factory KaiwaJlptLevelInfo.fromJson(Map<String, dynamic> json) =>
      KaiwaJlptLevelInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        available: json['available'] as bool? ?? false,
        themeCount: (json['themeCount'] as num?)?.toInt(),
      );
}
