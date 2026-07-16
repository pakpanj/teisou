/// Metadata for one JLPT grammar level (N5-N1) — the actual patterns live
/// in `bunpou_data.json`, filtered by level; this is just what
/// `BunpouHomeScreen` needs to render the level picker without loading the
/// full dataset first.
class BunpouLevel {
  final String id;
  final String name;
  final bool available;

  /// Real pattern count for available levels; null for not-yet-authored
  /// ones rather than guessing a number that might be wrong.
  final int? bunpouCount;

  BunpouLevel({
    required this.id,
    required this.name,
    required this.available,
    this.bunpouCount,
  });

  factory BunpouLevel.fromJson(Map<String, dynamic> json) => BunpouLevel(
        id: json['id'] as String,
        name: json['name'] as String,
        available: json['available'] as bool? ?? false,
        bunpouCount: (json['bunpouCount'] as num?)?.toInt(),
      );
}
