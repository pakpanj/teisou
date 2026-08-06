import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'mascot_widget.dart';
import 'speech_bubble.dart';

/// The mascot as a character standing in the corner of the screen, talking
/// to the learner — the Clash of Clans advisor arrangement.
///
/// The difference from a card in a list is not decoration. Something in the
/// scroll content is part of the page; something standing at the edge of the
/// screen, overlapping it, reads as present in the room and addressing you.
/// That is the whole effect, and it only works if it is anchored rather than
/// laid out inline.
///
/// **It must never cost the learner access to the screen**, and getting
/// that wrong is easy. The first version simply floated over the page. On
/// a short screen it floated over nothing and looked right; on the chapter
/// list — 50-odd rows — it sat squarely on top of two tappable chapters,
/// greying out their text. Bottom padding does not help there, because it
/// only clears the *end* of a list the learner spends most of their time
/// in the middle of.
///
/// So the advisor is a greeting, not an overlay. It is present while the
/// list is at rest at its top, and it steps aside the moment the learner
/// starts scrolling — which is exactly when they have stopped reading it
/// and started working. Coming back to the top brings it back. On a screen
/// with nothing to scroll it simply stays, which is why it can be used on
/// both without a flag.
///
/// While it is away it is also [IgnorePointer]-ed, so a chapter underneath
/// stays tappable rather than being blocked by an invisible character.
/// That is the one place a blanket ignore is correct: the advisor is
/// ignoring *itself*. Applying one while it is visible would instead have
/// made it untappable, since a descendant cannot un-ignore a parent that
/// ignores pointers — a mistake caught here before it shipped.
///
/// Wraps the scrollable rather than sitting beside it in a caller-built
/// [Stack]: it has to hear the list's scroll notifications, and owning the
/// arrangement keeps the bottom-padding contract in one place instead of
/// relying on every caller to remember it.
///
/// Dismissing hides only the bubble. The character stays, smaller and quiet,
/// and tapping it brings the message back — the same bargain Clash of Clans
/// makes, where the advisor can be waved off but never actually leaves.
class MascotAdvisor extends StatefulWidget {
  const MascotAdvisor({
    super.key,
    required this.mood,
    required this.message,
    required this.child,
    this.ctaLabel,
    this.onCtaTap,
    this.size = 150,
    this.bottomInset = 0,
  });

  /// The screen's own content — usually the scrollable this advisor
  /// listens to. Leave [reservedBottomSpace] of padding at its end so the
  /// last item can still be read with the character standing there.
  final Widget child;

  final MascotMood mood;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  /// Height of the character. Large enough to read as a character rather
  /// than an icon; the bubble sizes itself around it.
  final double size;

  /// Extra space to lift the advisor above whatever sits at the bottom of
  /// the screen — a banner ad, mostly.
  final double bottomInset;

  /// Bottom padding a scrolling child should leave for the character.
  /// Named here rather than written as a number at each call site, so it
  /// cannot drift away from [size] as the character is resized.
  static const double reservedBottomSpace = 170;

  @override
  State<MascotAdvisor> createState() => _MascotAdvisorState();
}

class _MascotAdvisorState extends State<MascotAdvisor>
    with SingleTickerProviderStateMixin {
  bool _speaking = true;

  /// False while the learner is scrolling away from the top. Not a
  /// scroll-direction test: coming back up should restore the advisor
  /// before the list has finished settling, so this tracks position.
  bool _atRest = true;

  bool _handleScroll(ScrollNotification notification) {
    // Only the primary vertical list, never a horizontal strip or a
    // nested list inside a card — those say nothing about whether the
    // page's own content has moved out from under the character.
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final atRest = notification.metrics.pixels <= 8;
    if (atRest != _atRest) setState(() => _atRest = atRest);
    return false;
  }

  /// Walks in from below the edge rather than fading in, so it reads as the
  /// character arriving rather than the UI drawing another panel.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.45),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack));

  late final Animation<double> _fade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0, 0.5),
  );

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: Stack(children: [widget.child, _buildAdvisor(palette)]),
    );
  }

  Widget _buildAdvisor(AppPalette palette) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: widget.bottomInset,
      child: IgnorePointer(
        // Only ever true while it is invisible, so this can never be the
        // reason a visible advisor refuses a tap.
        ignoring: !_atRest,
        child: AnimatedOpacity(
          opacity: _atRest ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
                child: Row(
                  // Beside the head, not the feet: a bubble level with the
                  // character's legs reads as floating past it.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MascotWidget(
                      mood: widget.mood,
                      size: widget.size,
                      showBackdrop: false,
                      // Poking a quiet advisor is how the message comes back,
                      // so the character is never a dead end.
                      onTap: () => setState(() => _speaking = true),
                    ),
                    Expanded(
                      // Slid back over the character's own empty margin. The
                      // art is square while the character is tall and narrow,
                      // so every mood carries transparent space at its sides —
                      // from 0.10 of the box width on the widest pose (sad) to
                      // 0.22 on the narrowest (proud). Reclaiming 0.08 closes
                      // most of the visible gap and still stays inside even the
                      // widest pose's margin, so the bubble cannot collide with
                      // the character. Translating rather than resizing keeps
                      // the character's box square, which is what holds its
                      // height steady as the mood changes.
                      child: Transform.translate(
                        offset: Offset(-widget.size * 0.08, 0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          // AnimatedSwitcher stacks its children centred by
                          // default and passes loose constraints, so a short
                          // bubble drifts to the middle of the remaining width
                          // and its tail ends up pointing at empty space rather
                          // than at the character. Left-aligning keeps the tail
                          // where the head is, and lets the bubble hug its text.
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.centerLeft,
                            children: [...previous, ?current],
                          ),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  alignment: Alignment.centerLeft,
                                  child: child,
                                ),
                              ),
                          child: _speaking
                              ? _buildBubble(palette)
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(AppPalette palette) {
    return GestureDetector(
      onTap: () => setState(() => _speaking = false),
      child: SpeechBubble(
        color: palette.cardWhite,
        // Aimed low, because the character stands on the ground beside
        // the bubble rather than sitting level with its middle — the
        // tail has to reach across to a head that is near the bubble's
        // bottom edge.
        tailTopOffset: 40,
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.message,
              style: TextStyle(fontSize: 14, color: palette.textNavy),
            ),
            if (widget.ctaLabel != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onCtaTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(widget.ctaLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
