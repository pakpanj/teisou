import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's single `Navigator`, reachable without a `BuildContext` — the
/// one thing a notification tap genuinely needs and can't otherwise have.
/// Tapping a chat/clan-message push can happen from a cold start (no
/// widget tree exists yet at all) or from deep in the background (no
/// context anywhere near the screen the tap should open), so `FcmService`
/// pushes routes through `rootNavigatorKey.currentState` instead of
/// threading a context through the whole notification pipeline.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// The same problem `rootNavigatorKey` solves for navigation, for Riverpod:
/// a [ProviderContainer] that stays valid regardless of which screen's
/// widget triggered the work needing it, or whether that widget still
/// exists by the time an `await` resolves. A widget's own `WidgetRef`
/// throws once its element is disposed — see `identity_sync.dart`'s own
/// doc comment for a real crash this caused. Resolved through the root
/// `Navigator`'s own context, which — same as `rootNavigatorKey` itself —
/// is only ever missing before the very first frame, well before anything
/// that would call this exists yet.
ProviderContainer rootProviderContainer() {
  final context = rootNavigatorKey.currentContext;
  if (context == null) {
    throw StateError(
      'rootProviderContainer() called before the root Navigator exists',
    );
  }
  return ProviderScope.containerOf(context, listen: false);
}
