import '../../data/models/kanji_entry.dart';
import '../../data/repositories/kanji_repository.dart';
import '../../data/repositories/kotoba_repository.dart';

/// One segment of a furigana-annotated sentence: either a kanji run with a
/// reading to show above it, or a plain run (kana, punctuation, latin) with
/// no reading.
class FuriganaSegment {
  final String text;
  final String? reading;

  const FuriganaSegment(this.text, [this.reading]);
}

/// A whole-word/whole-character kana lookup used to annotate example
/// sentences with furigana, built once from data that's already loaded for
/// other reasons (the Kotoba vocab module, the Kanji dataset).
///
/// Deliberately **not** built from [KanjiEntry.wordExamples] — that list's
/// own `reading` field is romaji ("hitotsu"), not kana, and this app has no
/// romaji->kana converter (only the reverse, used at content-authoring
/// time). Guessing one at furigana-render time risks a wrong reading
/// shipping silently to a child, which is worse than showing none — so
/// compound coverage comes only from Kotoba's own kana `reading` field, and
/// single-kanji coverage falls back to that kanji's own onyomi/kunyomi
/// (already kana). A sentence using a compound this dictionary doesn't
/// cover just renders without furigana for that run, same as any other
/// word not found in a real dictionary.
class FuriganaDictionary {
  final Map<String, String> _words;

  FuriganaDictionary._(this._words);

  static Future<FuriganaDictionary> build({
    required KotobaRepository kotoba,
    required KanjiRepository kanji,
  }) async {
    final words = <String, String>{};

    final vocab = await kotoba.getAllVocab();
    for (final entry in vocab) {
      final k = entry.kanji;
      if (k == null || k.isEmpty) continue;
      words.putIfAbsent(k, () => entry.reading);
    }

    final kanjiEntries = await kanji.getAll();
    for (final entry in kanjiEntries) {
      final reading = _primaryKanjiReading(entry);
      if (reading == null) continue;
      words.putIfAbsent(entry.character, () => reading);
    }

    return FuriganaDictionary._(words);
  }

  static String? _primaryKanjiReading(KanjiEntry entry) {
    final source = entry.kunyomi.isNotEmpty ? entry.kunyomi : entry.onyomi;
    if (source.isEmpty) return null;
    return source.first.replaceAll('-', '');
  }

  static const _maxWordLength = 4;

  bool _isKanji(int rune) =>
      (rune >= 0x4E00 && rune <= 0x9FFF) || (rune >= 0x3400 && rune <= 0x4DBF);

  /// Splits [sentence] into [FuriganaSegment]s via greedy longest-match
  /// against this dictionary: at every kanji run, try the longest substring
  /// first and fall back to shorter ones, so a covered compound (今日) is
  /// preferred over annotating its first character alone. Kana, punctuation
  /// and any other non-kanji text pass through as plain, unannotated runs.
  List<FuriganaSegment> segment(String sentence) {
    final runes = sentence.runes.toList();
    final segments = <FuriganaSegment>[];
    var i = 0;
    final plain = StringBuffer();

    void flushPlain() {
      if (plain.isNotEmpty) {
        segments.add(FuriganaSegment(plain.toString()));
        plain.clear();
      }
    }

    while (i < runes.length) {
      if (!_isKanji(runes[i])) {
        plain.writeCharCode(runes[i]);
        i++;
        continue;
      }

      final maxLen = _maxWordLength.clamp(1, runes.length - i);
      String? matchedText;
      String? matchedReading;
      for (var len = maxLen; len >= 1; len--) {
        final candidate = String.fromCharCodes(runes, i, i + len);
        final reading = _words[candidate];
        if (reading != null) {
          matchedText = candidate;
          matchedReading = reading;
          break;
        }
      }

      flushPlain();
      if (matchedText != null) {
        segments.add(FuriganaSegment(matchedText, matchedReading));
        i += matchedText.length;
      } else {
        // No entry at all for this character (rare — the dataset's own
        // kanji list is the source of the fallback map) — show it plain
        // rather than leaving a gap.
        segments.add(FuriganaSegment(String.fromCharCode(runes[i])));
        i++;
      }
    }
    flushPlain();
    return segments;
  }
}
