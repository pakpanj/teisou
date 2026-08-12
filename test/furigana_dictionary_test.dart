import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/furigana_dictionary.dart';
import 'package:kana_master/data/repositories/kanji_repository.dart';
import 'package:kana_master/data/repositories/kotoba_repository.dart';

/// Regression coverage for a real bug reported against the app: 三時半
/// ("3:30", read さんじはん as one word) rendered furigana さんときなかば —
/// 三's own reading (さん, correct in isolation) glued to 時's kunyomi
/// (とき) and 半's kunyomi (なかば), because the dictionary had no entry
/// for the compound and fell back to guessing each kanji's own reading
/// one character at a time. That guess is confidently wrong for almost
/// any real compound outside the curated word list, which is exactly the
/// outcome [FuriganaDictionary]'s own doc comment says must never happen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FuriganaDictionary dictionary;

  setUpAll(() async {
    dictionary = await FuriganaDictionary.build(
      kotoba: KotobaRepository(),
      kanji: KanjiRepository(),
    );
  });

  test('an uncovered multi-kanji compound is shown plain, not decomposed '
      'per-character', () {
    final segments = dictionary.segment('三時半に行きます。');

    // The whole 三時半 run must come back inside an unannotated plain
    // segment — never split into three individually-"correct" but
    // jointly wrong single-kanji readings.
    final compound = segments.firstWhere((s) => s.text.contains('三時半'));
    expect(compound.reading, isNull);

    // In particular, the exact wrong reading from the bug report must
    // never appear anywhere in the segmented output.
    final allReadings = segments.map((s) => s.reading).whereType<String>();
    expect(allReadings, isNot(contains('さんときなかば')));
    expect(allReadings, isNot(contains('とき')));
    expect(allReadings, isNot(contains('なかば')));
  });

  test('a genuinely isolated single kanji still gets its own reading', () {
    // 猫 (cat) flanked by kana on both sides — a real standalone
    // character, not part of a longer uncovered compound, so the
    // single-kanji fallback is still allowed to apply here.
    final segments = dictionary.segment('猫がいます。');
    final cat = segments.firstWhere((s) => s.text == '猫');
    expect(cat.reading, isNotEmpty);
  });

  test('a compound that really is in the dictionary still gets its real '
      'reading, not a per-character guess', () {
    // 今日 (today) is a common word almost certainly present as a Kotoba
    // entry; if it ever stops being covered this test should fail loudly
    // rather than silently accept a wrong per-character fallback.
    final segments = dictionary.segment('今日は晴れです。');
    final today = segments.firstWhere((s) => s.text == '今日');
    expect(today.reading, isNotNull);
    expect(today.reading, isNot('こん日'));
  });

  test('an uncovered run never leaves a gap — the original text always '
      'survives even without a reading', () {
    final segments = dictionary.segment('三時半に行きます。');
    final reconstructed = segments.map((s) => s.text).join();
    expect(reconstructed, '三時半に行きます。');
  });

  test('a leftover character after a matched prefix is not re-judged as '
      'freshly isolated', () {
    // 時間割 ("class schedule") matches 時間 as a covered 2-kanji prefix,
    // leaving a single trailing 割 — but 割 is still part of the
    // original 3-kanji run, not a standalone character. Its own
    // kunyomi (わる, the dictionary form of the verb 割る) is wrong here;
    // the real reading in this compound is わり. This reproduces a bug
    // where the run's isolated/multi-character status was re-derived
    // after the 時間 prefix was consumed, so 割 alone (now flanked by
    // non-kanji on its right) was wrongly treated as freshly isolated
    // and given its own guessed reading.
    final segments = dictionary.segment('時間割は要りません。');

    final allReadings = segments.map((s) => s.reading).whereType<String>();
    expect(allReadings, isNot(contains('わる')));

    // 割 must come back as part of an unannotated plain run, never as
    // its own annotated segment.
    final soleWariSegment = segments.where((s) => s.text == '割');
    expect(soleWariSegment, isEmpty);
  });
}
