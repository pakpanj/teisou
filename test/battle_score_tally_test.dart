import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/battle_rules.dart';
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
    test('never concludes before the main phase (ten cards each) has resolved',
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
          highestResolvedRound: kBattleMainPhaseRounds - 2,
        ),
        isNull,
      );
    });

    test('concludes with the higher-scoring player once the main phase has '
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
          highestResolvedRound: kBattleMainPhaseRounds - 1,
        ),
        'b',
      );
    });

    test('stays undecided (continues to extension) if tied and not yet '
        'at the end of both decks', () {
      final tally = tallyScores(
        players: players,
        turnOrder: turnOrder,
        correctByRound: {},
      );
      expect(
        clientConclusion(
          players: players,
          tally: tally,
          highestResolvedRound: kBattleMainPhaseRounds - 1,
        ),
        isNull,
      );
    });

    test('is a draw if still tied once both decks are spent', () {
      final tally = tallyScores(
        players: players,
        turnOrder: turnOrder,
        correctByRound: {},
      );
      expect(
        clientConclusion(
          players: players,
          tally: tally,
          highestResolvedRound: kBattleTotalRounds - 1,
        ),
        'draw',
      );
    });
  });

  /// The match screen's own call, which used to count the answers this
  /// device had received rather than ask the match how far it had got.
  /// One missed answer left that count permanently short — and a draw,
  /// callable only on the very last round, then never became callable at
  /// all: the screen sat spinning on a finished match.
  group('conclusionAt', () {
    final fullOrder = [
      for (var round = 0; round < kBattleTotalRounds; round++)
        TurnOrderEntry(
          round: round,
          deckOwnerUid: round.isEven ? players[0] : players[1],
          cardId: 'c$round',
        ),
    ];

    BattleScoreTally tallyOf(Map<int, bool> correct) => tallyScores(
          players: players,
          turnOrder: fullOrder,
          correctByRound: correct,
        );

    test('a tie at the end of the main phase plays on', () {
      expect(
        conclusionAt(
          players: players,
          tally: tallyOf(const {}),
          currentRound: kBattleMainPhaseRounds,
        ),
        isNull,
      );
    });

    test('a tie with every card spent is a draw', () {
      expect(
        conclusionAt(
          players: players,
          tally: tallyOf(const {}),
          currentRound: kBattleTotalRounds,
        ),
        'draw',
      );
    });

    /// The exact shape of the hang: the match is over and this device is
    /// missing one round's answer.
    test('a draw is still called when an answer never arrived', () {
      final missingOne = <int, bool>{
        for (var round = 0; round < kBattleTotalRounds; round++)
          if (round != 7) round: false,
      };
      final tally = tallyOf(missingOne);
      expect(
        conclusionAt(
          players: players,
          tally: tally,
          currentRound: kBattleTotalRounds,
        ),
        'draw',
      );
      // And what shipped, for contrast — counting the answers instead.
      expect(
        clientConclusion(
          players: players,
          tally: tally,
          highestResolvedRound: missingOne.length - 1,
        ),
        isNull,
      );
    });
  });
}
