import '../../data/repositories/kana_repository.dart';

/// Converts kana to romaji by looking each character up in the bundled
/// kana dataset (the same 208-entry table [KanaRepository] serves to
/// FlashcardScreen), rather than a second hardcoded romaji table.
/// Non-kana characters (kanji, punctuation) are left as-is since they
/// aren't in that dataset.
///
/// Two things a per-rune lookup alone can't do, both handled below:
///
/// **Youon is two Unicode characters** (きゃ = き + ゃ), and the dataset
/// stores it as a single two-character map key (see
/// `generate_kana_data.py`'s youon rows) — but converting one rune at a
/// time can never match a two-character key at all, so every youon-
/// containing word silently broke the moment those rows were added: きょう
/// converted to "kiゃう"-shaped garbage instead of "kyou" (き found, ゃ not
/// found at all since ゃ never appears as its own map entry, only inside
/// two-character combos). [convert] now tries the two-character lookup
/// first at every position, falling back to one character only when that
/// fails — the same greedy-longest-match idea `FuriganaDictionary.segment`
/// already uses for compounds, just capped at 2 since youon is the only
/// multi-character unit here.
///
/// **っ/ッ (sokuon) has no romaji of its own at all** — it's a pure
/// modifier meaning "double the next mora's leading consonant"
/// (がっこう -> gakkou, きっぷ -> kippu, いっしょ -> issho). There is
/// nothing to look up for it in a per-character table, so it is
/// deliberately **not** a [KanaRepository] entry (it isn't a real gojuon
/// mora and has no fixed correct-answer romaji, which would make it an
/// odd fit for the flashcard/exam pool that dataset also feeds) — it's
/// handled here by peeking at whatever romaji the *next* position
/// resolves to (itself possibly a youon two-character match) and
/// repeating that romaji's first letter.
class RomajiConverter {
  final KanaRepository _kanaRepository;
  Map<String, String>? _charToRomaji;

  RomajiConverter(this._kanaRepository);

  static const _sokuon = {'っ', 'ッ'};

  Future<Map<String, String>> _ensureMap() async {
    final cached = _charToRomaji;
    if (cached != null) return cached;
    final all = await _kanaRepository.getAll();
    final map = {for (final k in all) k.character: k.romaji};
    _charToRomaji = map;
    return map;
  }

  /// The romaji [runes] would produce starting at [index] — a youon
  /// two-character match if one exists there, otherwise the single
  /// character's own entry, otherwise `null` (nothing in the dataset,
  /// e.g. end of string or a non-kana character). Never consumes/advances
  /// anything itself; [convert] decides how far to move on based on which
  /// branch matched.
  String? _romajiAt(List<int> runes, int index, Map<String, String> map) {
    if (index >= runes.length) return null;
    if (index + 1 < runes.length) {
      final twoChar = String.fromCharCodes(runes, index, index + 2);
      final combined = map[twoChar];
      if (combined != null) return combined;
    }
    return map[String.fromCharCode(runes[index])];
  }

  Future<String> convert(String text) async {
    final map = await _ensureMap();
    final runes = text.runes.toList();
    final buffer = StringBuffer();
    var i = 0;
    while (i < runes.length) {
      final char = String.fromCharCode(runes[i]);
      if (_sokuon.contains(char)) {
        final nextRomaji = _romajiAt(runes, i + 1, map);
        if (nextRomaji != null && nextRomaji.isNotEmpty) {
          buffer.write(nextRomaji[0]);
        }
        i++;
        continue;
      }
      if (i + 1 < runes.length) {
        final twoChar = String.fromCharCodes(runes, i, i + 2);
        final combined = map[twoChar];
        if (combined != null) {
          buffer.write(combined);
          i += 2;
          continue;
        }
      }
      buffer.write(map[char] ?? char);
      i++;
    }
    return buffer.toString();
  }

  Future<String?> romajiForChar(String char) async {
    final map = await _ensureMap();
    return map[char];
  }
}
