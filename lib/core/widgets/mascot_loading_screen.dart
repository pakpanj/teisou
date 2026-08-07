import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'mascot_widget.dart';

/// A full-screen wait: the mascot working away, a bar underneath, and a
/// percentage — the shape a game loading screen takes.
///
/// **About that percentage, plainly.** It is an estimate of elapsed time,
/// not a measurement of work done. Almost everything this screen waits for
/// is a single `rootBundle.loadString`, which reports nothing at all until
/// it hands back the whole string; there is no half-loaded state to read.
/// A bar that claimed otherwise would be inventing a number.
///
/// So it is built to never say anything false. It rises quickly and then
/// slows, flattening out around **93%** and going no further — it cannot
/// sit at 100% while the app is still working, which is the single most
/// annoying thing a progress bar does. When the wait ends the screen is
/// simply removed by its parent, which is why you will rarely see it
/// finish: the honest reading of "92%" is "still going, and it has been a
/// while".
///
/// The mascot does the real reassuring. It cycles through the poses that
/// look like effort — reading, thinking, writing — so the screen shows
/// somebody working rather than a shape rotating at a fixed speed.
class MascotLoadingScreen extends StatefulWidget {
  const MascotLoadingScreen({
    super.key,
    this.label,
    this.progress,
    this.mascotSize = defaultMascotSize,
  });

  /// Named so the startup preloader can warm exactly this size's bitmap.
  /// `cacheWidth` is part of the image cache key, so warming any other
  /// size warms a key this screen never asks for.
  static const double defaultMascotSize = 200;

  /// Optional line under the bar, e.g. what is being prepared.
  final String? label;

  /// Real progress, 0 to 1, when the caller genuinely knows — the startup
  /// preload counts discrete datasets, so it does.
  ///
  /// Given one, the bar shows it and reaches 100% honestly. Left null, the
  /// bar falls back to the elapsed-time curve described above, which never
  /// claims to finish.
  final double? progress;

  final double mascotSize;

  @override
  State<MascotLoadingScreen> createState() => _MascotLoadingScreenState();
}

class _MascotLoadingScreenState extends State<MascotLoadingScreen>
    with SingleTickerProviderStateMixin {
  /// The poses that read as "working". Deliberately not the celebratory
  /// ones: a mascot cheering while you wait is celebrating nothing.
  static const _workingMoods = [
    MascotMood.reading,
    MascotMood.thinking,
    MascotMood.writing,
    MascotMood.curious,
  ];

  /// How long one pose is held. Long enough to register as a pose rather
  /// than a flicker, short enough that a three-second wait shows more
  /// than one.
  static const _poseDuration = Duration(milliseconds: 900);

  /// How quickly the curve approaches its limit.
  ///
  /// This single number sets both the feel and the cap: the bar tops out
  /// at `1 - exp(-_rate)`, which at 2.6 is 92.6%, and gets past half in
  /// about a second. **Raising it much past 3 defeats the point** — at 6
  /// the cap rounds to 100% and the bar starts claiming to be finished
  /// while the app is still working. There used to be a separate
  /// `_ceiling` constant meant to guarantee that, but it never bound:
  /// injecting `_ceiling = 1.0` changed the cap from 90% to 93% and no
  /// test noticed, because the exponential was doing all the work. One
  /// knob, and a test on the cap itself.
  static const _rate = 2.6;

  /// How long the curve is drawn over before it is essentially flat.
  static const _span = Duration(seconds: 8);

  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: _span,
  )..forward();

  int get _poseIndex =>
      (_clock.lastElapsedDuration ?? Duration.zero).inMilliseconds ~/
      _poseDuration.inMilliseconds;

  /// Fast at first, then slower and slower — the shape of a wait whose end
  /// nobody can see. Tops out at `1 - exp(-_rate)`, never at 1.
  double get _progress => 1 - math.exp(-_rate * _clock.value);

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    // A Scaffold, not a bare ColoredBox.
    //
    // This screen is returned straight into `home:`, with no Material
    // ancestor above it — and a Text with no Material inherits Flutter's
    // debug fallback, which paints yellow underlines under every word.
    // It shipped that way through one device check before anyone looked.
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, _) {
            final mood = _workingMoods[_poseIndex % _workingMoods.length];
            // Measured progress wins over the estimate whenever there is
            // any. The estimate exists only for waits nothing can count.
            final progress = widget.progress ?? _progress;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Keyed on the mood so each pose gets the widget's own
                // entrance rather than the image swapping underneath a
                // character that is standing still.
                MascotWidget(
                  key: ValueKey(mood),
                  mood: mood,
                  size: widget.mascotSize,
                  showBackdrop: false,
                  groundShadow: true,
                ),
                const SizedBox(height: 36),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _ProgressBar(
                    value: progress,
                    // The highlight rides a full cycle every 1.4s of the
                    // 8s clock, independent of how far the fill has got.
                    shimmer: (_clock.value * (_span.inMilliseconds / 1400)) % 1,
                    palette: palette,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: palette.primaryCoral,
                    // Tabular figures, or the number jitters sideways as
                    // the digits change width — which on a bar that is
                    // meant to feel steady is oddly distracting.
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (widget.label != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.label!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.textNavy.withValues(alpha: 0.55),
                    ),
                  ),
                ],
                const Spacer(),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The bar itself: a track, a fill, and a highlight travelling along the
/// filled part.
///
/// The travelling highlight is not decoration. A bar that only grows looks
/// stopped whenever progress flattens out — and this one flattens by
/// design near the end. Something moving inside it says the app is alive
/// even when the number has stopped climbing.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.shimmer,
    required this.palette,
  });

  final double value;

  /// Where the travelling highlight is, 0 to 1 across the filled part.
  final double shimmer;

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 12,
        // Full width explicitly.
        //
        // Without it the Stack has no unpositioned child of its own — the
        // track is `Positioned.fill` and the fill is a FractionallySizedBox
        // — so it shrank to whatever fraction was currently filled. The
        // track never showed, and the Column shrank with it and dragged
        // the mascot and the label off-centre with it. Left-aligned on a
        // device, and nothing in the code looked wrong.
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: palette.progressTrack)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            palette.primaryCoral.withValues(alpha: 0.85),
                            palette.primaryCoral,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: const [
                            Color(0x00FFFFFF),
                            Color(0x73FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                          stops: [
                            (shimmer - 0.18).clamp(0.0, 1.0),
                            shimmer.clamp(0.0, 1.0),
                            (shimmer + 0.18).clamp(0.0, 1.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
