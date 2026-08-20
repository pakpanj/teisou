import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/count_badge.dart';
import '../../data/models/friend_request.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import 'friend_providers.dart';
import 'leaderboard_screen.dart' show LeaderboardAvatar;
import 'widgets/search_friend_tab.dart';

/// Dedicated "Tambah Teman" entry point — its own icon on `ProfileScreen`'s
/// app bar, separate from the 🏆 leaderboard and 💬 chat icons, per an
/// explicit request to give search and confirmation their own mapped menu
/// instead of being buried inside a Leaderboard tab. Two tabs: search by
/// exact unique id/name (`SearchFriendTab`, unchanged logic, just no longer
/// hosting its own `Scaffold`), and the incoming requests a learner still
/// needs to confirm — the second tab a badge (`CountBadge`) sits on, since
/// that's the one that actually needs the learner's attention.
class AddFriendScreen extends ConsumerWidget {
  const AddFriendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final pendingCount = ref.watch(pendingFriendRequestCountProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.palette.background,
        appBar: AppBar(
          title: Text(s.addFriendMenuTitle),
          bottom: TabBar(
            labelColor: context.palette.primaryCoral,
            unselectedLabelColor: context.palette.textNavy,
            indicatorColor: context.palette.primaryCoral,
            tabs: [
              Tab(text: s.addFriendTabSearch),
              Tab(
                child: CountBadge(
                  count: pendingCount,
                  child: Text(s.addFriendTabIncoming),
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SearchFriendTab(),
            _IncomingRequestsTab(),
          ],
        ),
      ),
    );
  }
}

/// The "Permintaan" tab — every pending friend request addressed to the
/// signed-in learner, with Accept/Decline right there. Moved here (full
/// tab, not a small strip) from what used to be `FriendsTab`'s
/// `_PendingFriendRequestsStrip`.
class _IncomingRequestsTab extends ConsumerWidget {
  const _IncomingRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final requestsAsync = ref.watch(myPendingFriendRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📭', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    s.noIncomingRequestsTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: context.palette.textNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.noIncomingRequestsBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.palette.textNavy),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _IncomingRequestRow(request: requests[index], strings: s),
        );
      },
      loading: () => const AppLoading(),
      error: (e, _) => Center(child: Text(s.failedToLoadFriends(e))),
    );
  }
}

class _IncomingRequestRow extends ConsumerStatefulWidget {
  final FriendRequest request;
  final AppStrings strings;

  const _IncomingRequestRow({required this.request, required this.strings});

  @override
  ConsumerState<_IncomingRequestRow> createState() =>
      _IncomingRequestRowState();
}

class _IncomingRequestRowState extends ConsumerState<_IncomingRequestRow> {
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
      if (accept) {
        // The conversation document has to exist before either side can
        // read the messages under it — `firestore.rules` gates that
        // subcollection on the parent's `participants`, and a rule cannot
        // decode uids out of the id string. Created here, at the one
        // moment a friendship begins, rather than left to whoever opens
        // the chat screen first: the chat hub subscribes to every
        // friend's messages to show a preview line, so a friendship
        // without this document means a listener that is refused for
        // ever. Best-effort — the friendship itself already succeeded.
        try {
          await ref.read(directMessageRepositoryProvider).ensureConversation(
                uidA: uid,
                uidB: widget.request.fromUid,
              );
        } catch (_) {}
      }
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
    final avatarEntry = LeaderboardEntry(
      uid: widget.request.fromUid,
      displayName: widget.request.fromName,
      photoUrl: widget.request.fromPhotoUrl,
      avatarType: widget.request.fromAvatarType,
      avatarValue: widget.request.fromAvatarValue,
      totalMastered: 0,
      examHighScore: 0,
      updatedAt: widget.request.createdAt,
    );

    return Container(
      decoration: BoxDecoration(
        color: context.palette.cardWhite,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          LeaderboardAvatar(entry: avatarEntry, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.request.fromName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.palette.textNavy,
                  ),
                ),
                Text(
                  widget.strings.friendRequestSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_responding)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: widget.strings.declineFriendRequest,
                  style: IconButton.styleFrom(
                    backgroundColor: context.palette.errorRed.withValues(alpha: 0.1),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () => _respond(false),
                  icon: Icon(Icons.close, color: context.palette.errorRed, size: 18),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: widget.strings.acceptFriendRequest,
                  style: IconButton.styleFrom(
                    backgroundColor: context.palette.successGreen.withValues(alpha: 0.12),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () => _respond(true),
                  icon: Icon(Icons.check, color: context.palette.successGreen, size: 18),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
