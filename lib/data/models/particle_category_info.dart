import 'app_language.dart';

/// One of the 3 Partikel categories (Kasus / Keterangan / Akhir Kalimat).
/// Metadata only — the actual particle list lives in
/// `assets/data/particle_data.json`, filtered by `category`.
class ParticleCategoryInfo {
  final String id;
  final String name;
  final String? nameEn;
  final String icon;
  final bool available;

  /// Real particle count for available categories; null for not-yet-
  /// authored ones rather than guessing a number that might be wrong.
  final int? particleCount;

  ParticleCategoryInfo({
    required this.id,
    required this.name,
    this.nameEn,
    required this.icon,
    required this.available,
    this.particleCount,
  });

  String localizedName(AppLanguage language) =>
      language == AppLanguage.english && nameEn != null && nameEn!.isNotEmpty
          ? nameEn!
          : name;

  factory ParticleCategoryInfo.fromJson(Map<String, dynamic> json) =>
      ParticleCategoryInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        nameEn: json['nameEn'] as String?,
        icon: json['icon'] as String,
        available: json['available'] as bool? ?? false,
        particleCount: (json['particleCount'] as num?)?.toInt(),
      );
}
