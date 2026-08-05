import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/clan.dart';
import '../../data/models/clan_membership.dart';
import '../../data/models/leaderboard_entry.dart';

/// Live — one user's own clan memberships, small enough to keep streaming
/// so the "pilih clan" picker updates instantly after create/join/leave.
final myClansProvider = StreamProvider<List<ClanMembership>>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(clanRepositoryProvider).watchMyClans(user.uid);
});

/// One-shot clan details (name/hostUid/memberCount) for whichever clan the
/// Clan tab currently has selected — `ClanMembership` only carries the
/// denormalized name, not `hostUid`/`memberCount`, both needed for the
/// host crown badge and the member-count display.
final clanDetailsProvider = FutureProvider.family<Clan?, String>((ref, code) {
  return ref.watch(clanRepositoryProvider).findByCode(code);
});

/// Combines a clan's full member roster with whatever leaderboard data
/// exists for each member, ranked by the same global score the main
/// leaderboard uses. Every roster member always appears — even a student
/// with zero attempts and no `leaderboard/{uid}` doc at all — because the
/// whole point of this feature is letting a teacher see every student, not
/// just the ones who've already scored something.
final clanRankingProvider =
    FutureProvider.family<List<LeaderboardEntry>, String>((ref, code) async {
  final clanRepository = ref.watch(clanRepositoryProvider);
  final leaderboardRepository = ref.watch(leaderboardRepositoryProvider);

  final members = await clanRepository.getMembersOnce(code);
  final uids = members.map((m) => m.uid).toList();
  final byUid = {
    for (final entry in await leaderboardRepository.getMany(uids))
      entry.uid: entry,
  };

  final combined = members
      .map(
        (m) =>
            byUid[m.uid] ??
            LeaderboardEntry(
              uid: m.uid,
              displayName: m.displayName,
              photoUrl: m.photoUrl,
              avatarType: m.avatarType,
              avatarValue: m.avatarValue,
              totalMastered: 0,
              examHighScore: 0,
              updatedAt: m.joinedAt,
            ),
      )
      .toList();

  return leaderboardRepository.sortByGlobalScore(combined);
});
