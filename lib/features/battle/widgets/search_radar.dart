import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/mascot_widget.dart';

/// The "looking for someone" dial from the redesign: rings, a sweeping
/// beam, and the mascot in the middle with its magnifying glass.
///
/// **It is showing that the app is doing something, not what it found.**
/// Matchmaking gives no progress to report — a player is either paired
/// or not — so a bar that filled would be a lie. A sweep says "still
/// looking" honestly, and the countdown beneath it carries the only real
/// number there is.
class SearchRadar extends StatefulWidget {
  const SearchRadar({super.key, this.size = 190});

  final double size;

  @override
  State<SearchRadar> createState() => _SearchRadarState();
}

class _SearchRadarState extends State<SearchRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _sweep,
            builder: (context, _) => CustomPaint(
              size: Size.square(widget.size),
              painter: _RadarPainter(
                palette: palette,
                turns: _sweep.value,
              ),
            ),
          ),
          MascotWidget(
            mood: MascotMood.searching,
            size: widget.size * 0.52,
            showBackdrop: false,
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.palette, required this.turns});

  final AppPalette palette;
  final double turns;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(
      centre,
      radius,
      Paint()..color = palette.hiraganaCardBg.withValues(alpha: 0.55),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = palette.primaryCoral.withValues(alpha: 0.28);
    for (final r in [0.42, 0.71, 1.0]) {
      canvas.drawCircle(centre, radius * r, ring);
    }

    // The beam: a wedge that fades out behind itself, so the direction
    // of travel reads without any motion blur to draw.
    final start = turns * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      start,
      math.pi / 3,
      true,
      Paint()
        ..shader = SweepGradient(
          startAngle: start,
          endAngle: start + math.pi / 3,
          colors: [
            palette.primaryCoral.withValues(alpha: 0.0),
            palette.primaryCoral.withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );

    // A blip riding the beam. Deliberately decorative — it marks nobody,
    // and sits on the outer ring where it cannot be mistaken for a
    // player who has been found.
    final blip = Offset(
      centre.dx + math.cos(start) * radius * 0.71,
      centre.dy + math.sin(start) * radius * 0.71,
    );
    canvas.drawCircle(
      blip,
      4,
      Paint()..color = palette.primaryCoral.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.turns != turns;
}
