import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A card that flips on tap between [front] and [back]. Give it a `key`
/// tied to the current item's id so switching cards resets it to the
/// front side.
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final ValueChanged<bool>? onFlipped;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.onFlipped,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  bool _isFront = true;

  void _toggle() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
    widget.onFlipped?.call(_isFront);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * math.pi;
          final showFront = angle <= math.pi / 2;
          final displayAngle = showFront ? angle : angle - math.pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(displayAngle),
            child: showFront ? widget.front : widget.back,
          );
        },
      ),
    );
  }
}
