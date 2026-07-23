import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Pull-to-refresh wrapper used across every main content-listing screen
/// (Kotoba/Kanji/Bunpou/Partikel/Kaiwa's Home/Level/Category screens,
/// Profile, Leaderboard) — a thin [RefreshIndicator] with the app's brand
/// color, so the gesture looks consistent everywhere without repeating the
/// same styling at every call site. [onRefresh] should invalidate whatever
/// Riverpod provider(s) supply that screen's data and await the refreshed
/// value, e.g. `await ref.refresh(someProvider.future);`.
class AppRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primaryCoral,
      child: child,
    );
  }
}
