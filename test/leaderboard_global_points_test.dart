import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_master/data/models/leaderboard_entry.dart';
import 'package:kana_master/data/repositories/leaderboard_repository.dart';

/// Covers the Dart-side half of Global Points: that [LeaderboardEntry]
/// parses `globalPoints` off a Firestore map correctly (including the
/// absent-vs-zero distinction — a doc with no field at all must not be
/// mistaken for a real 0), that it is genuinely never written back out by
/// [LeaderboardEntry.toMap] (the client-side half of "server-authoritative
/// only"), and that `watchTop`/`rankOf` genuinely sort on the new field
/// rather than the older `globalScore`.
///
/// This is a source-inspection pass for the repository query shape
/// (mirrors this project's own established convention for pinning a
/// Firestore query's field without a live emulator — see
/// `leaderboard_bab_backfill_test.dart`) plus a plain unit test for the
/// model parsing, since no Firebase mock exists in this test suite.
void main() {
  group('LeaderboardEntry.globalPoints parsing', () {
    test('absent from the map parses to null, not 0 — a doc that has '
        'never had a trigger-processed attempt must stay distinguishable '
        'from an account that genuinely earned zero points', () {
      final entry = LeaderboardEntry.fromMap('u1', {
        'displayName': 'Budi',
        'totalMastered': 0,
        'examHighScore': 0,
      });
      expect(entry.globalPoints, isNull);
    });

    test('a stored numeric value parses correctly', () {
      final entry = LeaderboardEntry.fromMap('u1', {
        'displayName': 'Budi',
        'totalMastered': 0,
        'examHighScore': 0,
        'globalPoints': 1234.5,
      });
      expect(entry.globalPoints, 1234.5);
    });

    test('an integer stored in Firestore (no decimal) still parses as a '
        'double — Firestore does not distinguish int/double on the wire '
        'the way Dart does', () {
      final entry = LeaderboardEntry.fromMap('u1', {
        'displayName': 'Budi',
        'totalMastered': 0,
        'examHighScore': 0,
        'globalPoints': 90,
      });
      expect(entry.globalPoints, 90.0);
    });

    test('toMap never includes globalPoints — the client must never even '
        'attempt to write it, since firestore.rules refuses the write '
        'anyway and a silently-dropped write is worse than an absent key',
        () {
      final entry = LeaderboardEntry(
        uid: 'u1',
        displayName: 'Budi',
        totalMastered: 0,
        examHighScore: 0,
        globalPoints: 500,
        updatedAt: DateTime(2026, 8, 3),
      );
      expect(entry.toMap().containsKey('globalPoints'), isFalse);
    });
  });

  group('Top Global sorts by globalPoints, not the older globalScore', () {
    test('LeaderboardRepository.globalPointsField is the new field name,'
        ' distinct from globalScoreField', () {
      expect(LeaderboardRepository.globalPointsField, 'globalPoints');
      expect(LeaderboardRepository.globalScoreField, 'globalScore');
      expect(
        LeaderboardRepository.globalPointsField,
        isNot(LeaderboardRepository.globalScoreField),
      );
    });

    test('watchTop and rankOf both orderBy/where on globalPointsField, '
        'never globalScoreField — the two must agree on which field '
        'defines "Top Global" or a self-rank display would disagree with '
        'the list it claims to rank within', () {
      final source = File(
        'lib/data/repositories/leaderboard_repository.dart',
      ).readAsStringSync();

      final watchTop = RegExp(
        r'Stream<List<LeaderboardEntry>> watchTop\(.*?\n  \}',
        dotAll: true,
      ).firstMatch(source);
      expect(watchTop, isNotNull, reason: 'watchTop not found');
      expect(watchTop!.group(0)!.contains('orderBy(globalPointsField'), isTrue);
      expect(watchTop.group(0)!.contains('orderBy(globalScoreField'), isFalse);

      final rankOf = RegExp(
        r'Future<int> rankOf\(.*?\n  \}',
        dotAll: true,
      ).firstMatch(source);
      expect(rankOf, isNotNull, reason: 'rankOf not found');
      expect(rankOf!.group(0)!.contains('where(globalPointsField'), isTrue);
      expect(rankOf.group(0)!.contains('where(globalScoreField'), isFalse);
    });
  });
}
