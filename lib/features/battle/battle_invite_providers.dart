import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/battle_invite.dart';
import '../../data/models/battle_match.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../data/repositories/battle_repository.dart' show battleBotUid;

/// Live — one user's own pending "Tantang" challenges, small enough to
/// keep streaming so the invites strip updates the instant one arrives,
/// is answered, or (via [BattleInvite.isExpired]'s client-side filter in
/// `BattleInviteRepository.watchMyInvites`) ages out past its 2-minute
/// window.
final myPendingBattleInvitesProvider =
    StreamProvider<List<BattleInvite>>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(battleInviteRepositoryProvider).watchMyInvites(user.uid);
});

/// Public identity (name + avatar) for the players in a match, keyed by
/// uid — so the arena can show who you are actually playing.
///
/// Reads `leaderboard/{uid}`, which is the app's only world-readable
/// profile row; `users/{uid}` is owner-only, so an opponent's name is
/// simply not available from there. A player with no row yet resolves to
/// nothing and the arena falls back to a neutral label: a cosmetic
/// lookup must never be able to block a match from rendering.
///
/// `family` on the player list rather than on a single uid, so both
/// sides come back in one query instead of two round trips.
///
/// **A live stream, not a one-shot fetch — this is the fix for the
/// "opponent's equipped card skin visible inconsistently" report
/// (2026-08-30, observed on iOS).** A one-shot `FutureProvider.family`
/// fetched `leaderboard/{opponentUid}` exactly once, at match entry.
/// That raced the opponent's *own* self-heal repair below
/// (`_republishMyCardSkin`) — a write that runs on *their* device, not
/// this one — so whichever side's read happened to land first saw a
/// stale/default skin for the opponent, permanently, since nothing ever
/// re-fetched. Watching both players' rows live via
/// `LeaderboardRepository.watchMany` means a correction landing even a
/// moment later still reaches this device automatically, the same
/// self-correcting behavior every other live Firestore listener in this
/// app already has. See `battle_screen.dart`'s `_skinFor` for why the
/// opponent's skin is trusted from this mirror at all rather than a
/// live entitlement re-check (a separate, still-true security
/// boundary this change does not touch).
final battleOpponentsProvider =
    StreamProvider.family<Map<String, LeaderboardEntry>, List<String>>((
  ref,
  players,
) async* {
  final real = players.where((uid) => uid != battleBotUid).toList();
  if (real.isEmpty) {
    yield const {};
    return;
  }
  final repository = ref.read(leaderboardRepositoryProvider);

  // The one-shot self-heal check stays exactly as it was — see
  // _republishMyCardSkin/_republishMyAvatar's own doc comments — just
  // run once, off a plain getMany, rather than on every live snapshot
  // below (which would be redundant: once synced, it is a no-op every
  // time anyway, but there is no reason to keep re-checking).
  final initial = await repository.getMany(real);
  final byUid = {for (final e in initial) e.uid: e};
  await _republishMyCardSkin(ref, byUid);
  await _republishMyAvatar(ref, byUid);

  yield* repository
      .watchMany(real)
      .map((entries) => {for (final e in entries) e.uid: e});
});

/// Re-publishes this player's own card skin onto their public row if the
/// two disagree.
///
/// **Because the write at selection time can fail silently, and does.**
/// Choosing a skin saves it to the private profile and then mirrors it to
/// `leaderboard/{uid}` best-effort, in a `try/catch` with nothing to show
/// for a failure — this project's standing convention for mirrors. That
/// convention is fine when the mirror only feeds a leaderboard row, and
/// wrong here: the mirror *is* the feature. Caught on two devices, where
/// a phone that had picked a skin kept showing the default to its
/// opponent until the skin was picked a second time, with nothing on the
/// owner's own screen suggesting anything was missing. For a cosmetic
/// meant to be sold, that is the worst shape of failure — you pay, you
/// see it, and nobody else does.
///
/// So it is repaired where it matters: on the way into a match, which is
/// the only place the value is ever read. Same shape as
/// `backfillGlobalScore` and the Bab progress backfill — a write from a
/// read-shaped provider, a no-op once in sync, and best-effort, since a
/// failed repair must never stop a match from rendering.
///
/// A player whose public row does not exist yet is still written to:
/// `set(merge: true)` creates it holding just this one field, which no
/// ranking can surface, because every board orders by a sort key that
/// document would not have.
Future<void> _republishMyCardSkin(
  Ref ref,
  Map<String, LeaderboardEntry> byUid,
) async {
  try {
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;
    final profile = await ref.read(userProfileProvider.future);
    if (profile.cardSkinId == byUid[myUid]?.cardSkinId) return;
    await ref
        .read(leaderboardRepositoryProvider)
        .updateCardSkinId(myUid, profile.cardSkinId);
  } catch (_) {
    // The next match tries again.
  }
}

/// C3-2 (AUDIT_PHASE_C_BATTLE_RELIABILITY.md): avatar's counterpart to
/// [_republishMyCardSkin], same self-heal shape and same reason it exists —
/// `AvatarPickerSheet` already mirrors a chosen avatar to `leaderboard/{uid}`
/// best-effort on selection, and that mirror write can fail silently the
/// same way the skin one does. Unlike the skin (which only ever renders for
/// an opponent, never for yourself, so a stale mirror was invisible to its
/// owner), a stale avatar mirror is *also* visible to every other screen
/// that reads `leaderboard/{uid}` for this uid (the global leaderboard, clan
/// rankings, public profiles) — Battle just happens to be the one place
/// this session was asked to hook the repair into, on the same "match
/// entry" read path already proven for the skin.
///
/// Deliberately does **not** touch [LeaderboardEntry.photoUrl]/
/// `displayName` — this is an avatar-only repair, matching
/// [LeaderboardRepository.updateAvatar]'s own narrow scope, not a general
/// identity resync (that's `identity_sync.dart`'s job, run at
/// name/avatar-change time, not on every match entry).
Future<void> _republishMyAvatar(
  Ref ref,
  Map<String, LeaderboardEntry> byUid,
) async {
  try {
    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;
    final profile = await ref.read(userProfileProvider.future);
    final mirrored = byUid[myUid];
    if (profile.avatarType == mirrored?.avatarType &&
        profile.avatarValue == mirrored?.avatarValue) {
      return;
    }
    await ref
        .read(leaderboardRepositoryProvider)
        .updateAvatar(myUid, profile.avatarType, profile.avatarValue);
  } catch (_) {
    // The next match tries again.
  }
}

/// The match the "Kembali ke Pertandingan" card offers a return to — see
/// `BattleRepository.findResumableMatch`'s own doc comment for the
/// query. `autoDispose`, so re-entering the Card Game lobby (from Home,
/// from the app cold-starting, or just switching tabs and back) always
/// asks fresh rather than trusting a value that could already be stale
/// — a match that resolved (naturally, or via the 30-second grace period
/// finalizing) while the lobby wasn't on screen must stop being offered
/// the moment it's looked at again.
final battleResumableMatchProvider = FutureProvider.autoDispose<BattleMatch?>((
  ref,
) async {
  final user = await ref.watch(appStartupProvider.future);
  return ref.watch(battleRepositoryProvider).findResumableMatch(user.uid);
});
