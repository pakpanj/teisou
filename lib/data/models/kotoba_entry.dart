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
  final KotobaSentenceExample? sentenceExample;
  final String? imageAsset;

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
    this.sentenceExample,
    this.imageAsset,
    this.placeholder = false,
  });

  factory KotobaEntry.fromJson(Map<String, dynamic> json) {
    final rawRegisters = json['registers'] as Map<String, dynamic>? ?? {};
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
      sentenceExample: json['sentenceExample'] != null
          ? KotobaSentenceExample.fromJson(
              json['sentenceExample'] as Map<String, dynamic>)
          : null,
      imageAsset: json['imageAsset'] as String?,
      placeholder: json['placeholder'] as bool? ?? false,
    );
  }
}
