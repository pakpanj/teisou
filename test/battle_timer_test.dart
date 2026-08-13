import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/battle_timer.dart';

void main() {
  test('cards 1-10 (rounds 0-9) always get the full 30 seconds', () {
    for (var round = 0; round <= 9; round++) {
      expect(
        cardTimeLimit(round),
        const Duration(seconds: 30),
        reason: 'round $round',
      );
    }
  });

  test('cards 11-20 (rounds 10-19) shrink by 2 seconds per card', () {
    final expected = {
      10: 28,
      11: 26,
      12: 24,
      13: 22,
      14: 20,
      15: 18,
      16: 16,
      17: 14,
      18: 12,
      19: 10,
    };
    expected.forEach((round, seconds) {
      expect(
        cardTimeLimit(round),
        Duration(seconds: seconds),
        reason: 'round $round',
      );
    });
  });

  test('never goes below the 10-second floor', () {
    expect(cardTimeLimit(19).inSeconds, greaterThanOrEqualTo(10));
  });

  test('throws for a round outside 0-19', () {
    expect(() => cardTimeLimit(-1), throwsA(isA<AssertionError>()));
    expect(() => cardTimeLimit(20), throwsA(isA<AssertionError>()));
  });
}
