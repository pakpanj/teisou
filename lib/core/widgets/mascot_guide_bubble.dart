import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'mascot_widget.dart';

/// Pairs the existing [MascotWidget] with a short speech-bubble message and
/// an optional action button — the mascot's first "active guide" use, as
/// opposed to its other call sites (exam result, paywall, coming-soon
/// sheets), which are static reactions with no message and no action.
///
/// Deliberately a plain rounded card next to the mascot rather than a
/// literal comic-style speech bubble with a pointer tail — a hand-drawn
/// tail shape can't be visually verified without a physical device in this
/// project's current environment (see CLAUDE.md's standing on-device-
/// testing gap), so this sticks to shapes already proven safe elsewhere in
/// the app (rounded [Container] + [BoxShadow], same as every module card).
class MascotGuideBubble extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MascotWidget(mood: mood, size: mascotSize),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: TextStyle(fontSize: 14, color: palette.textNavy),
                ),
                if (ctaLabel != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onCtaTap,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(ctaLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
