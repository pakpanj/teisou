import 'jlpt_level.dart';
import 'kanji_example.dart';
import 'kanji_word_example.dart';
import 'sentence_example.dart';

class KanjiEntry {
  final String id;
  final String character;
  final JlptLevel jlptLevel;
  final List<String> onyomi;
  final List<String> kunyomi;
  final List<String> meanings;
  final int strokeCount;

  /// Path to this kanji's KanjiVG stroke-order SVG (e.g.
  /// `assets/kanjivg/04e00.svg`), read by both the static [KanjiGlyph] and
  /// the animated `StrokeOrderAnimator` (Batch 7) — one field, one file,
  /// no separate "svgPath" duplicate.
  final String? svgAsset;

  /// Compound-word usage examples ("contoh kata", Batch 7) — minimum 3 per
  /// real entry.
  final List<KanjiWordExample> wordExamples;

  /// Full example sentences ("contoh kalimat", Batch 7) — minimum 2 per
  /// real entry.
  final List<SentenceExample> sentenceExamples;

  /// Radical/bushu (e.g. 氵, 木) — nullable since older entries may not
  /// have it filled in yet.
  final String? radical;

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
    this.wordExamples = const [],
    this.sentenceExamples = const [],
    this.radical,
    required this.relatedBunpou,
    this.placeholder = false,
  });

  /// Backward-compat view for callers built against Batch 4's flat
  /// word+sentence shape (`search/kanji_detail_screen.dart`) — pairs word
  /// example *i* with sentence example *i* where one exists, rather than
  /// carrying two parallel content shapes in the dataset itself.
  List<KanjiExample> get examples {
    return [
      for (var i = 0; i < wordExamples.length; i++)
        KanjiExample(
          word: wordExamples[i].word,
          reading: wordExamples[i].reading,
          meaning: wordExamples[i].meaning,
          sentence: i < sentenceExamples.length ? sentenceExamples[i].japanese : '',
          sentenceTranslation:
              i < sentenceExamples.length ? sentenceExamples[i].translation : '',
        ),
    ];
  }

  factory KanjiEntry.fromJson(Map<String, dynamic> json) => KanjiEntry(
        id: json['id'] as String,
        character: json['character'] as String,
        jlptLevel: JlptLevelX.fromKey(json['jlptLevel'] as String?),
        onyomi: (json['onyomi'] as List? ?? []).cast<String>(),
        kunyomi: (json['kunyomi'] as List? ?? []).cast<String>(),
        meanings: (json['meanings'] as List? ?? []).cast<String>(),
        strokeCount: (json['strokeCount'] as num?)?.toInt() ?? 0,
        svgAsset: json['svgAsset'] as String?,
        wordExamples: (json['wordExamples'] as List? ?? [])
            .map((e) => KanjiWordExample.fromJson(e as Map<String, dynamic>))
            .toList(),
        sentenceExamples: (json['sentenceExamples'] as List? ?? [])
            .map((e) => SentenceExample.fromJson(e as Map<String, dynamic>))
            .toList(),
        radical: json['radical'] as String?,
        relatedBunpou: (json['relatedBunpou'] as List? ?? []).cast<String>(),
        placeholder: json['placeholder'] as bool? ?? false,
      );
}
