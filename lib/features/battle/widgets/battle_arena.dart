import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/battle_rules.dart';
import '../../../core/constants/card_skins.dart';
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
    // Forty slivers in one row is a barcode, not a scoreboard. Split at
    // the phase boundary instead: the top row is the ten cards each that
    // decide it, the bottom row the all-in that only happens on a draw —
    // so the shape of the match is visible, not just its length.
    final split = slots.length > kBattleMainPhaseRounds
        ? kBattleMainPhaseRounds
        : slots.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SlotRow(slots: slots.take(split).toList()),
        if (slots.length > split) ...[
          const SizedBox(height: 4),
          Opacity(
            // Dimmed until it is actually in play: the extension is a
            // tie-breaker most matches never reach.
            opacity: slots.skip(split).any(
                      (s) => s != BattleSlotState.upcoming,
                    )
                ? 1
                : 0.35,
            child: _SlotRow(slots: slots.skip(split).toList()),
          ),
        ],
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slots});

  final List<BattleSlotState> slots;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      height: 14,
      child: Row(
        children: [
          for (var i = 0; i < slots.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: slots[i] == BattleSlotState.current ? 14 : 9,
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
    this.faceDown = false,
    this.skin,
  });

  final String prompt;
  final String caption;

  /// Face down while its owner is still choosing. Drawn as a real card
  /// back rather than a card with "?" on it: a question mark reads as
  /// "the app doesn't know", a patterned back reads as "not your
  /// business yet", which is what is actually true.
  final bool faceDown;

  /// The card back of whoever *owns* this card — so the skin a player
  /// bought is shown to the person they are playing, which is the whole
  /// point of owning one. Null falls back to the free default.
  final CardSkinPreset? skin;

  /// Briefly tints the whole card after an answer — the only feedback
  /// that arrives fast enough to feel connected to the tap, since the
  /// authoritative score comes from a Cloud Function seconds later.
  final Color? flashColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Long prompts are compound words, not single kana: shrink rather
    // than overflow, and keep single characters as large as possible.
    final fontSize = switch (prompt.characters.isEmpty
        ? 1
        : prompt.characters.length) {
      1 => 76.0,
      2 => 64.0,
      3 => 52.0,
      _ => 40.0,
    };

    // Sized from what is actually available rather than fixed at 214x292.
    // A shorter screen (the Pixel 8 emulator is 60px shorter than the
    // Moto G52J, and a windowed emulator shorter still) overflowed the
    // card by 16px and drew Flutter's striped banner across the bottom of
    // it — reported from the emulator while the phone looked perfect,
    // which is exactly the failure a fixed height hides until it doesn't.
    return LayoutBuilder(
      builder: (context, constraints) {
        const captionSpace = 30.0;
        const maxCardHeight = 292.0;
        final available = constraints.maxHeight.isFinite
            ? constraints.maxHeight - captionSpace
            : maxCardHeight;
        final cardHeight = available.clamp(150.0, maxCardHeight);
        final cardWidth = cardHeight * 214 / 292;
        return _buildCard(context, palette, fontSize, cardHeight, cardWidth);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppPalette palette,
    double fontSize,
    double cardHeight,
    double cardWidth,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: faceDown
                  ? [Colors.transparent, Colors.transparent]
                  : [
                      // Lifted a little in dark mode. A skinless card is
                      // dark grey and the backdrop is a night sky, so
                      // the two sat at almost the same value and the
                      // card stopped reading as an object — it looked
                      // like a rectangle cut out of the sky. Reported
                      // after playing a real match on the new backdrop.
                      isDark
                          ? Color.alphaBlend(
                              Colors.white.withValues(alpha: 0.09),
                              palette.cardWhite,
                            )
                          : palette.cardWhite,
                      flashColor?.withValues(alpha: 0.28) ??
                          palette.hiraganaCardBg.withValues(alpha: 0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: flashColor ??
                  (faceDown
                      ? palette.cardWhite
                      : palette.primaryCoral.withValues(alpha: 0.45)),
              width: 3,
            ),
            boxShadow: [
              // **On a dark ground a card is separated by a light edge,
              // not by a shadow.** A darker shadow under a dark card on
              // a dark sky changes nothing you can see, so in dark mode
              // this is a soft outward glow instead — the same trick the
              // hand cards get from their pale top edge.
              BoxShadow(
                color: isDark
                    ? palette.textNavy.withValues(alpha: 0.22)
                    : palette.textNavy.withValues(alpha: 0.18),
                blurRadius: isDark ? 26 : 18,
                spreadRadius: isDark ? 1 : 0,
                offset: isDark ? Offset.zero : const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: faceDown
              ? CardSkinBack(skin: skin ?? CardSkinPresets.classic)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // The owner's art behind the character, which is what
                    // the illustrated skins were drawn for — every one of
                    // them keeps its middle clear precisely so a glyph can
                    // sit here. A painted skin stays behind the card back
                    // only: stretched across the face its pattern would
                    // compete with the character it exists to frame.
                    if (skinArt != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.asset(
                          skinArt!.assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, _) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    _faceContent(context, palette, fontSize, cardHeight,
                        cardWidth),
                  ],
                ),
        ),
      ],
    );
  }

  /// The skin whose art backs the face — only ever an illustrated one,
  /// since the painted patterns are card *backs* and would fight the
  /// character for attention if stretched across a face.
  CardSkinPreset? get skinArt =>
      (skin?.illustrated ?? false) ? skin : null;

  /// Ink that reads against whatever is behind it. On a dark skin the
  /// navy glyph would be black on black — which is what
  /// [CardSkinPreset.darkFace] exists to prevent.
  Color _ink(AppPalette palette) =>
      (skinArt?.darkFace ?? false) ? Colors.white : palette.textNavy;

  Widget _faceContent(
    BuildContext context,
    AppPalette palette,
    double fontSize,
    double cardHeight,
    double cardWidth,
  ) {
    final ink = _ink(palette);
    return Stack(
      // Must fill the card: a Stack sized to its children shrinks to the
      // glyph, and then the "inset" rule and the corner marks land
      // around the character instead of around the card. That is exactly
      // how it first rendered on the device.
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        // An inner rule and two corner marks: the cheapest way to make a
        // rectangle read as a playing card rather than a box with a
        // letter in it. Dropped on an illustrated skin, which draws its
        // own border — two frames inside each other reads as a mistake.
        if (skinArt == null)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: palette.primaryCoral.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: cardHeight * 0.06,
          left: cardWidth * 0.09,
          child: _CornerMark(prompt: prompt, palette: palette, ink: ink),
        ),
        Positioned(
          bottom: cardHeight * 0.06,
          right: cardWidth * 0.09,
          child: RotatedBox(
            quarterTurns: 2,
            child: _CornerMark(prompt: prompt, palette: palette, ink: ink),
          ),
        ),
        // Centred explicitly: `StackFit.expand` stretches a
        // non-positioned child to the whole card, which left the
        // character sitting against the top edge.
        Center(
          child: Text(
            prompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              // Scaled with the card: a full-size glyph on a shrunken
              // card fills it edge to edge.
              fontSize: fontSize * (cardHeight / 292),
              fontWeight: FontWeight.bold,
              color: ink,
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

  /// Painted art if it exists, falling petals drawn in code if it does
  /// not.
  ///
  /// **Two files, because this app has a dark mode.** One bright sakura
  /// scene is wrong at night and one night scene is wrong by day, so the
  /// pair is picked by theme brightness — the same `_light`/`_dark`
  /// convention `clan_banner_light.png` already uses, rather than a
  /// second naming scheme for the same idea.
  ///
  /// The painted petals stay as the fallback rather than being deleted.
  /// They are what every one of these screens has looked like until now,
  /// so a missing or broken file leaves the mode looking exactly as it
  /// did rather than leaving a blank rectangle — the same contract
  /// `RankCrest` and `CardSkinBack` keep.
  ///
  /// The art is not overlaid *on* the petals: the scene carries its own,
  /// and drawing both would double them.
  static String assetFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? 'assets/backgrounds/battle_bg_dark.png'
          : 'assets/backgrounds/battle_bg_light.png';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            assetFor(Theme.of(context).brightness),
            fit: BoxFit.cover,
            errorBuilder: (context, _, _) =>
                CustomPaint(painter: _PetalPainter(palette)),
          ),
        ),
        // A scrim across the top third, because that is where the art is
        // busiest and where every one of these screens puts its
        // smallest text — the lobby's name and standing, the arena's
        // player chips. Checked on a device rather than assumed: in dark
        // the moon sits directly behind the wordmark and washed it out.
        //
        // It fades to nothing well before the middle, so the scene is
        // still a scene; this lifts the text off it rather than hiding
        // what it was drawn for.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.background.withValues(alpha: 0.82),
                    palette.background.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
            ),
          ),
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
      ..color = palette.primaryCoral.withValues(alpha: 0.16);

    for (var i = 0; i < 22; i++) {
      final dx = random.nextDouble() * size.width;
      // Kept to the top and bottom margins. Petals drifting across the
      // middle sit behind the card, where they read as dirt on the
      // screen rather than atmosphere.
      final band = random.nextBool();
      final dy = band
          ? random.nextDouble() * size.height * 0.22
          : size.height * (0.78 + random.nextDouble() * 0.22);
      final scale = 5 + random.nextDouble() * 6;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(random.nextDouble() * math.pi * 2);
      // A petal, not a dot: two arcs meeting at a point, which is what
      // separates falling sakura from bubbles.
      final path = Path()
        ..moveTo(0, -scale)
        ..quadraticBezierTo(scale * 0.9, -scale * 0.2, 0, scale)
        ..quadraticBezierTo(-scale * 0.9, -scale * 0.2, 0, -scale)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
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
/// The small repeat of the card's character in its corners.
class _CornerMark extends StatelessWidget {
  const _CornerMark({
    required this.prompt,
    required this.palette,
    this.ink,
  });

  final String prompt;
  final AppPalette palette;

  /// Overrides the coral when the card is backed by dark skin art —
  /// coral at 55% disappears against black.
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    return Text(
      prompt.characters.isEmpty ? '' : prompt.characters.first,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: (ink ?? palette.primaryCoral).withValues(alpha: 0.55),
      ),
    );
  }
}

/// A card back: seigaiha-style arcs, the wave pattern that is already
/// this app's visual shorthand for "Japanese" on the home screen.


/// The four numbers a player wants after a match, from the redesign's
/// result panel.
///
/// **Right/wrong are this player's own answers, not the match's.** The
/// score above already says who won; what this adds is how *you* did,
/// which on a loss is the only encouraging thing on the screen.
///
/// A duration of `null` shows a dash rather than a guess: matches
/// created before the start time was recorded genuinely cannot say how
/// long they took, and inventing "00:00" would be worse than admitting
/// it.
class BattleResultStats extends StatelessWidget {
  const BattleResultStats({
    super.key,
    required this.strings,
    required this.correct,
    required this.wrong,
    required this.cards,
    required this.duration,
  });

  final AppStrings strings;
  final int correct;
  final int wrong;
  final int cards;
  final Duration? duration;

  static String _clock(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: palette.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.divider),
        ),
        child: Row(
          children: [
            _Stat(
              icon: Icons.check_circle,
              tint: palette.secondaryBlue,
              value: '$correct',
              label: strings.battleStatCorrect,
            ),
            _Divider(palette: palette),
            _Stat(
              icon: Icons.cancel,
              tint: palette.errorRed,
              value: '$wrong',
              label: strings.battleStatWrong,
            ),
            _Divider(palette: palette),
            _Stat(
              icon: Icons.style,
              tint: palette.primaryCoral,
              value: '$cards',
              label: strings.battleStatCards,
            ),
            _Divider(palette: palette),
            _Stat(
              icon: Icons.timer_outlined,
              tint: palette.textNavy,
              value: duration == null ? '—' : _clock(duration!),
              label: strings.battleStatDuration,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: palette.divider);
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.tint,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color tint;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: tint),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: palette.textNavy,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: palette.textNavy.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}


/// What to do, said beside the card it is about — the redesign's
/// choosing panel.
///
/// The face-down card and this sit side by side with an arrow between
/// them, because the sentence is about *that* card: the one going to the
/// opponent as soon as a choice is made. A caption under the card said
/// the same words with none of that connection.
class BattleChoosePrompt extends StatelessWidget {
  const BattleChoosePrompt({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A dashed arrow, drawn rather than typed: an em-dash chain in a
        // Text would not line up with anything and cannot bend.
        SizedBox(
          width: 44,
          height: 14,
          child: CustomPaint(painter: _DashedArrow(palette.primaryCoral)),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: palette.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: palette.primaryCoral.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: palette.textNavy,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedArrow extends CustomPainter {
  _DashedArrow(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width - 10; x += 9) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), paint);
    }
    final tip = size.width;
    canvas.drawLine(Offset(tip - 7, y - 4), Offset(tip, y), paint);
    canvas.drawLine(Offset(tip - 7, y + 4), Offset(tip, y), paint);
  }

  @override
  bool shouldRepaint(_DashedArrow old) => old.color != color;
}
