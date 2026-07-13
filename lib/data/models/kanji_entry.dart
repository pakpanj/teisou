import 'jlpt_level.dart';
import 'kanji_example.dart';

class KanjiEntry {
  final String id;
  final String character;
  final JlptLevel jlptLevel;
  final List<String> onyomi;
  final List<String> kunyomi;
  final List<String> meanings;
  final int strokeCount;
  final String? svgAsset;
  final List<KanjiExample> examples;
  final List<String> relatedBunpou;

  /// True for N4-N1 marker rows that only reserve a level's slot in the
  /// dataset — content isn't authored yet. Search/detail screens should
  /// treat these as "not available" rather than a real entry.
  final bool placeholder;

  KanjiEntry({
    required this.id,
    required this.character,
    required this.jlptLevel,
    required this.onyomi,
    required this.kunyomi,
    required this.meanings,
    required this.strokeCount,
    this.svgAsset,
    required this.examples,
    required this.relatedBunpou,
    this.placeholder = false,
  });

  factory KanjiEntry.fromJson(Map<String, dynamic> json) => KanjiEntry(
        id: json['id'] as String,
        character: json['character'] as String,
        jlptLevel: JlptLevelX.fromKey(json['jlptLevel'] as String?),
        onyomi: (json['onyomi'] as List? ?? []).cast<String>(),
        kunyomi: (json['kunyomi'] as List? ?? []).cast<String>(),
        meanings: (json['meanings'] as List? ?? []).cast<String>(),
        strokeCount: (json['strokeCount'] as num?)?.toInt() ?? 0,
        svgAsset: json['svgAsset'] as String?,
        examples: (json['examples'] as List? ?? [])
            .map((e) => KanjiExample.fromJson(e as Map<String, dynamic>))
            .toList(),
        relatedBunpou: (json['relatedBunpou'] as List? ?? []).cast<String>(),
        placeholder: json['placeholder'] as bool? ?? false,
      );
}
