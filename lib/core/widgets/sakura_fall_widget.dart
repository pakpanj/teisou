import 'dart:math' as math;

import 'package:flutter/material.dart';

class _FallingPetal {
  final double xFraction;
  final double phase;
  final double speed;
  final double size;
  final double swayAmplitude;
  final double rotationSpeed;

  _FallingPetal({
    required this.xFraction,
    required this.phase,
    required this.speed,
    required this.size,
    required this.swayAmplitude,
    required this.rotationSpeed,
  });
}

/// Looping falling-sakura-petal overlay for HomeScreen. Pure
/// AnimationController + CustomPainter (no external animation package) so
/// it's cheap: one ticker, one repaint boundary, particles never
/// reallocated.
class SakuraFallWidget extends StatefulWidget {
  final int particleCount;

  const SakuraFallWidget({super.key, this.particleCount = 10});

  @override
  State<SakuraFallWidget> createState() => _SakuraFallWidgetState();
}

class _SakuraFallWidgetState extends State<SakuraFallWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_FallingPetal> _petals;

  @override
  void initState() {
    super.initState();
    final random = math.Random(7);
    _petals = List.generate(widget.particleCount, (_) {
      return _FallingPetal(
        xFraction: random.nextDouble(),
        phase: random.nextDouble(),
        speed: 0.6 + random.nextDouble() * 0.8,
        size: 10 + random.nextDouble() * 10,
        swayAmplitude: 10 + random.nextDouble() * 18,
        rotationSpeed: 0.5 + random.nextDouble(),
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _SakuraFallPainter(petals: _petals, t: _controller.value),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _SakuraFallPainter extends CustomPainter {
  final List<_FallingPetal> petals;
  final double t;

  _SakuraFallPainter({required this.petals, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF4A6B7).withValues(alpha: 0.7);

    for (final petal in petals) {
      final localT = (t * petal.speed + petal.phase) % 1.0;
      final y = -20 + localT * (size.height + 40);
      final sway = math.sin((localT * 2 * math.pi) + petal.phase * 10) * petal.swayAmplitude;
      final x = petal.xFraction * size.width + sway;
      final angle = localT * 2 * math.pi * petal.rotationSpeed;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: petal.size, height: petal.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SakuraFallPainter oldDelegate) => oldDelegate.t != t;
}
