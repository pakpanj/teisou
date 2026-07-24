import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/models/jlpt_level.dart';
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

  // konsep_umum is the one category still awaiting its English pass (416
  // abstract-noun entries). It is browsable in the app like any other
  // category, so this is a real gap, not an excluded dataset — tighten this
  // test by dropping the filter once that batch lands.
  const pendingEnglishPass = {'konsep_umum'};

  test('every real Kotoba word has an English meaning', () async {
    final categories = await KotobaCategoryRepository().getAll();
    final repo = KotobaRepository();
    final missing = <String>[];
    var total = 0;
    for (final category in categories.where(
        (c) => c.available && !pendingEnglishPass.contains(c.id))) {
      for (final word in await repo.getVocabCategory(category.id)) {
        if (word.placeholder) continue;
        total++;
        if ((word.meaningEn ?? '').isEmpty) missing.add(word.id);
      }
    }
    expect(total, greaterThan(1000));
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
}
