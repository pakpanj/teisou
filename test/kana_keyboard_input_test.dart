import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/kana_keyboard_input.dart';
import 'package:kana_master/data/repositories/kana_repository.dart';

/// Every mapping this class uses is derived from the real bundled kana
/// dataset's row/column scheme, not a second hand-written table — these
/// tests run against that real data, the same way furigana_dictionary_test
/// and romaji_converter_test do, so a mistake in the dataset's row
/// numbering would show up here too, not just in whichever screen
/// eventually uses this.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KanaKeyboardInput input;

  setUpAll(() async {
    final all = await KanaRepository().getAll();
    input = KanaKeyboardInput.fromAll(all);
  });

  group('tenten', () {
    test('か -> が, さ -> ざ, た -> だ, は -> ば', () {
      expect(input.applyTenten('か'), 'が');
      expect(input.applyTenten('さ'), 'ざ');
      expect(input.applyTenten('た'), 'だ');
      expect(input.applyTenten('は'), 'ば');
    });

    test('only replaces the trailing character, keeps everything before it',
        () {
      expect(input.applyTenten('がっこ'), 'がっご');
    });

    test('null (disabled) for a character with no tenten form', () {
      expect(input.applyTenten('あ'), isNull);
      expect(input.applyTenten('な'), isNull);
    });

    test('null on an empty buffer', () {
      expect(input.applyTenten(''), isNull);
    });
  });

  group('maru', () {
    test('only は-row has a maru form', () {
      expect(input.applyMaru('は'), 'ぱ');
      expect(input.applyMaru('ひ'), 'ぴ');
    });

    test('null (disabled) for a row that has no maru form, even か which '
        'does have tenten', () {
      expect(input.applyMaru('か'), isNull);
    });
  });

  group('small ya/yu/yo', () {
    test('appends after an eligible base, does not replace it', () {
      expect(input.applySmallY('き', 'ゃ'), 'きゃ');
      expect(input.applySmallY('じ', 'ゅ'), 'じゅ');
    });

    test('null (disabled) for a base that never forms youon', () {
      expect(input.applySmallY('あ', 'ゃ'), isNull);
      expect(input.applySmallY('な', 'ゃ'), isNull);
    });

    test('works after a longer buffer, checking only the trailing '
        'character', () {
      expect(input.applySmallY('がくせいひ', 'ゃ'), 'がくせいひゃ');
    });
  });

  group('sokuon', () {
    test('always appends っ, never disabled', () {
      expect(input.applySokuon('が'), 'がっ');
      expect(input.applySokuon(''), 'っ');
    });
  });

  group('backspace', () {
    test('drops exactly the last character', () {
      expect(input.backspace('がくせい'), 'がくせ');
    });

    test('is a no-op on an empty buffer, not an error', () {
      expect(input.backspace(''), '');
    });
  });
}
