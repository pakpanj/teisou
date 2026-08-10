import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import '../../../data/models/clan.dart';
import '../clan_providers.dart';

/// Tab 3 of `LeaderboardScreen` — the top 100 clans by [Clan.totalScore],
/// the cross-clan counterpart to tab 1's top-20-individuals ranking. See
/// `topClansProvider`/`clanRankingProvider`'s doc comments for why the sort
/// key is only as fresh as the last time someone opened that clan's own
/// ranking, not live.
class TopClanTab extends ConsumerWidget {
  const TopClanTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topClansAsync = ref.watch(topClansProvider);
    final s = ref.watch(appStringsProvider);

    return AppRefreshIndicator(
      onRefresh: () => ref.refresh(topClansProvider.future),
      child: topClansAsync.when(
        data: (clans) {
          if (clans.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: Center(
                    child: Text(
                      s.noTopClansYet,
                      style: TextStyle(color: context.palette.textNavy),
                    ),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: clans.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _TopClanTile(
              rank: index + 1,
              clan: clans[index],
              strings: s,
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text(s.failedToLoadTopClans(e))),
      ),
    );
  }
}

class _TopClanTile extends StatelessWidget {
  final int rank;
  final Clan clan;
  final AppStrings strings;

  const _TopClanTile({
    required this.rank,
    required this.clan,
    required this.strings,
  });

  String get _rankBadge {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                _rankBadge,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.palette.textNavy,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: context.palette.hiraganaCardBg,
              child: const Text('👥', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clan.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.palette.textNavy,
                    ),
                  ),
                  Text(
                    strings.topClanMembers(clan.memberCount),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.palette.textNavy.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              strings.topClanScorePoints(clan.totalScore.toStringAsFixed(0)),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.palette.primaryCoral,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
