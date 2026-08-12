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

  test('an onyomi-only kanji shows hiragana furigana, not katakana', () {
    // KanjiEntry.onyomi is stored katakana (万's is ['マン','バン'], no
    // kunyomi at all) — every other reading source in this app (Kotoba
    // words, kunyomi) is hiragana, so falling straight through without
    // converting made 万 (and 78 other onyomi-only kanji found by a full
    // audit) the only katakana furigana anywhere in the app.
    // 万 flanked by が (hiragana) on both sides of the run boundary, so it
    // stays a true isolated single-kanji run rather than getting absorbed
    // into a longer compound like 一万 (which is itself a real Kotoba
    // word and would swallow 万 into a whole-word match instead).
    final segments = dictionary.segment('万が一に備えます。');
    final man = segments.firstWhere((s) => s.text == '万');
    expect(man.reading, 'まん');
    expect(man.reading, isNot('マン'));
  });

  test('known homograph/rendaku words with no safe single reading are '
      'never annotated at all', () {
    // 市場: Kotoba only records いちば (a physical market stall), but real
    // N2/N1 content uses it as しじょう ("market" in the economic sense —
    // 労働市場/市場調査/海外市場). A flat one-reading-per-word map can't
    // pick the right one by context, so — per this class's own "show
    // nothing over something wrong" rule — it's excluded rather than
    // guessed.
    final marketSegments = dictionary.segment('労働市場の変化について。');
    final market = marketSegments.where((s) => s.text.contains('市場'));
    for (final s in market) {
      expect(s.reading, isNull);
    }

    // 気味: きみ is correct standalone ("気味が悪い"), but the very common
    // 〜気味 suffix ("a touch of") always rendaku-voices to ぎみ — this
    // app's own Bunpou entry for that pattern spells it "Kazegimi desu."
    // for 風邪気味, not "Kazekimi desu."
    final gimiSegments = dictionary.segment('最近、風邪気味です。');
    final gimi = gimiSegments.where((s) => s.text.contains('気味'));
    for (final s in gimi) {
      expect(s.reading, isNull);
    }
  });

  test('a kunyomi-with-okurigana reading is trimmed to just the kanji\'s '
      'own portion, not the whole word', () {
    // 遠 -> "とお-い": とお is 遠's own reading, い is okurigana that's
    // already written out as its own character right after 遠 in any real
    // sentence. Showing the whole "とおい" as furigana over 遠 alone would
    // put い twice — once folded into the ruby text, once again as the
    // real character right below it.
    final segments = dictionary.segment('ここから遠いですか。');
    final tooi = segments.firstWhere((s) => s.text == '遠');
    expect(tooi.reading, 'とお');
    expect(tooi.reading, isNot('とおい'));
  });

  test('a kunyomi with no okurigana is unaffected by the hyphen split', () {
    // 山 -> "やま" has no hyphen at all (it's a plain noun, no inflectional
    // tail) — splitting must be a no-op here, not accidentally truncate a
    // real reading that never had an okurigana boundary to begin with.
    final segments = dictionary.segment('山に登ります。');
    final yama = segments.firstWhere((s) => s.text == '山');
    expect(yama.reading, 'やま');
  });

  test('known words whose one recorded reading is wrong for how this app '
      'actually uses them are never annotated at all', () {
    // Each pair here: (sentence, the wrong reading that must never appear).
    // Found by checking real occurrences across Kaiwa/Dokkai/Choukai/Bunpou
    // — see the class-level _excludedWords doc comment for the full
    // reasoning behind each one.
    final cases = <String, String>{
      'それでは、この件はこれで大丈夫ですね。': '件', // くだん, real use needs けん
      '字が汚くてごめんね。': '字', // あざ, real use needs じ
      'コンピューター室を使う時は、飲食禁止です。': '室', // むろ, real use needs しつ
      '女：市の図書館へはどうやって行きますか。': '市', // いち, real use needs し
      'サークルには入りますか。': '入', // い, real use needs はい
      '最近、ギターを弾いていないよね。': '弾', // たま, real use needs ひ
      'たんぱく質を多く摂るようにしているんだ。': '摂', // せつ, real use needs とる
      '敢えて厳しいことを言わせてもらいます。': '敢', // かん, real use needs あえて
      'あまり関わりたくありません。': '関', // せき, real use needs かかわる
      '自分の非を認めて謝ることは、簡単なようで実は勇気がいる行為だ。': '非', // あら, real use needs ひ
    };
    for (final entry in cases.entries) {
      final segments = dictionary.segment(entry.key);
      final matches = segments.where((s) => s.text == entry.value);
      for (final m in matches) {
        expect(
          m.reading,
          isNull,
          reason: '${entry.value} in "${entry.key}" should show no furigana',
        );
      }
    }
  });

  test('known reading-changes-with-usage kanji reported by real users are '
      'never annotated at all', () {
    // 降: kunyomi [お-りる, ふ-る] — "雨/雪が降る" (falling) needs ふ, but the
    // dictionary's first kunyomi is おりる's お, which is only right for
    // "getting off/down". Reported against a real Kotoba cuaca (weather)
    // example sentence.
    final furuSegments = dictionary.segment('雪が降る。');
    for (final s in furuSegments.where((s) => s.text == '降')) {
      expect(s.reading, isNull);
    }

    // 来: kunyomi [く-る, きた-る] — 来る is one of Japanese's two truly
    // irregular verbs, so its reading changes with conjugation: くる but
    // きます/きた, こない/こい. The dictionary's static く is wrong for the
    // very common ます/た-conjugated forms. Reported against real Bunpou
    // も/から example sentences (彼も来ます, 日本から来ました).
    final kuruSegments = dictionary.segment('彼も来ます。');
    for (final s in kuruSegments.where((s) => s.text == '来')) {
      expect(s.reading, isNull);
    }
  });
}
