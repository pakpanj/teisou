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
      expect(disposeBody, contains('_matchSub?.cancel()'),
          reason: 'the manually-managed match subscription (replacing '
              'ref.watch(battleMatchProvider(...)) — see _matchSub\'s own '
              'doc comment) must be cancelled here just like every other '
              'subscription this screen owns, or it leaks the same way '
              'the Riverpod listener it replaced did');
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

  // C1 (LAPORAN_FIX_FEEDBACKHOLDTIMER_DAN_AUDIT_FORENSIK_RIVERPOD.md) — the
  // Riverpod listener leak proven on-device: resuming the same active match
  // repeatedly left every earlier `BattleScreen` instance's
  // `ref.watch(battleMatchProvider(...))` listener attached forever (its
  // `ConsumerStatefulElement` bookkeeping never dropped to zero — confirmed
  // via dedicated logging instrumentation: the provider's builder ran once
  // for ten resumed instances, `onCancel`/`onResume` never fired, and stale
  // listeners kept throwing `_ElementLifecycle.defunct` minutes after their
  // owning widget had already disposed cleanly). Fixed by removing the
  // `ref.watch()` call from this screen entirely — see [_matchSub]'s own doc
  // comment in `battle_screen.dart`. The real behavioral stress test for
  // "does this pattern actually avoid piling up listeners across repeated
  // resume cycles" lives in
  // `test/battle_match_subscription_stress_test.dart` — `BattleScreen`
  // itself needs a live Firestore/Riverpod match this test suite has no
  // harness for (see `battle_answer_feedback_c4_test.dart`'s own doc
  // comment), so that file drives the *pattern* through real Flutter
  // Element lifecycle instead. What is verified here, cheaply, is that the
  // live code is actually shaped that way and can't quietly regress back to
  // `ref.watch(battleMatchProvider(...))`.
  group('battle_screen.dart — C1 Riverpod listener leak fix', () {
    late String source;
    setUpAll(
      () =>
          source = File('lib/features/battle/battle_screen.dart')
              .readAsStringSync(),
    );

    test(
      '_BattleScreenState never calls ref.watch or ref.read on '
      'battleMatchProvider — the exact call that leaked',
      () {
        // battleMatchProvider itself is untouched and still legitimately
        // named in doc comments (explaining the fix, always spelled with a
        // literal `(...)` placeholder there, never a real argument) and
        // imports — what must never come back is an actual watch/read call
        // on it, which would always be written with the real argument,
        // `widget.matchId`.
        expect(
          source,
          isNot(contains('ref.watch(battleMatchProvider(widget.matchId)')),
        );
        expect(
          source,
          isNot(contains('ref.read(battleMatchProvider(widget.matchId)')),
        );
      },
    );

    test('the match is subscribed manually via _matchSub, mirroring the '
        'already-safe _answersSub pattern exactly', () {
      expect(source, contains('StreamSubscription<BattleMatch>? _matchSub;'));
      expect(source, contains('void _subscribeToMatch() {'));
      expect(source, contains('.watchMatch(widget.matchId)'));
      expect(source, contains('.listen(_onMatchUpdate, onError: _onMatchError)'));
    });

    test('_subscribeToMatch is called from initState, same as '
        '_subscribeToAnswers', () {
      final start = source.indexOf('void initState() {');
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);
      expect(body, contains('_subscribeToAnswers();'));
      expect(body, contains('_subscribeToMatch();'));
    });

    test('_onMatchUpdate and _onMatchError both bail out on a closing/'
        'disposed screen before touching setState/ref', () {
      for (final signature in [
        'void _onMatchUpdate(BattleMatch match) {',
        'void _onMatchError(Object error, StackTrace stackTrace) {',
      ]) {
        final start = source.indexOf(signature);
        expect(start, greaterThan(-1), reason: signature);
        final end = source.indexOf('\n  }', start);
        final body = source.substring(start, end);
        expect(
          body,
          contains('if (_isClosing || !mounted) return;'),
          reason: '$signature must use the same lifecycle gate every other '
              'callback in this screen does',
        );
      }
    });

    test('_matchSub is cancelled in dispose', () {
      final start = source.indexOf('void dispose() {');
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);
      expect(body, contains('_matchSub?.cancel();'));
    });

    test('every former read site (absence-mark, answers update, choice '
        'deadline, card picker) now reads _match instead of the provider',
        () {
      // _maybeMarkAbsentOnLeave
      final abandonStart = source.indexOf('void _maybeMarkAbsentOnLeave() {');
      expect(abandonStart, greaterThan(-1));
      final abandonEnd = source.indexOf('\n  }', abandonStart);
      expect(
        source.substring(abandonStart, abandonEnd),
        contains('final match = _match;'),
      );

      // _onAnswersUpdate
      final answersStart = source.indexOf('Future<void> _onAnswersUpdate(');
      expect(answersStart, greaterThan(-1));
      final answersEnd = source.indexOf('\n  }', answersStart);
      expect(
        source.substring(answersStart, answersEnd),
        contains('final match = _match;'),
      );

      // build() itself reads _match/_matchError, not an AsyncValue
      final buildStart = source.indexOf('Widget build(BuildContext context) {');
      expect(buildStart, greaterThan(-1));
      final buildEnd = source.indexOf('\n  }', buildStart);
      final buildBody = source.substring(buildStart, buildEnd);
      expect(buildBody, contains('final matchError = _matchError;'));
      expect(buildBody, contains('final match = _match;'));
    });
  });

  group('two-sided absence / pause system (2026-09)', () {
    late String repoSource;
    late String screenSource;
    late String rulesSource;
    setUpAll(() {
      // Normalized to `\n` — this repo's files are CRLF on disk, and a
      // multi-line `contains(...)` check written with plain `\n` between
      // lines (the only sane way to write one in Dart source) would
      // otherwise never match a `\r\n`-terminated file.
      String normalize(String path) =>
          File(path).readAsStringSync().replaceAll('\r\n', '\n');
      repoSource = normalize('lib/data/repositories/battle_repository.dart');
      screenSource = normalize('lib/features/battle/battle_screen.dart');
      rulesSource = normalize('firestore.rules');
    });

    test('markAbsent and clearAbsence exist as transactions, not plain '
        'merge writes — a full-map read-then-write is what makes the '
        'per-uid add/remove safe against a concurrent write from the '
        'other player', () {
      final markStart = repoSource.indexOf('Future<void> markAbsent(');
      expect(markStart, greaterThan(-1));
      final markEnd = repoSource.indexOf('\n  }\n', markStart);
      final markBody = repoSource.substring(markStart, markEnd);
      expect(markBody, contains('runTransaction'));
      expect(
        markBody,
        contains("(data['status'] as String? ?? 'active') != 'active') return;"),
        reason: 'must refuse to reopen a finished/abandoned match into a '
            'paused one',
      );

      final clearStart = repoSource.indexOf('Future<void> clearAbsence(');
      expect(clearStart, greaterThan(-1));
      final clearEnd = repoSource.indexOf('\n  }\n', clearStart);
      final clearBody = repoSource.substring(clearStart, clearEnd);
      expect(clearBody, contains('runTransaction'));
      expect(
        clearBody,
        contains("updates['turnStartedAt'] = FieldValue.serverTimestamp();"),
        reason: 'resuming from a pause must give the round a fresh clock, '
            'not resume one that may have already run out unseen',
      );
    });

    test('findResumableMatch checks isResumable with the caller\'s own '
        'uid, not the old no-argument form', () {
      expect(repoSource, contains('match.isResumable(uid: uid)'));
    });

    test('_onMatchUpdate calls _maybeConclude — the one call site that '
        'notices a server-only conclusion (an absence-timeout win, or '
        'an abandoned match) the moment it happens, not only when this '
        'device\'s own answers stream produces a new round to tally',
        () {
      final start = screenSource.indexOf('void _onMatchUpdate(BattleMatch match) {');
      expect(start, greaterThan(-1));
      final end = screenSource.indexOf('\n  }', start);
      expect(screenSource.substring(start, end), contains('_maybeConclude(match);'));
    });

    test('_maybeConclude falls back to the server\'s own status/result '
        'once the local tally cannot decide, and treats an abandoned '
        'match as its own outcome rather than a draw', () {
      final start = screenSource.indexOf('void _maybeConclude(BattleMatch match) {');
      expect(start, greaterThan(-1));
      final end = screenSource.indexOf('\n  }\n', start);
      final body = screenSource.substring(start, end);
      expect(body, contains('match.status != BattleMatchStatus.active'));
      expect(body, contains("conclusion = 'abandoned';"));
      expect(
        body,
        contains("if (conclusion != 'abandoned') {"),
        reason: 'the abandoned sentinel must never be persisted via '
            'setClientResult, or outcomeFor would misread it as a loss '
            'for both players',
      );
    });

    test('_buildBody only treats the opponent as paused while the match '
        'is still active — a finalized match must never show a stale '
        'pause screen', () {
      expect(
        screenSource,
        contains('match.status == BattleMatchStatus.active\n        ? match.absenceOf(opponentUid)\n        : null;'),
      );
    });

    test('firestore.rules lets a player add or remove exactly their own '
        'absence key, keyed off request.auth.uid, never an arbitrary '
        'uid', () {
      final start = rulesSource.indexOf('// `absence` — a map keyed by uid');
      expect(start, greaterThan(-1));
      final end = rulesSource.indexOf('\n          );', start);
      final block = rulesSource.substring(start, end);
      expect(block, contains('.affectedKeys().hasOnly([request.auth.uid])'));
      expect(block, contains("request.resource.data.absence[request.auth.uid].since == request.time"));
      expect(
        block,
        contains("resource.data.status == 'active'"),
        reason: 'a concluded match must never be reopened by a late '
            'absence write',
      );
    });

    test('firestore.rules freezes currentRound/playedCards while either '
        'side of a write has anyone in absence — the cheat a client '
        'could otherwise use to keep forcing rounds forward during a '
        'pause', () {
      final start = rulesSource.indexOf('// A match with anyone in `absence`');
      expect(start, greaterThan(-1));
      final end = rulesSource.indexOf('\n          );', start);
      final block = rulesSource.substring(start, end);
      expect(block, contains("request.resource.data.get('currentRound', 0) =="));
      expect(block, contains("request.resource.data.get('playedCards', {}) =="));
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

  // 2026-09-04 — real, on-device root cause: `dispose()` calling
  // `_maybeMarkAbsentOnLeave()`, which called `ref.read(appStartupProvider)`/
  // `ref.read(battleRepositoryProvider)` directly, threw `Bad state: Cannot
  // use "ref" after the widget was disposed.` — silently, caught nowhere in
  // the chain, so `markAbsent()` was **never actually reached** from a real
  // leave despite every earlier guard clause evaluating correctly. Confirmed
  // via `[ABSENCE_TRACE]` logcat instrumentation on a physical device: the
  // trace stopped dead right after `MAYBE_MARK_ABSENT_ENTRY`, with
  // `FlutterError: Bad state: Cannot use "ref" after the widget was
  // disposed.` appearing in the very next log line. Fixed by capturing both
  // values into plain fields while `ref` is still guaranteed valid
  // (`initState`, re-confirmed in `deactivate`) and having
  // `_maybeMarkAbsentOnLeave` read only those fields, never `ref`, again.
  group('battle_screen.dart — absence-mark ref-after-dispose fix '
      '(2026-09-04)', () {
    late String source;
    setUpAll(
      () =>
          source = File('lib/features/battle/battle_screen.dart')
              .readAsStringSync(),
    );

    test('_maybeMarkAbsentOnLeave never calls ref.read — this is the exact '
        'line that threw "Bad state: Cannot use \'ref\' after the widget '
        'was disposed." when called from dispose()', () {
      final start = source.indexOf('void _maybeMarkAbsentOnLeave() {');
      expect(start, greaterThan(-1));
      final end = source.indexOf('\n  }', start);
      expect(end, greaterThan(-1));
      final body = source.substring(start, end);
      expect(
        body,
        isNot(contains('ref.read(')),
        reason: 'dispose() cannot safely call ref.read() by the time this '
            'method runs — Riverpod\'s own element teardown invalidates '
            '`ref` before State.dispose() runs, even though dispose() is '
            'textually still part of this same widget. Any live ref access '
            'here silently breaks the whole leave-detection path again.',
      );
    });

    test('the uid and repository markAbsent needs are captured as plain '
        'fields, not read live from ref', () {
      expect(source, contains('String? _uidForLeave;'));
      expect(source, contains('BattleRepository? _repositoryForLeave;'));
      final start = source.indexOf('void _maybeMarkAbsentOnLeave() {');
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);
      expect(body, contains('final myUid = _uidForLeave;'));
      expect(body, contains('final repository = _repositoryForLeave;'));
      expect(body, contains('repository.markAbsent(widget.matchId, myUid);'));
    });

    test('initState captures both fields — the path didChangeAppLifecycleState '
        'also depends on, since backgrounding calls _maybeMarkAbsentOnLeave '
        'while the screen is still fully mounted (ref valid) but deactivate() '
        'has not run yet; capturing only in deactivate() would leave these '
        'null the first time that path fires', () {
      final start = source.indexOf('void initState() {');
      expect(start, greaterThan(-1));
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);
      expect(
        body,
        contains(
          '_uidForLeave = ref.read(appStartupProvider).valueOrNull?.uid;',
        ),
      );
      expect(
        body,
        contains('_repositoryForLeave = ref.read(battleRepositoryProvider);'),
      );
    });

    test('deactivate re-captures both fields as a defensive refresh '
        'immediately before the leave path, while ref is still valid', () {
      final start = source.indexOf('void deactivate() {');
      expect(start, greaterThan(-1));
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);
      expect(
        body,
        contains(
          '_uidForLeave = ref.read(appStartupProvider).valueOrNull?.uid;',
        ),
      );
      expect(
        body,
        contains('_repositoryForLeave = ref.read(battleRepositoryProvider);'),
      );
    });

    test('dispose still calls _maybeMarkAbsentOnLeave, and does so without '
        'any ref access of its own', () {
      final start = source.indexOf('void dispose() {');
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);
      expect(body, contains('_maybeMarkAbsentOnLeave();'));
      expect(
        body,
        isNot(contains('ref.read(')),
        reason: 'dispose() itself must never touch ref, matching '
            '_maybeMarkAbsentOnLeave\'s own rule',
      );
    });

    test('every call site that creates a BattleScreen pushes it as a fresh '
        'route — the audit this fix depends on: deactivate() must always '
        'precede a genuine dispose() for this screen, never a reparent, or '
        'marking absence from deactivate-captured state would be wrong', () {
      for (final path in [
        'lib/features/battle/battle_challenge.dart',
        'lib/features/battle/battle_matchmaking_screen.dart',
        'lib/features/battle/battle_invite_waiting_screen.dart',
        'lib/features/battle/card_game_shell.dart',
      ]) {
        final fileSource = File(path).readAsStringSync();
        expect(
          fileSource,
          contains('BattleScreen('),
          reason: '$path should still construct BattleScreen — update this '
              'list if that call site moved',
        );
      }
      // The one place BattleScreen's own class is declared — confirms the
      // widget itself is still a plain ConsumerStatefulWidget, not
      // reparented via IndexedStack/PageView/GlobalKey anywhere.
      expect(
        source,
        contains('class BattleScreen extends ConsumerStatefulWidget'),
      );
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
