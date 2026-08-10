import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/clan_icons.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import '../../../data/models/clan_invite.dart';
import '../../../data/models/clan_member.dart';
import '../../../data/models/user_profile.dart' show AvatarType;
import '../clan_providers.dart';
import '../leaderboard_screen.dart'
    show LeaderboardTile, globalScoreBreakdown, globalScoreLabel;
import 'clan_announcements_screen.dart';
import 'clan_chat_screen.dart';
import 'clan_members_screen.dart';
import 'clan_settings_screen.dart';
import 'create_clan_dialog.dart';
import 'join_clan_dialog.dart';
import '../../../core/widgets/app_loading.dart';

/// Tab 2 of `LeaderboardScreen` — a leaderboard scoped to whichever clan
/// the user picks from their own memberships, ranked by the same global
/// score the main tab uses (it used to carry its own dropdown over six
/// different metrics; one shared ranking is simpler for the students and
/// teachers this is built for, and keeps both tabs telling the same story).
/// Membership itself (`myClansProvider`) is read live so the clan picker
/// updates instantly after create/join/leave; the ranking
/// (`clanRankingProvider`) is a one-shot fetch refreshed on re-entry rather
/// than N realtime listeners — see the "Sistem Clan/Host" plan for the full
/// reasoning.
class ClanTab extends ConsumerStatefulWidget {
  const ClanTab({super.key});

  @override
  ConsumerState<ClanTab> createState() => _ClanTabState();
}

class _ClanTabState extends ConsumerState<ClanTab> {
  String? _selectedCode;

  Future<void> _leaveClan(String code, String name) async {
    final s = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.leaveClanConfirmTitle),
        content: Text(s.leaveClanConfirmBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.leave),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = ref.read(appStartupProvider).valueOrNull;
    if (user == null) return;
    await ref.read(clanRepositoryProvider).leaveClan(code: code, uid: user.uid);
    if (mounted && _selectedCode == code) {
      setState(() => _selectedCode = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _PendingInvitesStrip(),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final myClansAsync = ref.watch(myClansProvider);
    final s = ref.watch(appStringsProvider);

    return myClansAsync.when(
      data: (clans) {
        if (clans.isEmpty) {
          return _NoClanState(
            strings: s,
            onCreate: () => showDialog(
              context: context,
              builder: (_) => const CreateClanDialog(),
            ),
            onJoin: () => showDialog(
              context: context,
              builder: (_) => const JoinClanDialog(),
            ),
          );
        }

        final activeCode = clans.any((c) => c.code == _selectedCode)
            ? _selectedCode!
            : clans.first.code;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(activeCode),
                      initialValue: activeCode,
                      decoration: const InputDecoration(
                        labelText: 'Clan',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: clans
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.code,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedCode = value),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: s.createClan,
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const CreateClanDialog(),
                    ),
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: context.palette.primaryCoral,
                    ),
                  ),
                  IconButton(
                    tooltip: s.joinWithCode,
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const JoinClanDialog(),
                    ),
                    icon: Icon(
                      Icons.group_add,
                      color: context.palette.primaryCoral,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _ClanRanking(
                code: activeCode,
                strings: s,
                onLeave: (name) => _leaveClan(activeCode, name),
              ),
            ),
          ],
        );
      },
      loading: () => const AppLoading(),
      error: (e, _) => Center(child: Text(s.failedToLoadClan(e))),
    );
  }
}

/// Pending clan invites for the signed-in learner — shown above the clan
/// picker/ranking regardless of whether they already have a clan, since an
/// invite can arrive for an *additional* one. Collapsed to nothing when
/// there are none, so it never costs a permanent slice of the tab for the
/// common case of no pending invites.
class _PendingInvitesStrip extends ConsumerWidget {
  const _PendingInvitesStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(myPendingInvitesProvider);
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
            s.pendingInvitesTitle(invites.length),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.palette.textNavy,
            ),
          ),
          for (final invite in invites)
            _InviteRow(invite: invite, strings: s),
        ],
      ),
    );
  }
}

class _InviteRow extends ConsumerStatefulWidget {
  final ClanInvite invite;
  final AppStrings strings;

  const _InviteRow({required this.invite, required this.strings});

  @override
  ConsumerState<_InviteRow> createState() => _InviteRowState();
}

class _InviteRowState extends ConsumerState<_InviteRow> {
  bool _responding = false;

  Future<void> _respond(bool accept) async {
    final uid = ref.read(appStartupProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _responding = true);

    final profile = ref.read(userProfileProvider).valueOrNull;
    final user = ref.read(appStartupProvider).valueOrNull;
    try {
      await ref.read(clanRepositoryProvider).respondToInvite(
            uid: uid,
            invite: widget.invite,
            accept: accept,
            displayName: profile?.resolveDisplayName(user) ??
                (user?.displayName ?? widget.strings.defaultLearnerName),
            photoUrl: user?.photoURL,
            avatarType: profile?.avatarType ?? AvatarType.google,
            avatarValue: profile?.avatarValue,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.strings.inviteRespondFailed)),
      );
      setState(() => _responding = false);
    }
    // On success there's nothing to reset — the invite leaves the pending
    // list via watchMyInvites' own live status filter, and this row is
    // gone with it.
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.strings.invitedToClan(
                widget.invite.clanName,
                widget.invite.invitedByName,
              ),
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
              child: Text(widget.strings.declineInvite),
            ),
            FilledButton(
              onPressed: () => _respond(true),
              child: Text(widget.strings.acceptInvite),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoClanState extends StatelessWidget {
  final AppStrings strings;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _NoClanState({
    required this.strings,
    required this.onCreate,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👥', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              strings.noClanYetTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.palette.textNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.noClanYetBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textNavy),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(strings.createClan),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.group_add),
              label: Text(strings.joinWithCode),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClanRanking extends ConsumerWidget {
  final String code;
  final AppStrings strings;
  final void Function(String clanName) onLeave;

  const _ClanRanking({
    required this.code,
    required this.strings,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clanAsync = ref.watch(clanDetailsProvider(code));
    final rankingAsync = ref.watch(clanRankingProvider(code));
    final myRole = ref.watch(myRoleInClanProvider(code)).valueOrNull;
    final announcementUnread = ref.watch(clanAnnouncementUnreadProvider(code));

    return Column(
      children: [
        clanAsync.when(
          data: (clan) {
            if (clan == null) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.palette.primaryCoral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.palette.primaryCoral.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          color: context.palette.primaryCoral.withValues(
                            alpha: 0.5,
                          ),
                          child: ClanIconArt(
                            preset: ClanIconPresets.byId(clan.iconValue),
                            size: 40,
                            emojiFontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clan.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.palette.textNavy,
                              ),
                            ),
                            Text(
                              strings.codeAndMembers(clan.code, clan.memberCount),
                              style: TextStyle(
                                fontSize: 12,
                                color: context.palette.textNavy.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (clan.description != null && clan.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      clan.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textNavy.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: strings.clanChat,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClanChatScreen(
                              code: clan.code,
                              clanName: clan.name,
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                          color: context.palette.primaryCoral,
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            tooltip: strings.clanAnnouncements,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ClanAnnouncementsScreen(
                                  code: clan.code,
                                  clanName: clan.name,
                                ),
                              ),
                            ),
                            icon: Icon(
                              Icons.campaign_outlined,
                              size: 18,
                              color: context.palette.primaryCoral,
                            ),
                          ),
                          if (announcementUnread)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: context.palette.errorRed,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        tooltip: strings.manageMembers,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClanMembersScreen(
                              code: clan.code,
                              clanName: clan.name,
                            ),
                          ),
                        ),
                        icon: Icon(
                          Icons.manage_accounts,
                          size: 18,
                          color: context.palette.primaryCoral,
                        ),
                      ),
                      if (myRole == ClanRole.leader)
                        IconButton(
                          tooltip: strings.clanSettings,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ClanSettingsScreen(code: clan.code),
                            ),
                          ),
                          icon: Icon(
                            Icons.settings_outlined,
                            size: 18,
                            color: context.palette.primaryCoral,
                          ),
                        ),
                      IconButton(
                        tooltip: strings.copyCode,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: clan.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(strings.codeCopied)),
                          );
                        },
                        icon: Icon(
                          Icons.copy,
                          size: 18,
                          color: context.palette.primaryCoral,
                        ),
                      ),
                      IconButton(
                        tooltip: strings.leaveClanTooltip,
                        onPressed: () => onLeave(clan.name),
                        icon: Icon(
                          Icons.logout,
                          size: 18,
                          color: context.palette.errorRed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.refresh(clanDetailsProvider(code).future),
                ref.refresh(clanRankingProvider(code).future),
              ]);
            },
            child: rankingAsync.when(
              data: (entries) {
                final hostUid = clanAsync.valueOrNull?.hostUid;
                if (entries.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Center(
                          child: Text(
                            strings.noMembersYet,
                            style: TextStyle(color: context.palette.textNavy),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => LeaderboardTile(
                    rank: index + 1,
                    entry: entries[index],
                    valueLabel: globalScoreLabel(entries[index], strings),
                    subtitle: globalScoreBreakdown(entries[index], strings),
                    isHost: entries[index].uid == hostUid,
                  ),
                );
              },
              loading: () => const AppLoading(),
              error: (e, _) => Center(child: Text(strings.failedToLoadMembers(e))),
            ),
          ),
        ),
      ],
    );
  }
}
