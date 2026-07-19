/// Metadata for one JLPT level within Choukai — mirrors
/// `DokkaiJlptLevelInfo`/`KaiwaJlptLevelInfo`. All five levels currently
/// ship with `available: false` (zero authored clips) — the architecture
/// is ready, content is a separate future pass.
class ChoukaiJlptLevelInfo {
  final String id;
  final String name;
  final bool available;
  final int? clipCount;

  ChoukaiJlptLevelInfo({
    required this.id,
    required this.name,
    required this.available,
    this.clipCount,
  });

  factory ChoukaiJlptLevelInfo.fromJson(Map<String, dynamic> json) =>
      ChoukaiJlptLevelInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        available: json['available'] as bool? ?? false,
        clipCount: (json['clipCount'] as num?)?.toInt(),
      );
}
