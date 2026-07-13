/// Matches text containing at least one hiragana (U+3040-309F), katakana
/// (U+30A0-30FF), or kanji (U+4E00-9FFF) character.
final _japaneseCharPattern = RegExp(r'[぀-ゟ゠-ヿ一-鿿]');

bool containsJapanese(String text) => _japaneseCharPattern.hasMatch(text);

bool isSingleKanji(String text) {
  if (text.length != 1) return false;
  final code = text.codeUnitAt(0);
  return code >= 0x4E00 && code <= 0x9FFF;
}
