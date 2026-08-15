import 'package:flutter/material.dart';

import '../../../core/constants/card_game_rank_art.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/card_game_rank.dart';

/// The standing, as a badge and a row of stars rather than a line of
/// text.
///
/// Takes the mockup's shape — crest, name, star pips, progress bar — but
/// **not its numbers**. The pips count what this tier actually needs
/// (Bronze 3, Silver 4, Gold 5, Diamond 6), not a fixed five, and the
/// bar fills with stars in the current division rather than a
/// four-digit score the ladder does not have. "2 of 4 stars to the next
/// division" is a distance a child can picture; "1,250 / 1,600" is a
/// number that moves.
class RankCard extends StatelessWidget {
  const RankCard({
    super.key,
    required this.rank,
    required this.starTotal,
    required this.strings,
  });

  final CardGameRank rank;

  /// Server-written total across the whole ladder, shown small beside
  /// the tier name. Separate from [rank]'s stars, which are only the
  /// ones inside the current division.
  final int starTotal;

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tier = rank.tier;
    final perDivision = tier.starsPerDivision;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          RankCrest(tier: tier, size: 62),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rank.displayName,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: palette.textNavy,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.star, size: 15, color: palette.primaryCoral),
                    const SizedBox(width: 3),
                    Text(
                      '$starTotal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: palette.textNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (tier.hasDivisions) ...[
                  _StarPips(
                    filled: rank.stars,
                    total: perDivision,
                    color: palette.primaryCoral,
                    empty: palette.progressTrack,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: perDivision == 0 ? 0 : rank.stars / perDivision,
                      minHeight: 7,
                      backgroundColor: palette.progressTrack,
                      valueColor:
                          AlwaysStoppedAnimation(palette.primaryCoral),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.battleRankStars(rank.stars, perDivision),
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textNavy.withValues(alpha: 0.65),
                    ),
                  ),
                ] else
                  // Emerald has no divisions to fill, so pips and a bar
                  // would both be lying about a ceiling that isn't there.
                  Text(
                    strings.battleRankStarsUncapped(rank.stars),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: palette.textNavy.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarPips extends StatelessWidget {
  const _StarPips({
    required this.filled,
    required this.total,
    required this.color,
    required this.empty,
  });

  final int filled;
  final int total;
  final Color color;
  final Color empty;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Icon(
            i < filled ? Icons.star : Icons.star_border,
            size: 18,
            color: i < filled ? color : empty,
          ),
        ],
      ],
    );
  }
}
