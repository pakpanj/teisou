import 'app_language.dart';
import 'particle_function.dart';

/// A single Japanese particle (助詞) and every distinct function it can
/// serve, e.g. に nests 4-6 [ParticleFunction]s (location, direction, time,
/// ...) under one entry, rather than being split into separate flat entries
/// the way Bunpou's grammar patterns handle one-meaning-per-pattern.
///
/// [category] is one of the ids locked in `scripts/particle_lists.py`
/// ("kasus" / "keterangan" / "akhir_kalimat") — a plain validated String
/// rather than a dedicated Dart enum, since there are only 3 fixed values
/// and no exhaustive switch logic needs compile-time safety here (mirrors
/// how `KotobaCategory` also has no enum counterpart).
class ParticleEntry {
  final String id;
  final String particle;
  final String particleRomaji;
  final String category;
  final String overview;

  /// English rendering of [overview], null until authored.
  final String? overviewEn;

  final List<ParticleFunction> functions;

  /// Ids of other [ParticleEntry]s that are easily confused with this one
  /// (e.g. に vs で vs へ) — cross-referenced from the detail screen.
  final List<String> similarParticles;

  /// True for rows that only reserve a slot in the dataset — content isn't
  /// authored yet. Screens should treat these as "not available".
  final bool placeholder;

  ParticleEntry({
    required this.id,
    required this.particle,
    required this.particleRomaji,
    required this.category,
    required this.overview,
    this.overviewEn,
    this.functions = const [],
    this.similarParticles = const [],
    this.placeholder = false,
  });

  String localizedOverview(AppLanguage language) =>
      language == AppLanguage.english &&
              overviewEn != null &&
              overviewEn!.isNotEmpty
          ? overviewEn!
          : overview;

  factory ParticleEntry.fromJson(Map<String, dynamic> json) => ParticleEntry(
        id: json['id'] as String,
        particle: json['particle'] as String,
        particleRomaji: json['particleRomaji'] as String,
        category: json['category'] as String,
        overview: json['overview'] as String,
        overviewEn: json['overviewEn'] as String?,
        functions: (json['functions'] as List? ?? [])
            .map((e) => ParticleFunction.fromJson(e as Map<String, dynamic>))
            .toList(),
        similarParticles:
            (json['similarParticles'] as List? ?? []).cast<String>(),
        placeholder: json['placeholder'] as bool? ?? false,
      );
}
