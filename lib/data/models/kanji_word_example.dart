/// One compound-word usage example for a kanji entry (Batch 7's "contoh
/// kata") — distinct from [SentenceExample], which is a full sentence.
class KanjiWordExample {
  final String word;
  final String reading;
  final String meaning;

  KanjiWordExample({
    required this.word,
    required this.reading,
    required this.meaning,
  });

  factory KanjiWordExample.fromJson(Map<String, dynamic> json) =>
      KanjiWordExample(
        word: json['word'] as String,
        reading: json['reading'] as String,
        meaning: json['meaning'] as String,
      );
}
