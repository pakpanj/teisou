import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import '../clan_providers.dart';
import '../leaderboard_screen.dart'
    show LeaderboardTile, globalScoreBreakdown, globalScoreLabel;
import 'create_clan_dialog.dart';
import 'join_clan_dialog.dart';

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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(s.failedToLoadClan(e))),
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
              child: Row(
                children: [
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
                    icon: const Icon(
                      Icons.logout,
                      size: 18,
                      color: Colors.redAccent,
                    ),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(strings.failedToLoadMembers(e))),
            ),
          ),
        ),
      ],
    );
  }
}
