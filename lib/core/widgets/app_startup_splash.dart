import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'mascot_widget.dart';

/// What the app shows in the moment before it knows which screen to open.
///
/// This used to be a bare white rectangle. It is a short wait — the app is
/// reading one preference — but it is the *first* thing anyone sees, and a
/// blank white screen after a splash reads as the app having failed to
/// start rather than as it starting.
///
/// Deliberately not the skeleton loader: there is no list coming, and no
/// spinner either. The mascot is already the app's face, and a character
/// waving hello is a better answer to "is this thing working" than any
/// abstract animation. Three dots underneath give the eye something that
/// is plainly still running, without claiming to know how long is left —
/// which a progress bar would, falsely.
class AppStartupSplash extends StatelessWidget {
  const AppStartupSplash({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ColoredBox(
      color: palette.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotWidget(
              mood: MascotMood.waving,
              size: 200,
              showBackdrop: false,
              groundShadow: true,
            ),
            const SizedBox(height: 28),
            _BouncingDots(color: palette.primaryCoral),
          ],
        ),
      ),
    );
  }
}

/// Three dots rising in turn.
///
/// A spinner turns at a fixed rate no matter what is happening, which is
/// why it stops registering as information. These at least read as a
/// rhythm — and, unlike a progress bar, they promise nothing about how far
/// along the wait is, which is honest: nothing here knows.
class _BouncingDots extends StatefulWidget {
  const _BouncingDots({required this.color});

  final Color color;

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Transform.translate(
                  offset: Offset(0, -8 * _hop(i)),
                  child: Opacity(
                    // Fading with the hop as well as moving keeps the row
                    // reading as one wave rather than three separate dots.
                    opacity: 0.35 + 0.65 * _hop(i),
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: widget.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// How high dot [index] is right now, 0 to 1.
  ///
  /// Each dot is a third of a cycle behind the last, and each spends only
  /// the first 60% of its own slice in the air — the pause at the bottom
  /// is what makes it a bounce instead of a wobble.
  double _hop(int index) {
    final phase = (_controller.value - index * 0.16) % 1.0;
    if (phase > 0.6) return 0;
    return Curves.easeInOut.transform(1 - (phase / 0.3 - 1).abs().clamp(0, 1));
  }
}
