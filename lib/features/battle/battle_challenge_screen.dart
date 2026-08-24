import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_loading.dart';
import '../../data/models/battle_invite.dart';
import '../../data/models/clan_member.dart';
import '../../data/models/clan_membership.dart';
import '../../data/models/friend.dart';
import '../../data/models/leaderboard_entry.dart';
import '../leaderboard/clan_providers.dart';
import '../leaderboard/friend_providers.dart';
import '../leaderboard/leaderboard_screen.dart' show LeaderboardAvatar;
import 'battle_challenge.dart';

enum _ChallengeMode { friend, clan }

/// Picks a friend or clan mate to challenge — reached from Card Battle's
/// own Battle tab.
///
/// **Moved here from Profile, not duplicated.** A friend's "⚔️ Tantang"
/// button used to sit on `ChatHubScreen`'s own row, and a clan mate's on
/// `ClanMembersScreen` — both removed from there. Challenging is a Card
/// Battle action, the same way accepting one is (see
/// [PendingBattleInvitesStrip], moved here alongside it) — Profile's chat/
/// clan screens stay about messaging and roster management, not battling.
class BattleChallengeScreen extends ConsumerStatefulWidget {
  const BattleChallengeScreen({super.key});

  @override
  ConsumerState<BattleChallengeScreen> createState() =>
      _BattleChallengeScreenState();
}

class _BattleChallengeScreenState extends ConsumerState<BattleChallengeScreen> {
  _ChallengeMode _mode = _ChallengeMode.friend;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: Text(s.battleChallengePickOpponentTitle)),
      body: Column(
        children: [
          const PendingBattleInvitesStrip(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _ModeSwitch(
              mode: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
              friendLabel: s.battleChallengeModeFriend,
              clanLabel: s.battleChallengeModeClan,
            ),
          ),
          Expanded(
            child: _mode == _ChallengeMode.friend
                ? const _FriendChallengeList()
                : const _ClanChallengeSection(),
          ),
        ],
      ),
    );
  }
}

/// Same rounded two-segment pill shape as `ChatHubScreen`'s own mode
/// switch — kept as its own small copy rather than sharing a widget across
/// features, the same call already made for that screen's `_SectionLabel`-
/// style pieces elsewhere in this app.
class _ModeSwitch extends StatelessWidget {
  final _ChallengeMode mode;
  final ValueChanged<_ChallengeMode> onChanged;
  final String friendLabel;
  final String clanLabel;

  const _ModeSwitch({
    required this.mode,
    required this.onChanged,
    required this.friendLabel,
    required this.clanLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.palette.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.progressTrack),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: friendLabel,
              active: mode == _ChallengeMode.friend,
              onTap: () => onChanged(_ChallengeMode.friend),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: clanLabel,
              active: mode == _ChallengeMode.clan,
              onTap: () => onChanged(_ChallengeMode.clan),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? context.palette.primaryCoral : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: active ? Colors.white : context.palette.textNavy,
          ),
        ),
      ),
    );
  }
}

class _FriendChallengeList extends ConsumerWidget {
  const _FriendChallengeList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final friendsAsync = ref.watch(myFriendsProvider);

    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          return _EmptyState(
            emoji: '🤝',
            title: s.battleChallengeNoFriendsTitle,
            body: s.battleChallengeNoFriendsBody,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _OpponentRow.friend(friends[index]),
        );
      },
      loading: () => const AppLoading(),
      error: (e, _) => Center(child: Text(s.failedToLoadFriends(e))),
    );
  }
}

class _ClanChallengeSection extends ConsumerStatefulWidget {
  const _ClanChallengeSection();

  @override
  ConsumerState<_ClanChallengeSection> createState() =>
      _ClanChallengeSectionState();
}

class _ClanChallengeSectionState extends ConsumerState<_ClanChallengeSection> {
  String? _selectedCode;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final clansAsync = ref.watch(myClansProvider);

    return clansAsync.when(
      data: (clans) {
        if (clans.isEmpty) {
          return _EmptyState(
            emoji: '👥',
            title: s.battleChallengeNoClansTitle,
            body: s.battleChallengeNoClansBody,
          );
        }
        // Defaults to the first clan (and re-picks if the previously
        // selected one is no longer in the list, e.g. the learner left
        // it) — mirrors `ChatHubScreen`'s pre-redesign clan picker
        // reasoning: a learner belonging to more than one clan needs a
        // way to say which roster they mean.
        final selected = clans.any((c) => c.code == _selectedCode)
            ? _selectedCode!
            : clans.first.code;
        final selectedClan = clans.firstWhere((c) => c.code == selected);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (clans.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: DropdownButtonFormField<String>(
                  key: ValueKey(selected),
                  initialValue: selected,
                  decoration: InputDecoration(
                    labelText: s.battleChallengeSelectClanHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final clan in clans)
                      DropdownMenuItem(
                        value: clan.code,
                        child: Text(clan.name),
                      ),
                  ],
                  onChanged: (code) => setState(() => _selectedCode = code),
                ),
              ),
            Expanded(child: _ClanMemberChallengeList(clan: selectedClan)),
          ],
        );
      },
      loading: () => const AppLoading(),
      error: (e, _) => Center(child: Text(s.failedToLoadClan(e))),
    );
  }
}

class _ClanMemberChallengeList extends ConsumerWidget {
  final ClanMembership clan;

  const _ClanMemberChallengeList({required this.clan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final myUid = ref.watch(appStartupProvider).valueOrNull?.uid;
    final membersAsync = ref.watch(clanMembersProvider(clan.code));

    return membersAsync.when(
      data: (members) {
        final others = members.where((m) => m.uid != myUid).toList();
        if (others.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s.battleChallengeNoOtherMembers,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.palette.textNavy),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: others.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _OpponentRow.clanMember(others[index]),
        );
      },
      loading: () => const AppLoading(),
      error: (e, _) => Center(child: Text(s.failedToLoadMembers(e))),
    );
  }
}

/// One row — avatar, name, the `ChallengeButton` — shared by the friend
/// and clan-member lists. Built from whichever identity type the caller
/// has ([Friend] or [ClanMember]), both of which already carry the same
/// avatar fields `LeaderboardAvatar` needs.
class _OpponentRow extends StatelessWidget {
  final String uid;
  final String displayName;
  final LeaderboardEntry throwawayEntry;
  final BattleInviteSource source;

  const _OpponentRow._({
    required this.uid,
    required this.displayName,
    required this.throwawayEntry,
    required this.source,
  });

  factory _OpponentRow.friend(Friend friend) {
    return _OpponentRow._(
      uid: friend.uid,
      displayName: friend.displayName,
      throwawayEntry: LeaderboardEntry(
        uid: friend.uid,
        displayName: friend.displayName,
        photoUrl: friend.photoUrl,
        avatarType: friend.avatarType,
        avatarValue: friend.avatarValue,
        totalMastered: 0,
        examHighScore: 0,
        updatedAt: friend.addedAt,
      ),
      source: BattleInviteSource.friend,
    );
  }

  factory _OpponentRow.clanMember(ClanMember member) {
    return _OpponentRow._(
      uid: member.uid,
      displayName: member.displayName,
      throwawayEntry: LeaderboardEntry(
        uid: member.uid,
        displayName: member.displayName,
        photoUrl: member.photoUrl,
        avatarType: member.avatarType,
        avatarValue: member.avatarValue,
        totalMastered: 0,
        examHighScore: 0,
        updatedAt: member.joinedAt,
      ),
      source: BattleInviteSource.clan,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            LeaderboardAvatar(entry: throwawayEntry, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.palette.textNavy,
                ),
              ),
            ),
            ChallengeButton(
              targetUid: uid,
              targetName: displayName,
              source: source,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;

  const _EmptyState({
    required this.emoji,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.palette.textNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textNavy),
            ),
          ],
        ),
      ),
    );
  }
}
