import 'package:flutter/material.dart';

/// Custom transitions for the handful of navigations that get special
/// treatment; everything else keeps the platform-default push. Back
/// navigation reverses these automatically since [PageRouteBuilder] runs
/// the same `transitionsBuilder` on pop.
class AppNavigator {
  AppNavigator._();

  static const _duration = Duration(milliseconds: 350);

  /// Home/Modules -> FlashcardScreen: slide in from the right + fade.
  static Future<T?> slideFromRight<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      _route(page, _slideFromRightTransition),
    );
  }

  /// Home/Modules -> ExamModePickerScreen / ExamScreen: slide up from the
  /// bottom, like a modal flow starting.
  static Future<T?> slideFromBottom<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      _route(page, _slideFromBottomTransition),
    );
  }

  /// ExamScreen -> ExamResultScreen: fade + scale, a small dramatic reveal.
  static Future<T?> replaceFadeScale<T>(BuildContext context, Widget page) {
    return Navigator.of(context).pushReplacement<T, void>(
      _route(page, _fadeScaleTransition),
    );
  }

  static PageRouteBuilder<T> _route<T>(
    Widget page,
    Widget Function(
      BuildContext,
      Animation<double>,
      Animation<double>,
      Widget,
    )
    transitionsBuilder,
  ) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: transitionsBuilder,
      transitionDuration: _duration,
      reverseTransitionDuration: _duration,
    );
  }

  static Widget _slideFromRightTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    );
  }

  static Widget _slideFromBottomTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    );
  }

  static Widget _fadeScaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
        child: child,
      ),
    );
  }
}
