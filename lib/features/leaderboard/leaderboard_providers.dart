import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../bab/bab_providers.dart';

/// Top 20 by global score. No longer keyed by a metric: the leaderboard
/// ranks by one number now (every exam category's Rekor added together),
/// so there's a single ranking to watch instead of one stream per tab.
///
/// **Waits for `appStartupProvider` before subscribing.** Without this, the
/// `.snapshots()` listener can fire before Firebase anonymous sign-in
/// resolves — the very first request goes out with no `auth`, Firestore's
/// rules correctly reject it with `permission-denied`, and a `.snapshots()`
/// stream that has already failed a security-rule check does not silently
/// retry on its own once auth becomes valid a moment later. This provider
/// is a plain (non-`autoDispose`) `StreamProvider`, so that failed state
/// stuck around for the rest of the app session — reproduced as "Peringkat
/// ke-18" rendering fine (via `selfLeaderboardEntryProvider`, which already
/// awaits startup first) while the ranked list below it stayed on a
/// permission-denied error forever. Same bug shape already fixed elsewhere
/// in this codebase for the same reason; this provider had never been
/// updated to match.
final leaderboardTopProvider = StreamProvider<List<LeaderboardEntry>>((
  ref,
) async* {
  await ref.watch(appStartupProvider.future);
  yield* ref.watch(leaderboardRepositoryProvider).watchTop();
});

/// The signed-in user's own leaderboard row, or null if the doc genuinely
/// can't be created right now (offline on the very first-ever open).
///
/// Also repairs the denormalized `globalScore` sort key when it has drifted
/// (or never existed, for docs written before that field did) — a write from
/// a read-shaped provider, which is deliberate: Firestore's `orderBy` drops
/// documents missing the sorted field, so without this every pre-existing
/// user would be invisible in the ranking until their next exam submission.
/// Doing it here means simply opening the leaderboard heals your own row.
/// It's a no-op once in sync, and best-effort — a failed backfill must not
/// take down the screen, since the entry itself is still perfectly readable.
///
/// **Creates the doc itself if missing, rather than only relying on
/// `appStartupProvider`'s separate `ensurePublished` call.** That call is
/// `unawaited` (has to be — see `appStartupProvider`'s own doc comment on why
/// startup can't block on Firestore writes), so it races this provider: on a
/// real device, the very first read here regularly beats that write to the
/// server, resolves to `entry: null`, and — because this used to be a plain
/// (non-`autoDispose`) `FutureProvider` — stayed cached at `null` for the
/// rest of the app session even after `ensurePublished`'s write landed a
/// moment later. Confirmed on-device: a direct `getSelf` call showed the doc
/// already existed with a real `globalScore`, while this provider's cached
/// value was still `null` and the UI kept showing "Belum ada" — this is
/// exactly the "must save your name first" bug report, since `EditNameDialog`
/// happened to be the one action that wrote the doc through a *different,
/// unraced* path (`syncProfileInfo`, called directly, not gated behind
/// reading this provider first). Awaiting the create-if-missing step here
/// closes the race outright — the doc is guaranteed to exist (network
/// permitting) by the time this provider resolves, not just "usually does".
/// `.autoDispose` is added on top as a second line of defense for the rarer
/// genuinely-offline-on-first-open case, though it only actually retries once
/// every listener (Profile's card *and* the Leaderboard screen) has
/// unsubscribed — Profile's own tab is kept alive across tab switches, so in
/// practice a fresh Leaderboard-screen open is the more reliable retry
/// trigger than merely revisiting the Profile tab.
final selfLeaderboardEntryProvider =
    FutureProvider.autoDispose<LeaderboardEntry?>((ref) async {
  final user = await ref.watch(appStartupProvider.future);
  final repository = ref.watch(leaderboardRepositoryProvider);
  var entry = await repository.getSelf(user.uid);
  if (entry == null) {
    try {
      await repository.ensurePublished(
        uid: user.uid,
        displayName: user.displayName ?? 'Pelajar Kana',
        photoUrl: user.photoURL,
      );
      entry = await repository.getSelf(user.uid);
    } catch (_) {
      // Genuinely offline on the very first open — nothing to back into;
      // the next open (autoDispose) retries.
    }
  }
  if (entry != null) {
    // A separate non-nullable local: `entry` is reassigned inside the try
    // blocks below, which loses Dart's null-promotion across a try/catch
    // boundary — this avoids re-fighting that on every line that follows.
    var current = entry;
    try {
      await repository.backfillGlobalScore(current);
    } catch (_) {
      // Ranking may briefly omit this user; the next open retries.
    }
    try {
      await repository.backfillDisplayNameLower(current);
    } catch (_) {
      // Search may briefly miss this user; the next open retries.
    }
    try {
      final profile = await ref.watch(userProfileProvider.future);
      await repository.backfillUserId(current, profile.userId);
      final resolvedName = profile.resolveDisplayName(user);
      await repository.backfillDisplayName(current, resolvedName);
      if (current.displayName != resolvedName) {
        final refreshed = await repository.getSelf(user.uid);
        if (refreshed != null) current = refreshed;
      }
    } catch (_) {
      // Search-by-id/name may briefly miss this user; the next open retries.
    }
    entry = await _backfillBabProgress(ref, repository, user.uid, current);
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
