import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The "Kembali ke Pertandingan" popup (2026-09-08) — moved from a card
/// scoped to Card Game Mode's own Beranda tab to an app-wide overlay so it
/// follows the learner to whatever tab/screen they're on, per the user's
/// own request: it stays up until either the X is tapped or the match it
/// offers stops being resumable, never merely because the learner switched
/// screens.
///
/// Source checks, the same reasoning `battle_reliability_wiring_test.dart`
/// already documents for this feature area: reproducing "does the popup
/// actually float above every screen" needs a live Navigator/Firestore
/// this suite has no harness for (`BattleScreen` itself already carries
/// that same limitation) — what can be verified cheaply and reliably is
/// that the wiring exists and can't quietly regress.
void main() {
  group('main.dart', () {
    late String source;
    setUpAll(() => source = File('lib/main.dart').readAsStringSync());

    test('MaterialApp.builder draws GlobalResumableMatchPopup above the '
        'navigated app, not inside any one screen', () {
      final builderStart = source.indexOf('builder: (context, child) =>');
      expect(builderStart, greaterThan(-1));
      final builderEnd = source.indexOf('\n    );', builderStart);
      final body = source.substring(builderStart, builderEnd);
      expect(body, contains('GlobalResumableMatchPopup()'));
      // Must be a Stack sibling of `child` (the real Navigator), not a
      // replacement for it — dropping `child` here would blank the whole
      // app behind the popup.
      expect(body, contains('?child'));
    });
  });

  group('battle_screen.dart — currentlyOpenMatchId', () {
    late String source;
    setUpAll(
      () =>
          source = File('lib/features/battle/battle_screen.dart')
              .readAsStringSync(),
    );

    test('BattleScreen exposes a static currentlyOpenMatchId field', () {
      expect(source, contains('static String? currentlyOpenMatchId;'));
    });

    test('initState sets it to this instance\'s own matchId', () {
      final start = source.indexOf('void initState() {');
      final end = source.indexOf('\n  }', start);
      expect(
        source.substring(start, end),
        contains('BattleScreen.currentlyOpenMatchId = widget.matchId;'),
      );
    });

    test('dispose clears it, guarded against clobbering a different, '
        'already-mounted instance\'s own matchId', () {
      final start = source.indexOf('void dispose() {');
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);
      expect(
        body,
        contains(
          'if (BattleScreen.currentlyOpenMatchId == widget.matchId) {',
        ),
      );
      expect(body, contains('BattleScreen.currentlyOpenMatchId = null;'));
    });
  });

  group('global_resumable_match_popup.dart', () {
    late String source;
    setUpAll(
      () => source =
          File('lib/features/battle/global_resumable_match_popup.dart')
              .readAsStringSync(),
    );

    test('never shows a return-to-match banner over the match already on '
        'screen', () {
      expect(
        source,
        contains('if (match.id == BattleScreen.currentlyOpenMatchId) {'),
      );
    });

    test('a dismissed match is compared by id, not remembered forever', () {
      expect(
        source,
        contains(
          'final dismissedResumableMatchIdProvider = StateProvider<String?>((_) => null);',
        ),
      );
      expect(source, contains('if (match.id == dismissedId) return const SizedBox.shrink();'));
    });

    test('the X button records this match\'s id as dismissed', () {
      final start = source.indexOf('void _dismiss() {');
      expect(start, greaterThan(-1));
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);
      expect(
        body,
        contains(
          'ref.read(dismissedResumableMatchIdProvider.notifier).state =\n        widget.matchId;',
        ),
      );
    });

    test('the CTA navigates through the root navigator, not '
        'Navigator.of(context) — this widget sits above MaterialApp\'s own '
        'Navigator, so a local context has none to find', () {
      final start = source.indexOf('Future<void> _openBattle() async {');
      expect(start, greaterThan(-1));
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);
      expect(body, contains('rootNavigatorKey.currentState?.push('));
      expect(body, contains('BattleScreen(matchId: widget.matchId)'));
    });
  });

  group('battle_invite_providers.dart — liveResumableMatchProvider', () {
    late String source;
    setUpAll(
      () => source =
          File('lib/features/battle/battle_invite_providers.dart')
              .readAsStringSync(),
    );

    test('composes the one-shot lookup with the live per-match stream, '
        're-checking isResumable on every update rather than only once', () {
      final start =
          source.indexOf('final liveResumableMatchProvider = StreamProvider');
      expect(start, greaterThan(-1));
      final body = source.substring(start);
      expect(body, contains('repository.findResumableMatch(user.uid)'));
      expect(body, contains('repository.watchMatch(found.id)'));
      expect(
        body,
        contains('if (!updated.isResumable(uid: user.uid)) {'),
        reason: 'must go back to null the moment the live match stops '
            'being resumable, not just at the moment it was first found',
      );
    });
  });

  group('card_game_shell.dart no longer owns its own resumable-match UI', () {
    test('the old, tab-scoped card and its private widgets are gone', () {
      final source =
          File('lib/features/battle/card_game_shell.dart').readAsStringSync();
      expect(source, isNot(contains('battleResumableMatchProvider')));
      expect(source, isNot(contains('class _ResumableMatchCard')));
      expect(source, isNot(contains('BattleScreen(')));
    });
  });
}
