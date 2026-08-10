import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/direct_message.dart';
import '../../data/models/friend.dart';
import '../../data/models/friend_request.dart';

/// Live — one user's own friend list, small enough to keep streaming so it
/// updates instantly after a request is accepted or a friend is removed.
final myFriendsProvider = StreamProvider<List<Friend>>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(friendRepositoryProvider).watchFriends(user.uid);
});

/// Live — small (one user's own pending friend requests), so the "kamu
/// punya N permintaan" strip updates the instant one arrives or is
/// answered.
final myPendingFriendRequestsProvider =
    StreamProvider<List<FriendRequest>>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(friendRepositoryProvider).watchMyRequests(user.uid);
});

/// Live — the last 100 messages in a 1:1 conversation, oldest first.
final directMessagesProvider =
    StreamProvider.family<List<DirectMessage>, String>((ref, conversationId) {
  return ref
      .watch(directMessageRepositoryProvider)
      .watchMessages(conversationId);
});
