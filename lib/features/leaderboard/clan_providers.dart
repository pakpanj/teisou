import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/models/clan.dart';
import '../../data/models/clan_announcement.dart';
import '../../data/models/clan_invite.dart';
import '../../data/models/clan_member.dart';
import '../../data/models/clan_membership.dart';
import '../../data/models/clan_message.dart';
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

  // Self-heals Clan.totalScore (the Top Clan sort key) the same way
  // selfLeaderboardEntryProvider self-heals globalScore — a write from a
  // read-shaped provider, best-effort, so simply opening a clan's own
  // ranking keeps its Top Clan standing current without a live increment
  // on every single exam across every member's every clan.
  try {
    final totalScore = combined.fold<double>(
      0,
      (sum, entry) => sum + entry.computedGlobalScore,
    );
    await clanRepository.updateTotalScore(code, totalScore);
  } catch (_) {
    // Ranking itself is still perfectly usable; the next open retries.
  }

  return leaderboardRepository.sortByGlobalScore(combined);
});

/// Raw roster with each member's [ClanRole] — unlike [clanRankingProvider],
/// which merges in live leaderboard data for scoring, this is what
/// role-aware UI (promote/demote/kick) needs, since `LeaderboardEntry`
/// carries no role at all. One-shot, refreshed the same way the ranking
/// screen refreshes: on tab re-entry or pull-to-refresh.
final clanMembersProvider =
    FutureProvider.family<List<ClanMember>, String>((ref, code) {
  return ref.watch(clanRepositoryProvider).getMembersOnce(code);
});

/// The signed-in user's own [ClanRole] in [code], or `null` if they're not
/// a member at all (shouldn't normally happen for a clan they can see the
/// ranking of, but a role check has to handle it rather than assume).
final myRoleInClanProvider =
    FutureProvider.family<ClanRole?, String>((ref, code) async {
  final user = await ref.watch(appStartupProvider.future);
  final members = await ref.watch(clanMembersProvider(code).future);
  for (final member in members) {
    if (member.uid == user.uid) return member.role;
  }
  return null;
});

/// Live — small (one user's own pending invites), so the "kamu punya N
/// undangan" strip and the Join dialog's alternative path both update the
/// instant someone accepts/declines/receives a new one.
final myPendingInvitesProvider = StreamProvider<List<ClanInvite>>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(clanRepositoryProvider).watchMyInvites(user.uid);
});

/// Top 100 clans by [Clan.totalScore] — the cross-clan counterpart to
/// `leaderboardTopProvider`'s top-20-individuals ranking.
final topClansProvider = StreamProvider<List<Clan>>((ref) {
  return ref.watch(clanRepositoryProvider).watchTopClans();
});

/// Live — the signed-in user's own block list, across every clan (a block
/// is a per-person decision, not scoped to one clan chat).
final myBlockedUsersProvider = StreamProvider<Set<String>>((ref) async* {
  final user = await ref.watch(appStartupProvider.future);
  yield* ref.watch(clanMessageRepositoryProvider).watchBlockedUsers(user.uid);
});

/// Live — the last 100 messages in [code]'s clan chat, oldest first.
final clanMessagesProvider =
    StreamProvider.family<List<ClanMessage>, String>((ref, code) {
  return ref.watch(clanMessageRepositoryProvider).watchMessages(code);
});

/// Live — [code]'s single most recent message (or `null`), for the "Chat
/// Clan" list's preview line and [clanChatUnreadProvider]'s unread check.
final clanLastMessageProvider =
    StreamProvider.family<ClanMessage?, String>((ref, code) {
  return ref.watch(clanMessageRepositoryProvider).watchLastMessage(code);
});

/// Live — every member's last-read timestamp for [code]'s chat.
final clanLastReadAtProvider =
    StreamProvider.family<Map<String, DateTime>, String>((ref, code) {
  return ref.watch(clanMessageRepositoryProvider).watchLastReadAt(code);
});

/// Whether [code]'s clan chat has a message the signed-in learner hasn't
/// read yet — combines [clanLastMessageProvider]/[clanLastReadAtProvider]
/// with the signed-in uid rather than being its own stream, since it's a
/// pure derivation of two values this file already watches independently
/// (both providers stay shared/live regardless of how many places derive
/// from them, so this costs nothing extra).
final clanChatUnreadProvider = Provider.family<bool, String>((ref, code) {
  final myUid = ref.watch(appStartupProvider).valueOrNull?.uid;
  final lastMessage = ref.watch(clanLastMessageProvider(code)).valueOrNull;
  if (myUid == null || lastMessage == null) return false;
  if (lastMessage.senderUid == myUid) return false;
  final lastReadAt = ref.watch(clanLastReadAtProvider(code)).valueOrNull;
  final readAt = lastReadAt?[myUid];
  if (readAt == null) return true;
  return lastMessage.createdAt.isAfter(readAt);
});

/// Live — the last 50 announcements in [code], newest first (see
/// `ClanAnnouncementRepository.watchAnnouncements`'s own doc comment for why
/// this stays newest-first rather than reversing like [clanMessagesProvider]
/// does).
final clanAnnouncementsProvider =
    StreamProvider.family<List<ClanAnnouncement>, String>((ref, code) {
  return ref
      .watch(clanAnnouncementRepositoryProvider)
      .watchAnnouncements(code);
});

/// Live — [code]'s single most recent announcement (or `null`).
final clanLastAnnouncementProvider =
    StreamProvider.family<ClanAnnouncement?, String>((ref, code) {
  return ref
      .watch(clanAnnouncementRepositoryProvider)
      .watchLastAnnouncement(code);
});

/// Live — every member's last-read timestamp for [code]'s announcements —
/// a separate field from [clanLastReadAtProvider] (chat), so the two track
/// independently.
final clanAnnouncementLastReadAtProvider =
    StreamProvider.family<Map<String, DateTime>, String>((ref, code) {
  return ref.watch(clanAnnouncementRepositoryProvider).watchLastReadAt(code);
});

/// Whether [code] has an announcement the signed-in learner hasn't read yet
/// — same derivation shape as [clanChatUnreadProvider], just against the
/// announcement pair of providers instead of the chat pair. The author
/// themself never sees their own post as unread, same reasoning as chat.
final clanAnnouncementUnreadProvider = Provider.family<bool, String>((
  ref,
  code,
) {
  final myUid = ref.watch(appStartupProvider).valueOrNull?.uid;
  final last = ref.watch(clanLastAnnouncementProvider(code)).valueOrNull;
  if (myUid == null || last == null) return false;
  if (last.authorUid == myUid) return false;
  final lastReadAt =
      ref.watch(clanAnnouncementLastReadAtProvider(code)).valueOrNull;
  final readAt = lastReadAt?[myUid];
  if (readAt == null) return true;
  return last.createdAt.isAfter(readAt);
});
