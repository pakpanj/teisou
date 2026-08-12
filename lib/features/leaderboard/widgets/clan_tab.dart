import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/clan_icons.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import '../../../core/widgets/seigaiha_wave.dart';
import '../../../data/models/clan.dart';
import '../../../data/models/clan_invite.dart';
import '../../../data/models/clan_member.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../../../data/models/user_profile.dart' show AvatarType;
import '../clan_providers.dart';
import '../leaderboard_screen.dart'
    show LeaderboardAvatar, LeaderboardTile, globalScoreBreakdown, globalScoreLabel;
import '../public_profile_screen.dart' show openPublicProfile;
import 'clan_announcements_screen.dart';
import 'clan_chat_screen.dart';
import 'clan_leaderboard_banner.dart';
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
    try {
      await ref
          .read(clanRepositoryProvider)
          .leaveClan(code: code, uid: user.uid);
    } catch (_) {
      // Previously unguarded: a rejected/failed write here left the clan
      // exactly where it was in `myClansProvider`'s live stream (nothing
      // ever committed), the confirmation dialog had already closed, and
      // nothing told the user it didn't work — reported as "I left this
      // clan but it's still there." Surface it instead of leaving the
      // failure indistinguishable from a working leave.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(appStringsProvider).leaveClanFailed)),
        );
      }
      return;
    }
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
            const LeaderboardBannerHeader(),
            const SizedBox(height: 14),
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
            return _ClanHeaderCard(
              clan: clan,
              strings: strings,
              isLeader: myRole == ClanRole.leader,
              announcementUnread: announcementUnread,
              onLeave: () => onLeave(clan.name),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 90,
                child: SeigaihaWave(
                  color: context.palette.primaryCoral.withValues(alpha: 0.08),
                ),
              ),
              AppRefreshIndicator(
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
                    // Ranks 1-3 move into the podium above the list; the
                    // list itself starts at rank 4, same data, just a
                    // different rendering for the first three positions.
                    final podiumEntries = entries.take(3).toList();
                    final restEntries = entries.skip(3).toList();
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: restEntries.length + 1,
                      separatorBuilder: (_, index) =>
                          index == 0 ? const SizedBox.shrink() : const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _ClanPodium(
                            entries: podiumEntries,
                            strings: strings,
                          );
                        }
                        final entry = restEntries[index - 1];
                        return LeaderboardTile(
                          rank: index + 3,
                          entry: entry,
                          valueLabel: globalScoreLabel(entry, strings),
                          subtitle: globalScoreBreakdown(entry, strings),
                          isHost: entry.uid == hostUid,
                        );
                      },
                    );
                  },
                  loading: () => const AppLoading(),
                  error: (e, _) => Center(child: Text(strings.failedToLoadMembers(e))),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The solid-coral clan summary card — icon, name, code (tap to copy),
/// description, and the four everyday actions (chat/announcements/
/// members/leave). Settings is leader-only and deliberately kept as a
/// small corner icon rather than a fifth slot in that row, since only one
/// role ever sees it and a row that changes width per-role reads as
/// unstable UI.
class _ClanHeaderCard extends StatelessWidget {
  final Clan clan;
  final AppStrings strings;
  final bool isLeader;
  final bool announcementUnread;
  final VoidCallback onLeave;

  const _ClanHeaderCard({
    required this.clan,
    required this.strings,
    required this.isLeader,
    required this.announcementUnread,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final coral = context.palette.primaryCoral;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        color: coral,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: coral.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HexagonIconFrame(
                preset: ClanIconPresets.byId(clan.iconValue),
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clan.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: clan.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.codeCopied)),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              strings.codeAndMembers(clan.code, clan.memberCount),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.copy,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isLeader)
                Tooltip(
                  message: strings.clanSettings,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClanSettingsScreen(code: clan.code),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.settings_outlined,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          if (clan.description != null && clan.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              clan.description!,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _HeaderActionButton(
                icon: Icons.chat_bubble_outline,
                label: strings.clanChat,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClanChatScreen(
                      code: clan.code,
                      clanName: clan.name,
                    ),
                  ),
                ),
              ),
              _HeaderActionButton(
                icon: Icons.campaign_outlined,
                label: strings.clanAnnouncements,
                showDot: announcementUnread,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClanAnnouncementsScreen(
                      code: clan.code,
                      clanName: clan.name,
                    ),
                  ),
                ),
              ),
              _HeaderActionButton(
                icon: Icons.manage_accounts,
                label: strings.manageMembers,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClanMembersScreen(
                      code: clan.code,
                      clanName: clan.name,
                    ),
                  ),
                ),
              ),
              _HeaderActionButton(
                icon: Icons.logout,
                label: strings.leave,
                onTap: onLeave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One icon-circle-and-label button in the header card's action row —
/// white on the solid coral card, matching this app's established
/// "wash, not a solid fill" restraint even here (the circle is a soft
/// white wash, not opaque white, so it reads as part of the card rather
/// than a separate button floating on top of it).
class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDot;

  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: Colors.white),
                  ),
                  if (showDot)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: context.palette.errorRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws a regular hexagon (pointy-top) as the clan icon's frame — cream
/// field, gold ring — with the existing circular crest icon centred
/// inside it. Deliberately code, not a generated asset: it's a plain
/// geometric shape, and building it this way means it wraps any of the
/// 20 [ClanIconPresets] (or the emoji fallback) with zero extra art.
class _HexagonIconFrame extends StatelessWidget {
  final ClanIconPreset? preset;
  final double size;

  const _HexagonIconFrame({required this.preset, required this.size});

  @override
  Widget build(BuildContext context) {
    final iconSize = size * 0.62;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _HexagonPainter(
              fill: context.palette.tertiaryAmberCardBg,
              border: context.palette.premiumGoldEnd,
            ),
          ),
          ClanIconArt(
            preset: preset,
            size: iconSize,
            emojiFontSize: iconSize * 0.5,
          ),
        ],
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color fill;
  final Color border;

  const _HexagonPainter({required this.fill, required this.border});

  Path _hexagonPath(Size size) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 2;
    for (var i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 90);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexagonPath(size);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.border != border;
}

/// Top-3 podium — [entries] is already sorted by rank and holds at most 3
/// (fewer for a clan that small, rendered gracefully rather than padded
/// out with placeholders). Laid out 2nd/1st/3rd left-to-right, the
/// standard podium reading order, with the first-place column taller.
class _ClanPodium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final AppStrings strings;

  const _ClanPodium({required this.entries, required this.strings});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final first = entries[0];
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    final gold = context.palette.premiumGoldEnd;
    final silver = context.palette.freeBadgeGrey;
    final bronze = context.palette.tertiaryAmber;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (second != null)
            _PodiumColumn(
              entry: second,
              rank: 2,
              accent: silver,
              avatarSize: 52,
              cardHeight: 124,
              valueLabel: globalScoreLabel(second, strings),
            ),
          const SizedBox(width: 8),
          _PodiumColumn(
            entry: first,
            rank: 1,
            accent: gold,
            avatarSize: 64,
            cardHeight: 146,
            valueLabel: globalScoreLabel(first, strings),
          ),
          const SizedBox(width: 8),
          if (third != null)
            _PodiumColumn(
              entry: third,
              rank: 3,
              accent: bronze,
              avatarSize: 52,
              cardHeight: 124,
              valueLabel: globalScoreLabel(third, strings),
            ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final Color accent;
  final double avatarSize;
  final double cardHeight;
  final String valueLabel;

  const _PodiumColumn({
    required this.entry,
    required this.rank,
    required this.accent,
    required this.avatarSize,
    required this.cardHeight,
    required this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openPublicProfile(context, entry),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RankPin(rank: rank, color: accent),
          Transform.translate(
            offset: const Offset(0, -6),
            child: Container(
              width: 96,
              height: cardHeight,
              padding: const EdgeInsets.fromLTRB(6, 16, 6, 10),
              decoration: BoxDecoration(
                color: context.palette.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.6)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  LeaderboardAvatar(entry: entry, size: avatarSize),
                  const SizedBox(height: 6),
                  Text(
                    entry.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: context.palette.textNavy,
                    ),
                  ),
                  Text(
                    valueLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The pentagon "pin" tag sitting above each podium avatar, flat top /
/// tapered point at the bottom.
class _RankPin extends StatelessWidget {
  final int rank;
  final Color color;

  const _RankPin({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _PinClipper(),
      child: Container(
        width: 32,
        height: 38,
        color: color,
        alignment: const Alignment(0, -0.35),
        child: Text(
          '$rank',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _PinClipper extends CustomClipper<Path> {
  const _PinClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.55)
      ..lineTo(w / 2, h)
      ..lineTo(0, h * 0.55)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

