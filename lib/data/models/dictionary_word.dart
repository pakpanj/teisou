/// A single Japanese-Indonesian example sentence, scoped to
/// [DictionaryWord] — deliberately not the shared module-neutral
/// `SentenceExample` class (Kanji/Kotoba/Bunpou/Kaiwa's), since this
/// dictionary schema is intentionally text-only (no romaji field, no
/// register variants) to keep 10,000+ entries lightweight.
class DictionaryExample {
  final String japanese;
  final String translation;

  const DictionaryExample({required this.japanese, required this.translation});

  factory DictionaryExample.fromJson(Map<String, dynamic> json) {
    return DictionaryExample(
      japanese: json['japanese'] as String,
      translation: json['translation'] as String,
    );
  }
}

/// One entry in the comprehensive, search-only vocabulary dictionary —
/// distinct from [KotobaEntry] (the curated 519-word learning module):
/// no image, no category, no JLPT level, no speech registers. Just
/// enough to power a translator-style search result: kanji (if any),
/// reading, meaning, and one example sentence.
class DictionaryWord {
  final String id;
  final String? kanji;
  final String reading;
  final String meaning;
  final DictionaryExample example;

  const DictionaryWord({
    required this.id,
    this.kanji,
    required this.reading,
    required this.meaning,
    required this.example,
  });

  /// The word as displayed — kanji form when available, else the reading.
  String get display => kanji ?? reading;

  /// Individual characters of [kanji], for best-effort tap-through to
  /// `KanjiDetailScreen` where a character happens to be in the curated
  /// 2425-entry Kanji dataset. Not every character will resolve there.
  List<String> get kanjiCharacters => kanji?.split('') ?? const [];

  factory DictionaryWord.fromJson(Map<String, dynamic> json) {
    return DictionaryWord(
      id: json['id'] as String,
      kanji: json['kanji'] as String?,
      reading: json['reading'] as String,
      meaning: json['meaning'] as String,
      example: DictionaryExample.fromJson(
        json['example'] as Map<String, dynamic>,
      ),
    );
  }
}
