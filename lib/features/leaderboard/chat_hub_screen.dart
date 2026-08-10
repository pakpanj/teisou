import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_loading.dart';
import '../../data/models/clan_membership.dart';
import '../../data/models/friend.dart';
import 'clan_providers.dart';
import 'friend_providers.dart';
import 'widgets/clan_chat_screen.dart';
import 'widgets/direct_message_screen.dart';

enum _ChatMode { clan, personal }

/// Dedicated "Chat" entry point — its own icon on `ProfileScreen`'s app
/// bar, separate from 🏆 leaderboard and ➕ add-friend, per an explicit
/// request to give chat its own mapped menu instead of it only being
/// reachable via icons buried inside a clan card or a friend row.
///
/// A picker, not a chat surface itself: a Clan/Pribadi mode toggle, then a
/// dropdown of whichever clans (`myClansProvider`) or friends
/// (`myFriendsProvider`) the mode implies — picking one immediately opens
/// the real chat screen (`ClanChatScreen`/`DirectMessageScreen`, both
/// unchanged), which already does all the message-list/send/report work.
/// Keeping this screen a pure picker avoids re-implementing that UI a
/// second time inline.
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
      appBar: AppBar(title: Text(s.chatMenuTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ModeTab(
                  label: s.chatModeClan,
                  active: _mode == _ChatMode.clan,
                  onTap: () => setState(() => _mode = _ChatMode.clan),
                ),
                const SizedBox(width: 20),
                _ModeTab(
                  label: s.chatModePersonal,
                  active: _mode == _ChatMode.personal,
                  onTap: () => setState(() => _mode = _ChatMode.personal),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _mode == _ChatMode.clan
                  ? const _ClanChatPicker()
                  : const _PersonalChatPicker(),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the two labels at the top that switch between Clan/Pribadi mode
/// — mirrors `AvatarPickerSheet`'s `_PickerModeTab` (Avatar/Bingkai) look
/// exactly, since this is the same "two modes sharing one screen" shape.
class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? context.palette.primaryCoral : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: active
                ? context.palette.textNavy
                : context.palette.textNavy.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _ClanChatPicker extends ConsumerStatefulWidget {
  const _ClanChatPicker();

  @override
  ConsumerState<_ClanChatPicker> createState() => _ClanChatPickerState();
}

class _ClanChatPickerState extends ConsumerState<_ClanChatPicker> {
  String? _selectedCode;

  @override
  Widget build(BuildContext context) {
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
        final selected =
            clans.any((c) => c.code == _selectedCode) ? _selectedCode : null;
        return _PickerColumn(
          hint: s.selectClanToChatHint,
          items: clans
              .map((c) => DropdownMenuItem(value: c.code, child: Text(c.name)))
              .toList(),
          value: selected,
          onChanged: (code) => setState(() => _selectedCode = code),
          buttonLabel: s.openChatButton,
          onOpen: selected == null
              ? null
              : () {
                  final clan =
                      clans.firstWhere((c) => c.code == selected);
                  _openClanChat(context, clan);
                },
        );
      },
      loading: () => const AppLoading(),
      error: (e, _) => Center(child: Text(s.failedToLoadClan(e))),
    );
  }

  void _openClanChat(BuildContext context, ClanMembership clan) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClanChatScreen(code: clan.code, clanName: clan.name),
      ),
    );
  }
}

class _PersonalChatPicker extends ConsumerStatefulWidget {
  const _PersonalChatPicker();

  @override
  ConsumerState<_PersonalChatPicker> createState() =>
      _PersonalChatPickerState();
}

class _PersonalChatPickerState extends ConsumerState<_PersonalChatPicker> {
  String? _selectedUid;

  @override
  Widget build(BuildContext context) {
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
        final selected =
            friends.any((f) => f.uid == _selectedUid) ? _selectedUid : null;
        return _PickerColumn(
          hint: s.selectFriendToChatHint,
          items: friends
              .map((f) =>
                  DropdownMenuItem(value: f.uid, child: Text(f.displayName)))
              .toList(),
          value: selected,
          onChanged: (uid) => setState(() => _selectedUid = uid),
          buttonLabel: s.openChatButton,
          onOpen: selected == null
              ? null
              : () {
                  final friend = friends.firstWhere((f) => f.uid == selected);
                  _openDirectMessage(context, friend);
                },
        );
      },
      loading: () => const AppLoading(),
      error: (e, _) => Center(child: Text(s.failedToLoadFriends(e))),
    );
  }

  void _openDirectMessage(BuildContext context, Friend friend) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DirectMessageScreen(
          friendUid: friend.uid,
          friendName: friend.displayName,
        ),
      ),
    );
  }
}

/// Shared dropdown-plus-button shape for both pickers above — a manual
/// "Buka Chat" tap rather than auto-navigating the instant the dropdown
/// changes, so browsing the options doesn't risk jumping into a chat
/// screen from an accidental selection.
class _PickerColumn extends StatelessWidget {
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String buttonLabel;
  final VoidCallback? onOpen;

  const _PickerColumn({
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.buttonLabel,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          items: items,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(buttonLabel),
          ),
        ),
      ],
    );
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
