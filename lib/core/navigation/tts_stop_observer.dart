import 'package:flutter/widgets.dart';

/// Stops Japanese speech when the screen that started it goes away.
///
/// `ttsServiceProvider` is a plain `Provider`, so one [TtsService] — and
/// one Android TTS engine — is shared by the whole app. Nothing was
/// stopping it on navigation, so a sentence started on a detail screen
/// kept being read aloud over whatever came next: over the home screen,
/// over the next chapter, over a listening-exam result page.
///
/// Eleven screens speak, and four of them ([ChoukaiExamScreen] among
/// them, which plays the longest clips in the app) are `ConsumerWidget`s
/// with no `dispose()` to hang a `stop()` call on. Handling it once here
/// covers all eleven, covers `AppNavigator.replaceFadeScale`'s route swap
/// when a Choukai exam finishes mid-clip, and means a screen added later
/// cannot reintroduce the bug by forgetting the call.
///
/// [onLeaveRoute] is a callback rather than a `TtsService` so this stays
/// testable without a platform channel.
class TtsStopObserver extends NavigatorObserver {
  TtsStopObserver(this.onLeaveRoute);

  final VoidCallback onLeaveRoute;

  /// Pushing forward counts as leaving too: tapping through to another
  /// screen while a word is being read has the same result as pressing
  /// back. A route that speaks on arrival is unaffected — `didPush` runs
  /// before that route builds.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onLeaveRoute();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onLeaveRoute();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onLeaveRoute();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onLeaveRoute();
    super.didRemove(route, previousRoute);
  }
}
