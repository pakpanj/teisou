/// Metadata for one JLPT level within Dokkai — mirrors
/// `KaiwaJlptLevelInfo`/`BunpouLevel`.
class DokkaiJlptLevelInfo {
  final String id;
  final String name;
  final bool available;

  /// Real passage count for available levels; null for not-yet-authored
  /// ones rather than guessing a number that might be wrong.
  final int? passageCount;

  DokkaiJlptLevelInfo({
    required this.id,
    required this.name,
    required this.available,
    this.passageCount,
  });

  factory DokkaiJlptLevelInfo.fromJson(Map<String, dynamic> json) =>
      DokkaiJlptLevelInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        available: json['available'] as bool? ?? false,
        passageCount: (json['passageCount'] as num?)?.toInt(),
      );
}
