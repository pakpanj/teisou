import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../core/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/count_badge.dart';
import '../../data/models/friend_request.dart';
import '../../data/models/user_profile.dart' show AvatarType;
import 'friend_providers.dart';
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
    return Material(
      color: context.palette.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.strings.friendRequestFrom(widget.request.fromName),
                style: TextStyle(color: context.palette.textNavy),
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
      ),
    );
  }
}
