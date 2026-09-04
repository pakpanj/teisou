import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/constants/battle_rules.dart';
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

    /// The compatibility that makes this field safe to add to a
    /// collection that already holds matches. Every document written
    /// before it existed — and every public/bot match written after,
    /// which never sets it — has to read back as "already started". Get
    /// this default the wrong way round and every match in the database
    /// becomes one that nobody is allowed to play.
    test('a match with no inviteState is already under way', () {
      final legacy = BattleMatch.fromMap('m', {});
      expect(legacy.inviteState, BattleInviteState.none);
      expect(legacy.isAwaitingAccept, isFalse);
    });

    test('fromMap parses each inviteState, and only pending is waiting', () {
      const expected = <String, BattleInviteState>{
        'pending': BattleInviteState.pending,
        'accepted': BattleInviteState.accepted,
        'declined': BattleInviteState.declined,
        // Anything unrecognised falls back to "started" for the same
        // reason as the legacy case above: refusing to run a real match
        // is worse than running one whose label we did not recognise.
        'something-else': BattleInviteState.none,
      };
      expected.forEach((key, state) {
        final match = BattleMatch.fromMap('m', {'inviteState': key});
        expect(match.inviteState, state, reason: key);
        expect(
          match.isAwaitingAccept,
          state == BattleInviteState.pending,
          reason: key,
        );
      });
    });

    test('toCreateMap carries inviteState as its string key', () {
      BattleMatch withState(BattleInviteState state) => BattleMatch(
            id: '',
            players: ['uid-a', 'uid-b'],
            status: BattleMatchStatus.active,
            currentRound: 0,
            turnOrder: [
              TurnOrderEntry(round: 0, deckOwnerUid: 'uid-a', cardId: 'k1'),
            ],
            officialScore: {'uid-a': 0, 'uid-b': 0},
            inviteState: state,
          );
      expect(
        withState(BattleInviteState.pending).toCreateMap()['inviteState'],
        'pending',
      );
      expect(
        withState(BattleInviteState.none).toCreateMap()['inviteState'],
        'none',
      );
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

    group('absence (two-sided reconnect grace period)', () {
      test('fromMap parses a real Timestamp since, keyed by uid', () {
        final since = Timestamp.fromDate(DateTime.utc(2026, 8, 30, 12, 0, 0));
        final match = BattleMatch.fromMap('m', {
          'absence': {
            'uid-a': {'since': since},
          },
        });
        expect(match.absenceOf('uid-a'), isNotNull);
        expect(match.absenceOf('uid-a')!.since, since.toDate());
        expect(match.absenceOf('uid-b'), isNull);
      });

      test('fromMap leaves absence empty when absent, not throwing', () {
        final match = BattleMatch.fromMap('m', {});
        expect(match.absence, isEmpty);
        expect(match.isPaused, isFalse);
      });

      test('both players can each have their own independent entry', () {
        final sinceA = Timestamp.fromDate(DateTime.utc(2026, 9, 1, 10));
        final sinceB = Timestamp.fromDate(DateTime.utc(2026, 9, 1, 10, 0, 5));
        final match = BattleMatch.fromMap('m', {
          'absence': {
            'uid-a': {'since': sinceA},
            'uid-b': {'since': sinceB},
          },
        });
        expect(match.absentUids.toSet(), {'uid-a', 'uid-b'});
        expect(match.absenceOf('uid-a')!.since, sinceA.toDate());
        expect(match.absenceOf('uid-b')!.since, sinceB.toDate());
      });

      test('isPaused is true whenever anyone is away, false once the map '
          'is empty — and it never depends on which uid is asking, unlike '
          'absenceOf', () {
        final active = BattleMatch.fromMap('m', {
          'status': 'active',
        });
        expect(active.isPaused, isFalse);
        final paused = BattleMatch.fromMap('m', {
          'status': 'active',
          'absence': {
            'uid-a': {'since': null},
          },
        });
        expect(paused.isPaused, isTrue);
      });

      test('isPaused is false once the match has concluded, even with a '
          'stale absence entry still on the doc — status wins', () {
        final match = BattleMatch.fromMap('m', {
          'status': 'finished',
          'absence': {
            'uid-a': {'since': null},
          },
        });
        expect(match.isPaused, isFalse);
      });

      test('elapsedSince computes a real Duration once since is known', () {
        final since = DateTime.utc(2026, 8, 30, 12, 0, 0);
        final marker = BattleAbsenceMarker(since: since);
        final elapsed = marker.elapsedSince(since.add(const Duration(seconds: 12)));
        expect(elapsed, const Duration(seconds: 12));
      });

      test('elapsedSince is null while the serverTimestamp sentinel has '
          'not round-tripped back down yet', () {
        const marker = BattleAbsenceMarker();
        expect(marker.elapsedSince(DateTime.now()), isNull);
      });

      test('toCreateMap never includes absence — a fresh match starts '
          'with nobody marked away', () {
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
        expect(match.toCreateMap().containsKey('absence'), isFalse);
      });
    });

    group('abandoned status', () {
      test('key/fromKey round-trip the new terminal status', () {
        expect(BattleMatchStatus.abandoned.key, 'abandoned');
        expect(
          BattleMatchStatusX.fromKey('abandoned'),
          BattleMatchStatus.abandoned,
        );
      });

      test('an abandoned match is never resumable', () {
        final match = BattleMatch(
          id: 'm',
          players: ['uid-a', 'uid-b'],
          status: BattleMatchStatus.abandoned,
          currentRound: 3,
          turnOrder: [
            TurnOrderEntry(round: 0, deckOwnerUid: 'uid-a', cardId: 'k1'),
          ],
          officialScore: {'uid-a': 0, 'uid-b': 0},
          createdAt: DateTime(2026, 1, 1),
        );
        expect(
          match.isResumable(uid: 'uid-a', now: DateTime(2026, 1, 1, 0, 1)),
          isFalse,
        );
      });
    });

    group('isResumable', () {
      final fixedNow = DateTime(2026, 1, 1, 12);

      BattleMatch baseMatch({
        BattleMatchStatus status = BattleMatchStatus.active,
        String? result,
        BattleInviteState inviteState = BattleInviteState.none,
        DateTime? createdAt,
        Map<String, BattleAbsenceMarker> absence = const {},
      }) =>
          BattleMatch(
            id: 'm',
            players: ['uid-a', 'uid-b'],
            status: status,
            currentRound: 3,
            turnOrder: [
              TurnOrderEntry(round: 0, deckOwnerUid: 'uid-a', cardId: 'k1'),
            ],
            officialScore: {'uid-a': 0, 'uid-b': 0},
            result: result,
            inviteState: inviteState,
            createdAt: createdAt ?? fixedNow.subtract(const Duration(minutes: 5)),
            absence: absence,
          );

      test('an active match with no result and no pending invite is '
          'resumable', () {
        expect(baseMatch().isResumable(uid: 'uid-a', now: fixedNow), isTrue);
      });

      test('a finished match is never resumable', () {
        expect(
          baseMatch(status: BattleMatchStatus.finished, result: 'uid-a')
              .isResumable(uid: 'uid-a', now: fixedNow),
          isFalse,
        );
      });

      test('an active match that already has a result (about to be '
          'finished, or a race mid-write) is not resumable', () {
        expect(
          baseMatch(result: 'uid-a').isResumable(uid: 'uid-a', now: fixedNow),
          isFalse,
        );
      });

      test('a friend/clan challenge still awaiting its accept is not '
          'resumable — there is no live battle to return to yet', () {
        expect(
          baseMatch(
            inviteState: BattleInviteState.pending,
          ).isResumable(uid: 'uid-a', now: fixedNow),
          isFalse,
        );
      });

      // M3 (AUDIT_ARSITEKTUR_PRESENCE_LIFECYCLE_MODE_KARTU.md) — the age
      // ceiling: a match this old should already have resolved through
      // the absence grace period or the abandonment sweep, whichever
      // applies, so it is no longer offered as "still in progress".
      test('a match right at the age ceiling is still resumable', () {
        final match = baseMatch(
          createdAt: fixedNow.subtract(kBattleResumableMaxAge),
        );
        expect(match.isResumable(uid: 'uid-a', now: fixedNow), isTrue);
      });

      test('a match one second past the age ceiling is not resumable', () {
        final match = baseMatch(
          createdAt: fixedNow.subtract(
            kBattleResumableMaxAge + const Duration(seconds: 1),
          ),
        );
        expect(match.isResumable(uid: 'uid-a', now: fixedNow), isFalse);
      });

      test('a match with no createdAt at all is not resumable — treated '
          'as too old rather than ageless, matching the result screen\'s '
          'own "no timestamp, no duration shown" precedent for the same '
          'field', () {
        final match = BattleMatch(
          id: 'm',
          players: ['uid-a', 'uid-b'],
          status: BattleMatchStatus.active,
          currentRound: 3,
          turnOrder: [
            TurnOrderEntry(round: 0, deckOwnerUid: 'uid-a', cardId: 'k1'),
          ],
          officialScore: {'uid-a': 0, 'uid-b': 0},
          // createdAt deliberately omitted — every match created before
          // that field existed reads back this way.
        );
        expect(match.createdAt, isNull);
        expect(match.isResumable(uid: 'uid-a', now: fixedNow), isFalse);
      });

      // Two-sided absence, from the caller's own perspective — KASUS 1/2's
      // "my own 30-second window is up" rule. Only ever gates *this*
      // uid's own resumability; it never looks at the opponent's entry.
      test('a match is still resumable for me while my own absence is '
          'inside the grace period', () {
        final match = baseMatch(
          absence: {
            'uid-a': BattleAbsenceMarker(
              since: fixedNow.subtract(const Duration(seconds: 10)),
            ),
          },
        );
        expect(match.isResumable(uid: 'uid-a', now: fixedNow), isTrue);
      });

      test('a match is no longer resumable for me once my own absence has '
          'run past the grace period', () {
        final match = baseMatch(
          absence: {
            'uid-a': BattleAbsenceMarker(
              since: fixedNow.subtract(
                const Duration(seconds: kBattleAbsenceGracePeriodSeconds + 1),
              ),
            ),
          },
        );
        expect(match.isResumable(uid: 'uid-a', now: fixedNow), isFalse);
      });

      test('the opponent being past their own grace period does not '
          'affect my own resumability — each player is judged only by '
          'their own entry', () {
        final match = baseMatch(
          absence: {
            'uid-b': BattleAbsenceMarker(
              since: fixedNow.subtract(
                const Duration(seconds: kBattleAbsenceGracePeriodSeconds + 30),
              ),
            ),
          },
        );
        expect(match.isResumable(uid: 'uid-a', now: fixedNow), isTrue);
      });

      test('a match with no known `since` yet for my own entry (the '
          'serverTimestamp sentinel has not round-tripped down) is still '
          'resumable — a fresh mark, not a stale one', () {
        final match = baseMatch(absence: {'uid-a': const BattleAbsenceMarker()});
        expect(match.isResumable(uid: 'uid-a', now: fixedNow), isTrue);
      });
    });
  });
}
