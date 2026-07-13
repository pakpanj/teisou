import '../../data/repositories/kana_repository.dart';

/// Converts kana to romaji by looking each character up in the bundled
/// kana dataset (the same 92-entry table [KanaRepository] serves to
/// FlashcardScreen), rather than a second hardcoded romaji table.
/// Non-kana characters (kanji, punctuation) are left as-is since they
/// aren't in that dataset.
class RomajiConverter {
  final KanaRepository _kanaRepository;
  Map<String, String>? _charToRomaji;

  RomajiConverter(this._kanaRepository);

  Future<Map<String, String>> _ensureMap() async {
    final cached = _charToRomaji;
    if (cached != null) return cached;
    final all = await _kanaRepository.getAll();
    final map = {for (final k in all) k.character: k.romaji};
    _charToRomaji = map;
    return map;
  }

  Future<String> convert(String text) async {
    final map = await _ensureMap();
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(map[char] ?? char);
    }
    return buffer.toString();
  }

  Future<String?> romajiForChar(String char) async {
    final map = await _ensureMap();
    return map[char];
  }
}
