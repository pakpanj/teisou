import 'package:flutter/material.dart';

/// Wraps [child] with horizontal-swipe next/prev detection. Generic on
/// purpose (no flashcard-specific typing) so other next/prev screens
/// (kotoba/kanji word detail) can reuse it later without changes here.
class SwipeNavigator extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const SwipeNavigator({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  static const _velocityThreshold = 300.0;

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -_velocityThreshold) {
      onSwipeLeft?.call();
    } else if (velocity > _velocityThreshold) {
      onSwipeRight?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onHorizontalDragEnd: _handleDragEnd, child: child);
  }
}
