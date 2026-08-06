import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// Emotional state for the maneki-neko mascot shown across the app
/// (exam results, paywall, coming-soon sheets, profile header, and — since
/// the mascot started coaching — every quiz).
///
/// **Every mood here is one the app actually selects somewhere.** The list
/// is not a wishlist: each value costs a drawn PNG, and art nothing ever
/// picks is work thrown away. If you add one, wire it in the same change.
///
/// Art lives at `assets/mascot/{mood}.png`; a mood with no file yet falls
/// back to its emoji, so the set can be filled in one drawing at a time
/// without breaking a screen. `scripts/mascot_prompts.md` carries the
/// generation prompt for each, and the shared character sheet they all
/// have to match.
enum MascotMood {
  // --- the original six
  happy,
  excited,
  sleepy,
  proud,
  sad,
  cheering,

  // --- reactions while learning
  /// "It is fine, try again" — the face for a wrong answer. Its own mood
  /// rather than reusing [happy], which reads as pleased about the slip.
  encouraging,

  /// Paw to chin, working something out. For a question still unanswered.
  thinking,

  /// Pointing at what it is talking about. For guidance that explains a
  /// control rather than reacting to the learner.
  explaining,

  /// Wide-eyed. A perfect score, or a run better than expected.
  surprised,

  /// Head tilted, interested. First time into a module.
  curious,

  /// Fists up, ready — Kaiwa's `semangat`. The start of an exam.
  determined,

  // --- social expressions, shared with Kaiwa's `expressionTag` vocabulary
  /// Waving hello. Greeting on Home.
  waving,

  /// A polite bow — Kaiwa's `sopan` and `minta_maaf`.
  bowing,

  /// At ease — Kaiwa's `santai`.
  relaxed,

  /// Concerned — Kaiwa's `khawatir`. A locked level, a streak about to end.
  worried,

  // --- studying
  /// Holding an open book. Reading and lesson screens.
  reading,

  /// Brush in paw. Stroke-order and kanji writing screens.
  writing,
}

/// The mascot, with weight.
///
/// Two motions run at once. An idle loop per mood gives it a resting
/// presence, and a **spring** answers every tap: it squashes on impact and
/// springs back past its resting size before settling, the way a character
/// in Clash of Clans reacts when you poke it.
///
/// The squash is real squash-and-stretch, not a uniform shrink — the body
/// flattens vertically and spreads horizontally by the inverse, so its
/// volume looks roughly conserved. It is anchored at the bottom so the
/// mascot compresses **into the ground** instead of shrinking toward its own
/// centre, which is what makes it read as something with weight standing on
/// a surface rather than a picture being resized.
///
/// A [SpringSimulation] drives it rather than a curve, so the overshoot and
/// the settle fall out of the physics instead of being drawn into an easing
/// curve by hand.
///
/// Each poke applies the same compression rather than stacking onto
/// whatever squash is already in flight. Compounding would look livelier
/// for two taps and then drive an impatient child's mascot down to nothing,
/// so a poke always re-launches the spring from the same place — the
/// *velocity* it launches with is what carries the previous motion.
///
/// Still emoji art. The body is a single [Text] widget, and the whole point
/// of keeping that in one place is that real per-mood art drops into
/// [_buildBody] alone — every motion above already applies to whatever is
/// returned there, so nothing else changes when the art arrives.
class MascotWidget extends StatefulWidget {
  final MascotMood mood;
  final double size;

  /// Called after the tap reaction fires. The reaction itself is not
  /// optional — a mascot that ignores being touched is the thing this
  /// widget exists to stop being.
  final VoidCallback? onTap;

  /// The mood-tinted disc behind the character.
  ///
  /// Right for a mascot sitting inside a card, where the disc separates it
  /// from the surface it is on. Wrong for one standing at the edge of the
  /// screen as a character in the room with you — a disc there reads as a
  /// sticker pinned to the corner. Hence [MascotAdvisor] turns it off.
  final bool showBackdrop;

  const MascotWidget({
    super.key,
    required this.mood,
    this.size = 140,
    this.onTap,
    this.showBackdrop = true,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _durationFor(widget.mood),
  )..repeat(reverse: true);

  /// Vertical scale of the body: 1.0 at rest, below 1 while squashed, and
  /// briefly above 1 as the spring overshoots on the way back.
  late final AnimationController _squash = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  /// Tuned by feel rather than by physical units. Stiff enough that the
  /// answer is immediate, damped enough that it settles in one visible
  /// bounce instead of wobbling like jelly — a couple of oscillations reads
  /// as playful, more reads as broken.
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 420,
    ratio: 0.42,
  );

  void _poke() {
    // Snap to the compressed state first: the impact should be instant, and
    // only the recovery is springy. Easing into the squash as well would
    // make it feel like rubber rather than a knock.
    _squash.value = 0.82;
    _squash.animateWith(
      SpringSimulation(_spring, _squash.value, 1, -2.4),
    );
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  static Duration _durationFor(MascotMood mood) {
    switch (mood) {
      case MascotMood.happy:
        return const Duration(milliseconds: 900);
      case MascotMood.excited:
        return const Duration(milliseconds: 700);
      case MascotMood.sleepy:
        return const Duration(milliseconds: 2200);
      case MascotMood.proud:
        return const Duration(milliseconds: 1400);
      case MascotMood.sad:
        return const Duration(milliseconds: 1600);
      case MascotMood.cheering:
        return const Duration(milliseconds: 500);
      // Grouped by how busy the pose should look. A mascot that breathes
      // at one rate in every mood stops reading as a character.
      case MascotMood.determined:
      case MascotMood.surprised:
        return const Duration(milliseconds: 650);
      case MascotMood.waving:
      case MascotMood.curious:
        return const Duration(milliseconds: 850);
      case MascotMood.encouraging:
      case MascotMood.explaining:
      case MascotMood.bowing:
        return const Duration(milliseconds: 1100);
      case MascotMood.thinking:
      case MascotMood.worried:
      case MascotMood.reading:
      case MascotMood.writing:
        return const Duration(milliseconds: 1600);
      case MascotMood.relaxed:
        return const Duration(milliseconds: 2000);
    }
  }

  static const _emoji = {
    MascotMood.happy: '😸',
    MascotMood.excited: '🐱',
    MascotMood.sleepy: '😴',
    MascotMood.proud: '😻',
    MascotMood.sad: '🙀',
    MascotMood.cheering: '🙌',
    MascotMood.encouraging: '🤗',
    MascotMood.thinking: '🤔',
    MascotMood.explaining: '👉',
    MascotMood.surprised: '😲',
    MascotMood.curious: '🐈',
    MascotMood.determined: '💪',
    MascotMood.waving: '👋',
    MascotMood.bowing: '🙇',
    MascotMood.relaxed: '😌',
    MascotMood.worried: '😟',
    MascotMood.reading: '📖',
    MascotMood.writing: '🖌',
  };

  static const _background = {
    MascotMood.happy: Color(0xFFFCE0E6),
    MascotMood.excited: Color(0xFFFBD9DD),
    MascotMood.sleepy: Color(0xFFE4DCF7),
    MascotMood.proud: Color(0xFFFFF0C6),
    MascotMood.sad: Color(0xFFDDE5E9),
    MascotMood.cheering: Color(0xFFD9F5E3),
    // Warm tints for encouragement, cool ones for concentration, so the
    // backdrop agrees with the face even before the art lands.
    MascotMood.encouraging: Color(0xFFFDE7DC),
    MascotMood.thinking: Color(0xFFE7E9F7),
    MascotMood.explaining: Color(0xFFE3F0FA),
    MascotMood.surprised: Color(0xFFFFF2D6),
    MascotMood.curious: Color(0xFFEDE7F8),
    MascotMood.determined: Color(0xFFFFE2E2),
    MascotMood.waving: Color(0xFFFCE0E6),
    MascotMood.bowing: Color(0xFFF1E8E2),
    MascotMood.relaxed: Color(0xFFE2F1EC),
    MascotMood.worried: Color(0xFFE6E8EC),
    MascotMood.reading: Color(0xFFE8F0E4),
    MascotMood.writing: Color(0xFFF3EAE0),
  };

  @override
  void didUpdateWidget(covariant MascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _controller.duration = _durationFor(widget.mood);
      _controller
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _squash.dispose();
    super.dispose();
  }

  Offset _offsetFor(double t) {
    switch (widget.mood) {
      case MascotMood.happy:
        return Offset(0, -widget.size * 0.05 * t);
      case MascotMood.cheering:
        return Offset(0, -widget.size * 0.14 * t);
      case MascotMood.sad:
        return Offset((t - 0.5) * widget.size * 0.06, 0);
      case MascotMood.waving:
        // A smaller bounce than happy's: the arm carries the motion.
        return Offset(0, -widget.size * 0.03 * t);
      case MascotMood.determined:
        return Offset(0, -widget.size * 0.08 * t);
      case MascotMood.worried:
        // The same uneasy sway as sad, gentler.
        return Offset((t - 0.5) * widget.size * 0.04, 0);
      case MascotMood.bowing:
        // Dips rather than rises — the only mood that moves downward.
        return Offset(0, widget.size * 0.05 * t);
      case MascotMood.excited:
      case MascotMood.sleepy:
      case MascotMood.proud:
      case MascotMood.encouraging:
      case MascotMood.thinking:
      case MascotMood.explaining:
      case MascotMood.surprised:
      case MascotMood.curious:
      case MascotMood.relaxed:
      case MascotMood.reading:
      case MascotMood.writing:
        return Offset.zero;
    }
  }

  double _angleFor(double t) {
    switch (widget.mood) {
      case MascotMood.excited:
        return (t - 0.5) * 0.3;
      case MascotMood.sad:
        return (t - 0.5) * 0.12;
      case MascotMood.curious:
        // The head-tilt that makes a cat look interested.
        return (t - 0.5) * 0.18;
      case MascotMood.waving:
        return (t - 0.5) * 0.1;
      case MascotMood.worried:
        return (t - 0.5) * 0.08;
      case MascotMood.happy:
      case MascotMood.sleepy:
      case MascotMood.proud:
      case MascotMood.cheering:
      case MascotMood.encouraging:
      case MascotMood.thinking:
      case MascotMood.explaining:
      case MascotMood.surprised:
      case MascotMood.determined:
      case MascotMood.bowing:
      case MascotMood.relaxed:
      case MascotMood.reading:
      case MascotMood.writing:
        return 0;
    }
  }

  double _scaleFor(double t) {
    switch (widget.mood) {
      case MascotMood.sleepy:
        return 1 + 0.04 * t;
      case MascotMood.proud:
        return 1 + 0.06 * t;
      case MascotMood.cheering:
        return 1 + 0.05 * t;
      case MascotMood.surprised:
        // A bigger jolt than any other mood, then back — the whole read of
        // being taken aback.
        return 1 + 0.09 * t;
      case MascotMood.determined:
        return 1 + 0.05 * t;
      case MascotMood.relaxed:
      case MascotMood.reading:
        // Breathing, essentially: slow and shallow.
        return 1 + 0.03 * t;
      case MascotMood.happy:
      case MascotMood.excited:
      case MascotMood.sad:
      case MascotMood.encouraging:
      case MascotMood.thinking:
      case MascotMood.explaining:
      case MascotMood.curious:
      case MascotMood.waving:
      case MascotMood.bowing:
      case MascotMood.worried:
      case MascotMood.writing:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _emoji[widget.mood]!;
    final background = _background[widget.mood]!;

    return RepaintBoundary(
      child: GestureDetector(
        // Opaque so the whole circle answers, not just the glyph's own
        // bounds — a character you have to hit precisely does not feel
        // touchable.
        behavior: HitTestBehavior.opaque,
        onTap: _poke,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _squash]),
            builder: (context, child) {
              final t = _controller.value;
              // Volume roughly conserved: flatten vertically and the body
              // spreads sideways by the inverse. Without this the squash
              // reads as the whole mascot moving away from the viewer.
              final squashY = _squash.value;
              final squashX = 1 / squashY;
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (widget.showBackdrop)
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: background,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (widget.mood == MascotMood.proud) ..._sparkles(t),
                  Transform.translate(
                    offset: _offsetFor(t),
                    child: Transform.rotate(
                      angle: _angleFor(t),
                      child: Transform.scale(
                        scale: _scaleFor(t),
                        // Bottom-anchored: the mascot compresses into the
                        // ground rather than toward its own centre, which
                        // is what sells it as having weight.
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.diagonal3Values(
                            squashX,
                            squashY,
                            1,
                          ),
                          child: _buildBody(emoji),
                        ),
                      ),
                    ),
                  ),
                  if (widget.mood == MascotMood.sleepy) _buildZzz(t),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// The mascot's body: real art when it exists, the emoji otherwise.
  ///
  /// Every motion above applies to whatever this returns, so supplying art
  /// is purely a matter of dropping `assets/mascot/{mood}.png` into place —
  /// no code change, and no risk of a half-finished set breaking a screen,
  /// because each mood falls back on its own.
  ///
  /// Same never-crash contract as [AvatarPresetArt] and [KotobaImage]: a
  /// missing or unreadable file shows the emoji rather than Flutter's broken
  /// image icon. Art is expected to arrive one mood at a time, so a mixed
  /// state has to look deliberate rather than broken.
  Widget _buildBody(String emoji) {
    // Without a disc the character owns the whole box; inside one it has to
    // leave a ring of the disc visible around itself.
    final extent = widget.size * (widget.showBackdrop ? 0.72 : 1.0);
    return Image.asset(
      'assets/mascot/${widget.mood.name}.png',
      width: extent,
      height: extent,
      fit: BoxFit.contain,
      // Art is drawn at the size it will be shown, so let Flutter decode it
      // that way instead of holding a full-resolution bitmap per mood.
      cacheWidth: (extent * 3).round(),
      errorBuilder: (context, error, stack) => Text(
        emoji,
        style: TextStyle(fontSize: extent * 0.7),
      ),
    );
  }

  Widget _buildZzz(double t) {
    return Positioned(
      top: widget.size * (0.08 - 0.03 * t),
      right: widget.size * 0.08,
      child: Opacity(
        opacity: 0.5 + 0.5 * t,
        child: Text('💤', style: TextStyle(fontSize: widget.size * 0.18)),
      ),
    );
  }

  List<Widget> _sparkles(double t) {
    const count = 4;
    return List.generate(count, (i) {
      final angle = (i / count) * 2 * math.pi;
      final radius = widget.size * (0.38 + 0.06 * t);
      final dx = math.cos(angle) * radius;
      final dy = math.sin(angle) * radius;
      return Positioned(
        left: widget.size / 2 + dx - widget.size * 0.06,
        top: widget.size / 2 + dy - widget.size * 0.06,
        child: Opacity(
          opacity: 0.4 + 0.6 * t,
          child: Text('✨', style: TextStyle(fontSize: widget.size * 0.12)),
        ),
      );
    });
  }
}
