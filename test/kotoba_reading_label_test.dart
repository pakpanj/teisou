import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/dictionary_word.dart';
import 'package:kana_master/data/models/jlpt_level.dart';
import 'package:kana_master/data/models/kotoba_entry.dart';

/// Rows that would otherwise print the same word twice.
///
/// A kana-only word *is* its own reading, so `けしゴム` over `けしゴム`
/// reads as a rendering bug rather than as a reading — and it is not a
/// handful of entries, it is 150 of the 1682 in the dataset.
void main() {
  KotobaEntry entryWith({
    String? kanji,
    required String word,
    required String reading,
  }) {
    return KotobaEntry(
      id: 'x',
      word: word,
      kanji: kanji,
      reading: reading,
      romaji: 'x',
      meaning: 'x',
      jlptLevel: JlptLevel.n5,
      category: 'x',
      wordType: 'noun',
      registers: const {},
      sentenceExamples: const [],
    );
  }

  test('a kana-only word does not repeat itself as its own reading', () {
    final entry = entryWith(word: 'けしゴム', reading: 'けしゴム');
    expect(entry.displayWord, 'けしゴム');
    expect(entry.readingIfDifferent, isNull);
  });

  test('a word written in kanji still shows how it is read', () {
    final entry = entryWith(kanji: '革新', word: 'かくしん', reading: 'かくしん');
    expect(entry.displayWord, '革新');
    expect(entry.readingIfDifferent, 'かくしん');
  });

  test('the dictionary follows the same rule', () {
    const kana = DictionaryWord(
      id: 'a',
      reading: 'ノート',
      meaning: 'buku',
      example: DictionaryExample(japanese: '', translation: ''),
    );
    const kanji = DictionaryWord(
      id: 'b',
      kanji: '本',
      reading: 'ほん',
      meaning: 'buku',
      example: DictionaryExample(japanese: '', translation: ''),
    );
    expect(kana.readingIfDifferent, isNull);
    expect(kanji.readingIfDifferent, 'ほん');
  });

  test('every screen that shows a reading checks it is worth showing', () {
    // A source check, because the rows are spread over three screens and
    // the fault is invisible unless the entry happens to be kana-only —
    // which is exactly how it shipped. Asserting on the absence of the
    // old string would pass the moment someone reformatted it; asserting
    // the check is present is what actually holds.
    const screens = [
      'lib/features/kotoba/kotoba_category_screen.dart',
      'lib/features/search/search_screen.dart',
      'lib/features/search/kotoba_detail_screen.dart',
    ];
    for (final path in screens) {
      final source = File(path).readAsStringSync();
      if (!source.contains('.reading')) continue;
      expect(
        source,
        contains('readingIfDifferent'),
        reason:
            '$path prints a reading without checking it differs from '
            'the word above it',
      );
    }
  });

  test('the dataset really does contain kana-only entries', () {
    // Guards the rule against being deleted as theoretical.
    final files = Directory('assets/data/kotoba')
        .listSync()
        .whereType<File>()
        .where((f) => !f.path.contains('_categories'));
    var sameAsReading = 0;
    for (final file in files) {
      final list = jsonDecode(file.readAsStringSync()) as List;
      for (final raw in list) {
        final map = raw as Map<String, dynamic>;
        final display = (map['kanji'] ?? map['word']) as String;
        if (display == map['reading']) sameAsReading++;
      }
    }
    expect(
      sameAsReading,
      greaterThan(100),
      reason: 'expected the kana-only entries this rule exists for',
    );
  });
}
