import 'example_word.dart';
import 'kana_type.dart';

class KanaCharacter {
  final String id;
  final String character;
  final String romaji;
  final KanaType type;
  final int row;
  final int column;
  final String svgAsset;
  final List<ExampleWord> examples;

  KanaCharacter({
    required this.id,
    required this.character,
    required this.romaji,
    required this.type,
    required this.row,
    required this.column,
    required this.svgAsset,
    required this.examples,
  });

  factory KanaCharacter.fromJson(Map<String, dynamic> json) => KanaCharacter(
        id: json['id'] as String,
        character: json['character'] as String,
        romaji: json['romaji'] as String,
        type: json['type'] == 'hiragana' ? KanaType.hiragana : KanaType.katakana,
        row: json['row'] as int,
        column: json['column'] as int,
        svgAsset: json['svgAsset'] as String,
        examples: (json['examples'] as List)
            .map((e) => ExampleWord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
