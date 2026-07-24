import 'app_language.dart';
import 'jlpt_level.dart';
import 'sentence_example.dart';

class BunpouEntry {
  final String id;
  final String pattern;
  final String patternRomaji;
  final JlptLevel jlptLevel;
  final String meaning;
  final String formation;
  final String usageNotes;

  /// English renderings of the three prose fields above, null until
  /// authored — [localizedMeaning]/[localizedUsageNotes] fall back to the
  /// Indonesian text so an untranslated entry never renders blank.
  final String? meaningEn;
  final String? usageNotesEn;

  /// Ids of other [BunpouEntry]s with a similar/easily-confused pattern
  /// (e.g. てある vs ている) — cross-referenced from the detail screen.
  final List<String> similarPatterns;

  /// Full example sentences ("contoh kalimat") — minimum 3 per real entry.
  final List<SentenceExample> sentenceExamples;

  /// True for level rows that only reserve a slot in the dataset — content
  /// isn't authored yet. Screens should treat these as "not available"
  /// rather than a real entry.
  final bool placeholder;

  BunpouEntry({
    required this.id,
    required this.pattern,
    required this.patternRomaji,
    required this.jlptLevel,
    required this.meaning,
    required this.formation,
    required this.usageNotes,
    this.meaningEn,
    this.usageNotesEn,
    this.similarPatterns = const [],
    this.sentenceExamples = const [],
    this.placeholder = false,
  });

  String localizedMeaning(AppLanguage language) =>
      _pick(language, meaning, meaningEn);

  String localizedUsageNotes(AppLanguage language) =>
      _pick(language, usageNotes, usageNotesEn);

  static String _pick(AppLanguage language, String id, String? en) =>
      language == AppLanguage.english && en != null && en.isNotEmpty ? en : id;

  factory BunpouEntry.fromJson(Map<String, dynamic> json) => BunpouEntry(
        id: json['id'] as String,
        pattern: json['pattern'] as String,
        patternRomaji: json['patternRomaji'] as String,
        jlptLevel: JlptLevelX.fromKey(json['jlptLevel'] as String?),
        meaning: json['meaning'] as String,
        formation: json['formation'] as String,
        usageNotes: json['usageNotes'] as String,
        similarPatterns: (json['similarPatterns'] as List? ?? []).cast<String>(),
        sentenceExamples: (json['sentenceExamples'] as List? ?? [])
            .map((e) => SentenceExample.fromJson(e as Map<String, dynamic>))
            .toList(),
        placeholder: json['placeholder'] as bool? ?? false,
      );
}
