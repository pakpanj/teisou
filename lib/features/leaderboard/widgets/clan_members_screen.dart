import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/clan_member.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../clan_providers.dart';
import '../leaderboard_screen.dart' show LeaderboardAvatar;
import 'search_invite_screen.dart';

/// Roster with roles and, for whoever has permission, kick/promote/demote
/// actions — separate from the Clan tab's own ranking list (score-focused,
/// no roles shown there) since role-aware moderation and score ranking are
/// different concerns with different data shapes (`ClanMember` carries the
/// role; `LeaderboardEntry`, what the ranking renders, doesn't).
class ClanMembersScreen extends ConsumerWidget {
  final String code;
  final String clanName;

  const ClanMembersScreen({
    super.key,
    required this.code,
    required this.clanName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final membersAsync = ref.watch(clanMembersProvider(code));
    final myRoleAsync = ref.watch(myRoleInClanProvider(code));
    final myRole = myRoleAsync.valueOrNull;
    final canInvite = myRole == ClanRole.leader || myRole == ClanRole.coLeader;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        title: Text(s.manageMembers),
        actions: [
          if (canInvite)
            IconButton(
              tooltip: s.inviteMember,
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      SearchInviteScreen(code: code, clanName: clanName),
                ),
              ),
            ),
        ],
      ),
      body: membersAsync.when(
        data: (members) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _MemberRow(
            code: code,
            member: members[index],
            myRole: myRole,
            myUid: ref.watch(appStartupProvider).valueOrNull?.uid,
          ),
        ),
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(s.failedToLoadMembers(e))),
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  final String code;
  final ClanMember member;
  final ClanRole? myRole;
  final String? myUid;

  const _MemberRow({
    required this.code,
    required this.member,
    required this.myRole,
    required this.myUid,
  });

  bool get _isSelf => member.uid == myUid;

  /// Mirrors `firestore.rules`' `canKick` exactly — the UI hides an action
  /// the server would refuse anyway, rather than showing a button that
  /// fails silently.
  bool get _canKick {
    if (_isSelf) return false;
    if (myRole == ClanRole.leader) return true;
    if (myRole == ClanRole.coLeader) return member.role == ClanRole.member;
    return false;
  }

  bool get _canChangeRole =>
      myRole == ClanRole.leader && !_isSelf && member.role != ClanRole.leader;

  Future<void> _setRole(
    BuildContext context,
    WidgetRef ref,
    ClanRole role,
  ) async {
    final s = ref.read(appStringsProvider);
    try {
      await ref
          .read(clanRepositoryProvider)
          .setMemberRole(code: code, targetUid: member.uid, role: role);
      ref.invalidate(clanMembersProvider(code));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.roleChangeFailed)));
    }
  }

  Future<void> _kick(BuildContext context, WidgetRef ref) async {
    final s = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.kickConfirmTitle(member.displayName)),
        content: Text(s.kickConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.kickMember),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(clanRepositoryProvider)
          .kickMember(code: code, targetUid: member.uid);
      ref.invalidate(clanMembersProvider(code));
      ref.invalidate(clanRankingProvider(code));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.kickFailed)));
    }
  }

  String _roleLabel(BuildContext context, WidgetRef ref) {
    final s = ref.read(appStringsProvider);
    switch (member.role) {
      case ClanRole.leader:
        return '👑 ${s.roleLeader}';
      case ClanRole.coLeader:
        return '⭐ ${s.roleCoLeader}';
      case ClanRole.member:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final roleLabel = _roleLabel(context, ref);

    return Material(
      color: context.palette.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // LeaderboardAvatar takes a LeaderboardEntry, this screen only
            // has a ClanMember — both carry the same identity fields, so a
            // throwaway entry reuses the real avatar-resolution logic
            // (preset art, not just photo/emoji) instead of a stripped-down
            // copy that would render preset avatars wrong.
            LeaderboardAvatar(
              entry: LeaderboardEntry(
                uid: member.uid,
                displayName: member.displayName,
                photoUrl: member.photoUrl,
                avatarType: member.avatarType,
                avatarValue: member.avatarValue,
                totalMastered: 0,
                examHighScore: 0,
                updatedAt: member.joinedAt,
              ),
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.palette.textNavy,
                    ),
                  ),
                  if (roleLabel.isNotEmpty)
                    Text(
                      roleLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.palette.textNavy.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
            if (_canChangeRole)
              IconButton(
                tooltip: member.role == ClanRole.coLeader
                    ? s.demoteToMember
                    : s.promoteToCoLeader,
                icon: Icon(
                  member.role == ClanRole.coLeader
                      ? Icons.arrow_downward
                      : Icons.star_outline,
                  color: context.palette.primaryCoral,
                ),
                onPressed: () => _setRole(
                  context,
                  ref,
                  member.role == ClanRole.coLeader
                      ? ClanRole.member
                      : ClanRole.coLeader,
                ),
              ),
            if (_canKick)
              IconButton(
                tooltip: s.kickMember,
                icon: Icon(
                  Icons.person_remove,
                  color: context.palette.errorRed,
                ),
                onPressed: () => _kick(context, ref),
              ),
          ],
        ),
      ),
    );
  }
}
