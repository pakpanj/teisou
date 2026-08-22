import 'app_language.dart';
import 'jlpt_level.dart';
import 'sentence_example.dart';
import 'speech_register.dart';

class KotobaEntry {
  final String id;
  final String word;
  final String? kanji;
  final String reading;
  final String romaji;
  final String meaning;

  /// English translation of [meaning], authored incrementally category by
  /// category (see CLAUDE.md's Kotoba-localization note) — null for any
  /// word not translated yet. [localizedMeaning] falls back to the
  /// Indonesian [meaning] whenever this is null, so an untranslated word
  /// never renders blank even mid-rollout.
  final String? meaningEn;

  final JlptLevel jlptLevel;
  final String category;
  final String wordType;
  final Map<SpeechRegister, String> registers;

  /// English translation of [registers], keyed the same way — null (or a
  /// key missing from the map) for any register note not translated yet.
  /// [localizedRegisters] falls back per-key to the Indonesian [registers]
  /// value whenever this is null/incomplete, so an untranslated word never
  /// renders blank even mid-rollout.
  final Map<SpeechRegister, String>? registersEn;

  final List<SentenceExample> sentenceExamples;
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
    this.meaningEn,
    required this.jlptLevel,
    required this.category,
    required this.wordType,
    required this.registers,
    this.registersEn,
    this.sentenceExamples = const [],
    this.imageAsset,
    this.imagePath,
    this.placeholder = false,
  });

  /// What a list row or a heading shows as the word itself: the kanji
  /// when there is one, otherwise the kana it is written in.
  String get displayWord => kanji ?? word;

  /// The reading, or null when it would only repeat [displayWord].
  ///
  /// A kana-only word — けしゴム, ノート, ワイファイ — *is* its own reading,
  /// so printing both under each other showed the same characters twice
  /// on 150 of the 1682 entries and made the row look like it had a bug
  /// in it. The romaji still earns its place there; the kana does not.
  String? get readingIfDifferent => reading == displayWord ? null : reading;

  /// Convenience accessor for callers that only ever want one example.
  SentenceExample? get sentenceExample =>
      sentenceExamples.isEmpty ? null : sentenceExamples.first;

  /// [meaningEn] when [language] is English and a translation exists yet,
  /// else the original Indonesian [meaning].
  String localizedMeaning(AppLanguage language) =>
      language == AppLanguage.english &&
          meaningEn != null &&
          meaningEn!.isNotEmpty
      ? meaningEn!
      : meaning;

  /// [registers] with each value swapped for its [registersEn] counterpart
  /// when [language] is English and a translation exists for that key,
  /// else the original Indonesian value for that key.
  Map<SpeechRegister, String> localizedRegisters(AppLanguage language) {
    if (language != AppLanguage.english) return registers;
    return {
      for (final entry in registers.entries)
        entry.key: (registersEn?[entry.key]?.isNotEmpty ?? false)
            ? registersEn![entry.key]!
            : entry.value,
    };
  }

  static Map<SpeechRegister, String> _parseRegisters(
    Map<String, dynamic> raw,
  ) => {
    for (final entry in raw.entries)
      if (entry.key == 'casual')
        SpeechRegister.casual: entry.value as String
      else if (entry.key == 'formal')
        SpeechRegister.formal: entry.value as String
      else if (entry.key == 'keigo')
        SpeechRegister.keigo: entry.value as String,
  };

  factory KotobaEntry.fromJson(Map<String, dynamic> json) {
    final rawRegisters = json['registers'] as Map<String, dynamic>? ?? {};
    final rawRegistersEn = json['registersEn'] as Map<String, dynamic>?;

    // Batch 6 datasets write a `sentenceExamples` list; Batch 4's
    // kotoba_data.json predates that and only has a single `sentenceExample`
    // object. Support both without needing to regenerate the older file.
    final examples = <SentenceExample>[];
    final rawList = json['sentenceExamples'] as List?;
    if (rawList != null) {
      examples.addAll(
        rawList.map((e) => SentenceExample.fromJson(e as Map<String, dynamic>)),
      );
    } else {
      final rawSingle = json['sentenceExample'] as Map<String, dynamic>?;
      if (rawSingle != null) {
        examples.add(SentenceExample.fromJson(rawSingle));
      }
    }

    return KotobaEntry(
      id: json['id'] as String,
      word: json['word'] as String,
      kanji: json['kanji'] as String?,
      reading: json['reading'] as String,
      romaji: json['romaji'] as String,
      meaning: json['meaning'] as String,
      meaningEn: json['meaningEn'] as String?,
      jlptLevel: JlptLevelX.fromKey(json['jlptLevel'] as String?),
      category: json['category'] as String? ?? '',
      wordType: json['wordType'] as String? ?? '',
      registers: _parseRegisters(rawRegisters),
      registersEn: rawRegistersEn != null
          ? _parseRegisters(rawRegistersEn)
          : null,
      sentenceExamples: examples,
      imageAsset: json['imageAsset'] as String?,
      imagePath: json['imagePath'] as String?,
      placeholder: json['placeholder'] as bool? ?? false,
    );
  }
}
