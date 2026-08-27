import 'ad_reward.dart';

/// Every avatar/frame/cover unlock signal a picker's tap decision needs,
/// read live from the same `users/{uid}` document `xpProgressProvider`
/// already listens to (`xp.unlocked{Avatar,Frame,Cover}Ids`) plus the
/// sibling `adRewards` map.
///
/// **Why this exists, not just "read the fields inline"**: Avatar/Frame/
/// Cover pickers used to load these once via a one-shot `Future` fetch in
/// `initState`, into plain `State` fields. That was fine for a picker
/// opened fresh each time (Profile's bottom-sheet), but Toko's own copies
/// of these three pickers are kept alive for the app's whole session
/// (`HomeScreen`'s `_KeepAlivePage`/`AutomaticKeepAliveClientMixin`), so
/// once mounted they never refreshed again — a level-up reward
/// (`ProgressRepository.claimLevelReward`, "Klaim hadiah" on Home) granted
/// through a completely different screen left an already-mounted Toko
/// picker showing that same item as locked for the rest of the session,
/// even though it was already genuinely owned. See
/// AUDIT_COSMETIC_PROFILE_SHOP.md's BUG-1 for the full trace.
///
/// Live-watching this instead (via [ProgressRepository.watchUnlockedCosmetics]
/// / `unlockedCosmeticsProvider`) closes that gap the same way
/// `xpProgressProvider` already does for `totalXp`/`claimedLevel` on the
/// same document — no picker-specific plumbing, no callback from
/// Home back into Toko, just the provider each screen already watches
/// updating on its own the moment Firestore does.
class UnlockedCosmetics {
  final Set<String> avatarIds;
  final Set<String> frameIds;
  final Set<String> coverIds;

  /// Keyed by module id (`avatar_premium`/`frame_premium`/`cover_premium`),
  /// same shape [ProgressRepository.getAdRewards] already returned.
  final Map<String, AdReward> adRewards;

  const UnlockedCosmetics({
    required this.avatarIds,
    required this.frameIds,
    required this.coverIds,
    required this.adRewards,
  });

  static const empty = UnlockedCosmetics(
    avatarIds: {},
    frameIds: {},
    coverIds: {},
    adRewards: {},
  );

  bool isAdRewardActive(String moduleId) => adRewards[moduleId]?.isActive ?? false;

  factory UnlockedCosmetics.fromMap(Map<String, dynamic>? data) {
    final xp = data?['xp'] as Map<String, dynamic>?;
    final rewardsRaw = data?['adRewards'] as Map<String, dynamic>?;
    return UnlockedCosmetics(
      avatarIds: _stringSet(xp?['unlockedAvatarIds']),
      frameIds: _stringSet(xp?['unlockedFrameIds']),
      coverIds: _stringSet(xp?['unlockedCoverIds']),
      adRewards: rewardsRaw == null
          ? const {}
          : rewardsRaw.map(
              (moduleId, value) => MapEntry(
                moduleId,
                AdReward.fromMap(moduleId, value as Map<String, dynamic>),
              ),
            ),
    );
  }

  static Set<String> _stringSet(dynamic value) {
    if (value is! List) return const {};
    return value.whereType<String>().toSet();
  }
}
