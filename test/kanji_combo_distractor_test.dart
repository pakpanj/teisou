import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_master/data/repositories/kanji_combo_repository.dart';

void main() {
  group('generateMutationDistractors', () {
    test('never returns the correct answer itself', () {
      final random = Random(1);
      for (final reading in ['じじょう', 'きげん', 'せいしょうねん', 'つか']) {
        final distractors = generateMutationDistractors(reading, 3, random);
        expect(distractors.contains(reading), isFalse);
      }
    });

    test('never produces duplicates (enforced by Set, sanity-checked anyway)', () {
      final random = Random(2);
      final distractors = generateMutationDistractors('しょうがっこう', 3, random);
      expect(distractors.length, distractors.toSet().length);
    });

    test('preserves mora count for a typical multi-mora reading', () {
      final random = Random(3);
      const correct = 'じじょう'; // mora: じ, じょ, う
      final distractors = generateMutationDistractors(correct, 3, random);
      for (final d in distractors) {
        expect(_moraCount(d), _moraCount(correct));
      }
    });

    test('handles katakana onyomi and keeps the result in katakana', () {
      final random = Random(4);
      final distractors = generateMutationDistractors('セン', 3, random);
      for (final d in distractors) {
        expect(d.runes.every((r) => r >= 0x30A1 && r <= 0x30F6), isTrue);
      }
    });

    test('treats a hyphenated okurigana marker as immutable', () {
      final random = Random(5);
      final distractors = generateMutationDistractors('のこ-す', 5, random);
      for (final d in distractors) {
        expect(d.contains('-'), isTrue);
      }
    });

    test('never yields a distractor starting with ん/ン/を/ヲ', () {
      final random = Random(6);
      for (final reading in ['げんそう', 'んき', 'じじょう', 'きげん']) {
        final distractors = generateMutationDistractors(reading, 3, random);
        for (final d in distractors) {
          expect(isValidKotobaStart(d), isTrue, reason: '$d should not start with ん/ン/を/ヲ');
        }
      }
    });

    test('degrades gracefully (fewer than n) for a structurally limited reading', () {
      final random = Random(7);
      // わ has no dakuten pair, and its only other vowel-row members (を, ん)
      // are banned as word-initial - no valid single-mora mutation exists.
      final distractors = generateMutationDistractors('わ', 3, random);
      expect(distractors.length, lessThan(3));
    });
  });

  group('isValidKotobaStart', () {
    test('rejects ん/ン/を/ヲ as the first mora', () {
      expect(isValidKotobaStart('んき'), isFalse);
      expect(isValidKotobaStart('ンキ'), isFalse);
      expect(isValidKotobaStart('をんな'), isFalse);
      expect(isValidKotobaStart('ヲンナ'), isFalse);
    });

    test('accepts normal readings', () {
      expect(isValidKotobaStart('じじょう'), isTrue);
      expect(isValidKotobaStart('きん'), isTrue);
    });
  });
}

int _moraCount(String reading) {
  var count = 0;
  var i = 0;
  final chars = reading.runes.map(String.fromCharCode).toList();
  const smallY = {'ゃ', 'ゅ', 'ょ'};
  while (i < chars.length) {
    if (chars[i] == '-') {
      i += 1;
      continue;
    }
    count++;
    if (i + 1 < chars.length && smallY.contains(chars[i + 1])) {
      i += 2;
    } else {
      i += 1;
    }
  }
  return count;
}
