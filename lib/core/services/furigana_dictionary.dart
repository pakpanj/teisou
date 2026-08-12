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
  ///
  /// **A kanji that is part of a longer, uncovered compound is never
  /// annotated with its own isolated reading.** The per-kanji fallback
  /// (single-kanji Kotoba entries, then onyomi/kunyomi) only fires for a
  /// kanji that truly stands alone — flanked by non-kanji on both sides.
  /// Applying it to the *first character of an unmatched multi-kanji run*
  /// used to be the actual behaviour, and it produces confidently wrong
  /// readings for real compounds: 三時半 ("3:30", read さんじはん) has no
  /// entry as a whole word, so it fell back to 三(さん)+時(とき)+半(なかば)
  /// — three individually real but jointly nonsensical readings, exactly
  /// the "guessed, silently wrong" outcome this class's own doc comment
  /// says is worse than showing nothing. When no dictionary entry covers
  /// any prefix of a multi-kanji run, the whole run is left unannotated
  /// instead.
  ///
  /// **A leftover character after a partial match must not be re-judged
  /// as freshly "isolated" either.** 時間割 ("class schedule") matches
  /// 時間(じかん) as a covered 2-kanji prefix, leaving a single trailing
  /// 割 — but 割 is still part of the original 3-kanji run, not a
  /// standalone character, so its own kunyomi (わる, the dictionary form
  /// of the verb 割る) is exactly as wrong here as 三時半's per-character
  /// guess was: the real reading in this compound is わり, not わる. Each
  /// contiguous kanji run's isolated/multi-character status is decided
  /// once, from its true start and end, before any matching begins —
  /// never re-derived from wherever a partial match happens to leave off.
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

      // The extent of the *whole* contiguous kanji run, decided once —
      // not re-derived after a prefix of it is consumed by a match.
      var runEnd = i + 1;
      while (runEnd < runes.length && _isKanji(runes[runEnd])) {
        runEnd++;
      }
      final minLen = (runEnd - i) == 1 ? 1 : 2;

      while (i < runEnd) {
        final maxLen = _maxWordLength.clamp(1, runEnd - i);
        String? matchedText;
        String? matchedReading;
        if (maxLen >= minLen) {
          for (var len = maxLen; len >= minLen; len--) {
            final candidate = String.fromCharCodes(runes, i, i + len);
            final reading = _words[candidate];
            if (reading != null) {
              matchedText = candidate;
              matchedReading = reading;
              break;
            }
          }
        }

        if (matchedText != null) {
          flushPlain();
          segments.add(FuriganaSegment(matchedText, matchedReading));
          i += matchedText.length;
        } else if (minLen == 1) {
          // This run is exactly one character long — a genuinely
          // isolated kanji with no dictionary entry (rare — the
          // dataset's own kanji list is the source of the fallback map)
          // — show it plain rather than leaving a gap.
          flushPlain();
          segments.add(FuriganaSegment(String.fromCharCode(runes[i])));
          i++;
        } else {
          // No compound covers this position, and it belongs to a
          // longer run — never decompose per character (see the method
          // doc comment above). Swallow the rest of the run as one
          // plain chunk instead of retrying character by character,
          // since every remaining character would hit this same branch.
          plain.write(String.fromCharCodes(runes, i, runEnd));
          i = runEnd;
        }
      }
    }
    flushPlain();
    return segments;
  }
}
