import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/battle_match.dart';
import '../../../data/models/card_game_rank.dart';

/// What a finished match did to the player's climb — the star delta, the
/// standing it left them at, and whether that crossed a division.
///
/// **Why this needs a waiting state at all.** The result appears the
/// moment the client sees the match conclude, but stars are moved by a
/// Cloud Function reacting to that same conclusion, so for a second or
/// two there is genuinely no answer yet. Showing nothing would read as
/// "this match didn't count"; showing a guessed number would sometimes
/// be wrong, and this is the only feedback the player gets about their
/// rank. So it says it is counting, and swaps in the real figure when it
/// lands.
///
/// If it never lands — the function failed, or the device went offline
/// between finishing and reading — the wait gives up after
/// [_patienceLimit] and says the stars are still updating rather than
/// spinning forever. That is honest: the match is over and scored, and
/// whatever the ladder decided is already stored server-side; only this
/// screen's copy is missing.
class StarResultCard extends StatefulWidget {
  const StarResultCard({
    super.key,
    required this.match,
    required this.myUid,
    required this.strings,
  });

  final BattleMatch match;
  final String myUid;
  final AppStrings strings;

  @override
  State<StarResultCard> createState() => _StarResultCardState();
}

class _StarResultCardState extends State<StarResultCard> {
  static const _patienceLimit = Duration(seconds: 12);

  Timer? _giveUp;
  bool _waitedLongEnough = false;

  @override
  void initState() {
    super.initState();
    _giveUp = Timer(_patienceLimit, () {
      if (mounted) setState(() => _waitedLongEnough = true);
    });
  }

  @override
  void dispose() {
    // Cancellable rather than a bare Future.delayed: this widget is
    // routinely disposed before the timer fires, which is the normal
    // case (the stars usually arrive first).
    _giveUp?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final palette = context.palette;

    // An abandoned match (both players left, neither returned in time —
    // see `BattleMatch.absence`'s own doc comment) never gets a
    // `starResult` at all: `battle_stars.js`'s `onBattleMatchConcluded`
    // trigger gates on `result` being non-null, and an abandoned match
    // deliberately never writes one. Without this branch, `result` below
    // would stay permanently null and this card would sit on
    // "menghitung..." until [_patienceLimit], then settle on "masih
    // diperbarui" forever — technically not wrong, but misleading: there
    // is nothing to wait for here, the match simply never decided a
    // winner.
    if (widget.match.status == BattleMatchStatus.abandoned) {
      return _wrap(
        context,
        Text(
          s.battleResultAbandonedExplanation,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textNavy.withValues(alpha: 0.7)),
        ),
      );
    }

    // Friend and clan matches never move stars, by design — their card
    // content is freely chosen, so ranking them would be a shortcut. Say
    // so plainly instead of leaving a gap where a number belongs.
    if (!widget.match.rankedMatch) {
      return _wrap(
        context,
        Text(
          s.battleStarsCasual,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textNavy.withValues(alpha: 0.7)),
        ),
      );
    }

    final result = widget.match.starResult[widget.myUid];
    if (result == null) {
      return _wrap(
        context,
        Text(
          _waitedLongEnough ? s.battleStarsPending : s.battleStarsCounting,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.textNavy.withValues(alpha: 0.7)),
        ),
      );
    }

    return _wrap(context, _buildOutcome(context, s, result));
  }

  Widget _buildOutcome(
    BuildContext context,
    AppStrings s,
    BattleStarResult result,
  ) {
    final palette = context.palette;
    final rank = result.rank;
    final gained = result.delta > 0;

    final deltaLabel = result.delta == 0
        ? s.battleStarsUnchanged
        : gained
        ? s.battleStarsGained(result.delta)
        : s.battleStarsLostAmount(result.delta);

    final standing = rank.displayName;
    final movement = result.tierChanged
        ? s.battleStarsPromotedTier(standing)
        : result.divisionChanged
        ? (gained
              ? s.battleStarsPromotedDivision(standing)
              : s.battleStarsDroppedDivision(standing))
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              gained ? Icons.star : Icons.star_border,
              color: gained ? palette.primaryCoral : palette.textNavy,
            ),
            const SizedBox(width: 6),
            Text(
              deltaLabel,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: gained ? palette.primaryCoral : palette.textNavy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          s.cardGameSubtitleWithRank(
            standing,
            rank.tier.hasDivisions
                ? s.battleRankStars(rank.stars, rank.tier.starsPerDivision)
                : s.battleRankStarsUncapped(rank.stars),
          ),
          style: TextStyle(color: palette.textNavy.withValues(alpha: 0.7)),
        ),
        if (movement != null) ...[
          const SizedBox(height: 6),
          Text(
            movement,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: gained ? palette.secondaryBlue : palette.textNavy,
            ),
          ),
        ],
        // Only when it explains something the player can see: a loss
        // that took nothing. `lossAbsorbed` covers two different
        // reasons — Bronze/Silver's blanket loss protection, or simply
        // already sitting at the division floor above those tiers —
        // and each needs its own wording, or a Gold+ player at floor
        // would silently see nothing explaining their unchanged stars.
        if (result.lossAbsorbed) ...[
          const SizedBox(height: 6),
          Text(
            rank.tier.lossProtected
                ? s.battleStarsProtected
                : s.battleStarsFloorAbsorbed,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _wrap(BuildContext context, Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.palette.mutedSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
