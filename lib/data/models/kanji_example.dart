class KanjiExample {
  final String word;
  final String reading;
  final String meaning;
  final String sentence;
  final String sentenceTranslation;

  KanjiExample({
    required this.word,
    required this.reading,
    required this.meaning,
    required this.sentence,
    required this.sentenceTranslation,
  });

  factory KanjiExample.fromJson(Map<String, dynamic> json) => KanjiExample(
        word: json['word'] as String,
        reading: json['reading'] as String,
        meaning: json['meaning'] as String,
        sentence: json['sentence'] as String? ?? '',
        sentenceTranslation: json['sentenceTranslation'] as String? ?? '',
      );
}
