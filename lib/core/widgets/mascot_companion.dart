import 'package:flutter/material.dart';

import '../services/mascot_coach.dart';
import '../theme/app_palette.dart';
import 'mascot_widget.dart';
import 'speech_bubble.dart';

/// The mascot sitting beside a lesson, reacting to each answer.
///
/// Deliberately **inline**, not anchored to the screen edge like
/// [MascotAdvisor]. A quiz screen is the one place where floating over the
/// content is indefensible: everything on it is either an option to tap or
/// the button to move on, so a character parked on top of it is in the way
/// no matter where it stands. Taking part in the layout costs a little
/// height and cannot cover anything.
///
/// It occupies its space only while it has something to say, and collapses
/// the moment the next question starts — so a learner who has not answered
/// yet sees the same screen they always did.
class MascotCompanion extends StatelessWidget {
  const MascotCompanion({
    super.key,
    required this.line,
    this.size = 92,
  });

  /// What to say, or null between questions.
  final CoachLine? line;

  /// Small on purpose. This one shares a screen with the question, the
  /// options and the Next button, and on a short phone every one of those
  /// matters more than the character does — so it grew only from 76 to
  /// 92, most of which came free from the art filling its canvas rather
  /// than from taking more of the screen.
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final current = line;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: current == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Keyed on the mood so a change of face restarts the
                  // mascot's own entrance rather than silently swapping
                  // the image underneath a character that is already
                  // standing still — the reaction is the point.
                  MascotWidget(
                    key: ValueKey(current.mood),
                    mood: current.mood,
                    size: size,
                    showBackdrop: false,
                  ),
                  Expanded(
                    // Pulled back over the transparent margin the square
                    // artwork carries at its sides, the same 0.08 the
                    // advisor uses and for the same reason.
                    child: Transform.translate(
                      offset: Offset(-size * 0.08, 0),
                      child: SpeechBubble(
                        color: palette.cardWhite,
                        padding: const EdgeInsets.all(10),
                        // Aimed at a head that sits near the top of a
                        // short bubble rather than at its middle.
                        tailTopOffset: 20,
                        shadow: BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                        child: Text(
                          current.message,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: palette.textNavy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
