class ExampleWord {
  final String word;
  final String reading;
  final String meaning;

  ExampleWord({
    required this.word,
    required this.reading,
    required this.meaning,
  });

  factory ExampleWord.fromJson(Map<String, dynamic> json) => ExampleWord(
        word: json['word'] as String,
        reading: json['reading'] as String,
        meaning: json['meaning'] as String,
      );

  Map<String, dynamic> toJson() => {
        'word': word,
        'reading': reading,
        'meaning': meaning,
      };
}
