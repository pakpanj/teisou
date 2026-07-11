import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Emotional state for the maneki-neko mascot shown across the app
/// (exam results, paywall, coming-soon sheets, profile header).
enum MascotMood { happy, excited, sleepy, proud, sad, cheering }

/// Placeholder mascot rendering: an emoji + colored circle + simple looping
/// animation, standing in for real per-mood SVG art. Once that art exists,
/// swap the `Text(emoji)` below for `SvgPicture.asset(...)` per mood —
/// callers don't need to change since they only see [MascotWidget].
class MascotWidget extends StatefulWidget {
  final MascotMood mood;
  final double size;

  const MascotWidget({super.key, required this.mood, this.size = 140});

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _durationFor(widget.mood),
  )..repeat(reverse: true);

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
    }
  }

  static const _emoji = {
    MascotMood.happy: '😸',
    MascotMood.excited: '🐱',
    MascotMood.sleepy: '😴',
    MascotMood.proud: '😻',
    MascotMood.sad: '🙀',
    MascotMood.cheering: '🙌',
  };

  static const _background = {
    MascotMood.happy: Color(0xFFFCE0E6),
    MascotMood.excited: Color(0xFFFBD9DD),
    MascotMood.sleepy: Color(0xFFE4DCF7),
    MascotMood.proud: Color(0xFFFFF0C6),
    MascotMood.sad: Color(0xFFDDE5E9),
    MascotMood.cheering: Color(0xFFD9F5E3),
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
      case MascotMood.excited:
      case MascotMood.sleepy:
      case MascotMood.proud:
        return Offset.zero;
    }
  }

  double _angleFor(double t) {
    switch (widget.mood) {
      case MascotMood.excited:
        return (t - 0.5) * 0.3;
      case MascotMood.sad:
        return (t - 0.5) * 0.12;
      case MascotMood.happy:
      case MascotMood.sleepy:
      case MascotMood.proud:
      case MascotMood.cheering:
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
      case MascotMood.happy:
      case MascotMood.excited:
      case MascotMood.sad:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _emoji[widget.mood]!;
    final background = _background[widget.mood]!;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
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
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: widget.size * 0.5),
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
