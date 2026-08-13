import '../../data/models/kana_character.dart';
import '../../data/models/kana_type.dart';

/// The typing logic behind [KanaKeyboard] — deliberately separated from
/// the widget so it's directly unit-testable without pumping a widget
/// tree, and so it stays reusable if a future non-keyboard input surface
/// ever needs the same rules.
///
/// Tenten/maru/small-ya-yu-yo are **modifiers on the last character
/// already typed**, not keys that produce a character of their own — か
/// then ゛ turns the buffer's trailing か into が, it doesn't append が as
/// a second character. This mirrors how real Japanese keyboards work,
/// and is why the main board only needs the 46 base characters rather
/// than all 104.
///
/// Every mapping here is **derived from the bundled kana dataset's own
/// `row`/`column` scheme** (`generate_kana_data.py`), not a second
/// hand-written list — か and が are both real entries at the same
/// `column` in two different rows (1 and 11), and youon's base
/// characters are recoverable as the first rune of every youon entry's
/// own `character` field (row 16-26). Deriving both this way means there
/// is only ever one place that knows "what row is what" — the dataset
/// itself — instead of a second copy that could quietly drift from it.
class KanaKeyboardInput {
  final Map<String, String> _tenten;
  final Map<String, String> _maru;
  final Set<String> _youonBases;

  KanaKeyboardInput._(this._tenten, this._maru, this._youonBases);

  /// Row pairs (base row -> voiced row) taken straight from the row
  /// numbers `generate_kana_data.py` assigns: 1=か 2=さ 3=た 5=は (base),
  /// 11=が 12=ざ 13=だ 14=ば (dakuten), 15=ぱ (handakuten, は only).
  static const _tentenRowPairs = {1: 11, 2: 12, 3: 13, 5: 14};
  static const _maruRowPairs = {5: 15};

  factory KanaKeyboardInput.fromAll(List<KanaCharacter> allKana) {
    final hiragana = allKana.where((k) => k.type == KanaType.hiragana);
    final byRowColumn = <(int, int), String>{
      for (final k in hiragana) (k.row, k.column): k.character,
    };

    final tenten = <String, String>{};
    _tentenRowPairs.forEach((baseRow, voicedRow) {
      for (final entry in byRowColumn.entries) {
        final (row, column) = entry.key;
        if (row != baseRow) continue;
        final voiced = byRowColumn[(voicedRow, column)];
        if (voiced != null) tenten[entry.value] = voiced;
      }
    });

    final maru = <String, String>{};
    _maruRowPairs.forEach((baseRow, voicedRow) {
      for (final entry in byRowColumn.entries) {
        final (row, column) = entry.key;
        if (row != baseRow) continue;
        final voiced = byRowColumn[(voicedRow, column)];
        if (voiced != null) maru[entry.value] = voiced;
      }
    });

    // Youon rows (16-26) store the full two-rune combo (きゃ) as their
    // `character` — the base this modifier applies to is just that
    // combo's own first rune.
    final youonBases = <String>{
      for (final k in hiragana)
        if (k.row >= 16 && k.row <= 26) String.fromCharCode(k.character.runes.first),
    };

    return KanaKeyboardInput._(tenten, maru, youonBases);
  }

  String _lastRune(String value) => String.fromCharCode(value.runes.last);

  String _dropLastRune(String value) {
    final runes = value.runes.toList();
    return String.fromCharCodes(runes.sublist(0, runes.length - 1));
  }

  /// `null` when [value] is empty or its last character has no tenten
  /// form — callers use that to disable the button, not just to skip
  /// applying it.
  String? applyTenten(String value) {
    if (value.isEmpty) return null;
    final mapped = _tenten[_lastRune(value)];
    if (mapped == null) return null;
    return _dropLastRune(value) + mapped;
  }

  String? applyMaru(String value) {
    if (value.isEmpty) return null;
    final mapped = _maru[_lastRune(value)];
    if (mapped == null) return null;
    return _dropLastRune(value) + mapped;
  }

  /// Appends [smallKana] (ゃ, ゅ, or よ) after the last character —
  /// `null` (button disabled) unless that character is one of the 11
  /// bases that actually forms youon.
  String? applySmallY(String value, String smallKana) {
    if (value.isEmpty) return null;
    if (!_youonBases.contains(_lastRune(value))) return null;
    return value + smallKana;
  }

  /// っ has no character it depends on — it only matters for whatever
  /// comes *after* it, so unlike the others this is never disabled.
  String applySokuon(String value) => '$valueっ';

  String backspace(String value) => value.isEmpty ? value : _dropLastRune(value);
}
