import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_master/core/firebase/firestore_paths.dart';
import 'package:kana_master/data/models/weekly_period_standing.dart';

/// Covers the Dart-side half of the Weekly Global Ranking (see
/// `functions/award_top_coins.js`'s own top-of-file doc comment for the
/// server-side design this mirrors): [WeeklyPeriodStanding] parsing, the
/// [FirestorePaths] path helpers, and — since no Firebase mock exists in
/// this test suite (see `leaderboard_global_points_test.dart`'s own doc
/// comment establishing this exact convention) — a source-inspection
/// pass confirming `WeeklyGlobalRankingRepository`'s query methods
/// genuinely use the same three-level tie-break
/// (`functions/award_top_coins.js`'s own `awardTopGlobalCoinsOnce` ranks
/// by) rather than drifting from it, which would make a displayed rank
/// disagree with what the payout actually pays.
void main() {
  group('WeeklyPeriodStanding.fromMap', () {
    test('parses points/attempts/periodId, uses the doc id for uid', () {
      final standing = WeeklyPeriodStanding.fromMap('uid123', {
        'points': 450.5,
        'attempts': 7,
        'periodId': '2026-W36',
        'uid': 'uid123',
      });
      expect(standing.uid, 'uid123');
      expect(standing.periodId, '2026-W36');
      expect(standing.points, 450.5);
      expect(standing.attempts, 7);
    });

    test('an integer points value (no decimal on the wire) still parses '
        'as a double — same Firestore int/double wire-format quirk '
        'documented in leaderboard_global_points_test.dart', () {
      final standing = WeeklyPeriodStanding.fromMap('uid123', {
        'points': 90,
        'attempts': 1,
        'periodId': '2026-W36',
      });
      expect(standing.points, 90.0);
    });

    test('a missing points/attempts field defaults to 0, not a crash — '
        'defensive against a document shape this app itself never '
        'actually writes incomplete, but a parser should not assume', () {
      final standing = WeeklyPeriodStanding.fromMap('uid123', {});
      expect(standing.points, 0);
      expect(standing.attempts, 0);
      expect(standing.periodId, '');
    });

    test('uid comes from the passed docId, not a (possibly absent) '
        '"uid" field inside the map — the doc id is always correct '
        'since the server writes this doc at .../users/{uid}', () {
      final standing = WeeklyPeriodStanding.fromMap('the-real-uid', {
        'points': 1,
        'attempts': 1,
        // Deliberately no 'uid' field in the map at all.
      });
      expect(standing.uid, 'the-real-uid');
    });
  });

  group('FirestorePaths — Weekly Global Ranking path helpers', () {
    test('globalScorePeriodUsersCollection builds the correct nested '
        'subcollection path', () {
      expect(
        FirestorePaths.globalScorePeriodUsersCollection('2026-W36'),
        'globalScorePeriods/2026-W36/users',
      );
    });

    test('globalScorePeriodAwardDoc builds the correct doc path', () {
      expect(
        FirestorePaths.globalScorePeriodAwardDoc('2026-W36'),
        'globalScorePeriodAwards/2026-W36',
      );
    });
  });

  group(
    'WeeklyGlobalRankingRepository — query shape matches the server\'s '
    'own deterministic tie-break exactly',
    () {
      final source = File(
        'lib/data/repositories/weekly_global_ranking_repository.dart',
      ).readAsStringSync();

      test('getTopForPeriod orders by points desc, attempts desc, then '
          'document id — the exact same three-level tie-break '
          'award_top_coins.js\'s awardTopGlobalCoinsOnce pays out by', () {
        // Matches through to the query's own `.get();` terminator rather
        // than a generic `\n  }` — this method's parameter list itself
        // spans multiple lines (dart format wraps the optional-named
        // `{int limit = 20}` block onto its own lines once the
        // signature gets long enough), which would otherwise make a
        // naive `\n  }` stop match end the capture at the PARAMETER
        // list's own closing brace instead of the method body's.
        final method = RegExp(
          r'Future<List<WeeklyPeriodStanding>> getTopForPeriod\(.*?\.get\(\);',
          dotAll: true,
        ).firstMatch(source);
        expect(method, isNotNull, reason: 'getTopForPeriod not found');
        final body = method!.group(0)!;
        expect(
          body.contains("orderBy('points', descending: true)"),
          isTrue,
        );
        expect(
          body.contains("orderBy('attempts', descending: true)"),
          isTrue,
        );
        expect(body.contains('orderBy(FieldPath.documentId)'), isTrue);

        // Ordering matters: points must appear before attempts, which
        // must appear before the document-id tiebreak, matching
        // Firestore's own multi-orderBy call sequence semantics.
        final pointsIdx = body.indexOf("orderBy('points'");
        final attemptsIdx = body.indexOf("orderBy('attempts'");
        final docIdIdx = body.indexOf('orderBy(FieldPath.documentId)');
        expect(pointsIdx, lessThan(attemptsIdx));
        expect(attemptsIdx, lessThan(docIdIdx));
      });

      test('watchTopForPeriod uses the identical ordering as '
          'getTopForPeriod — a live view must never disagree with the '
          'one-shot fetch about ranking order', () {
        // Same reasoning as getTopForPeriod's own matcher above — stop
        // at the stream's own `.snapshots()` call rather than a generic
        // `\n  }`, which the wrapped parameter list would end early.
        final method = RegExp(
          r'Stream<List<WeeklyPeriodStanding>> watchTopForPeriod\(.*?\.snapshots\(\)',
          dotAll: true,
        ).firstMatch(source);
        expect(method, isNotNull, reason: 'watchTopForPeriod not found');
        final body = method!.group(0)!;
        expect(
          body.contains("orderBy('points', descending: true)"),
          isTrue,
        );
        expect(
          body.contains("orderBy('attempts', descending: true)"),
          isTrue,
        );
        expect(body.contains('orderBy(FieldPath.documentId)'), isTrue);
      });

      test('rankOf composes the same three-level comparison the payout '
          'itself uses (strictly higher points; OR tied points with '
          'strictly higher attempts; OR tied points AND attempts with a '
          'lower document id) rather than a single-field approximation', () {
        final method = RegExp(
          r'Future<int\?> rankOf\(.*?\n  \}',
          dotAll: true,
        ).firstMatch(source);
        expect(method, isNotNull, reason: 'rankOf not found');
        final body = method!.group(0)!;
        expect(body.contains("where('points', isGreaterThan:"), isTrue);
        expect(
          body.contains("where('attempts', isGreaterThan:"),
          isTrue,
        );
        expect(body.contains('FieldPath.documentId, isLessThan:'), isTrue);
      });

      test('no write method exists anywhere in this repository — every '
          'method is read-only by construction, since there is no '
          'legitimate client write path to either collection at all', () {
        expect(source.contains('.set('), isFalse);
        expect(source.contains('.update('), isFalse);
        expect(RegExp(r'\bdelete\s*\(').hasMatch(source), isFalse);
      });
    },
  );
}
