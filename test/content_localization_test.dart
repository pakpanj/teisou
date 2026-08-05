import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/app_language.dart';
import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/data/models/speech_register.dart';
import 'package:kana_master/data/repositories/bunpou_repository.dart';
import 'package:kana_master/data/repositories/choukai_repository.dart';
import 'package:kana_master/data/repositories/dokkai_repository.dart';
import 'package:kana_master/data/repositories/dictionary_repository.dart';
import 'package:kana_master/data/repositories/kaiwa_category_repository.dart';
import 'package:kana_master/data/repositories/kanji_repository.dart';
import 'package:kana_master/data/repositories/kotoba_category_repository.dart';
import 'package:kana_master/data/repositories/kotoba_repository.dart';
import 'package:kana_master/data/repositories/particle_category_repository.dart';
import 'package:kana_master/data/repositories/particle_repository.dart';

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

  test('every Kotoba word has an English example translation', () async {
    final categories = await KotobaCategoryRepository().getAll();
    final repo = KotobaRepository();
    final missing = <String>[];
    var total = 0;
    for (final category in categories.where((c) => c.available)) {
      for (final word in await repo.getVocabCategory(category.id)) {
        if (word.placeholder) continue;
        for (final se in word.sentenceExamples) {
          total++;
          if ((se.translationEn ?? '').isEmpty) missing.add(word.id);
        }
      }
    }
    expect(total, greaterThan(1600));
    expect(missing.take(10).toList(), isEmpty,
        reason: '${missing.length} Kotoba examples have no translationEn — '
            'add them to scripts/kotoba_example_translation_en.py and run '
            'the applier');

    final unagi = (await repo.getVocabCategory('ikan'))
        .firstWhere((w) => w.id.endsWith('_unagi'));
    expect(
        unagi.sentenceExamples.first
            .localizedTranslation(AppLanguage.indonesian),
        'Di musim panas, orang makan belut.');
    expect(
        unagi.sentenceExamples.first
            .localizedTranslation(AppLanguage.english),
        'In summer, people eat eel.');
  });

  test('every dictionary example has an English translation', () async {
    final words = await DictionaryRepository().getAll();
    final missing = words
        .where((w) => (w.example.translationEn ?? '').isEmpty)
        .toList();
    expect(
      missing.map((w) => w.id).take(10).toList(),
      isEmpty,
      reason: '${missing.length} dictionary examples have no translationEn '
          '— add them to scripts/dictionary_example_translation_en.py and '
          'run the applier',
    );

    final taberu = words.firstWhere((w) => w.id == 'dict_00001');
    expect(taberu.example.localizedTranslation(AppLanguage.indonesian),
        'Saya makan sarapan setiap hari.');
    expect(taberu.example.localizedTranslation(AppLanguage.english),
        'I eat breakfast every day.');
  });

  test('all kanji word examples have English glosses', () async {
    final entries = await KanjiRepository().getAll();
    final missing = <String>[];
    for (final entry in entries) {
      for (final example in entry.wordExamples) {
        if ((example.meaningEn ?? '').isEmpty) {
          missing.add('${entry.character}/${example.word}');
        }
      }
    }
    expect(missing.take(10).toList(), isEmpty,
        reason: '${missing.length} word examples have no meaningEn — '
            'add them to scripts/kanji_word_meaning_en.py and run the applier');

    final yuki = entries.firstWhere((e) => e.character == '雪');
    expect(yuki.wordExamples.first.localizedMeaning(AppLanguage.indonesian),
        'salju');
    expect(yuki.wordExamples.first.localizedMeaning(AppLanguage.english), 'snow');
  });

  test('every particle field has an English translation', () async {
    final entries = await ParticleRepository().getAll();
    expect(entries, isNotEmpty);

    final missingOverview =
        entries.where((e) => (e.overviewEn ?? '').isEmpty).toList();
    expect(missingOverview.map((e) => e.id).toList(), isEmpty,
        reason: '${missingOverview.length} particles have no overviewEn — '
            'add them to scripts/particle_meaning_en.py and run the applier');

    final missingFunctionFields = <String>[];
    final missingExamples = <String>[];
    for (final entry in entries) {
      for (final fn in entry.functions) {
        if ((fn.titleEn ?? '').isEmpty || (fn.explanationEn ?? '').isEmpty) {
          missingFunctionFields.add('${entry.id}/${fn.id}');
        }
        for (final se in fn.sentenceExamples) {
          if ((se.translationEn ?? '').isEmpty) {
            missingExamples.add('${entry.id}/${fn.id}/se');
          }
        }
        for (final ce in fn.clozeExamples) {
          if ((ce.translationEn ?? '').isEmpty) {
            missingExamples.add('${entry.id}/${fn.id}/cloze');
          }
        }
      }
    }
    expect(missingFunctionFields, isEmpty,
        reason: '${missingFunctionFields.length} functions have no '
            'titleEn/explanationEn — add them to '
            'scripts/particle_meaning_en.py and run the applier');
    expect(missingExamples, isEmpty,
        reason: '${missingExamples.length} examples have no translationEn — '
            'add them to scripts/particle_meaning_en.py and run the applier');

    final ga = entries.firstWhere((e) => e.id == 'particle_ga');
    expect(ga.localizedOverview(AppLanguage.indonesian),
        contains('menandai subjek'));
    expect(ga.localizedOverview(AppLanguage.english), contains('marks the'));
    final gaSubject =
        ga.functions.firstWhere((fn) => fn.id == 'ga_subject');
    expect(gaSubject.localizedTitle(AppLanguage.english),
        contains('subject'));
  });

  test('every Bunpou field has an English translation', () async {
    final entries = await BunpouRepository().getAll();
    expect(entries, isNotEmpty);
    expect(entries.where((e) => e.placeholder).toList(), isEmpty);

    final missingProse = <String>[];
    final missingExamples = <String>[];
    for (final entry in entries) {
      if ((entry.meaningEn ?? '').isEmpty ||
          (entry.formationEn ?? '').isEmpty ||
          (entry.usageNotesEn ?? '').isEmpty) {
        missingProse.add(entry.id);
      }
      for (var i = 0; i < entry.sentenceExamples.length; i++) {
        if ((entry.sentenceExamples[i].translationEn ?? '').isEmpty) {
          missingExamples.add('${entry.id}/se$i');
        }
      }
    }
    expect(missingProse.take(10).toList(), isEmpty,
        reason: '${missingProse.length} Bunpou entries have no '
            'meaningEn/formationEn/usageNotesEn — add them to '
            'scripts/bunpou_meaning_en.py and run the applier');
    expect(missingExamples.take(10).toList(), isEmpty,
        reason: '${missingExamples.length} Bunpou examples have no '
            'translationEn — add them to scripts/bunpou_meaning_en.py '
            'and run the applier');

    final teForm = entries.firstWhere((e) => e.id == 'bunpou_te_kudasai');
    expect(teForm.localizedMeaning(AppLanguage.indonesian),
        contains('Tolong'));
    expect(
        teForm.localizedMeaning(AppLanguage.english), contains('Please'));
    expect(teForm.localizedFormation(AppLanguage.english),
        contains('te-form'));
  });

  test('every kanji sentence example has an English translation', () async {
    final entries = await KanjiRepository().getAll();
    expect(entries, isNotEmpty);

    final missing = <String>[];
    for (final entry in entries) {
      for (var i = 0; i < entry.sentenceExamples.length; i++) {
        if ((entry.sentenceExamples[i].translationEn ?? '').isEmpty) {
          missing.add('${entry.character}/se$i');
        }
      }
    }
    expect(missing.take(10).toList(), isEmpty,
        reason: '${missing.length} kanji sentence examples have no '
            'translationEn — add them to '
            'scripts/kanji_sentence_translation_en.py and run the applier');

    final yuki = entries.firstWhere((e) => e.character == '雪');
    expect(yuki.sentenceExamples.first.localizedTranslation(AppLanguage.english),
        isNotEmpty);
    expect(yuki.sentenceExamples.first.localizedTranslation(AppLanguage.english),
        isNot(yuki.sentenceExamples.first.translation));
  });

  test('every Kotoba register note has an English translation', () async {
    final categories = await KotobaCategoryRepository().getAll();
    final repo = KotobaRepository();
    final missing = <String>[];
    var total = 0;
    for (final category in categories.where((c) => c.available)) {
      for (final word in await repo.getVocabCategory(category.id)) {
        if (word.placeholder) continue;
        for (final key in word.registers.keys) {
          total++;
          if ((word.registersEn?[key] ?? '').isEmpty) missing.add(word.id);
        }
      }
    }
    expect(total, greaterThan(5000));
    expect(missing.take(10).toList(), isEmpty,
        reason: '${missing.length} Kotoba register fields have no '
            'registersEn — add them to scripts/kotoba_registers_note_en.py '
            'and run the applier');

    final maguro = (await repo.getVocabCategory('ikan'))
        .firstWhere((w) => w.reading == 'まぐろ');
    expect(
        maguro.localizedRegisters(AppLanguage.indonesian)[SpeechRegister.keigo],
        contains('tidak ada bentuk keigo khusus'));
    expect(
        maguro.localizedRegisters(AppLanguage.english)[SpeechRegister.keigo],
        contains('no special keigo form'));
  });

  test('Particle and Kaiwa category names have English translations',
      () async {
    final particleCategories = await ParticleCategoryRepository().getAll();
    expect(particleCategories, isNotEmpty);
    for (final category in particleCategories) {
      expect(category.nameEn, isNotNull, reason: category.id);
      expect(category.nameEn, isNotEmpty, reason: category.id);
    }
    final kasus = particleCategories.firstWhere((c) => c.id == 'kasus');
    expect(kasus.localizedName(AppLanguage.indonesian), 'Partikel Kasus');
    expect(kasus.localizedName(AppLanguage.english), 'Case Particles');

    final kaiwaCategories = await KaiwaCategoryRepository().getAll();
    expect(kaiwaCategories, isNotEmpty);
    final missingKaiwaNames = <String>[];
    for (final category in kaiwaCategories) {
      if ((category.nameEn ?? '').isEmpty) missingKaiwaNames.add(category.id);
    }
    expect(missingKaiwaNames, isEmpty);
    final perkenalan =
        kaiwaCategories.firstWhere((c) => c.id == 'perkenalan');
    expect(perkenalan.localizedName(AppLanguage.indonesian), 'Perkenalan');
    expect(perkenalan.localizedName(AppLanguage.english), 'Introductions');
  });

  // Choukai and Dokkai were the two modules this file never covered, and
  // that gap cost real work: `generate_dokkai_seed.py` rewrites
  // `dokkai_data.json` from scratch, so a regeneration silently dropped
  // all 1,000 already-authored English fields, and nothing failed. They
  // were absent from the shipped asset until an on-device pass happened
  // to show an English screen wrapped around an Indonesian passage title.
  // Re-run `apply_dokkai_meaning_en.py` / `apply_choukai_meaning_en.py`
  // after any regeneration; these tests make forgetting loud.
  test('every Dokkai passage has an English title and translation', () async {
    final passages = await DokkaiRepository().getAll();
    expect(passages, isNotEmpty);

    final missing = <String>[];
    for (final p in passages) {
      if ((p.titleEn ?? '').trim().isEmpty) missing.add('${p.id}|title');
      if ((p.passageTranslationEn ?? '').trim().isEmpty) {
        missing.add('${p.id}|passageTranslation');
      }
    }
    expect(missing, isEmpty,
        reason: '${missing.length} field(s) lost — run '
            'python scripts/apply_dokkai_meaning_en.py');

    final first = passages.firstWhere((p) => p.id == 'dokkai_surat_sahabat_pena');
    expect(first.localizedTitle(AppLanguage.indonesian), 'Surat dari Sahabat Pena');
    expect(first.localizedTitle(AppLanguage.english), 'A Letter from a Pen Pal');
  });

  test('every Choukai clip has an English title and script translation',
      () async {
    final clips = await ChoukaiRepository().getAll();
    expect(clips, isNotEmpty);

    final missing = <String>[];
    for (final c in clips) {
      if ((c.titleEn ?? '').trim().isEmpty) missing.add('${c.id}|title');
      if ((c.audioTranslationEn ?? '').trim().isEmpty) {
        missing.add('${c.id}|audioTranslation');
      }
    }
    expect(missing, isEmpty,
        reason: '${missing.length} field(s) lost — run '
            'python scripts/apply_choukai_meaning_en.py');

    final first = clips.firstWhere((c) => c.id == 'choukai_n5_jam_berapa');
    expect(first.localizedTitle(AppLanguage.indonesian), 'Jam Berapa Sekarang');
    expect(first.localizedTitle(AppLanguage.english), 'What Time Is It Now');
  });

  test('no Indonesian is left inside a Choukai or Dokkai English field',
      () async {
    // A field can be present and still be a copy-paste of the Indonesian.
    // These words do not occur in ordinary English prose.
    final indonesian = RegExp(
      r'\b(yang|dengan|untuk|tidak|adalah|karena|sudah|akan|dari|pada|'
      r'saya|kami|mereka|bisa|harus|lebih|juga)\b',
      caseSensitive: false,
    );

    final leaks = <String>[];
    for (final c in await ChoukaiRepository().getAll()) {
      if (indonesian.hasMatch(c.titleEn ?? '')) leaks.add('${c.id}|title');
      if (indonesian.hasMatch(c.audioTranslationEn ?? '')) {
        leaks.add('${c.id}|audioTranslation');
      }
    }
    for (final p in await DokkaiRepository().getAll()) {
      if (indonesian.hasMatch(p.titleEn ?? '')) leaks.add('${p.id}|title');
      if (indonesian.hasMatch(p.passageTranslationEn ?? '')) {
        leaks.add('${p.id}|passageTranslation');
      }
    }
    expect(leaks, isEmpty, reason: 'Indonesian text in an English field');
  });
}
