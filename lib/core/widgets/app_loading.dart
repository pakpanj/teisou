import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// The shape of the content that is coming, greyed out and lit by a
/// travelling sheen — instead of a spinner.
///
/// **Why not a spinner.** A spinner says "something is happening" and
/// nothing else; it looks identical whether a list, a picture or a whole
/// screen is on its way, and it turns at the same speed whether the wait
/// is 40ms or four seconds. A skeleton in the shape of the rows about to
/// arrive tells the learner what they are waiting for and lets the page
/// settle into place rather than snap.
///
/// **The timing matters more than the drawing.** Nearly everything here
/// loads from the asset bundle in a few tens of milliseconds, so a loader
/// that appeared instantly would mostly appear *and vanish* inside one
/// blink — a flicker, which is worse than showing nothing at all. So this
/// draws nothing for [appearAfter], and fades in rather than snapping in
/// when it does arrive.
///
/// **What that does not cover, honestly**: a load finishing just after
/// [appearAfter] still gets a brief partial fade. Removing that would mean
/// holding the loading view for a minimum time after the data arrives,
/// which this widget cannot do — its parent's `AsyncValue.when` swaps it
/// out the instant the future completes, and it is never told. Fixing it
/// properly means a wrapper that owns the swap at all 26 call sites. The
/// fade softens it in the meantime.
class AppLoading extends StatefulWidget {
  const AppLoading({
    super.key,
    this.rows = 5,
    this.appearAfter = const Duration(milliseconds: 180),
  });

  /// How many placeholder rows to draw. The default suits the level and
  /// category lists this replaces; a screen showing a long list can ask
  /// for more, but there is no point drawing past the fold.
  final int rows;

  /// How long a load may take before it is worth telling anyone about.
  final Duration appearAfter;

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading>
    with SingleTickerProviderStateMixin {
  bool _visible = false;

  /// Held so it can be cancelled. A bare `Future.delayed` cannot be, and
  /// this widget is disposed early by design — the whole point is that a
  /// fast load tears it down before it ever appears. Leaving the timer to
  /// run means the screen keeps a callback alive after it is gone, which
  /// the test binding rightly refuses to let pass.
  Timer? _appearance;

  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _appearance = Timer(
      widget.appearAfter,
      () => setState(() => _visible = true),
    );
  }

  @override
  void dispose() {
    _appearance?.cancel();
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedOpacity(
      // Nothing at all until the wait has earned an explanation, and
      // then eased in — a skeleton that snaps into place is its own
      // small jolt on a screen that is meant to feel calm.
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 260),
      child: ListView.builder(
        // The wait is not the place to let someone scroll a fake list.
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: widget.rows,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _SkeletonRow(sheen: _sheen, palette: palette, index: index),
        ),
      ),
    );
  }
}

/// One placeholder shaped like the app's list rows: a round badge and two
/// lines of text.
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({
    required this.sheen,
    required this.palette,
    required this.index,
  });

  final Animation<double> sheen;
  final AppPalette palette;
  final int index;

  @override
  Widget build(BuildContext context) {
    // The second line is shorter than the first, and the rows differ from
    // each other, because a stack of identical bars reads as a pattern
    // rather than as text waiting to arrive.
    final titleWidth = 0.42 + (index % 3) * 0.09;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: palette.cardWhite,
            child: Row(
              children: [
                _Block(width: 56, height: 56, radius: 28, palette: palette),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: titleWidth,
                        child: _Block(height: 14, radius: 7, palette: palette),
                      ),
                      const SizedBox(height: 10),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: titleWidth + 0.28,
                        child: _Block(height: 10, radius: 5, palette: palette),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // The sheen is an overlay, not a mask.
          //
          // The first version wrapped the whole row in a ShaderMask, which
          // repainted card and blocks alike in one gradient — so the badge
          // and the two text bars vanished into a plain grey slab, losing
          // the only thing a skeleton has over a spinner. Caught by
          // looking at it on a device; the test counted ShaderMasks and
          // was perfectly happy. A translucent white band laid on top
          // lightens what is underneath instead of replacing it.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: sheen,
                builder: (context, _) {
                  final travel = sheen.value * 2.4 - 0.7;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [
                          Color(0x00FFFFFF),
                          Color(0x8CFFFFFF),
                          Color(0x00FFFFFF),
                        ],
                        stops: [
                          (travel - 0.22).clamp(0.0, 1.0),
                          travel.clamp(0.0, 1.0),
                          (travel + 0.22).clamp(0.0, 1.0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    this.width,
    required this.height,
    required this.radius,
    required this.palette,
  });

  final double? width;
  final double height;
  final double radius;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.progressTrack,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
