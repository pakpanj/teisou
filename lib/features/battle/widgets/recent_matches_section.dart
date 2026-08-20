import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_palette.dart';
import '../recent_matches_providers.dart';

/// "Pertandingan terakhir" on the card game lobby — the last few matches,
/// newest first.
///
/// Deliberately a short list rather than a tab of its own. The shell
/// already carries five tabs, and what a player wants at a glance is how
/// the last handful went, not an archive.
///
/// **Renders nothing at all when there is nothing to show.** An empty
/// state here would be a heading and a shrug on a screen whose job is to
/// start a match; a player with no history has the "Cari Lawan" button
/// right below, which is the thing to do about it.
class RecentMatchesSection extends ConsumerWidget {
  const RecentMatchesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final palette = context.palette;
    final rows = ref.watch(recentMatchRowsProvider).valueOrNull ?? const [];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            s.recentMatchesTitle,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: palette.textNavy.withValues(alpha: 0.75),
            ),
          ),
        ),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MatchRow(row: row, strings: s),
          ),
      ],
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.row, required this.strings});

  final RecentMatchRow row;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Win reads blue, not green: this app already settled on blue for a
    // right answer, because solid red against solid green is the one pair
    // a red-green colourblind learner cannot separate.
    final (accent, label) = switch (row.outcome) {
      MatchOutcome.win => (palette.secondaryBlue, strings.matchOutcomeWin),
      MatchOutcome.loss => (palette.errorRed, strings.matchOutcomeLoss),
      MatchOutcome.draw => (palette.freeBadgeGrey, strings.matchOutcomeDraw),
      MatchOutcome.unfinished =>
        (palette.freeBadgeGrey, strings.matchOutcomeUnfinished),
    };

    final opponent = row.againstBot
        ? strings.battleBotName
        : (row.opponentName ?? strings.battleOpponentUnknown);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: palette.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          // A coloured bar rather than only a word, so the run of results
          // reads down the column without being parsed one row at a time.
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                Text(
                  strings.matchAgainst(opponent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: palette.textNavy.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            row.outcome == MatchOutcome.unfinished
                ? '—'
                : '${row.myScore}–${row.theirScore}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: palette.textNavy,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (row.starDelta case final delta? when delta != 0) ...[
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  delta > 0 ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 15,
                  color: delta > 0 ? palette.tertiaryAmber : palette.freeBadgeGrey,
                ),
                Text(
                  delta > 0 ? '+$delta' : '$delta',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        delta > 0 ? palette.tertiaryAmber : palette.freeBadgeGrey,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
