import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/mascot_widget.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../../leaderboard/leaderboard_screen.dart' show LeaderboardAvatar;

/// The pieces that make a match look like a card game rather than a form.
///
/// Follows the layout the user's own mockups settled on — the two players
/// facing each other with a compact score panel between them, the deck of
/// face-down cards along the bottom, and the card in play raised in the
/// middle — while ignoring the mechanics drawn there (HP bars, running
/// rating numbers), which this mode deliberately does not use. See
/// `NOTES_CARD_GAME_MODE.md`'s "Mockup TEISOU BATTLE — acuan tampilan,
/// bukan acuan aturan".
///
/// Everything is drawn from shapes rather than image assets, the same way
/// `ProfileHeaderIllustration` and the cover art already work here: card
/// art would be one more thing to commission before the mode could ship.

/// One player's side of the score panel: avatar, name, and score.
///
/// [entry] is allowed to be null — the identity comes from the public
/// `leaderboard/{uid}` row, which a brand-new opponent may not have yet,
/// and a match must never be blocked on a cosmetic lookup. It falls back
/// to a neutral placeholder rather than an empty gap.
class BattlePlayerChip extends StatelessWidget {
  const BattlePlayerChip({
    super.key,
    required this.entry,
    required this.fallbackName,
    required this.score,
    required this.isMe,
    required this.isTheirTurn,
    this.isBot = false,
  });

  final LeaderboardEntry? entry;
  final String fallbackName;
  final int score;
  final bool isMe;

  /// The bot wears the app's mascot rather than the anonymous person
  /// glyph every other missing avatar falls back to. It has no
  /// `leaderboard/{uid}` row and never will, so without this it is the
  /// one opponent that always looks like a loading failure.
  final bool isBot;

  /// Whose turn it is right now — the active side lifts and gains a ring,
  /// so "who is everyone waiting for" is readable at a glance instead of
  /// only from the text below the card.
  final bool isTheirTurn;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = isMe ? palette.primaryCoral : palette.secondaryBlue;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isTheirTurn ? accent : Colors.transparent,
              width: 3,
            ),
          ),
          child: isBot
              ? SizedBox(
                  width: 44,
                  height: 44,
                  child: MascotWidget(
                    mood: MascotMood.curious,
                    size: 44,
                    showBackdrop: true,
                  ),
                )
              : entry != null
              ? LeaderboardAvatar(entry: entry!, size: 44)
              : CircleAvatar(
                  radius: 22,
                  backgroundColor: accent.withValues(alpha: 0.2),
                  child: Icon(Icons.person, color: accent, size: 24),
                ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 92,
          child: Text(
            entry?.displayName ?? fallbackName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.textNavy,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
      ],
    );
  }
}

/// The countdown, as a ring that drains rather than a bare number.
///
/// The number stays in the middle — a ring alone reads as decoration and
/// a child cannot tell 4 seconds from 9 by arc length. It turns red in
/// the last five seconds, the same threshold the old text version used.
class BattleTimerRing extends StatelessWidget {
  const BattleTimerRing({
    super.key,
    required this.remaining,
    required this.limit,
  });

  final Duration remaining;
  final Duration limit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final seconds = remaining.inSeconds;
    final urgent = seconds <= 5;
    final fraction = limit.inMilliseconds == 0
        ? 0.0
        : (remaining.inMilliseconds / limit.inMilliseconds).clamp(0.0, 1.0);

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              value: fraction,
              strokeWidth: 5,
              backgroundColor: palette.progressTrack,
              valueColor: AlwaysStoppedAnimation(
                urgent ? palette.errorRed : palette.primaryCoral,
              ),
            ),
          ),
          Text(
            '$seconds',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: urgent ? palette.errorRed : palette.textNavy,
            ),
          ),
        ],
      ),
    );
  }
}

/// How a single round came out, for the deck strip below the card.
enum BattleSlotState { upcoming, current, correct, wrong }

/// The deck: one slot per round, face-down ahead of play and marked
/// right or wrong behind it.
///
/// This is the piece that makes a match feel finite. The old screen said
/// "Kartu 3 / 20" in text, which is the same information and none of the
/// feeling — a child can see at a glance how much is left, and how they
/// have been doing, without reading anything.
class BattleDeckStrip extends StatelessWidget {
  const BattleDeckStrip({super.key, required this.slots});

  final List<BattleSlotState> slots;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      height: 26,
      child: Row(
        children: [
          for (var i = 0; i < slots.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: slots[i] == BattleSlotState.current ? 26 : 18,
                decoration: BoxDecoration(
                  color: switch (slots[i]) {
                    BattleSlotState.correct => palette.secondaryBlue,
                    BattleSlotState.wrong => palette.errorRed,
                    BattleSlotState.current => palette.primaryCoral,
                    BattleSlotState.upcoming => palette.progressTrack,
                  },
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The card in play: the character on a raised, framed face, captioned
/// with whose deck it came from.
///
/// The caption is not decoration — in this mode you always answer a card
/// from your *opponent's* deck, which is the one rule players get wrong
/// when nothing on screen says so.
class BattleCardFace extends StatelessWidget {
  const BattleCardFace({
    super.key,
    required this.prompt,
    required this.caption,
    required this.flashColor,
  });

  final String prompt;
  final String caption;

  /// Briefly tints the whole card after an answer — the only feedback
  /// that arrives fast enough to feel connected to the tap, since the
  /// authoritative score comes from a Cloud Function seconds later.
  final Color? flashColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Long prompts are compound words, not single kana: shrink rather
    // than overflow, and keep single characters as large as possible.
    final fontSize = switch (prompt.characters.length) {
      1 => 76.0,
      2 => 64.0,
      3 => 52.0,
      _ => 40.0,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          caption,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.textNavy.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 200,
          height: 268,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.cardWhite,
                flashColor?.withValues(alpha: 0.28) ??
                    palette.hiraganaCardBg.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: flashColor ?? palette.primaryCoral.withValues(alpha: 0.45),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.textNavy.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            prompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: palette.textNavy,
            ),
          ),
        ),
      ],
    );
  }
}

/// Header: the two players either side of the round counter.
class BattleScorePanel extends StatelessWidget {
  const BattleScorePanel({
    super.key,
    required this.me,
    required this.opponent,
    required this.round,
    required this.totalRounds,
    required this.remaining,
    required this.limit,
    required this.strings,
  });

  final Widget me;
  final Widget opponent;
  final int round;
  final int totalRounds;
  final Duration remaining;
  final Duration limit;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          me,
          Expanded(
            child: Column(
              children: [
                BattleTimerRing(remaining: remaining, limit: limit),
                const SizedBox(height: 6),
                Text(
                  strings.battleCardProgress(round, totalRounds),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textNavy.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          opponent,
        ],
      ),
    );
  }
}

/// Sakura petals drifting behind the arena — the app's own visual
/// language (Home and the profile header already use it), and the one
/// piece of the mockup's atmosphere that costs nothing to draw.
class BattleBackdrop extends StatelessWidget {
  const BattleBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _PetalPainter(context.palette)),
        ),
        child,
      ],
    );
  }
}

class _PetalPainter extends CustomPainter {
  _PetalPainter(this.palette);

  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    // Fixed positions from a seeded generator: petals that reshuffle on
    // every repaint would flicker once a second, since the timer rebuilds
    // this screen constantly.
    final random = math.Random(7);
    final paint = Paint()
      ..color = palette.primaryCoral.withValues(alpha: 0.12);
    for (var i = 0; i < 18; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final r = 4 + random.nextDouble() * 7;
      canvas.drawCircle(Offset(dx, dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_PetalPainter oldDelegate) => false;
}

/// One card as it was played, for the post-match review.
class BattleReviewCard {
  const BattleReviewCard({
    required this.prompt,
    required this.reading,
    required this.correct,
    required this.mine,
  });

  final String prompt;

  /// The right answer, always shown — this row is the one place a
  /// learner sees the reading for a card they got wrong.
  final String reading;
  final bool correct;

  /// Whether this was a card *this* player answered.
  final bool mine;
}

/// The played cards in order, each marked right or wrong with its
/// reading underneath.
///
/// Straight from the user's mockup, and the single best idea in it: it
/// turns the end of a match into study material instead of a score. A
/// child who lost 3-7 still leaves with the seven readings they missed.
class BattleResultReview extends StatelessWidget {
  const BattleResultReview({
    super.key,
    required this.cards,
    required this.title,
  });

  final List<BattleReviewCard> cards;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _ReviewTile(card: cards[i]),
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.card});

  final BattleReviewCard card;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final mark = card.correct ? palette.secondaryBlue : palette.errorRed;

    return Container(
      width: 66,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: palette.cardWhite,
        borderRadius: BorderRadius.circular(10),
        // A learner's own cards read solid; the opponent's are dimmed, so
        // "which of these were mine to get right" needs no legend.
        border: Border.all(
          color: mark.withValues(alpha: card.mine ? 1 : 0.3),
          width: card.mine ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.prompt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: palette.textNavy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            card.reading,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: palette.textNavy.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            card.correct ? Icons.check_circle : Icons.cancel,
            size: 15,
            color: mark,
          ),
        ],
      ),
    );
  }
}

/// The cards a player still holds, to choose from on their own turn.
///
/// This is the piece that makes a turn a *decision* rather than a wait.
/// Which card you send is the only tactical choice in the mode — you are
/// picking what your opponent has to read — and until now the app chose
/// for you, silently, at match creation.
class BattleHand extends StatelessWidget {
  const BattleHand({
    super.key,
    required this.cards,
    required this.onPlay,
    required this.secondsLeft,
    required this.title,
  });

  /// Prompt text per card, in hand order, paired with its card id.
  final List<({String cardId, String prompt})> cards;
  final void Function(String cardId) onPlay;

  /// Counts down the choosing window. When it runs out the card dealt to
  /// this round goes out on its own, so this is a nudge, not a wall.
  final int secondsLeft;
  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textNavy,
                ),
              ),
              Text(
                '${secondsLeft}s',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: secondsLeft <= 3
                      ? palette.errorRed
                      : palette.textNavy.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _HandCard(
              prompt: cards[i].prompt,
              onTap: () => onPlay(cards[i].cardId),
            ),
          ),
        ),
      ],
    );
  }
}

class _HandCard extends StatelessWidget {
  const _HandCard({required this.prompt, required this.onTap});

  final String prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.cardWhite,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 74,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: palette.secondaryBlue.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Text(
            prompt,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: prompt.characters.length > 2 ? 22 : 30,
              fontWeight: FontWeight.bold,
              color: palette.textNavy,
            ),
          ),
        ),
      ),
    );
  }
}
