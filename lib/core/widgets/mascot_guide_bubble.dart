import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'mascot_widget.dart';
import 'speech_bubble.dart';

/// Pairs the existing [MascotWidget] with a short speech-bubble message and
/// an optional action button — the mascot's first "active guide" use, as
/// opposed to its other call sites (exam result, paywall, coming-soon
/// sheets), which are static reactions with no message and no action.
///
/// The bubble has a real tail pointing at the mascot. It was a plain
/// rounded card for a long while because a hand-drawn tail could not be
/// checked without a physical device — that constraint is gone, and the
/// tail is what turns the message from a caption *about* the mascot into
/// the mascot *talking to you*.
///
/// The pair animates in together: the mascot rises and the bubble springs
/// open from beside its head, so the message reads as having been said
/// rather than having always been there. Tapping the mascot pokes it (see
/// [MascotWidget]) — the bubble is deliberately not a tap target, since a
/// message that navigates on touch is a trap next to a character that
/// invites touching.
class MascotGuideBubble extends StatefulWidget {
  final MascotMood mood;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;
  final double mascotSize;

  const MascotGuideBubble({
    super.key,
    required this.mood,
    required this.message,
    this.ctaLabel,
    this.onCtaTap,
    this.mascotSize = 72,
  });

  @override
  State<MascotGuideBubble> createState() => _MascotGuideBubbleState();
}

class _MascotGuideBubbleState extends State<MascotGuideBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  )..forward();

  /// Overshoots slightly before settling, so the bubble pops rather than
  /// fades — the same reason the mascot springs instead of scaling.
  late final Animation<double> _pop = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutBack,
  );

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MascotWidget(mood: widget.mood, size: widget.mascotSize),
        const SizedBox(width: 12),
        Expanded(
          child: ScaleTransition(
            scale: _pop,
            // Grows out of the mascot's head rather than its own middle, so
            // the bubble looks like it came from the character.
            alignment: Alignment.centerLeft,
            child: SpeechBubble(
              color: palette.cardWhite,
              // Aimed at roughly a third of the way down the mascot, which
              // is where a face sits on a body — and where the emoji sits
              // in the placeholder circle.
              tailTopOffset: widget.mascotSize * 0.34,
              shadow: BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
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
          ),
        ),
      ],
    );
  }
}
