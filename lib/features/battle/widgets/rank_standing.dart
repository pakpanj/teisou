import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/card_game_rank.dart';

/// A player's Card Game Mode standing, in one line: tier, division, and
/// how far through the current division their stars are.
///
/// Pulled out of `BattleMatchmakingScreen` rather than written inline
/// because the match-result screen and the star leaderboard both need
/// exactly this, and three copies of the "which denominator applies at
/// this tier" rule is three chances to get Emerald wrong — it is the one
/// tier with no division to count towards, so it shows a running total
/// instead of a fraction.
class RankStanding extends StatelessWidget {
  const RankStanding({super.key, required this.rank, required this.strings});

  final CardGameRank rank;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final starsLabel = rank.tier.hasDivisions
        ? strings.battleRankStars(rank.stars, rank.tier.starsPerDivision)
        : strings.battleRankStarsUncapped(rank.stars);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.mutedSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.battleRankStandingLabel,
            style: TextStyle(
              fontSize: 12,
              color: palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                rank.displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: palette.textNavy,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.star, size: 16, color: palette.primaryCoral),
              const SizedBox(width: 4),
              Text(starsLabel, style: TextStyle(color: palette.textNavy)),
            ],
          ),
          // Only once the bonus is actually live, so it reads as news
          // rather than as a permanent piece of furniture.
          if (rank.winStreak >= 2) ...[
            const SizedBox(height: 4),
            Text(
              strings.battleRankWinStreak(rank.winStreak),
              style: TextStyle(fontSize: 12, color: palette.primaryCoral),
            ),
          ],
        ],
      ),
    );
  }
}
