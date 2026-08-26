import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kana_master/core/localization/app_strings.dart';
import 'package:kana_master/data/models/app_language.dart';

/// C4 (Battle Answer Feedback, Alternative B) — the fixed
/// `_flashColor`/`_heldRound` mechanism, the "Benar!"/"Salah!" badge, and
/// the self-only haptic.
///
/// Source checks, the same reasoning `battle_reliability_wiring_test.dart`
/// already documents for this exact file: `_BattleScreenState` and
/// `_AnswerFeedbackBadge` are library-private, so a test file (a
/// different library) cannot construct or drive them directly, and
/// `BattleScreen` itself needs a live Firestore/Riverpod match to pump as
/// a widget — no such harness exists for this screen anywhere in this
/// project's test suite (every other `battle_*_test.dart` file tests pure
/// logic or does the same source-check style this file uses). What can be
/// verified cheaply and reliably is that the wiring exists, is shaped the
/// way the locked C4 spec requires, and that a future edit can't quietly
/// drop it.
///
/// Finds a function/method's own closing brace — the one alone on its own
/// line at 2-space (method) indent — starting the search from [start].
/// Plain `indexOf('\n  }', start)` (this project's usual convention, see
/// `battle_reliability_wiring_test.dart`) is not safe for every function
/// touched by this phase: a multi-line named-parameter list closes with
/// `  }) {` on its own line, which also contains the substring `\n  }` and
/// matches far too early — hit for real on `_showRoundFeedback`'s
/// multi-line signature while writing this file. Requiring the closing
/// brace to be followed by a real line break (`\r?\n`, this repo's source
/// files use CRLF) rules that out, since `  }) {` is followed by `) {`,
/// not a newline.
int _endOfFunction(String source, int start) {
  final match = RegExp(r'\n {2}\}\r?\n').firstMatch(source.substring(start));
  return match == null ? -1 : start + match.start;
}

/// A faithful mirror of `_onAnswersUpdate`'s own "which round gets the
/// transient feedback" selection in `battle_screen.dart` — same control
/// flow: skip anything in [alreadyKnownRounds] (mirrors the real
/// `_correctByRound.containsKey(round)` guard), then keep whichever
/// remaining round has the highest number (mirrors the real
/// `if (latestNewRound == null || round > latestNewRound)`).
///
/// **This is a logic mirror, not the live code** — `_BattleScreenState`
/// is library-private (see this file's own top-of-file doc comment), so
/// it cannot be constructed or driven from here. This proves the
/// *algorithm* picks correctly across the batch shapes a reconnect can
/// produce; the source-check group further below proves the *live code*
/// is shaped identically to this mirror (single call site, gated,
/// strictly-greater-than comparison) — same two-part pattern
/// `cosmetic_ownership_equip_test.dart`'s own "logic-mirror" group
/// already uses in this project for an analogous can't-touch-it-directly
/// situation.
({int? round, bool correct, String? byUid}) _pickFeedbackRound({
  required Map<int, ({bool correct, String byUid})> newSnapshot,
  required Set<int> alreadyKnownRounds,
}) {
  int? latestNewRound;
  var latestNewCorrect = false;
  String? latestNewByUid;
  for (final entry in newSnapshot.entries) {
    final round = entry.key;
    if (alreadyKnownRounds.contains(round)) continue;
    if (latestNewRound == null || round > latestNewRound) {
      latestNewRound = round;
      latestNewCorrect = entry.value.correct;
      latestNewByUid = entry.value.byUid;
    }
  }
  return (
    round: latestNewRound,
    correct: latestNewCorrect,
    byUid: latestNewByUid,
  );
}

void main() {
  group('battle_screen.dart', () {
    late String source;
    setUpAll(
      () =>
          source = File('lib/features/battle/battle_screen.dart')
              .readAsStringSync(),
    );

    // 1 & 2. Answer round N -> feedback uses card/round N, and stays on N
    // even once match.currentRound has already moved to N+1.
    group('the held round is independent of match.currentRound', () {
      test('_showRoundFeedback holds the round it was actually called '
          'with, not whatever match.currentRound happens to be', () {
        final start = source.indexOf('void _showRoundFeedback({');
        expect(start, greaterThan(-1));
        final end = _endOfFunction(source, start);
        final body = source.substring(start, end);
        expect(body, contains('_heldRound = round;'));
        expect(
          body,
          isNot(contains('match.currentRound')),
          reason: '_showRoundFeedback must not re-derive the round from '
              'the live match — it is only ever handed the round that '
              'just resolved',
        );
      });

      test('_buildHeldCard resolves everything from _heldRound alone, '
          'never from match.currentRound', () {
        final start = source.indexOf('Widget? _buildHeldCard(');
        expect(start, greaterThan(-1));
        final end = _endOfFunction(source, start);
        final body = source.substring(start, end);
        expect(body, contains('final heldRound = _heldRound;'));
        expect(body, contains('match.turnOrder[heldRound]'));
        expect(body, contains('match.effectiveCardId(heldRound)'));
        expect(
          body,
          isNot(contains('match.currentRound')),
          reason: 'the held card must be pinned to _heldRound regardless '
              'of where the live round has moved on to — this is the '
              'direct fix for the C4 bug',
        );
      });

      test('the bottom control area (choosing/keyboard/waiting) is built '
          'from the live match state, never from _heldRound', () {
        // The C4 spec's own constraint: only the card VISUAL may be held;
        // choosing/iChoose/isAnswerer — which drive the keyboard, the
        // choose button and the waiting text — must still come from the
        // real current round so a player can always act on it without
        // delay.
        final buildBodyStart = source.indexOf('Widget _buildBody(');
        final cardAreaCallStart = source.indexOf(
          '_buildCardArea(',
          buildBodyStart,
        );
        expect(cardAreaCallStart, greaterThan(-1));
        final cardAreaCallEnd = source.indexOf(');', cardAreaCallStart);
        final callSite =
            source.substring(cardAreaCallStart, cardAreaCallEnd);
        expect(callSite, contains('choosing: choosing'));
        expect(callSite, contains('iChoose: iChoose'));
        expect(callSite, contains('isAnswerer: isAnswerer'));
      });
    });

    // 3. After the hold -> UI returns to N+1 on its own.
    test('the feedback hold timer clears _heldRound after exactly '
        '_feedbackHoldDuration, via setState', () {
      final start = source.indexOf('void _showRoundFeedback({');
      final end = _endOfFunction(source, start);
      final body = source.substring(start, end);
      expect(
        body,
        contains(
          '_feedbackHoldTimer = Timer(_feedbackHoldDuration, () {',
        ),
      );
      expect(body, contains('setState(() => _heldRound = null);'));
      expect(body, contains('if (!mounted) return;'));
    });

    test('_feedbackHoldDuration is the locked ~700ms target', () {
      expect(
        source,
        contains(
          'static const _feedbackHoldDuration = Duration(milliseconds: 700);',
        ),
      );
    });

    test('the hold timer is cancelled on dispose, like every other timer '
        'this screen owns', () {
      final start = source.indexOf('void dispose() {');
      final end = _endOfFunction(source, start);
      final body = source.substring(start, end);
      expect(body, contains('_feedbackHoldTimer?.cancel();'));
    });

    // 4 & 5. Correct -> "Benar!" / wrong -> "Salah!" — wiring half; the
    // actual string values are checked directly against AppStrings below.
    test('_AnswerFeedbackBadge renders battleAnswerCorrect/'
        'battleAnswerWrong based on the correct flag, not a literal', () {
      final start = source.indexOf('class _AnswerFeedbackBadge');
      final end = source.indexOf('\n}', start);
      final body = source.substring(start, end);
      expect(body, contains('strings.battleAnswerCorrect'));
      expect(body, contains('strings.battleAnswerWrong'));
      // Uses this app's existing colourblind-safe correct/wrong tokens
      // (the same two _flashColor/BattleDeckStrip already use) rather
      // than green, which this app avoids everywhere else.
      expect(body, contains('palette.secondaryBlue'));
      expect(body, contains('palette.errorRed'));
      expect(body, isNot(contains('Colors.green')));
    });

    // 6 & 7. Self answer -> haptic once; enemy answer -> no haptic.
    group('haptic is self-only', () {
      test('HapticFeedback only ever fires inside the answeredByMe guard',
          () {
        final start = source.indexOf('void _showRoundFeedback({');
        final end = _endOfFunction(source, start);
        final body = source.substring(start, end);
        final guardStart = body.indexOf('if (answeredByMe) {');
        expect(guardStart, greaterThan(-1));
        // Every HapticFeedback call in this method must appear AFTER the
        // guard opens — none before it (which would mean it fires
        // unconditionally, including for the opponent's own answer).
        for (final match in RegExp(r'HapticFeedback\.\w+\(\)').allMatches(body)) {
          expect(
            match.start,
            greaterThan(guardStart),
            reason: 'a HapticFeedback call outside the answeredByMe guard '
                'would buzz for an answer this device did not give',
          );
        }
      });

      test('correct uses lightImpact, wrong uses mediumImpact — distinct '
          'feel for the two outcomes', () {
        final start = source.indexOf('void _showRoundFeedback({');
        final end = _endOfFunction(source, start);
        final body = source.substring(start, end);
        expect(body, contains('HapticFeedback.lightImpact();'));
        expect(body, contains('HapticFeedback.mediumImpact();'));
      });

      test('answeredByMe is derived from the answer\'s own byUid, not '
          'assumed', () {
        final start = source.indexOf('Future<void> _onAnswersUpdate(');
        final end = _endOfFunction(source, start);
        final body = source.substring(start, end);
        expect(
          body,
          contains('answeredByMe: myUid != null && latestNewByUid == myUid'),
        );
        expect(body, contains('latestNewByUid = e.value.byUid;'));
      });
    });

    // 8. Duplicate Firestore snapshot -> no duplicate feedback/haptic.
    test('a round already in _correctByRound can never reach '
        '_showRoundFeedback again — the same guard that makes correctness '
        'idempotent also gates the haptic/feedback trigger', () {
      final start = source.indexOf('Future<void> _onAnswersUpdate(');
      final end = _endOfFunction(source, start);
      final body = source.substring(start, end);
      final guardIndex =
          body.indexOf('if (_correctByRound.containsKey(round)) continue;');
      final feedbackCallIndex = body.indexOf('_showRoundFeedback(');
      expect(guardIndex, greaterThan(-1));
      expect(feedbackCallIndex, greaterThan(guardIndex),
          reason: '_showRoundFeedback must only be reachable for a round '
              'that just passed the containsKey guard for the first time');
      // latestNewRound (which gates the _showRoundFeedback call) is only
      // ever assigned inside the same loop iteration that also sets
      // _correctByRound[round] — never independently.
      expect(body, contains('_correctByRound[round] = correct;'));
      final setCorrectIndex = body.indexOf('_correctByRound[round] = correct;');
      final latestNewRoundAssignIndex =
          body.indexOf('latestNewRound = round;');
      expect(latestNewRoundAssignIndex, greaterThan(setCorrectIndex));
    });

    // C1 + C4 gap closed: a reconnect/re-subscribe (C1's own scenario —
    // `_onAnswersError` cancels and re-subscribes `_answersSub`) delivers
    // a fresh Firestore snapshot carrying the FULL current `answers` map,
    // not a delta — so a single `_onAnswersUpdate` call can see several
    // rounds this device has never processed before all at once. These
    // tests lock that only the highest-numbered one of those triggers
    // feedback/haptic, never the older ones, and that a single live round
    // still behaves exactly as before. See `_pickFeedbackRound`'s own doc
    // comment further down for the pure-logic half of this coverage —
    // these are the structural proof that the live code is shaped the
    // same way that logic assumes.
    group('reconnect / multi-round batch (C1 + C4)', () {
      test('_showRoundFeedback has exactly one call site in '
          '_onAnswersUpdate, reached at most once per invocation — '
          'structurally impossible to fire per-round inside the loop',
          () {
        final start = source.indexOf('Future<void> _onAnswersUpdate(');
        final end = _endOfFunction(source, start);
        final body = source.substring(start, end);

        expect(
          '_showRoundFeedback('.allMatches(body).length,
          1,
          reason: 'a second call site would mean feedback could fire more '
              'than once for a single batch of answers',
        );

        final loopStart =
            body.indexOf('for (final e in answers.entries) {');
        expect(loopStart, greaterThan(-1));
        // The loop's own closing brace sits one indent level deeper (4
        // spaces) than the method body (2 spaces) — the first `if
        // (!mounted) return;` after the loop starts is the one right
        // after it closes (see the method's own structure: the loop,
        // then this guard, then the feedback trigger).
        final postLoopGuard =
            body.indexOf('if (!mounted) return;', loopStart);
        expect(postLoopGuard, greaterThan(loopStart));

        final gateStart =
            body.indexOf('if (latestNewRound != null) {', postLoopGuard);
        final callStart = body.indexOf('_showRoundFeedback(', postLoopGuard);
        expect(gateStart, greaterThan(postLoopGuard),
            reason: 'the call must be gated, not unconditional');
        expect(callStart, greaterThan(gateStart),
            reason: 'the call must be outside the loop entirely, not just '
                'guarded — a call site left inside the loop body would '
                'fire once per new round, not once per batch');
      });

      test('the round comparison keeps the strict numeric maximum, not '
          'first-seen or last-iterated', () {
        final start = source.indexOf('Future<void> _onAnswersUpdate(');
        final end = _endOfFunction(source, start);
        final body = source.substring(start, end);
        expect(
          body,
          contains(
            'if (latestNewRound == null || round > latestNewRound) {',
          ),
          reason: 'must be a strict > comparison — >= or first-write-wins '
              'would not reliably pick the newest round out of an '
              'out-of-order batch',
        );
      });

      test('haptic calls are a genuine if/else inside _showRoundFeedback '
          '— structurally at most one fires per call, hence at most one '
          'per batch (since _showRoundFeedback itself fires at most once '
          'per batch, per the test above)', () {
        final start = source.indexOf('void _showRoundFeedback({');
        final end = _endOfFunction(source, start);
        final body = source.substring(start, end);
        final mutuallyExclusive = RegExp(
          r'if\s*\(correct\)\s*\{\s*HapticFeedback\.lightImpact\(\);\s*\}'
          r'\s*else\s*\{\s*HapticFeedback\.mediumImpact\(\);\s*\}',
        ).hasMatch(body);
        expect(
          mutuallyExclusive,
          isTrue,
          reason: 'two independent ifs (rather than if/else) could both '
              'evaluate true in principle and double-fire',
        );
      });
    });

    // 9. _deckSlots feedback (the pre-existing, working signal) is
    // untouched by this phase.
    test('_deckSlots is unchanged — still keyed off _correctByRound alone, '
        'no coupling to the new held-round mechanism', () {
      final start = source.indexOf('List<BattleSlotState> _deckSlots(');
      final end = _endOfFunction(source, start);
      final body = source.substring(start, end);
      expect(body, contains('_correctByRound[i] == true'));
      expect(body, contains('_correctByRound[i] == false'));
      expect(body, isNot(contains('_heldRound')));
      expect(body, isNot(contains('_feedbackHoldTimer')));
    });

    // 10. The next round's own timer is never delayed by the hold.
    test('_ensureTimerFor and _scheduleChoiceDeadline are untouched by '
        'this phase — neither references the held-round state at all', () {
      for (final signature in [
        'void _ensureTimerFor(BattleMatch match) {',
        'void _scheduleChoiceDeadline(BattleMatch match, {required bool ownerIsBot}) {',
      ]) {
        final start = source.indexOf(signature);
        expect(start, greaterThan(-1), reason: signature);
        final end = _endOfFunction(source, start);
        final body = source.substring(start, end);
        expect(
          body,
          isNot(contains('_heldRound')),
          reason: '$signature must not be coupled to the feedback hold — '
              'the round clock must keep running regardless of it',
        );
        expect(body, isNot(contains('_feedbackHoldTimer')));
      }
    });

    // 11. The badge never renders the raw typed answer text.
    test('_AnswerFeedbackBadge never references BattleAnswer or a raw '
        '.text field — only the derived correct/wrong boolean', () {
      final start = source.indexOf('class _AnswerFeedbackBadge');
      final end = source.indexOf('\n}', start);
      final body = source.substring(start, end);
      expect(body, isNot(contains('BattleAnswer')));
      expect(body, isNot(contains('.text')));
    });

    // 12. No platform branching introduced.
    test('no Android-only or platform-branching API was added', () {
      expect(source, isNot(contains('dart:io')));
      expect(source, isNot(contains('Platform.isAndroid')));
      expect(source, isNot(contains('Platform.isIOS')));
    });

    test('HapticFeedback is imported from the Flutter SDK, not a new '
        'package', () {
      expect(source, contains("import 'package:flutter/services.dart';"));
    });
  });

  // C1 + C4 gap closed — the pure-logic half of the reconnect/multi-round
  // batch coverage (the source-check half lives inside the
  // 'battle_screen.dart' group above, under 'reconnect / multi-round
  // batch (C1 + C4)'). Runs the actual algorithm, not just checking that
  // its shape exists in source.
  group('_pickFeedbackRound — reconnect batch picking, logic mirror', () {
    test('a normal single new round is picked unchanged — the ordinary, '
        'non-reconnect case still behaves exactly as before', () {
      final result = _pickFeedbackRound(
        newSnapshot: {7: (correct: true, byUid: 'me')},
        alreadyKnownRounds: {0, 1, 2, 3, 4, 5, 6},
      );
      expect(result.round, 7);
      expect(result.correct, isTrue);
      expect(result.byUid, 'me');
    });

    test('a reconnect snapshot with several never-seen rounds picks only '
        'the highest — the exact scenario this gap was about: rejoining '
        'mid-match delivers a backlog in one snapshot', () {
      final result = _pickFeedbackRound(
        newSnapshot: {
          15: (correct: false, byUid: 'opponent'),
          16: (correct: true, byUid: 'me'),
          17: (correct: false, byUid: 'opponent'),
        },
        alreadyKnownRounds: {for (var i = 0; i < 15; i++) i},
      );
      expect(result.round, 17,
          reason: 'rounds 15 and 16 are older and already superseded by '
              '17 within the same batch — showing feedback for them would '
              'describe a moment that has already passed');
      expect(result.correct, isFalse);
      expect(result.byUid, 'opponent');
    });

    test('rounds already known are excluded entirely, even when a known '
        'round is numerically higher than every genuinely new one', () {
      // Round 5 is already known (say, processed just before a brief
      // disconnect); the reconnect's fresh snapshot re-delivers it
      // alongside two genuinely new rounds, 3 and 4. The known round must
      // never be reconsidered just because it is numerically largest.
      final result = _pickFeedbackRound(
        newSnapshot: {
          0: (correct: true, byUid: 'me'),
          1: (correct: true, byUid: 'opponent'),
          2: (correct: false, byUid: 'me'),
          3: (correct: true, byUid: 'opponent'),
          4: (correct: false, byUid: 'me'),
          5: (correct: true, byUid: 'opponent'),
        },
        alreadyKnownRounds: {0, 1, 2, 5},
      );
      expect(result.round, 4);
    });

    test('no genuinely new rounds at all -> null, no feedback triggered '
        '— reconnecting to a match with nothing new since must stay '
        'silent, not replay old feedback', () {
      final result = _pickFeedbackRound(
        newSnapshot: {0: (correct: true, byUid: 'me'), 1: (
          correct: false,
          byUid: 'opponent',
        )},
        alreadyKnownRounds: {0, 1},
      );
      expect(result.round, isNull);
    });

    test('picks the numeric maximum regardless of Map iteration/insertion '
        'order — a Firestore snapshot is not guaranteed to iterate in '
        'round order', () {
      // Deliberately inserted out of numeric order.
      final result = _pickFeedbackRound(
        newSnapshot: {
          9: (correct: true, byUid: 'me'),
          3: (correct: false, byUid: 'opponent'),
          20: (correct: true, byUid: 'opponent'),
          11: (correct: false, byUid: 'me'),
        },
        alreadyKnownRounds: {},
      );
      expect(result.round, 20);
    });
  });

  // 4 & 5, the actual string values — a real, non-source-check test since
  // AppStrings is a plain, Firebase-free class.
  group('AppStrings — the badge wording itself', () {
    const id = AppStrings(AppLanguage.indonesian);
    const en = AppStrings(AppLanguage.english);

    test('Indonesian matches the locked spec exactly', () {
      expect(id.battleAnswerCorrect, 'Benar!');
      expect(id.battleAnswerWrong, 'Salah!');
    });

    test('English has a real translation, not a copy of the Indonesian',
        () {
      expect(en.battleAnswerCorrect, isNotEmpty);
      expect(en.battleAnswerWrong, isNotEmpty);
      expect(en.battleAnswerCorrect, isNot(id.battleAnswerCorrect));
      expect(en.battleAnswerWrong, isNot(id.battleAnswerWrong));
    });
  });
}
