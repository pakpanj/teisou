// "Pertandingan terakhir" history bug (2026-09): an abandoned match
// (`status: 'abandoned'`, `result` never written) never appeared in the
// Card Game lobby's recent-matches list, even after a cold app restart and
// a pull-to-refresh — confirmed live against TEST E's own match
// (`oF99qtvrUG783D6ssASF`, see `TEST_E_REPORT_KEDUA_LEAVE_TIDAK_ADA_YANG_KEMBALI.md`).
//
// Root cause, confirmed by ruling out every other candidate first: not the
// query's filter/orderBy shape (a `fake_cloud_firestore` reproduction of
// the exact same query, given the exact document shape the real code
// writes, returns the abandoned match correctly — see the "query itself is
// correct" group below), not a missing composite index (`firebase
// firestore:indexes` confirmed the real project already has the
// `players`-array-contains + `createdAt`-descending index this query
// needs, live), not `BattleMatch.fromMap`/`outcomeFor` dropping a
// `result == null` row (both already treat it as "unfinished", not
// absent). What was left: `BattleRepository.recentMatches()`'s one-shot
// `.get()` carried no `GetOptions`, so it could resolve from Firestore's
// on-device persistence cache instead of a fresh server round trip — the
// exact same bug class this codebase already fixed once in
// `MinVersionRepository.fetchMinBuildNumber()` (see that file's own doc
// comment). `fake_cloud_firestore` has no real cache/server split to
// prove that half of the fix against, so these tests instead cover
// everything that *can* be proven deterministically: the query's
// filter/sort/limit behaviour is correct for every match shape, and the
// active-match exclusion (a real, separate business-rule gap found during
// the same audit — a currently-in-progress match rendered as history
// *and* as the lobby's own resumable card at once) actually holds.
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/providers.dart';
import 'package:kana_master/data/models/battle_match.dart';
import 'package:kana_master/data/repositories/battle_repository.dart';
import 'package:kana_master/data/repositories/leaderboard_repository.dart';
import 'package:kana_master/features/battle/recent_matches_providers.dart';
import 'package:kana_master/features/battle/widgets/recent_matches_section.dart';

const _uidA = 'uid_pak_panjang';
const _uidB = 'uid_pelajar_kana';

/// Writes a match doc through the exact same shape
/// `BattleMatch.toCreateMap()` produces, then layers on whatever a real
/// conclusion path (a normal finish, or the abandonment sweep's own
/// merge-set) would add — so these fixtures are the real code's own
/// output, not an invented shape.
Future<DocumentReference<Map<String, dynamic>>> _seedMatch(
  FakeFirebaseFirestore firestore, {
  required DateTime createdAt,
  String? result,
  bool active = false,
}) {
  final match = BattleMatch(
    id: '',
    players: [_uidA, _uidB],
    status: active ? BattleMatchStatus.active : BattleMatchStatus.finished,
    currentRound: 3,
    turnOrder: const [],
    officialScore: {_uidA: 0, _uidB: 0},
    rankedMatch: false,
  );
  final map = match.toCreateMap()
    ..['createdAt'] = Timestamp.fromDate(createdAt);
  return firestore.collection('battleMatches').add(map).then((ref) async {
    if (!active && result == null) {
      // The abandonment sweep's own KASUS 3 write
      // (`functions/battle_abandonment_sweep.js`): a merge-set that adds
      // `status`/`abandonedBy` and deliberately never touches `result`.
      await ref.set({
        'status': 'abandoned',
        'abandonedBy': [_uidA, _uidB],
      }, SetOptions(merge: true));
    } else if (!active) {
      await ref.set({'result': result}, SetOptions(merge: true));
    }
    return ref;
  });
}

class _FakeUser implements User {
  const _FakeUser(this._uid);
  final String _uid;
  @override
  String get uid => _uid;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('BattleRepository.recentMatches — query is correct', () {
    late FakeFirebaseFirestore firestore;
    late BattleRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = BattleRepository(firestore: firestore);
    });

    test('Test 1 — a normal finished match with a winner still appears',
        () async {
      await _seedMatch(
        firestore,
        createdAt: DateTime(2026, 9, 1),
        result: _uidA,
      );

      final matches = await repository.recentMatches(_uidA);

      expect(matches, hasLength(1));
      expect(matches.single.status, BattleMatchStatus.finished);
      expect(matches.single.result, _uidA);
    });

    test('Test 1b — a normal finished draw still appears', () async {
      await _seedMatch(
        firestore,
        createdAt: DateTime(2026, 9, 1),
        result: 'draw',
      );

      final matches = await repository.recentMatches(_uidA);

      expect(matches, hasLength(1));
      expect(matches.single.result, 'draw');
    });

    test(
        'Test 2 — an abandoned match (both players absent, result never '
        'written) appears — this is the exact bug: it used to be '
        'invisible in "Pertandingan terakhir" no matter how long the '
        'player waited', () async {
      final ref = await _seedMatch(
        firestore,
        createdAt: DateTime(2026, 9, 4, 20, 4),
      );

      final matches = await repository.recentMatches(_uidA);

      expect(
        matches.map((m) => m.id),
        contains(ref.id),
        reason: 'an abandoned match must not be silently excluded',
      );
      final abandoned = matches.firstWhere((m) => m.id == ref.id);
      expect(abandoned.status, BattleMatchStatus.abandoned);
    });

    test(
        'Test 4 — result == null on the abandoned match does not itself '
        'cause the row to be dropped (distinct from Test 2: this pins '
        'the specific field, not just the overall outcome)', () async {
      final ref = await _seedMatch(
        firestore,
        createdAt: DateTime(2026, 9, 4, 20, 4),
      );

      final matches = await repository.recentMatches(_uidA);
      final abandoned = matches.firstWhere((m) => m.id == ref.id);

      expect(abandoned.result, isNull);
      expect(abandoned.clientResult, isNull);
    });

    test(
        'Test 3 — a match still genuinely active (in progress right now) '
        'is excluded from history — it already has its own "Kembali ke '
        'Pertandingan" resumable card in the lobby, so showing it again '
        'here as "Belum selesai" would be the same match under two '
        'different names at once', () async {
      final activeRef = await _seedMatch(
        firestore,
        createdAt: DateTime(2026, 9, 5), // newest of all — would sort first
        active: true,
      );
      await _seedMatch(firestore, createdAt: DateTime(2026, 9, 1), result: _uidA);

      final matches = await repository.recentMatches(_uidA);

      expect(matches.map((m) => m.id), isNot(contains(activeRef.id)));
      expect(matches, hasLength(1));
    });

    test(
        'Test 3b — a *paused* match (still status active, one or both '
        'players currently marked absent) is excluded the same way as '
        'plain active — isPaused is active under the hood, not a '
        'separate status value', () async {
      final ref = await _seedMatch(
        firestore,
        createdAt: DateTime(2026, 9, 5),
        active: true,
      );
      await ref.set({
        'absence': {
          _uidA: {'since': Timestamp.now()},
        },
      }, SetOptions(merge: true));

      final matches = await repository.recentMatches(_uidA);

      expect(matches, isEmpty);
    });

    test('Test 5 — sorted newest-first by createdAt, regardless of '
        'insertion order', () async {
      await _seedMatch(firestore, createdAt: DateTime(2026, 8, 1), result: _uidA);
      await _seedMatch(firestore, createdAt: DateTime(2026, 9, 1), result: _uidB);
      await _seedMatch(firestore, createdAt: DateTime(2026, 8, 15), result: 'draw');

      final matches = await repository.recentMatches(_uidA);

      expect(
        matches.map((m) => m.createdAt),
        [DateTime(2026, 9, 1), DateTime(2026, 8, 15), DateTime(2026, 8, 1)],
      );
    });

    test('Test 6 — limit is respected: more matches exist than the '
        'requested limit', () async {
      for (var i = 0; i < 8; i++) {
        await _seedMatch(
          firestore,
          createdAt: DateTime(2026, 9, i + 1),
          result: _uidA,
        );
      }

      final matches = await repository.recentMatches(_uidA, limit: 5);

      expect(matches, hasLength(5));
      // The 5 newest of the 8 — Sept 8 down to Sept 4.
      expect(matches.first.createdAt, DateTime(2026, 9, 8));
      expect(matches.last.createdAt, DateTime(2026, 9, 4));
    });

    test('only returns matches the requesting uid actually played', () async {
      await firestore.collection('battleMatches').add(
        BattleMatch(
          id: '',
          players: ['someone_else', 'another_someone'],
          status: BattleMatchStatus.finished,
          currentRound: 0,
          turnOrder: const [],
          officialScore: const {},
        ).toCreateMap()
          ..['createdAt'] = Timestamp.fromDate(DateTime(2026, 9, 1)),
      );

      final matches = await repository.recentMatches(_uidA);

      expect(matches, isEmpty);
    });
  });

  group(
    'recentMatches source guard — pins the actual fix',
    () {
      test(
          'recentMatches forces a server read via GetOptions, never the '
          'default (cache-eligible) source — this is the field a code '
          'review could delete without anything else here noticing, '
          'since fake_cloud_firestore has no real cache to catch its '
          'absence',
          () {
        // Deliberately a source check, not a behavioural one — see this
        // file's own top comment for why the caching half of this bug
        // isn't provable against a fake in-memory Firestore. Mirrors the
        // established pattern in this codebase for exactly this shape of
        // regression (e.g. theme_consistency_test.dart's palette sweep).
        final source = File.fromUri(
          Uri.file(
            'lib/data/repositories/battle_repository.dart',
            windows: Platform.isWindows,
          ),
        ).readAsStringSync();
        final recentMatchesBody = source.substring(
          source.indexOf('Future<List<BattleMatch>> recentMatches('),
        );
        final methodBody = recentMatchesBody.substring(
          0,
          recentMatchesBody.indexOf('\n  }'),
        );
        expect(
          methodBody,
          contains('GetOptions(source: Source.server)'),
          reason:
              'recentMatches() must force a server read — a plain .get() '
              'can silently resolve from the on-device Firestore cache, '
              'which is the exact bug this pins (see this file\'s top '
              'comment)',
        );
      });
    },
  );

  group('recentMatchRowsProvider — repository through to display rows', () {
    test(
        'an abandoned match becomes a RecentMatchRow with '
        'MatchOutcome.unfinished, and an active match produces no row at '
        'all — the full Firestore-data -> repository -> model -> '
        'provider chain, not just BattleMatch in isolation', () async {
      final firestore = FakeFirebaseFirestore();
      await _seedMatch(firestore, createdAt: DateTime(2026, 9, 1), result: _uidA);
      await _seedMatch(firestore, createdAt: DateTime(2026, 9, 2)); // abandoned
      await _seedMatch(firestore, createdAt: DateTime(2026, 9, 3), active: true);

      final container = ProviderContainer(
        overrides: [
          appStartupProvider.overrideWith((ref) async => const _FakeUser(_uidA)),
          battleRepositoryProvider.overrideWithValue(
            BattleRepository(firestore: firestore),
          ),
          leaderboardRepositoryProvider.overrideWithValue(
            LeaderboardRepository(firestore: firestore),
          ),
        ],
      );
      addTearDown(container.dispose);

      final rows = await container.read(recentMatchRowsProvider.future);

      // The active match contributes no row (Test 3's rule, seen end to
      // end this time); the win and the abandoned match both do.
      expect(rows, hasLength(2));
      expect(
        rows.map((r) => r.outcome),
        containsAll([MatchOutcome.win, MatchOutcome.unfinished]),
      );
    });
  });

  group('RecentMatchesSection — renders the established "unfinished" label',
      () {
    testWidgets(
        'an abandoned match (MatchOutcome.unfinished) renders with the '
        'same "Belum selesai" label already used for any other '
        'never-reached-a-result match — no new UX invented for '
        '"abandoned" specifically, per the existing pattern this widget '
        'already documents for exactly this case', (tester) async {
      final row = RecentMatchRow(
        match: BattleMatch(
          id: 'm1',
          players: const [_uidA, _uidB],
          status: BattleMatchStatus.abandoned,
          currentRound: 3,
          turnOrder: const [],
          officialScore: const {_uidA: 0, _uidB: 0},
        ),
        outcome: outcomeFor(
          BattleMatch(
            id: 'm1',
            players: const [_uidA, _uidB],
            status: BattleMatchStatus.abandoned,
            currentRound: 3,
            turnOrder: const [],
            officialScore: const {_uidA: 0, _uidB: 0},
          ),
          _uidA,
        ),
        myScore: 0,
        theirScore: 0,
        opponentUid: _uidB,
        opponentName: 'Pelajar Kana',
        starDelta: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentMatchRowsProvider.overrideWith((ref) async => [row]),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RecentMatchesSection()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Belum selesai'), findsOneWidget);
      expect(find.text('lawan Pelajar Kana'), findsOneWidget);
      // Unfinished shows a dash, never a fabricated 0-0 that could read
      // as a real, scored draw.
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('renders nothing when there is no history yet', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recentMatchRowsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(body: RecentMatchesSection()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(RecentMatchesSection), findsOneWidget);
      expect(find.text('Belum selesai'), findsNothing);
    });
  });
}
