import 'jlpt_level.dart';
import 'kotoba_sentence_example.dart';
import 'speech_register.dart';

class KotobaEntry {
  final String id;
  final String word;
  final String? kanji;
  final String reading;
  final String romaji;
  final String meaning;
  final JlptLevel jlptLevel;
  final String category;
  final String wordType;
  final Map<SpeechRegister, String> registers;
  final List<KotobaSentenceExample> sentenceExamples;
  final String? imageAsset;

  /// Firebase Storage path for the on-demand vocab illustration (Batch 6),
  /// e.g. `kotoba_images/ikan/kotoba_ikan_maguro.png`. Distinct from
  /// [imageAsset], which is reserved for a possible bundled-in-APK image —
  /// this one is always fetched over the network and cached locally.
  final String? imagePath;

  /// True for N4-N1 marker rows that only reserve a level's slot in the
  /// dataset — content isn't authored yet.
  final bool placeholder;

  KotobaEntry({
    required this.id,
    required this.word,
    this.kanji,
    required this.reading,
    required this.romaji,
    required this.meaning,
    required this.jlptLevel,
    required this.category,
    required this.wordType,
    required this.registers,
    this.sentenceExamples = const [],
    this.imageAsset,
    this.imagePath,
    this.placeholder = false,
  });

  /// Convenience accessor for callers that only ever want one example.
  KotobaSentenceExample? get sentenceExample =>
      sentenceExamples.isEmpty ? null : sentenceExamples.first;

  factory KotobaEntry.fromJson(Map<String, dynamic> json) {
    final rawRegisters = json['registers'] as Map<String, dynamic>? ?? {};

    // Batch 6 datasets write a `sentenceExamples` list; Batch 4's
    // kotoba_data.json predates that and only has a single `sentenceExample`
    // object. Support both without needing to regenerate the older file.
    final examples = <KotobaSentenceExample>[];
    final rawList = json['sentenceExamples'] as List?;
    if (rawList != null) {
      examples.addAll(
        rawList.map((e) => KotobaSentenceExample.fromJson(e as Map<String, dynamic>)),
      );
    } else {
      final rawSingle = json['sentenceExample'] as Map<String, dynamic>?;
      if (rawSingle != null) {
        examples.add(KotobaSentenceExample.fromJson(rawSingle));
      }
    }

    return KotobaEntry(
      id: json['id'] as String,
      word: json['word'] as String,
      kanji: json['kanji'] as String?,
      reading: json['reading'] as String,
      romaji: json['romaji'] as String,
      meaning: json['meaning'] as String,
      jlptLevel: JlptLevelX.fromKey(json['jlptLevel'] as String?),
      category: json['category'] as String? ?? '',
      wordType: json['wordType'] as String? ?? '',
      registers: {
        for (final entry in rawRegisters.entries)
          if (entry.key == 'casual')
            SpeechRegister.casual: entry.value as String
          else if (entry.key == 'formal')
            SpeechRegister.formal: entry.value as String
          else if (entry.key == 'keigo')
            SpeechRegister.keigo: entry.value as String,
      },
      sentenceExamples: examples,
      imageAsset: json['imageAsset'] as String?,
      imagePath: json['imagePath'] as String?,
      placeholder: json['placeholder'] as bool? ?? false,
    );
  }
}
