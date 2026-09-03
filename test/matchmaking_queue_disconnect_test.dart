import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// H3 (AUDIT_ARSITEKTUR_PRESENCE_LIFECYCLE_MODE_KARTU.md) — a player who
/// force-closes/loses signal while alone in `matchmakingQueue/{tier}/{uid}`
/// (nobody has claimed them yet) used to leave that node orphaned forever,
/// since nothing else was ever going to remove it — `functions/
/// battle_matchmaking.js`'s trigger would happily pair a real, present
/// player against this ghost the next time anyone joined the same tier,
/// no matter how much later.
///
/// Source check, the same reasoning this project already uses for every
/// Realtime Database write this test suite has no live instance to verify
/// against (see `battle_reliability_wiring_test.dart`'s own doc comment):
/// what can be verified cheaply and reliably is that `joinQueue` registers
/// `onDisconnect().remove()` — mirroring `PresenceService.goOnline`'s
/// already-proven-live pattern exactly — *before* the actual queue write,
/// and that `leaveQueue` cancels it again on a voluntary leave.
void main() {
  group('matchmaking_repository.dart', () {
    late String source;
    setUpAll(
      () => source = File(
        'lib/data/repositories/matchmaking_repository.dart',
      ).readAsStringSync(),
    );

    test('joinQueue registers onDisconnect().remove() before writing the '
        'queue entry — same ordering as PresenceService.goOnline, so a '
        'disconnect landing in the gap between the two still leaves the '
        'right thing behind', () {
      final start = source.indexOf('Future<void> joinQueue(');
      expect(start, greaterThan(-1));
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);

      final onDisconnectIndex = body.indexOf('.onDisconnect().remove()');
      final setIndex = body.indexOf('.set({');
      expect(onDisconnectIndex, greaterThan(-1));
      expect(setIndex, greaterThan(-1));
      expect(
        onDisconnectIndex,
        lessThan(setIndex),
        reason: 'registering the disconnect handler after the write would '
            'leave a real window where a drop mid-registration orphans '
            'the queue entry anyway',
      );
    });

    test('leaveQueue cancels the pending onDisconnect registration before '
        'removing the entry itself', () {
      final start = source.indexOf('Future<void> leaveQueue(');
      expect(start, greaterThan(-1));
      final end = source.indexOf('\n  }', start);
      final body = source.substring(start, end);
      expect(body, contains('.onDisconnect().cancel()'));
      expect(body, contains('.remove()'));
    });
  });
}
