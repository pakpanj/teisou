import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/clan_icons.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import '../../../data/models/clan.dart';
import '../clan_providers.dart';
import 'clan_leaderboard_banner.dart';

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

    return Column(
      children: [
        const LeaderboardBannerHeader(),
        const SizedBox(height: 14),
        Expanded(
          child: AppRefreshIndicator(
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
          ),
        ),
      ],
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

  /// Same gold/silver/bronze podium tint as [LeaderboardTile] — mapped
  /// onto existing palette tokens, not a new hardcoded colour.
  (Color bg, Color accent)? _podiumColors(AppPalette palette) {
    switch (rank) {
      case 1:
        return (palette.tertiaryAmberCardBg, palette.tertiaryAmber);
      case 2:
        return (palette.katakanaCardBg, palette.secondaryBlue);
      case 3:
        return (palette.hiraganaCardBg, palette.primaryCoral);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final podium = _podiumColors(context.palette);
    return Material(
      color: podium?.$1 ?? context.palette.cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: podium != null
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: podium.$2.withValues(alpha: 0.5)),
              )
            : null,
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
              child: ClanIconArt(
                preset: ClanIconPresets.byId(clan.iconValue),
                size: 28,
                emojiFontSize: 16,
              ),
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
