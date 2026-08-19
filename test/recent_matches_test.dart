import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/battle_match.dart';
import 'package:kana_master/features/battle/recent_matches_providers.dart';

/// The part of a match history that can actually be wrong is who won.
/// The same match is a win for one player and a loss for the other, and a
/// row that reads it from the wrong side is worse than no history at all —
/// it is a confident lie about something the player remembers.
void main() {
  const me = 'uid-me';
  const them = 'uid-them';

  BattleMatch match({String? result, Map<String, int>? score}) {
    return BattleMatch.fromMap('m1', {
      'players': [me, them],
      'status': 'finished',
      'currentRound': 40,
      'turnOrder': const [],
      'officialScore': score ?? {me: 10, them: 6},
      'result': result,
    });
  }

  test('a match is read from the side of the player looking at it', () {
    final won = match(result: me);
    expect(outcomeFor(won, me), MatchOutcome.win);
    expect(
      outcomeFor(won, them),
      MatchOutcome.loss,
      reason: 'the same match came out a win for both players',
    );
  });

  test('a draw is a draw for everyone', () {
    final drawn = match(result: 'draw');
    expect(outcomeFor(drawn, me), MatchOutcome.draw);
    expect(outcomeFor(drawn, them), MatchOutcome.draw);
  });

  test('a match with no recorded result is not silently a loss', () {
    // Reaching the history with no result at all should read as
    // inconclusive rather than picking a side — claiming a loss the
    // player never had is the worse of the two wrong answers.
    expect(outcomeFor(match(), me), MatchOutcome.draw);
  });

  test('the opponent is whoever is not you', () {
    expect(opponentOf(match(), me), them);
    expect(opponentOf(match(), them), me);
  });

  test('a match with nobody else in it has no opponent', () {
    final solo = BattleMatch.fromMap('m2', {
      'players': [me],
      'status': 'finished',
      'currentRound': 0,
      'turnOrder': const [],
      'officialScore': {me: 0},
    });
    expect(opponentOf(solo, me), isNull);
  });
}
