import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/leaderboard_entry.dart';

/// Top 20 by global score. No longer keyed by a metric: the leaderboard
/// ranks by one number now (every exam category's Rekor added together),
/// so there's a single ranking to watch instead of one stream per tab.
final leaderboardTopProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(leaderboardRepositoryProvider).watchTop();
});

/// The signed-in user's own leaderboard row, or null if they've never
/// earned one.
///
/// Also repairs the denormalized `globalScore` sort key when it has drifted
/// (or never existed, for docs written before that field did) — a write from
/// a read-shaped provider, which is deliberate: Firestore's `orderBy` drops
/// documents missing the sorted field, so without this every pre-existing
/// user would be invisible in the ranking until their next exam submission.
/// Doing it here means simply opening the leaderboard heals your own row.
/// It's a no-op once in sync, and best-effort — a failed backfill must not
/// take down the screen, since the entry itself is still perfectly readable.
final selfLeaderboardEntryProvider =
    FutureProvider<LeaderboardEntry?>((ref) async {
  final user = await ref.watch(appStartupProvider.future);
  final repository = ref.watch(leaderboardRepositoryProvider);
  final entry = await repository.getSelf(user.uid);
  if (entry != null) {
    try {
      await repository.backfillGlobalScore(entry);
    } catch (_) {
      // Ranking may briefly omit this user; the next open retries.
    }
  }
  return entry;
});

/// The user's 1-based rank. Reuses the single shared entry above rather than
/// re-reading the doc, so this costs only its own count query.
final selfRankProvider = FutureProvider<int?>((ref) async {
  final self = await ref.watch(selfLeaderboardEntryProvider.future);
  if (self == null) return null;
  return ref.watch(leaderboardRepositoryProvider).rankOf(self);
});
