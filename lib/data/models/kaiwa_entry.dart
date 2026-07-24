import 'app_language.dart';
import 'kaiwa_line.dart';

/// One conversation-practice dialogue — a fixed situation (e.g. "Memesan
/// Makanan di Restoran") made of an ordered [lines] list mixing scripted NPC
/// turns and interactive user turns.
///
/// [category] is one of the ids locked in `scripts/kaiwa_lists.py` — a plain
/// validated String rather than a Dart enum, same reasoning as
/// `ParticleEntry.category` (a fixed small set of scenario ids, no
/// exhaustive switch needs compile-time safety here).
class KaiwaEntry {
  final String id;
  final String title;
  final String category;
  final String description;

  /// English renderings of [title]/[description], null until authored.
  final String? titleEn;
  final String? descriptionEn;

  final List<KaiwaLine> lines;

  /// True for rows that only reserve a slot in the dataset — content isn't
  /// authored yet. Screens should treat these as "not available".
  final bool placeholder;

  KaiwaEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.titleEn,
    this.descriptionEn,
    this.lines = const [],
    this.placeholder = false,
  });

  String localizedTitle(AppLanguage language) => _pick(language, title, titleEn);

  String localizedDescription(AppLanguage language) =>
      _pick(language, description, descriptionEn);

  static String _pick(AppLanguage language, String id, String? en) =>
      language == AppLanguage.english && en != null && en.isNotEmpty ? en : id;

  factory KaiwaEntry.fromJson(Map<String, dynamic> json) => KaiwaEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        titleEn: json['titleEn'] as String?,
        descriptionEn: json['descriptionEn'] as String?,
        lines: (json['lines'] as List? ?? [])
            .map((e) => KaiwaLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        placeholder: json['placeholder'] as bool? ?? false,
      );
}
