import 'package:flutter/material.dart';

/// Wraps [child] with horizontal-swipe next/prev detection. Generic
/// on purpose (no module-specific typing) so any next/prev screen
/// across the app (flashcards, Kotoba/Kanji/Bunpou/Partikel word
/// detail, Kaiwa dialogues) can reuse it. Passing `null` for either
/// callback makes swiping that direction a no-op — mirrors the
/// disabled-arrow-button convention already used everywhere next/prev
/// buttons appear (`hasNext ? onNext : null`), so swipe and the arrow
/// buttons always agree on whether a direction is available.
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
