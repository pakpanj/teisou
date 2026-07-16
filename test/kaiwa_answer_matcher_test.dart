import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/kaiwa_accepted_answer.dart';
import 'package:kana_master/features/kaiwa/services/kaiwa_answer_matcher.dart';

void main() {
  const matcher = KaiwaAnswerMatcher();

  final accepted = [
    KaiwaAcceptedAnswer(
      japanese: '頑張ります',
      romaji: 'ganbarimasu',
      translation: 'Saya akan berusaha',
      variants: ['頑張ります！'],
      expressionTag: 'semangat',
    ),
    KaiwaAcceptedAnswer(
      japanese: 'はい',
      romaji: 'hai',
      translation: 'Ya',
    ),
  ];

  test('matches exact japanese text', () {
    final result = matcher.check('頑張ります', accepted);
    expect(result.isCorrect, isTrue);
    expect(result.matchedAnswer?.expressionTag, 'semangat');
  });

  test('matches romaji input case-insensitively', () {
    final result = matcher.check('GanbariMasu', accepted);
    expect(result.isCorrect, isTrue);
  });

  test('matches a hand-authored variant with different punctuation', () {
    final result = matcher.check('頑張ります！', accepted);
    expect(result.isCorrect, isTrue);
  });

  test('ignores trailing punctuation and whitespace noise', () {
    final result = matcher.check('  はい。 ', accepted);
    expect(result.isCorrect, isTrue);
    expect(result.matchedAnswer?.expressionTag, isNull);
  });

  test('rejects unrelated input', () {
    final result = matcher.check('いいえ', accepted);
    expect(result.isCorrect, isFalse);
    expect(result.matchedAnswer, isNull);
  });

  test('rejects empty input', () {
    final result = matcher.check('   ', accepted);
    expect(result.isCorrect, isFalse);
  });
}
