import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/data/repositories/dictionary_repository.dart';
import 'package:kana_master/data/repositories/kanji_repository.dart';
import 'package:kana_master/data/repositories/kotoba_category_repository.dart';
import 'package:kana_master/data/repositories/kotoba_repository.dart';

/// Guards the *content* side of the language toggle, as opposed to
/// `module_localization_test.dart`, which covers UI chrome.
///
/// The kanji cases specifically protect the `meaningsEn` split produced by
/// `scripts/split_kanji_meanings_en.py`: `generate_kanji_seed.py` writes
/// Indonesian and English glosses into one `meanings` list and knows
/// nothing about `meaningsEn`, so regenerating the dataset without re-running
/// the splitter would silently put the app back to showing both languages at
/// once. These assertions fail loudly if that happens.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every kanji has its English glosses split out of meanings', () async {
    final entries = await KanjiRepository().getAll();
    expect(entries, isNotEmpty);

    final missing = entries.where((e) => e.meaningsEn.isEmpty).toList();
    expect(
      missing.map((e) => e.character).take(10).toList(),
      isEmpty,
      reason: '${missing.length} kanji lost their English glosses — re-run '
          'python scripts/split_kanji_meanings_en.py',
    );

    final asa = entries.firstWhere((e) => e.character == '朝');
    expect(asa.meanings, ['pagi']);
    expect(asa.meaningsEn, ['morning']);
    expect(asa.localizedMeanings(AppLanguage.indonesian), ['pagi']);
    expect(asa.localizedMeanings(AppLanguage.english), ['morning']);
    expect(asa.localizedMeaning(AppLanguage.english), 'morning');
  });

  test('no Indonesian meaning leaks into the English kanji glosses', () async {
    final entries = await KanjiRepository().getAll();
    // Function words that only ever appear in Indonesian glosses. A hit on
    // the English side means the split put an Indonesian item in the wrong
    // list for that entry.
    const indonesianOnly = {
      'yang', 'dengan', 'untuk', 'dari', 'tidak', 'orang', 'buah', 'pohon',
      'burung', 'sesuatu', 'suatu', 'dalam', 'atau', 'nama',
    };
    final leaked = <String>[];
    for (final e in entries) {
      for (final gloss in e.meaningsEn) {
        final words = gloss.toLowerCase().split(RegExp(r'[^a-z]+'));
        if (words.any(indonesianOnly.contains)) {
          leaked.add('${e.character}: $gloss');
        }
      }
    }
    expect(leaked, isEmpty);
  });

  test('every real Kotoba word has an English meaning', () async {
    final categories = await KotobaCategoryRepository().getAll();
    final repo = KotobaRepository();
    final missing = <String>[];
    var total = 0;
    for (final category in categories.where((c) => c.available)) {
      for (final word in await repo.getVocabCategory(category.id)) {
        if (word.placeholder) continue;
        total++;
        if ((word.meaningEn ?? '').isEmpty) missing.add(word.id);
      }
    }
    expect(total, greaterThan(1600));
    expect(missing, isEmpty,
        reason: '${missing.length} words still have no meaningEn — add them '
            'to scripts/kotoba_meaning_en.py and run the applier');
  });

  test('Kotoba localizedMeaning follows the language toggle', () async {
    final words = await KotobaRepository().getVocabCategory('ikan');
    // 'belut' vs 'eel' — a word whose two languages genuinely differ, unlike
    // maguro, where the Indonesian gloss is also "tuna".
    final unagi = words.firstWhere((w) => w.id.endsWith('_unagi'));
    expect(unagi.localizedMeaning(AppLanguage.indonesian), 'belut');
    expect(unagi.localizedMeaning(AppLanguage.english), 'eel');
    expect(unagi.jlptLevel, isA<JlptLevel>());
  });

  test('every dictionary word has an English meaning', () async {
    final words = await DictionaryRepository().getAll();
    expect(words.length, greaterThan(900));
    final missing = words.where((w) => (w.meaningEn ?? '').isEmpty).toList();
    expect(
      missing.map((w) => w.id).take(10).toList(),
      isEmpty,
      reason: '${missing.length} dictionary words have no meaningEn — add them '
          'to scripts/dictionary_meaning_en.py and run the applier',
    );

    final taberu = words.firstWhere((w) => w.id == 'dict_00001');
    expect(taberu.localizedMeaning(AppLanguage.indonesian), 'makan');
    expect(taberu.localizedMeaning(AppLanguage.english), 'to eat');
  });

  test('dictionary search matches English glosses too', () async {
    final repo = DictionaryRepository();
    final byEnglish = await repo.search('to eat');
    expect(byEnglish.map((w) => w.id), contains('dict_00001'));
    final byIndonesian = await repo.search('makan');
    expect(byIndonesian.map((w) => w.id), contains('dict_00001'));
  });

  test('N5-N3 kanji word examples have English glosses', () async {
    final entries = await KanjiRepository().getAll();
    const covered = {JlptLevel.n5, JlptLevel.n4, JlptLevel.n3};
    final done = entries.where((e) => covered.contains(e.jlptLevel));
    final missing = <String>[];
    for (final entry in done) {
      for (final example in entry.wordExamples) {
        if ((example.meaningEn ?? '').isEmpty) {
          missing.add('${entry.character}/${example.word}');
        }
      }
    }
    expect(missing.take(10).toList(), isEmpty,
        reason: '${missing.length} N5-N3 word examples have no meaningEn — '
            'add them to scripts/kanji_word_meaning_en.py and run the applier');

    final yuki = entries.firstWhere((e) => e.character == '雪');
    expect(yuki.wordExamples.first.localizedMeaning(AppLanguage.indonesian),
        'salju');
    expect(yuki.wordExamples.first.localizedMeaning(AppLanguage.english), 'snow');
  });
}
