import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// C1 hardening (AUDIT_PHASE_C_BATTLE_RELIABILITY.md) — every stream this
/// feature listens to must have an `onError` handler, and every
/// timer/subscription created must be cancelled on dispose.
///
/// Source checks, the same reasoning `coach_wiring_test.dart` already
/// documents for this codebase: the failure mode here is not a screen
/// crashing loudly in a test run — it is a stream error reaching an
/// uncaught-exception path only once, on someone's phone, usually after
/// an iOS background/foreground cycle a widget test cannot easily
/// reproduce without a live Firestore/RTDB backend. What can be verified
/// cheaply and reliably is that the wiring exists at all, and that a
/// future edit to these files doesn't quietly drop it.
void main() {
  group('battle_screen.dart', () {
    late String source;
    setUpAll(
      () =>
          source = File('lib/features/battle/battle_screen.dart')
              .readAsStringSync(),
    );

    test('the answers stream is subscribed with an onError handler', () {
      expect(source, contains('onError: _onAnswersError'));
    });

    test('a stream error re-subscribes rather than leaving a dead listener',
        () {
      final errorHandlerStart = source.indexOf('void _onAnswersError(');
      expect(errorHandlerStart, greaterThan(-1));
      final handlerEnd = source.indexOf('\n  }', errorHandlerStart);
      final handlerBody =
          source.substring(errorHandlerStart, handlerEnd);

      expect(handlerBody, contains('_answersSub?.cancel()'));
      expect(handlerBody, contains('_subscribeToAnswers()'));
      // Must bail out on a disposed widget rather than touching `ref`/
      // `setState` after the fact. `_isClosing` closes a race `mounted`
      // alone does not — see `_isClosing`'s own doc comment in
      // battle_screen.dart.
      expect(handlerBody, contains('if (_isClosing || !mounted) return;'));
    });

    test('dispose cancels every timer and subscription this screen owns',
        () {
      final disposeStart = source.indexOf('void dispose() {');
      expect(disposeStart, greaterThan(-1));
      final disposeEnd = source.indexOf('\n  }', disposeStart);
      final disposeBody = source.substring(disposeStart, disposeEnd);

      expect(disposeBody, contains('_timer?.cancel()'));
      expect(disposeBody, contains('_choiceDeadlineTimer?.cancel()'),
          reason: 'the face-down-card reveal timer was previously '
              'untracked and never cancelled on dispose');
      expect(disposeBody, contains('_answersSub?.cancel()'));
    });

    test('the choice-deadline timer is tracked in a field, not a bare local',
        () {
      expect(source, contains('Timer? _choiceDeadlineTimer;'));
      expect(
        source,
        contains('_choiceDeadlineTimer = Timer('),
        reason: 'must be assigned to the tracked field, not a bare '
            'local Timer(...) that dispose() cannot reach',
      );
    });
  });

  group('battle_matchmaking_screen.dart', () {
    late String source;
    setUpAll(
      () =>
          source = File('lib/features/battle/battle_matchmaking_screen.dart')
              .readAsStringSync(),
    );

    test('the matchmaking result stream is subscribed with an onError '
        'handler', () {
      expect(source, contains('onError: (Object error) {'));
    });
  });

  group('global error handler (RISK-7, supersedes the old "no new global '
      'error handler" decision below)', () {
    // Correction, RISK-7: this group used to assert the OPPOSITE — that
    // main.dart deliberately had no global error handler, reasoning "each
    // stream now handles its own errors" was true for Battle specifically.
    // A broader audit found that premise doesn't hold app-wide
    // (fcm_service.dart's three FirebaseMessaging listeners have neither
    // onError nor internal try/catch) — see installGlobalErrorHandlers'
    // own doc comment in main.dart for the full reasoning. Full behavioral
    // coverage lives in test/global_error_handling_test.dart; this is just
    // the source-check confirming main.dart actually wires it in, matching
    // this file's own established pattern for the two Battle listeners
    // above.
    test('main.dart installs the global error boundary before runApp', () {
      final source = File('lib/main.dart').readAsStringSync();
      expect(source, contains('installGlobalErrorHandlers();'));
      final installIndex = source.indexOf('installGlobalErrorHandlers();');
      final runAppIndex = source.indexOf('runApp(');
      expect(installIndex, greaterThan(-1));
      expect(runAppIndex, greaterThan(-1));
      expect(
        installIndex,
        lessThan(runAppIndex),
        reason: 'the boundary must be installed before runApp, or an error '
            'during startup itself would go uncaught',
      );
    });
  });
}
