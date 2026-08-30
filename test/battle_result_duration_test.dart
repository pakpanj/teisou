import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The result screen shows a figure that must not move: how long the match
/// took. It used to compute that with `DateTime.now()` inside `build`, and
/// this screen is built from the match stream — writes keep landing after
/// the final round (the star result, the other player's own result), so the
/// number crept upward while the learner sat looking at it. Reported from a
/// real match: 01:15 climbing to 01:35 after the game was already won.
///
/// A source check rather than a widget test: reproducing it needs a live
/// match stream and a Firebase backend, while the defect itself is exactly
/// one readable thing — a clock read in a rebuild path.
void main() {
  test('the result duration is not read from the clock on every build', () {
    final source =
        File('lib/features/battle/battle_screen.dart').readAsStringSync();
    final start = source.indexOf('Widget _buildResult(');
    expect(start, greaterThan(-1), reason: 'the result builder is gone');
    // Bounded to _buildResult's own method, not "the rest of the file" —
    // an unbounded substring here would also (correctly) flag any later,
    // unrelated widget's own legitimate DateTime.now() use (e.g. the
    // 30-second reconnect grace period's own live countdown banner,
    // added 2026-08-30, which lives further down this same file and has
    // nothing to do with the result screen's duration figure) as if it
    // were this bug reappearing.
    final end = source.indexOf('\n  /// Every round that actually resolved');
    expect(end, greaterThan(start), reason: '_reviewCards marker moved');
    final body = source.substring(start, end);

    expect(
      body.contains('DateTime.now()'),
      isFalse,
      reason: 'the result screen reads the clock while building, so anything '
          'derived from it grows every time the match stream emits',
    );
  });

  test('the end of the match is stamped exactly once, where it concludes', () {
    final source =
        File('lib/features/battle/battle_screen.dart').readAsStringSync();
    expect(source.contains('_finishedAt = DateTime.now();'), isTrue);
    // Stamped in the one place a match can conclude, so the figure cannot
    // depend on when the screen happened to be rebuilt.
    final conclude = source.indexOf('void _maybeConclude(');
    final stamp = source.indexOf('_finishedAt = DateTime.now();');
    final nextMethod = source.indexOf('void _ensureTimerFor(');
    expect(
      stamp > conclude && stamp < nextMethod,
      isTrue,
      reason: 'the end time is stamped somewhere other than the conclusion',
    );
  });
}
