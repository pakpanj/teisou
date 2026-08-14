import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/battle_rules.dart';
import 'package:kana_master/core/services/battle_timer.dart';

/// The numbers here were corrected on 2026-08-14 along with the match
/// length itself — see `battle_rules.dart`. The main phase is ten cards
/// *each*, not ten in total, so the full 30 seconds now runs to round 19
/// rather than round 9.
void main() {
  test('every card of the main phase gets the full 30 seconds', () {
    for (var round = 0; round < kBattleMainPhaseRounds; round++) {
      expect(
        cardTimeLimit(round),
        const Duration(seconds: 30),
        reason: 'round $round',
      );
    }
  });

  test('the extension shrinks by 2 seconds per card', () {
    expect(cardTimeLimit(20), const Duration(seconds: 28));
    expect(cardTimeLimit(21), const Duration(seconds: 26));
    expect(cardTimeLimit(22), const Duration(seconds: 24));
    expect(cardTimeLimit(28), const Duration(seconds: 12));
    expect(cardTimeLimit(29), const Duration(seconds: 10));
  });

  test('the shrink stops at the floor instead of reaching zero', () {
    // Twenty extension cards at two seconds each would pass zero well
    // before the deck ran out, which is not a harder question but an
    // impossible one.
    for (var round = kBattleMainPhaseRounds;
        round < kBattleTotalRounds;
        round++) {
      expect(
        cardTimeLimit(round).inSeconds,
        greaterThanOrEqualTo(kBattleMinimumSeconds),
        reason: 'round $round',
      );
    }
    expect(cardTimeLimit(kBattleTotalRounds - 1).inSeconds,
        kBattleMinimumSeconds);
  });

  test('the limit never increases as the match goes on', () {
    for (var round = 1; round < kBattleTotalRounds; round++) {
      expect(
        cardTimeLimit(round) <= cardTimeLimit(round - 1),
        isTrue,
        reason: 'round $round',
      );
    }
  });
}
