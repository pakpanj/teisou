import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_loading.dart';
import '../../data/models/battle_invite.dart';
import '../../data/models/clan_membership.dart';
import '../../data/models/friend.dart';
import '../../data/repositories/direct_message_repository.dart';
import '../battle/battle_challenge.dart';
import '../battle/battle_invite_providers.dart';
import '../battle/battle_screen.dart';
import 'clan_providers.dart';
import 'friend_providers.dart';
import 'widgets/clan_chat_screen.dart';
import 'widgets/direct_message_screen.dart';

enum _ChatMode { clan, personal }

/// Dedicated "Chat" entry point — its own icon on `ProfileScreen`'s app
/// bar, separate from 🏆 leaderboard and ➕ add-friend. A real chat list
/// (avatar, name, last-message preview, time, unread dot) — like the
/// picker this replaced, still just a way to *reach*
/// `ClanChatScreen`/`DirectMessageScreen`, not a chat surface of its own,
/// but now showing enough at a glance that opening one is a single tap
/// instead of "pick from a dropdown, then press a button".
class ChatHubScreen extends ConsumerStatefulWidget {
  const ChatHubScreen({super.key});

  @override
  ConsumerState<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends ConsumerState<ChatHubScreen> {
  _ChatMode _mode = _ChatMode.clan;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text(s.chatMenuTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _ModeSwitch(
              clanLabel: s.chatModeClan,
              personalLabel: s.chatModePersonal,
              mode: _mode,
              onChanged: (mode) => setState(() => _mode = mode),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const _PendingBattleInvitesStrip(),
          Expanded(
            child: _mode == _ChatMode.clan
                ? const _ClanChatList()
                : const _PersonalChatList(),
          ),
        ],
      ),
    );
  }
}

/// Pending "Tantang" challenges for the signed-in learner — shown above
/// both chat lists here (not tucked inside just one mode), since a
/// challenge can arrive from either a friend or a clan mate and is
/// time-sensitive (2-minute expiry, see `BattleInvite.expiresAt`).
/// Collapsed to nothing when there are none, same "never a permanent
/// slice of the screen" discipline as Clan tab's own
/// `_PendingInvitesStrip`.
class _PendingBattleInvitesStrip extends ConsumerWidget {
  const _PendingBattleInvitesStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(myPendingBattleInvitesProvider);
    final invites = invitesAsync.valueOrNull ?? const [];
    if (invites.isEmpty) return const SizedBox.shrink();

    final s = ref.watch(appStringsProvider);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.primaryCoral.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.pendingBattleInvitesTitle(invites.length),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy,
            ),
          ),
          for (final invite in invites)
            _BattleInviteRow(invite: invite, strings: s),
        ],
      ),
    );
  }
}

class _BattleInviteRow extends ConsumerStatefulWidget {
  final BattleInvite invite;
  final AppStrings strings;

  const _BattleInviteRow({required this.invite, required this.strings});

  @override
  ConsumerState<_BattleInviteRow> createState() => _BattleInviteRowState();
}

class _BattleInviteRowState extends ConsumerState<_BattleInviteRow> {
  bool _responding = false;

  Future<void> _decline() async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _responding = true);
    try {
      await ref.read(battleInviteRepositoryProvider).respondToInvite(
            uid: uid,
            invite: widget.invite,
            accept: false,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() => _responding = false);
    }
    // On success the row disappears on its own via watchMyInvites' own
    // `status == pending` filter — nothing else to reset here.
  }

  Future<void> _accept() async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _responding = true);
    try {
      // Fire-and-forget on purpose: the match already exists (see
      // BattleInvite.matchId's own doc comment) and is what the learner
      // actually needs to reach — a failed status write here would only
      // mean this row lingers in the pending list a little longer, not
      // that joining the match itself failed.
      unawaited(
        ref.read(battleInviteRepositoryProvider).respondToInvite(
              uid: uid,
              invite: widget.invite,
              accept: true,
            ),
      );
    } catch (_) {
      // Deliberately swallowed — see the comment above.
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BattleScreen(matchId: widget.invite.matchId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tierLabel = cardTierContentLabel(
      widget.invite.cardTierContent,
      widget.strings,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.strings.battleInvitedBy(widget.invite.fromName, tierLabel),
              style: TextStyle(color: context.palette.textNavy, fontSize: 13),
            ),
          ),
          if (_responding)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            TextButton(
              onPressed: _decline,
              child: Text(widget.strings.declineInvite),
            ),
            FilledButton(
              onPressed: _accept,
              child: Text(widget.strings.acceptInvite),
            ),
          ],
        ],
      ),
    );
  }
}

/// A rounded, two-segment pill toggle — replaces the earlier underlined-
/// text tab pair with something that reads as a single control rather
/// than two form labels, closer to how a modern chat app switches
/// between inboxes.
class _ModeSwitch extends StatelessWidget {
  final String clanLabel;
  final String personalLabel;
  final _ChatMode mode;
  final ValueChanged<_ChatMode> onChanged;

  const _ModeSwitch({
    required this.clanLabel,
    required this.personalLabel,
    required this.mode,
    required this.onChanged,
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
              label: clanLabel,
              active: mode == _ChatMode.clan,
              onTap: () => onChanged(_ChatMode.clan),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: personalLabel,
              active: mode == _ChatMode.personal,
              onTap: () => onChanged(_ChatMode.personal),
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

class _ClanChatList extends ConsumerWidget {
  const _ClanChatList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final clansAsync = ref.watch(myClansProvider);

    return clansAsync.when(
      data: (clans) {
        if (clans.isEmpty) {
          return _EmptyChatState(
            emoji: '👥',
            title: s.noClansForChatTitle,
            body: s.noClansForChatBody,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: clans.length,
          separatorBuilder: (_, _) => const SizedBox(height: 2),
          itemBuilder: (context, index) => _ClanChatRow(clan: clans[index]),
        );
      },
      loading: () => const AppLoading(),
      error: (e, _) => Center(child: Text(s.failedToLoadClan(e))),
    );
  }
}

class _ClanChatRow extends ConsumerWidget {
  final ClanMembership clan;

  const _ClanChatRow({required this.clan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMessage = ref.watch(clanLastMessageProvider(clan.code)).valueOrNull;
    final unread = ref.watch(clanChatUnreadProvider(clan.code));

    return _ChatRow(
      title: clan.name,
      avatarLabel: clan.name,
      previewSenderName: lastMessage?.senderName,
      previewText: lastMessage?.text,
      time: lastMessage?.createdAt,
      unread: unread,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClanChatScreen(code: clan.code, clanName: clan.name),
        ),
      ),
    );
  }
}

class _PersonalChatList extends ConsumerWidget {
  const _PersonalChatList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final friendsAsync = ref.watch(myFriendsProvider);

    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          return _EmptyChatState(
            emoji: '🤝',
            title: s.noFriendsForChatTitle,
            body: s.noFriendsForChatBody,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: friends.length,
          separatorBuilder: (_, _) => const SizedBox(height: 2),
          itemBuilder: (context, index) =>
              _PersonalChatRow(friend: friends[index]),
        );
      },
      loading: () => const AppLoading(),
      error: (e, _) => Center(child: Text(s.failedToLoadFriends(e))),
    );
  }
}

class _PersonalChatRow extends ConsumerWidget {
  final Friend friend;

  const _PersonalChatRow({required this.friend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return const SizedBox.shrink();
    final conversationId =
        DirectMessageRepository.conversationId(myUid, friend.uid);
    final lastMessage =
        ref.watch(directLastMessageProvider(conversationId)).valueOrNull;
    final unread = ref.watch(directChatUnreadProvider(conversationId));

    return _ChatRow(
      title: friend.displayName,
      avatarLabel: friend.displayName,
      previewSenderName: null,
      previewText: lastMessage?.text,
      time: lastMessage?.createdAt,
      unread: unread,
      trailingAction: ChallengeButton(
        targetUid: friend.uid,
        targetName: friend.displayName,
        source: BattleInviteSource.friend,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DirectMessageScreen(
            friendUid: friend.uid,
            friendName: friend.displayName,
          ),
        ),
      ),
    );
  }
}

/// One WhatsApp-shaped row shared by both the clan and personal lists —
/// avatar, name, a one-line message preview (or a neutral "no messages
/// yet" placeholder), a relative timestamp, and an unread dot. Clan rows
/// additionally prefix the preview with the sender's name (a group chat
/// has more than one voice); personal rows don't need that.
class _ChatRow extends ConsumerWidget {
  final String title;
  final String avatarLabel;
  final String? previewSenderName;
  final String? previewText;
  final DateTime? time;
  final bool unread;
  final VoidCallback onTap;

  /// The friend list's `⚔️ Tantang` button — `null` for clan rows, which
  /// challenge from `ClanMembersScreen` instead (a clan's own chat row
  /// here represents the whole group, not one challengeable person).
  final Widget? trailingAction;

  const _ChatRow({
    required this.title,
    required this.avatarLabel,
    required this.previewSenderName,
    required this.previewText,
    required this.time,
    required this.unread,
    required this.onTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final preview = previewText == null
        ? s.directMessageEmpty
        : previewSenderName == null
            ? previewText!
            : '$previewSenderName: $previewText';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: context.palette.primaryCoral.withValues(alpha: 0.15),
              child: Text(
                avatarLabel.isEmpty ? '🐱' : avatarLabel[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: context.palette.primaryCoral,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.palette.textNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                      color: unread
                          ? context.palette.textNavy
                          : context.palette.textNavy.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (time != null)
                  Text(
                    _formatRelativeTime(time!),
                    style: TextStyle(
                      fontSize: 11,
                      color: unread
                          ? context.palette.primaryCoral
                          : context.palette.textNavy.withValues(alpha: 0.4),
                      fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                const SizedBox(height: 6),
                if (unread)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: context.palette.primaryCoral,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            ?trailingAction,
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays >= 1 || now.day != time.day) {
      return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
    }
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }
}

class _EmptyChatState extends StatelessWidget {
  final String emoji;
  final String title;
  final String body;

  const _EmptyChatState({
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
