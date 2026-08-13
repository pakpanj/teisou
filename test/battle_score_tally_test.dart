import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/services/battle_score_tally.dart';
import 'package:kana_master/data/models/turn_order_entry.dart';

void main() {
  final players = ['a', 'b'];
  final turnOrder = [
    TurnOrderEntry(round: 0, deckOwnerUid: 'a', cardId: 'k0'), // b answers
    TurnOrderEntry(round: 1, deckOwnerUid: 'b', cardId: 'k1'), // a answers
    TurnOrderEntry(round: 2, deckOwnerUid: 'a', cardId: 'k2'), // b answers
    TurnOrderEntry(round: 3, deckOwnerUid: 'b', cardId: 'k3'), // a answers
  ];

  group('tallyScores', () {
    test('a correct answer scores for the answerer, not the deck owner',
        () {
      final tally = tallyScores(
        players: players,
        turnOrder: turnOrder,
        correctByRound: {0: true},
      );
      // round 0's deck owner is 'a', so the answerer ('b') gets the point.
      expect(tally.scoreOf('b'), 1);
      expect(tally.scoreOf('a'), 0);
    });

    test('a wrong answer scores nothing for anyone', () {
      final tally = tallyScores(
        players: players,
        turnOrder: turnOrder,
        correctByRound: {0: false},
      );
      expect(tally.scoreOf('a'), 0);
      expect(tally.scoreOf('b'), 0);
    });

    test('scores accumulate across multiple rounds', () {
      final tally = tallyScores(
        players: players,
        turnOrder: turnOrder,
        correctByRound: {0: true, 1: true, 2: true, 3: false},
      );
      // round 0 -> b, round 1 -> a, round 2 -> b, round 3 -> a (wrong)
      expect(tally.scoreOf('b'), 2);
      expect(tally.scoreOf('a'), 1);
    });

    test('scoreOf a player with no rounds resolved yet is 0, not an '
        'error', () {
      final tally = tallyScores(
        players: players,
        turnOrder: turnOrder,
        correctByRound: {},
      );
      expect(tally.scoreOf('a'), 0);
      expect(tally.scoreOf('b'), 0);
    });
  });

  group('clientConclusion', () {
    test('never concludes before the main phase (round 9) has resolved',
        () {
      final tally = tallyScores(
        players: players,
        turnOrder: turnOrder,
        correctByRound: {0: true},
      );
      expect(
        clientConclusion(
          players: players,
          tally: tally,
          highestResolvedRound: 8,
        ),
        isNull,
      );
    });

    test('concludes with the higher-scoring player once round 9 has '
        'resolved and scores differ', () {
      final tally = tallyScores(
        players: players,
        turnOrder: turnOrder,
        correctByRound: {0: true, 2: true}, // both go to 'b'
      );
      expect(
        clientConclusion(
          players: players,
          tally: tally,
          highestResolvedRound: 9,
        ),
        'b',
      );
    });

    test('stays undecided (continues to extension) if tied and not yet '
        'at round 19', () {
      final tally = tallyScores(
        players: players,
        turnOrder: turnOrder,
        correctByRound: {},
      );
      expect(
        clientConclusion(
          players: players,
          tally: tally,
          highestResolvedRound: 9,
        ),
        isNull,
      );
    });

    test('is a draw if still tied once round 19 has resolved', () {
      final tally = tallyScores(
        players: players,
        turnOrder: turnOrder,
        correctByRound: {},
      );
      expect(
        clientConclusion(
          players: players,
          tally: tally,
          highestResolvedRound: 19,
        ),
        'draw',
      );
    });
  });
}
