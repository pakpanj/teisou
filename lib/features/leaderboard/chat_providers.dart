import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/repositories/direct_message_repository.dart';
import 'clan_providers.dart';
import 'friend_providers.dart';

/// How many of the learner's clans + friends have an unread chat message
/// right now — the number `CountBadge` shows on the 💬 Chat icon.
///
/// Watches every clan/friend's own [clanChatUnreadProvider]/
/// [directChatUnreadProvider] individually rather than maintaining a
/// separate counter anywhere — Riverpod re-runs this the moment any one
/// of those flips, so the badge is exactly as live as the underlying
/// per-conversation unread checks are, with nothing extra to keep in
/// sync. Fine at this app's scale (a learner's own clan/friend lists are
/// always small — classroom-sized, not thousands), which is also why
/// there's no persistent Cloud Functions-maintained aggregate here: this
/// project has none, and doesn't need one for a number this cheap to
/// derive client-side.
final totalUnreadChatCountProvider = Provider<int>((ref) {
  final myUid = ref.watch(appStartupProvider).valueOrNull?.uid;
  final clans = ref.watch(myClansProvider).valueOrNull ?? const [];
  final friends = ref.watch(myFriendsProvider).valueOrNull ?? const [];
  if (myUid == null) return 0;

  var count = 0;
  for (final clan in clans) {
    if (ref.watch(clanChatUnreadProvider(clan.code))) count++;
  }
  for (final friend in friends) {
    final conversationId =
        DirectMessageRepository.conversationId(myUid, friend.uid);
    if (ref.watch(directChatUnreadProvider(conversationId))) count++;
  }
  return count;
});
