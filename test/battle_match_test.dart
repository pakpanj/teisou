import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/battle_answer.dart';
import 'package:kana_master/data/models/battle_match.dart';
import 'package:kana_master/data/models/card_game_rank.dart';
import 'package:kana_master/data/models/turn_order_entry.dart';

void main() {
  group('TurnOrderEntry', () {
    test('toMap/fromMap round-trips every field', () {
      final entry = TurnOrderEntry(
        round: 7,
        deckOwnerUid: 'uid-a',
        cardId: 'kana_ka',
      );
      final roundTripped = TurnOrderEntry.fromMap(entry.toMap());
      expect(roundTripped.round, 7);
      expect(roundTripped.deckOwnerUid, 'uid-a');
      expect(roundTripped.cardId, 'kana_ka');
    });
  });

  group('BattleAnswer', () {
    test('fromMap parses byUid/text, defaults empty text rather than '
        'throwing', () {
      final answer = BattleAnswer.fromMap({'byUid': 'uid-b'});
      expect(answer.byUid, 'uid-b');
      expect(answer.text, '');
      expect(answer.submittedAt, isNull);
    });

    test('toMap carries byUid/text and a serverTimestamp sentinel for '
        'submittedAt', () {
      final map = BattleAnswer(byUid: 'uid-b', text: 'gakusei').toMap();
      expect(map['byUid'], 'uid-b');
      expect(map['text'], 'gakusei');
      expect(map['submittedAt'], isA<FieldValue>());
    });
  });

  group('BattleMatch', () {
    test('fromMap parses a full match document, including nested '
        'turnOrder and officialScore', () {
      final match = BattleMatch.fromMap('match-1', {
        'players': ['uid-a', 'uid-b'],
        'status': 'active',
        'currentRound': 3,
        'turnOrder': [
          {'round': 0, 'deckOwnerUid': 'uid-a', 'cardId': 'k1'},
          {'round': 1, 'deckOwnerUid': 'uid-b', 'cardId': 'k2'},
        ],
        'clientResult': null,
        'officialScore': {'uid-a': 2, 'uid-b': 1},
        'result': null,
      });
      expect(match.id, 'match-1');
      expect(match.players, ['uid-a', 'uid-b']);
      expect(match.status, BattleMatchStatus.active);
      expect(match.currentRound, 3);
      expect(match.turnOrder.length, 2);
      expect(match.turnOrder[0].cardId, 'k1');
      expect(match.officialScore['uid-a'], 2);
      expect(match.officialScore['uid-b'], 1);
      expect(match.result, isNull);
    });

    test('fromMap defaults missing fields rather than throwing', () {
      final match = BattleMatch.fromMap('match-2', {});
      expect(match.players, isEmpty);
      expect(match.status, BattleMatchStatus.active);
      expect(match.currentRound, 0);
      expect(match.turnOrder, isEmpty);
      expect(match.officialScore, isEmpty);
    });

    test('toCreateMap starts officialScore at 0 for both players and '
        'leaves result/clientResult absent', () {
      final match = BattleMatch(
        id: '',
        players: ['uid-a', 'uid-b'],
        status: BattleMatchStatus.active,
        currentRound: 0,
        turnOrder: [
          TurnOrderEntry(round: 0, deckOwnerUid: 'uid-a', cardId: 'k1'),
        ],
        officialScore: {'uid-a': 0, 'uid-b': 0},
      );
      final map = match.toCreateMap();
      expect(map['players'], ['uid-a', 'uid-b']);
      expect(map['status'], 'active');
      expect(map['currentRound'], 0);
      expect(map['officialScore'], {'uid-a': 0, 'uid-b': 0});
      expect(map['result'], isNull);
      expect(map['clientResult'], isNull);
      expect(map['turnStartedAt'], isA<FieldValue>());
      expect(map['scoredRounds'], <String, bool>{});
    });

    test('fromMap parses scoredRounds, defaulting to empty when absent',
        () {
      final withRounds = BattleMatch.fromMap('m', {
        'scoredRounds': {'0': true, '1': true},
      });
      expect(withRounds.scoredRounds, {'0': true, '1': true});

      final withoutRounds = BattleMatch.fromMap('m', {});
      expect(withoutRounds.scoredRounds, isEmpty);
    });

    test('fromMap parses rankedMatch, defaulting to true when absent', () {
      final unranked = BattleMatch.fromMap('m', {'rankedMatch': false});
      expect(unranked.rankedMatch, isFalse);

      final defaulted = BattleMatch.fromMap('m', {});
      expect(defaulted.rankedMatch, isTrue);
    });

    test('toCreateMap carries rankedMatch as a plain bool', () {
      final match = BattleMatch(
        id: '',
        players: ['uid-a', 'uid-b'],
        status: BattleMatchStatus.active,
        currentRound: 0,
        turnOrder: [
          TurnOrderEntry(round: 0, deckOwnerUid: 'uid-a', cardId: 'k1'),
        ],
        officialScore: {'uid-a': 0, 'uid-b': 0},
        rankedMatch: false,
      );
      expect(match.toCreateMap()['rankedMatch'], false);
    });

    test('currentAnswererUid is always the player who does NOT own the '
        'current round\'s deck', () {
      final match = BattleMatch(
        id: 'm',
        players: ['uid-a', 'uid-b'],
        status: BattleMatchStatus.active,
        currentRound: 0,
        turnOrder: [
          TurnOrderEntry(round: 0, deckOwnerUid: 'uid-a', cardId: 'k1'),
          TurnOrderEntry(round: 1, deckOwnerUid: 'uid-b', cardId: 'k2'),
        ],
        officialScore: {'uid-a': 0, 'uid-b': 0},
      );
      expect(match.currentAnswererUid, 'uid-b');
    });

    test('fromMap parses cardTierContent, defaulting to hiragana when '
        'absent', () {
      final withTier = BattleMatch.fromMap('m', {
        'cardTierContent': 'kanjiN4N3',
      });
      expect(withTier.cardTierContent, CardTierContent.kanjiN4N3);

      final withoutTier = BattleMatch.fromMap('m', {});
      expect(withoutTier.cardTierContent, CardTierContent.hiragana);
    });

    test('toCreateMap carries cardTierContent as its string key', () {
      final match = BattleMatch(
        id: '',
        players: ['uid-a', 'uid-b'],
        status: BattleMatchStatus.active,
        currentRound: 0,
        turnOrder: [
          TurnOrderEntry(round: 0, deckOwnerUid: 'uid-a', cardId: 'k1'),
        ],
        officialScore: {'uid-a': 0, 'uid-b': 0},
        cardTierContent: CardTierContent.kanjiN2N1,
      );
      expect(match.toCreateMap()['cardTierContent'], 'kanjiN2N1');
    });

    test('currentAnswererUid is null once currentRound runs past the end '
        'of turnOrder', () {
      final match = BattleMatch(
        id: 'm',
        players: ['uid-a', 'uid-b'],
        status: BattleMatchStatus.finished,
        currentRound: 5,
        turnOrder: [
          TurnOrderEntry(round: 0, deckOwnerUid: 'uid-a', cardId: 'k1'),
        ],
        officialScore: {'uid-a': 0, 'uid-b': 0},
      );
      expect(match.currentAnswererUid, isNull);
    });
  });
}
