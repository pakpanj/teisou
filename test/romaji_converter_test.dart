import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/romaji_converter.dart';
import 'package:kana_master/data/repositories/kana_repository.dart';

/// Regression coverage for two real gaps found while closing out the
/// sokuon (っ/ッ) gap flagged in NOTES_CARD_GAME_MODE.md:
///
/// 1. Youon (きゃ, しゃ, ...) is stored as a two-character map key, but
///    converting one rune at a time can never match a two-character key
///    at all — every youon-containing word silently broke the moment
///    those dataset rows were added.
/// 2. っ/ッ has no romaji of its own — it's deliberately not a dataset
///    entry — so it needs its own doubling logic rather than a lookup.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RomajiConverter converter;

  setUpAll(() async {
    converter = RomajiConverter(KanaRepository());
  });

  test('plain base kana still convert one-to-one, unaffected by the youon/'
      'sokuon changes', () async {
    expect(await converter.convert('あさ'), 'asa');
    expect(await converter.convert('わたし'), 'watashi');
  });

  test('youon converts as one mora, not per-character garbage', () async {
    expect(await converter.convert('きょう'), 'kyou');
    expect(await converter.convert('しゃしん'), 'shashin');
    expect(await converter.convert('ちゃいろ'), 'chairo');
    expect(await converter.convert('ぎょうざ'), 'gyouza');
    expect(await converter.convert('じゃがいも'), 'jagaimo');
  });

  test('sokuon doubles the following mora\'s leading consonant', () async {
    expect(await converter.convert('がっこう'), 'gakkou');
    expect(await converter.convert('きっぷ'), 'kippu');
    expect(await converter.convert('けっこん'), 'kekkon');
    expect(await converter.convert('ざっし'), 'zasshi');
  });

  test('sokuon followed by youon resolves through the two-character match, '
      'not the broken single-character one', () async {
    // いっしょ ("together") — っ + しょ (youon), not っ + し + ょ.
    expect(await converter.convert('いっしょ'), 'issho');
  });

  test('katakana sokuon (ッ) is handled the same way as hiragana っ',
      () async {
    expect(await converter.convert('ポケット'), 'poketto');
    // ー (chōonpu, the long-vowel mark) isn't in the kana dataset at all
    // — a separate, not-yet-addressed gap — so this deliberately avoids
    // it and sticks to a word sokuon+youon alone can fully resolve.
    expect(await converter.convert('ロケット'), 'roketto');
  });

  test('sokuon at the end of a string is dropped rather than crashing',
      () async {
    expect(await converter.convert('あっ'), 'a');
  });

  test('a character with no dataset entry (kanji, punctuation) passes '
      'through unchanged, same as before this change', () async {
    expect(await converter.convert('学校'), '学校');
    expect(await converter.convert('あ！'), 'a！');
  });
}
