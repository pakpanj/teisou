import 'app_language.dart';
import 'jlpt_level.dart';

/// One curriculum chapter — an original (not copied from any textbook)
/// theme that bundles already-authored ids from six existing modules into
/// a difficulty-escalating, Minna-no-Nihongo-*inspired* order (vocab ->
/// grammar/particle -> dialogue -> optional extra reading). Carries no
/// content of its own: every id below is resolved through that module's
/// own repository at render time (see `bab_providers.dart`).
class BabEntry {
  final String id;

  /// Global sequence number across the whole curriculum, not per-level —
  /// "Bab 1", "Bab 2"... keeps increasing once N4+ chapters are authored
  /// later, the same way a course doesn't renumber per JLPT level.
  final int order;

  final String title;
  final String? titleEn;
  final String description;
  final String? descriptionEn;
  final JlptLevel level;

  final List<String> kotobaIds;
  final List<String> kanjiIds;
  final List<String> bunpouIds;
  final List<String> particleIds;
  final List<String> kaiwaIds;
  final List<String> dokkaiIds;

  BabEntry({
    required this.id,
    required this.order,
    required this.title,
    this.titleEn,
    required this.description,
    this.descriptionEn,
    required this.level,
    this.kotobaIds = const [],
    this.kanjiIds = const [],
    this.bunpouIds = const [],
    this.particleIds = const [],
    this.kaiwaIds = const [],
    this.dokkaiIds = const [],
  });

  String localizedTitle(AppLanguage language) => _pick(language, title, titleEn);

  String localizedDescription(AppLanguage language) =>
      _pick(language, description, descriptionEn);

  static String _pick(AppLanguage language, String id, String? en) =>
      language == AppLanguage.english && en != null && en.isNotEmpty ? en : id;

  factory BabEntry.fromJson(Map<String, dynamic> json) => BabEntry(
        id: json['id'] as String,
        order: (json['order'] as num).toInt(),
        title: json['title'] as String,
        titleEn: json['titleEn'] as String?,
        description: json['description'] as String,
        descriptionEn: json['descriptionEn'] as String?,
        level: JlptLevelX.fromKey(json['level'] as String?),
        kotobaIds: (json['kotobaIds'] as List? ?? []).cast<String>(),
        kanjiIds: (json['kanjiIds'] as List? ?? []).cast<String>(),
        bunpouIds: (json['bunpouIds'] as List? ?? []).cast<String>(),
        particleIds: (json['particleIds'] as List? ?? []).cast<String>(),
        kaiwaIds: (json['kaiwaIds'] as List? ?? []).cast<String>(),
        dokkaiIds: (json['dokkaiIds'] as List? ?? []).cast<String>(),
      );
}
