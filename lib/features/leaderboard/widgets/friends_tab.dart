import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/friend.dart';
import '../../../data/models/friend_request.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../../../data/models/user_profile.dart' show AvatarType;
import '../friend_providers.dart';
import '../leaderboard_screen.dart' show LeaderboardAvatar;
import 'direct_message_screen.dart';
import 'search_friend_screen.dart';

/// Tab 4 of `LeaderboardScreen` — personal friends and 1:1 chat, found by
/// searching someone's exact unique id or name (`SearchFriendScreen`)
/// rather than open messaging to any public user. See
/// `DirectMessageRepository`'s doc comment for the full child-safety
/// reasoning behind that scope.
class FriendsTab extends ConsumerWidget {
  const FriendsTab({super.key});

  Future<void> _removeFriend(
    BuildContext context,
    WidgetRef ref,
    Friend friend,
  ) async {
    final s = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.removeFriendConfirmTitle(friend.displayName)),
        content: Text(s.removeFriendConfirmBody(friend.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.removeFriend),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final myUid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (myUid == null) return;
    try {
      await ref
          .read(friendRepositoryProvider)
          .removeFriend(uid: myUid, friendUid: friend.uid);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.removeFriendFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final friendsAsync = ref.watch(myFriendsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchFriendScreen()),
        ),
        icon: const Icon(Icons.person_search),
        label: Text(s.findFriend),
      ),
      body: Column(
        children: [
          const _PendingFriendRequestsStrip(),
          Expanded(
            child: friendsAsync.when(
              data: (friends) {
                if (friends.isEmpty) return _NoFriendsState(strings: s);
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: friends.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return _FriendRow(
                      friend: friend,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DirectMessageScreen(
                            friendUid: friend.uid,
                            friendName: friend.displayName,
                          ),
                        ),
                      ),
                      onRemove: () => _removeFriend(context, ref, friend),
                    );
                  },
                );
              },
              loading: () => const AppLoading(),
              error: (e, _) => Center(child: Text(s.failedToLoadFriends(e))),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pending friend requests — same "collapses to nothing when empty" shape
/// as `ClanTab`'s `_PendingInvitesStrip`.
class _PendingFriendRequestsStrip extends ConsumerWidget {
  const _PendingFriendRequestsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myPendingFriendRequestsProvider);
    final requests = requestsAsync.valueOrNull ?? const [];
    if (requests.isEmpty) return const SizedBox.shrink();

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
            s.pendingFriendRequestsTitle(requests.length),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy,
            ),
          ),
          for (final request in requests)
            _FriendRequestRow(request: request, strings: s),
        ],
      ),
    );
  }
}

class _FriendRequestRow extends ConsumerStatefulWidget {
  final FriendRequest request;
  final AppStrings strings;

  const _FriendRequestRow({required this.request, required this.strings});

  @override
  ConsumerState<_FriendRequestRow> createState() => _FriendRequestRowState();
}

class _FriendRequestRowState extends ConsumerState<_FriendRequestRow> {
  bool _responding = false;

  Future<void> _respond(bool accept) async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _responding = true);

    final profile = ref.read(userProfileProvider).valueOrNull;
    final user = ref.read(appStartupProvider).valueOrNull;
    try {
      await ref.read(friendRepositoryProvider).respondToRequest(
            uid: uid,
            request: widget.request,
            accept: accept,
            myName: profile?.resolveDisplayName(user) ??
                (user?.displayName ?? widget.strings.defaultLearnerName),
            myPhotoUrl: user?.photoURL,
            myAvatarType: profile?.avatarType ?? AvatarType.google,
            myAvatarValue: profile?.avatarValue,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.friendRequestRespondFailed)),
      );
      setState(() => _responding = false);
    }
    // On success there's nothing to reset — the request leaves the
    // pending list via watchMyRequests' own live status filter.
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.strings.friendRequestFrom(widget.request.fromName),
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
              onPressed: () => _respond(false),
              child: Text(widget.strings.declineFriendRequest),
            ),
            FilledButton(
              onPressed: () => _respond(true),
              child: Text(widget.strings.acceptFriendRequest),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoFriendsState extends StatelessWidget {
  final AppStrings strings;

  const _NoFriendsState({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤝', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              strings.noFriendsYetTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.palette.textNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.noFriendsYetBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textNavy),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FriendRow({
    required this.friend,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              LeaderboardAvatar(
                entry: _asEntry(friend),
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  friend.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.palette.textNavy,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chat_bubble_outline,
                    color: context.palette.primaryCoral),
                onPressed: onTap,
              ),
              IconButton(
                icon: Icon(Icons.person_remove, color: context.palette.errorRed),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [LeaderboardAvatar] takes a `LeaderboardEntry`, this screen only has a
/// [Friend] — both carry the same identity fields, so a throwaway entry
/// reuses the real avatar-resolution logic instead of a stripped-down copy,
/// mirroring exactly how `ClanMembersScreen`'s `_MemberRow` does the same
/// thing for a `ClanMember`.
LeaderboardEntry _asEntry(Friend friend) => LeaderboardEntry(
      uid: friend.uid,
      displayName: friend.displayName,
      photoUrl: friend.photoUrl,
      avatarType: friend.avatarType,
      avatarValue: friend.avatarValue,
      totalMastered: 0,
      examHighScore: 0,
      updatedAt: friend.addedAt,
    );
