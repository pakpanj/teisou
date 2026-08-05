import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../bab/bab_providers.dart';

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
  var entry = await repository.getSelf(user.uid);
  if (entry != null) {
    try {
      await repository.backfillGlobalScore(entry);
    } catch (_) {
      // Ranking may briefly omit this user; the next open retries.
    }
    entry = await _backfillBabProgress(ref, repository, user.uid, entry);
  }
  return entry;
});

/// Republishes the learner's Bab curriculum summary when the copy in
/// `leaderboard/{uid}` disagrees with their local progress, and returns the
/// corrected entry.
///
/// Those two counters used to be written at exactly one moment — passing a
/// gate quiz — with nothing anywhere reconciling them afterwards. So a
/// single missed publish (offline at that instant, or progress made before
/// the counters existed) left the public profile saying "Belum mulai
/// kurikulum" permanently, while the learner's own Profile tab, which reads
/// local SharedPreferences, correctly showed chapters done. That is exactly
/// the state this was found in.
///
/// Same shape and same reasoning as [LeaderboardRepository.
/// backfillGlobalScore] directly above: a write from a read-shaped
/// provider, so simply opening the leaderboard or your profile heals your
/// own row, a no-op once in sync, and best-effort because the entry stays
/// perfectly readable whether or not the repair lands.
///
/// Identity fields are copied from the row that already exists rather than
/// re-derived, so a repair can never clobber a display name or avatar with
/// a fallback.
Future<LeaderboardEntry> _backfillBabProgress(
  Ref ref,
  LeaderboardRepository repository,
  String uid,
  LeaderboardEntry entry,
) async {
  try {
    final all = await ref.watch(babAllProvider.future);
    final completed = await ref.watch(babCompletedIdsProvider.future);
    final done = all.where((b) => completed.contains(b.id));
    final completedCount = done.length;
    final highestOrder = done.fold<int>(
      0,
      (highest, b) => b.order > highest ? b.order : highest,
    );

    if (completedCount == entry.babCompletedCount &&
        highestOrder == entry.babHighestOrder) {
      return entry;
    }

    await repository.updateBabProgress(
      uid: uid,
      displayName: entry.displayName,
      photoUrl: entry.photoUrl,
      avatarType: entry.avatarType,
      avatarValue: entry.avatarValue,
      completedCount: completedCount,
      highestOrder: highestOrder,
    );
    // Re-read rather than patching the local copy, so what this provider
    // hands back is what other people will actually see.
    return await repository.getSelf(uid) ?? entry;
  } catch (_) {
    // Local progress is the source of truth and is untouched; the next
    // open retries.
    return entry;
  }
}

/// The user's 1-based rank. Reuses the single shared entry above rather than
/// re-reading the doc, so this costs only its own count query.
final selfRankProvider = FutureProvider<int?>((ref) async {
  final self = await ref.watch(selfLeaderboardEntryProvider.future);
  if (self == null) return null;
  return ref.watch(leaderboardRepositoryProvider).rankOf(self);
});
