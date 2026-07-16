/// One Kaiwa scenario category (e.g. Perkenalan / Di Restoran). Metadata
/// only — the actual dialogue list lives in `assets/data/kaiwa_data.json`,
/// filtered by `category`.
class KaiwaCategoryInfo {
  final String id;
  final String name;
  final String icon;
  final bool available;

  /// Real dialogue count for available categories; null for not-yet-
  /// authored ones rather than guessing a number that might be wrong.
  final int? dialogueCount;

  KaiwaCategoryInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.available,
    this.dialogueCount,
  });

  factory KaiwaCategoryInfo.fromJson(Map<String, dynamic> json) =>
      KaiwaCategoryInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        available: json['available'] as bool? ?? false,
        dialogueCount: (json['dialogueCount'] as num?)?.toInt(),
      );
}
