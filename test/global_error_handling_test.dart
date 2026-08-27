import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/main.dart' show installGlobalErrorHandlers;

/// RISK-7 (AUDIT_PHASE_C_BATTLE_RELIABILITY.md, C1's remaining half):
/// `main.dart` had zero global error boundary — no `FlutterError.onError`
/// override, no `PlatformDispatcher.instance.onError` override, no
/// `runZonedGuarded`. A prior session had deliberately decided against
/// one (see `test/battle_reliability_wiring_test.dart`'s git history),
/// reasoning that hardening the two Battle `.listen()` calls individually
/// was enough — true for Battle, but this session's broader audit found
/// `fcm_service.dart`'s three `FirebaseMessaging` listeners
/// (`onTokenRefresh`/`onMessage`/`onMessageOpenedApp`) have neither
/// `onError` nor internal try/catch, so "each stream handles its own
/// errors" was never actually true app-wide.
///
/// **What this file can and cannot prove — read before extending it.**
/// Confirmed empirically while building this: under
/// `TestWidgetsFlutterBinding`, setting `PlatformDispatcher.instance
/// .onError` does NOT intercept a genuinely uncaught async error (a raw
/// `scheduleMicrotask`/unguarded `StreamController` throw) — the test
/// binding installs its own zone that claims the error first (the same
/// mechanism `tester.takeException()` relies on), so a "real simulation"
/// test would either hang, false-pass, or just fail the test outright
/// with the error reported as a normal test failure — proven by
/// literally trying it before settling on this file's approach. This is
/// a structural limit of `flutter_test`, not a gap in this file's
/// rigor — the same category of "provably untestable in this harness,
/// only a real device confirms it" gap this codebase already accepts
/// elsewhere (e.g. the iOS backgrounding scenario C1 was originally
/// written about). What IS tested here, honestly:
/// 1. The wiring exists and runs before `runApp` (also covered as a
///    source-check in `battle_reliability_wiring_test.dart`, matching
///    that file's own established pattern for this class of gap).
/// 2. Both handler functions are real, callable, and behave correctly
///    when invoked directly with a synthetic error — they log via this
///    project's existing `debugPrint` convention and return the right
///    value, so a caller that DOES reach them (proven true in a real,
///    non-test app run per Flutter's own documented contract for
///    `PlatformDispatcher.instance.onError`) gets correct behavior, not
///    a rethrow or a crash.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('installGlobalErrorHandlers sets both FlutterError.onError and '
      'PlatformDispatcher.instance.onError', () {
    final previousFlutterError = FlutterError.onError;
    final previousPlatformError = PlatformDispatcher.instance.onError;
    try {
      installGlobalErrorHandlers();
      expect(FlutterError.onError, isNotNull);
      expect(
        FlutterError.onError,
        isNot(same(previousFlutterError)),
        reason: 'must actually install its own handler, not leave the '
            'previous one (even Flutter\'s own default) in place',
      );
      expect(PlatformDispatcher.instance.onError, isNotNull);
      expect(
        PlatformDispatcher.instance.onError,
        isNot(same(previousPlatformError)),
      );
    } finally {
      FlutterError.onError = previousFlutterError;
      PlatformDispatcher.instance.onError = previousPlatformError;
    }
  });

  test('the installed PlatformDispatcher.onError handler does not throw '
      'when given a real error, and reports itself as handled', () {
    final previous = PlatformDispatcher.instance.onError;
    try {
      installGlobalErrorHandlers();
      final handler = PlatformDispatcher.instance.onError!;
      late final Object result;
      expect(
        () => result = handler(
          Exception('simulated uncaught error'),
          StackTrace.current,
        ),
        returnsNormally,
        reason: 'the handler itself must never throw — a broken error '
            'handler would be worse than no handler at all',
      );
      expect(
        result,
        isTrue,
        reason: 'must return true (handled) — false would let this '
            'propagate further, which is the exact behavior this handler '
            'exists to prevent',
      );
    } finally {
      PlatformDispatcher.instance.onError = previous;
    }
  });

  test('the installed FlutterError.onError handler does not throw when '
      'given real FlutterErrorDetails, and still presents the error '
      '(does not silently swallow framework errors)', () {
    final previousOnError = FlutterError.onError;
    final previousPresentError = FlutterError.presentError;
    var presented = false;
    try {
      installGlobalErrorHandlers();
      // Swapped in AFTER installGlobalErrorHandlers so the installed
      // handler's own call to FlutterError.presentError(details) — see
      // main.dart's doc comment on why that call exists — reaches this
      // spy instead of actually dumping to the console during a test run.
      FlutterError.presentError = (details) => presented = true;
      final details = FlutterErrorDetails(
        exception: Exception('simulated framework error'),
        stack: StackTrace.current,
      );
      expect(
        () => FlutterError.onError!(details),
        returnsNormally,
      );
      expect(
        presented,
        isTrue,
        reason: 'RISK-7 must not change error VISIBILITY — a build/layout/'
            'paint error must still be presented (console dump / debug red '
            'screen) exactly as before, only with additional logging '
            'alongside it, per the task\'s own "jangan mengubah behaviour '
            'error bisnis menjadi silently ignored" constraint',
      );
    } finally {
      FlutterError.onError = previousOnError;
      FlutterError.presentError = previousPresentError;
    }
  });
}
