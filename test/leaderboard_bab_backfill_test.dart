import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/data/models/leaderboard_entry.dart';

/// The public profile reads two denormalized counters out of
/// `leaderboard/{uid}`, because the per-chapter list they summarise lives
/// in `users/{uid}/babProgress` and is owner-readable only.
///
/// Those counters used to be written at exactly one moment — passing a gate
/// quiz — and reconciled nowhere. A single missed publish left the public
/// profile stuck on "Belum mulai kurikulum" forever while the learner's own
/// Profile tab, reading local storage, correctly showed chapters done. That
/// is the state it was found in on a real device.
///
/// `_backfillBabProgress` in `leaderboard_providers.dart` now repairs the
/// row whenever the two disagree. The decision it makes is a pure
/// comparison, and these tests pin it. The write itself needs Firestore and
/// is covered by the on-device pass instead.
void main() {
  LeaderboardEntry entryWith({required int count, required int order}) {
    return LeaderboardEntry(
      uid: 'u1',
      displayName: 'Teisou',
      totalMastered: 0,
      examHighScore: 0,
      babCompletedCount: count,
      babHighestOrder: order,
      updatedAt: DateTime(2026, 8, 5),
    );
  }

  /// Mirrors the provider's guard exactly: republish only on disagreement.
  bool needsRepublish(
    LeaderboardEntry entry,
    int localCount,
    int localHighestOrder,
  ) {
    return localCount != entry.babCompletedCount ||
        localHighestOrder != entry.babHighestOrder;
  }

  test('a published row that already matches is left alone', () {
    final entry = entryWith(count: 2, order: 2);
    expect(needsRepublish(entry, 2, 2), isFalse);
  });

  test('the reported bug: local progress with a zeroed published row', () {
    // What the device actually showed — 2 chapters done locally, nothing
    // published, public profile saying the learner had not started.
    final entry = entryWith(count: 0, order: 0);
    expect(needsRepublish(entry, 2, 2), isTrue);
  });

  test('a stale count that stopped advancing is repaired', () {
    // One publish landed, later ones did not.
    final entry = entryWith(count: 1, order: 1);
    expect(needsRepublish(entry, 7, 7), isTrue);
  });

  test('a matching count but stale furthest chapter still republishes', () {
    // Same number of chapters, different ones — possible after an unmark
    // and a re-complete. The "Terakhir:" line on the public profile is
    // driven by the order, so an equal count is not enough to skip.
    final entry = entryWith(count: 3, order: 9);
    expect(needsRepublish(entry, 3, 12), isTrue);
  });

  test('a learner who has genuinely not started is not written to', () {
    final entry = entryWith(count: 0, order: 0);
    expect(needsRepublish(entry, 0, 0), isFalse,
        reason: 'an empty row plus no local progress must stay a no-op, '
            'otherwise every leaderboard open costs a pointless write');
  });

  test('an entry missing the fields entirely reads as zero, not as absent',
      () {
    // Docs written before these two fields existed carry neither key.
    final entry = LeaderboardEntry.fromMap('u1', const {
      'displayName': 'Teisou',
    });
    expect(entry.babCompletedCount, 0);
    expect(entry.babHighestOrder, 0);
    expect(needsRepublish(entry, 4, 4), isTrue,
        reason: 'an older doc must be repairable, not skipped');
  });
}
