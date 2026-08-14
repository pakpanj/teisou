import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/battle_invite.dart';
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
final battleOpponentsProvider =
    FutureProvider.family<Map<String, LeaderboardEntry>, List<String>>((
  ref,
  players,
) async {
  final real = players.where((uid) => uid != battleBotUid).toList();
  if (real.isEmpty) return const {};
  final entries = await ref.read(leaderboardRepositoryProvider).getMany(real);
  return {for (final e in entries) e.uid: e};
});
