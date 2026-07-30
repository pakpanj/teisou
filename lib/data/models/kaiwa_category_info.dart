import 'app_language.dart';
import 'jlpt_level.dart';

/// One Kaiwa scenario theme (e.g. Perkenalan / Di Restoran), nested under a
/// [level]. Metadata only — the actual dialogue list lives in
/// `assets/data/kaiwa_data.json`, filtered by `category`.
class KaiwaCategoryInfo {
  final String id;
  final String name;
  final String? nameEn;
  final String icon;
  final JlptLevel level;
  final bool available;

  /// Real dialogue count for available categories; null for not-yet-
  /// authored ones rather than guessing a number that might be wrong.
  final int? dialogueCount;

  KaiwaCategoryInfo({
    required this.id,
    required this.name,
    this.nameEn,
    required this.icon,
    required this.level,
    required this.available,
    this.dialogueCount,
  });

  String localizedName(AppLanguage language) =>
      language == AppLanguage.english && nameEn != null && nameEn!.isNotEmpty
          ? nameEn!
          : name;

  factory KaiwaCategoryInfo.fromJson(Map<String, dynamic> json) =>
      KaiwaCategoryInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        nameEn: json['nameEn'] as String?,
        icon: json['icon'] as String,
        level: JlptLevelX.fromKey(json['level'] as String?),
        available: json['available'] as bool? ?? false,
        dialogueCount: (json['dialogueCount'] as num?)?.toInt(),
      );
}
